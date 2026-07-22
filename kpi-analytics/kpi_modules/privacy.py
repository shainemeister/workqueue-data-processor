"""PHI field masking for score output (patient name / DOB).

Operational masking only — not a HIPAA Safe Harbor claim. Tokens are
batch-relative (alpha order of unique names within one score run).
"""

from __future__ import annotations

from typing import Any


def _privacy_root(cfg: dict[str, Any]) -> dict[str, Any]:
    root = cfg.get("privacy")
    return root if isinstance(root, dict) else {}


def _patient_cfg(cfg: dict[str, Any]) -> dict[str, Any]:
    p = _privacy_root(cfg).get("patient")
    return p if isinstance(p, dict) else {}


def _dob_cfg(cfg: dict[str, Any]) -> dict[str, Any]:
    d = _privacy_root(cfg).get("dob")
    return d if isinstance(d, dict) else {}


def privacy_enabled(cfg: dict[str, Any]) -> bool:
    """Return True when score-output PHI masking is active."""
    return bool(_privacy_root(cfg).get("enabled", False))


def _letters_only(value: str) -> str:
    return "".join(c for c in value if c.isalpha())


def _prefix(part: str, length: int, pad_char: str, uppercase: bool) -> str:
    letters = _letters_only(part)
    if uppercase:
        letters = letters.upper()
        pad = (pad_char or "X")[:1].upper()
    else:
        pad = (pad_char or "X")[:1]
    if length <= 0:
        return ""
    if len(letters) >= length:
        return letters[:length]
    return letters + (pad * (length - len(letters)))


def parse_person_name(
    raw: str,
    *,
    name_order: str = "last_first",
) -> tuple[str, str] | None:
    """
    Parse a patient name into (last, first).

    Expects a single comma separating the two parts. Returns None if blank
    or unparseable.
    """
    text = (raw or "").strip()
    if not text:
        return None
    if "," not in text:
        # Single token: treat as last name only
        if name_order == "first_last":
            return "", text.strip()
        return text.strip(), ""

    left, right = text.split(",", 1)
    left = left.strip()
    right = right.strip()
    # Drop further commas in the remainder (middle names stay with first side)
    if "," in right:
        right = right.split(",", 1)[0].strip()

    if name_order == "first_last":
        first, last = left, right
    else:
        last, first = left, right

    if not last and not first:
        return None
    return last, first


def normalize_person_key(
    raw: str,
    *,
    name_order: str = "last_first",
    uppercase: bool = True,
) -> str | None:
    """
    Stable identity key for token assignment (batch-unique person).

    Format: LAST,FIRST with optional uppercasing and collapsed spaces.
    """
    parsed = parse_person_name(raw, name_order=name_order)
    if parsed is None:
        return None
    last, first = parsed
    last_n = " ".join(last.split())
    first_n = " ".join(first.split())
    if uppercase:
        last_n = last_n.upper()
        first_n = first_n.upper()
    key = f"{last_n},{first_n}"
    if key == ",":
        return None
    return key


def format_masked_patient(
    raw: str,
    token: str,
    *,
    name_order: str = "last_first",
    prefix_len: int = 3,
    pad_char: str = "X",
    uppercase: bool = True,
) -> str:
    """Build LAST3+token,FIRST3+token (order always last-first in output)."""
    parsed = parse_person_name(raw, name_order=name_order)
    if parsed is None:
        return ""
    last, first = parsed
    last_p = _prefix(last, prefix_len, pad_char, uppercase)
    first_p = _prefix(first, prefix_len, pad_char, uppercase)
    return f"{last_p}{token},{first_p}{token}"


def build_patient_token_map(
    raw_names: list[str],
    *,
    name_order: str = "last_first",
    token_digits: int = 3,
    uppercase: bool = True,
) -> dict[str, str]:
    """
    Map normalize_person_key → zero-padded token via alpha order of keys.

    Raises ValueError if unique count exceeds 10**token_digits - 1.
    """
    if token_digits < 1:
        raise ValueError("privacy.patient.token_digits must be >= 1")

    keys: set[str] = set()
    for raw in raw_names:
        key = normalize_person_key(
            raw, name_order=name_order, uppercase=uppercase
        )
        if key is not None:
            keys.add(key)

    max_token = (10**token_digits) - 1
    if len(keys) > max_token:
        raise ValueError(
            f"Unique patients ({len(keys)}) exceed token capacity "
            f"({max_token} with token_digits={token_digits})"
        )

    ordered = sorted(keys)
    width = token_digits
    return {
        key: str(i).zfill(width)
        for i, key in enumerate(ordered, start=1)
    }


def mask_patient_value(
    raw: str,
    token_map: dict[str, str],
    pcfg: dict[str, Any],
) -> str:
    """Mask one patient cell according to patient config and token map."""
    mode = str(pcfg.get("mode", "prefix_token")).lower()
    empty_policy = str(pcfg.get("empty_policy", "leave_empty")).lower()
    name_order = str(pcfg.get("name_order", "last_first")).lower()
    uppercase = bool(pcfg.get("uppercase", True))
    prefix_len = int(pcfg.get("prefix_len", 3))
    pad_char = str(pcfg.get("pad_char", "X") or "X")

    text = (raw or "").strip()
    if not text:
        if empty_policy == "placeholder":
            digits = int(pcfg.get("token_digits", 3))
            zero = "0" * digits
            return f"UNK{zero},UNK{zero}"
        return ""

    if mode == "passthrough":
        return str(raw)
    if mode == "omit":
        return ""

    # prefix_token (default)
    key = normalize_person_key(
        text, name_order=name_order, uppercase=uppercase
    )
    if key is None:
        if empty_policy == "placeholder":
            digits = int(pcfg.get("token_digits", 3))
            zero = "0" * digits
            return f"UNK{zero},UNK{zero}"
        return ""

    token = token_map.get(key)
    if token is None:
        return ""
    return format_masked_patient(
        text,
        token,
        name_order=name_order,
        prefix_len=prefix_len,
        pad_char=pad_char,
        uppercase=uppercase,
    )


def mask_dob_value(raw: str, dcfg: dict[str, Any]) -> str:
    """Mask one DOB cell (omit or passthrough)."""
    mode = str(dcfg.get("mode", "omit")).lower()
    if mode == "passthrough":
        return "" if raw is None else str(raw)
    # omit (default) and any unknown mode → blank
    return ""


def apply_privacy_to_rows(
    rows: list[dict[str, Any]],
    cfg: dict[str, Any],
) -> dict[str, Any]:
    """
    In-place mask patient/DOB fields on scored output rows.

    Returns a small stats dict for CLI/summary (no original PHI values).
    """
    root = _privacy_root(cfg)
    enabled = bool(root.get("enabled", False))
    pcfg = _patient_cfg(cfg)
    dcfg = _dob_cfg(cfg)

    patient_field = str(root.get("patient_field", "patient"))
    dob_field = str(root.get("dob_field", "dob"))
    patient_mode = str(pcfg.get("mode", "prefix_token")).lower()
    dob_mode = str(dcfg.get("mode", "omit")).lower()

    stats: dict[str, Any] = {
        "enabled": enabled,
        "patient_mode": patient_mode if enabled else "passthrough",
        "dob_mode": dob_mode if enabled else "passthrough",
        "patient_field": patient_field,
        "dob_field": dob_field,
        "unique_patients": 0,
        "rows_touched": 0,
    }

    if not enabled or not rows:
        return stats

    name_order = str(pcfg.get("name_order", "last_first")).lower()
    uppercase = bool(pcfg.get("uppercase", True))
    token_digits = int(pcfg.get("token_digits", 3))

    token_map: dict[str, str] = {}
    if patient_mode == "prefix_token":
        raw_names = [str(r.get(patient_field, "") or "") for r in rows]
        token_map = build_patient_token_map(
            raw_names,
            name_order=name_order,
            token_digits=token_digits,
            uppercase=uppercase,
        )
        stats["unique_patients"] = len(token_map)

    for row in rows:
        touched = False
        if patient_field in row:
            raw_p = str(row.get(patient_field, "") or "")
            row[patient_field] = mask_patient_value(raw_p, token_map, pcfg)
            touched = True
        if dob_field in row:
            raw_d = str(row.get(dob_field, "") or "")
            row[dob_field] = mask_dob_value(raw_d, dcfg)
            touched = True
        if touched:
            stats["rows_touched"] += 1

    return stats
