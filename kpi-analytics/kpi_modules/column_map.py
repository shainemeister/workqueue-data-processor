"""
Role-based column identification and mapping profiles for score inputs.

Maps arbitrary CSV headers to config field roles without mutating wq_schema.json.
Stdlib only.
"""

from __future__ import annotations

import json
import sys
from copy import deepcopy
from pathlib import Path
from typing import Any, TextIO

from .config import METRIC_KEYS
from .metrics import parse_date, parse_float

# Semantic roles used by scoring (config ``fields`` keys).
ROLE_KEYS: tuple[str, ...] = (
    "service_date",
    "out_ins_amt",
    "billed_amount",
    "days_until_appeal_deadline",
    "days_on_wq_tab",
    "last_worked_date",
    "denial_count",
    "days_until_replacement_deadline",
)

# Expected cell type for sample verification (date / numeric / any).
ROLE_TYPE_HINTS: dict[str, str] = {
    "service_date": "date",
    "out_ins_amt": "numeric",
    "billed_amount": "numeric",
    "days_until_appeal_deadline": "numeric",
    "days_on_wq_tab": "numeric",
    "last_worked_date": "date",
    "denial_count": "numeric",
    "days_until_replacement_deadline": "numeric",
}

# Short descriptions for guided mapping and operator-facing reports.
ROLE_DESCRIPTIONS: dict[str, str] = {
    "service_date": "Date of service (claim age / BWDO)",
    "out_ins_amt": "Outstanding insurance balance",
    "billed_amount": "Billed / charge amount",
    "days_until_appeal_deadline": "Days remaining until appeal deadline",
    "days_on_wq_tab": "Days on the work queue tab",
    "last_worked_date": "Date the claim was last worked",
    "denial_count": "Number of denials on the claim",
    "days_until_replacement_deadline": (
        "Days remaining until replacement deadline"
    ),
}

# Header name tokens that may carry PHI; samples are redacted.
_SENSITIVE_HEADER_TOKENS: tuple[str, ...] = (
    "patient",
    "dob",
    "date of birth",
    "birth",
    "ssn",
    "account",
    "member",
    "subscriber",
    "mrn",
)

# Metric key -> roles that must be resolved for the metric to stay active.
METRIC_REQUIRED_ROLES: dict[str, tuple[str, ...]] = {
    "claim_age_days": ("service_date",),
    "claim_age_disparity": ("service_date",),
    "out_ins_amt": ("out_ins_amt",),
    "billed_amount": ("billed_amount",),
    "appeal_urgency": ("days_until_appeal_deadline",),
    "wq_age": ("days_on_wq_tab",),
    "balance_weighted_days_outstanding": (
        "service_date",
        "out_ins_amt",
        "billed_amount",
    ),
    "denial_count": ("denial_count",),
    "days_since_last_worked": ("last_worked_date",),
    # Dual-deadline needs at least one deadline column present
    "dual_deadline_urgency": (),
}

# Known synonyms / display labels per role (case/space-insensitive match).
ROLE_ALIASES: dict[str, tuple[str, ...]] = {
    "service_date": (
        "service_date",
        "service date",
        "dos",
        "date of service",
        "bill date",
        "svc date",
    ),
    "out_ins_amt": (
        "out_ins_amt",
        "out. ins. amt.",
        "out ins amt",
        "outstanding insurance",
        "outstanding balance",
        "insurance balance",
        "balance",
        "remaining",
        "remaining balance",
    ),
    "billed_amount": (
        "billed_amount",
        "billed amount",
        "charges",
        "charge amount",
        "total charges",
        "gross charges",
    ),
    "days_until_appeal_deadline": (
        "days_until_appeal_deadline",
        "days until appeal deadline",
        "appeal deadline days",
        "appeal days left",
        "days to appeal",
    ),
    "days_on_wq_tab": (
        "days_on_wq_tab",
        "days on wq tab",
        "days on work queue",
        "wq age",
        "days in wq",
        "work queue age",
    ),
    "last_worked_date": (
        "last_worked_date",
        "last worked date",
        "last worked",
        "date last worked",
        "last activity date",
    ),
    "denial_count": (
        "denial_count",
        "denial count",
        "denials",
        "number of denials",
        "denial times",
    ),
    "days_until_replacement_deadline": (
        "days_until_replacement_deadline",
        "days until replacement deadline",
        "replacement deadline days",
        "days to replacement",
        "replacement days left",
    ),
}

MAPPING_PROFILE_VERSION = "1.0"
_SAMPLE_VALUE_MAX_LEN = 24
_DEFAULT_SAMPLE_LIMIT = 5
_DEFAULT_ROW_SCAN = 25
_MIN_PARSE_RATIO = 0.5


def normalize_header(name: str | None) -> str:
    """Lowercase, strip, collapse internal whitespace for header comparison."""
    if name is None:
        return ""
    text = str(name).strip().lower()
    return " ".join(text.split())


def _alias_lookup() -> dict[str, str]:
    """Return normalized alias -> role key."""
    out: dict[str, str] = {}
    for role, aliases in ROLE_ALIASES.items():
        for alias in aliases:
            key = normalize_header(alias)
            if key and key not in out:
                out[key] = role
    return out


def _header_looks_sensitive(header: str) -> bool:
    """True when a header name may carry patient / account identifiers."""
    norm = normalize_header(header)
    if not norm:
        return False
    for token in _SENSITIVE_HEADER_TOKENS:
        if token in norm:
            return True
    return False


def _truncate_sample(value: str, *, sensitive: bool = False) -> str:
    """Truncate (and optionally redact) a sample cell for reports / guided UI."""
    text = str(value).strip().replace("\n", " ").replace("\r", " ")
    if not text:
        return ""
    if sensitive:
        return f"[redacted len={len(text)}]"
    if len(text) > _SAMPLE_VALUE_MAX_LEN:
        return text[: _SAMPLE_VALUE_MAX_LEN - 1] + "…"
    return text


def _collect_nonempty_samples(
    rows: list[dict[str, str]],
    column: str,
    *,
    limit: int = _DEFAULT_SAMPLE_LIMIT,
    row_scan: int = _DEFAULT_ROW_SCAN,
) -> list[str]:
    """Return up to *limit* non-empty cell strings from the first *row_scan* rows."""
    samples: list[str] = []
    sensitive = _header_looks_sensitive(column)
    for row in rows[: max(0, row_scan)]:
        raw = row.get(column)
        if raw is None:
            continue
        text = str(raw).strip()
        if not text:
            continue
        samples.append(_truncate_sample(text, sensitive=sensitive))
        if len(samples) >= limit:
            break
    return samples


def verify_resolved_samples(
    resolved: dict[str, str],
    rows: list[dict[str, str]] | None,
    *,
    date_formats: list[str] | None = None,
    sample_limit: int = _DEFAULT_SAMPLE_LIMIT,
    row_scan: int = _DEFAULT_ROW_SCAN,
) -> dict[str, Any]:
    """
    Inspect sample cell values for resolved role columns.

    Returns role_confidence, sample_values, type_checks, low_confidence_roles.
    Does not block scoring; low confidence is advisory only.
    """
    formats = list(date_formats or [])
    role_confidence: dict[str, str] = {}
    sample_values: dict[str, list[str]] = {}
    type_checks: dict[str, str] = {}
    low_confidence: list[str] = []

    if not rows:
        for role in resolved:
            role_confidence[role] = "unknown"
            sample_values[role] = []
            type_checks[role] = "no_rows"
        return {
            "role_confidence": role_confidence,
            "sample_values": sample_values,
            "type_checks": type_checks,
            "low_confidence_roles": low_confidence,
        }

    for role, column in resolved.items():
        samples = _collect_nonempty_samples(
            rows,
            column,
            limit=sample_limit,
            row_scan=row_scan,
        )
        sample_values[role] = samples
        expected = ROLE_TYPE_HINTS.get(role, "any")

        if not samples:
            type_checks[role] = "mostly_empty"
            role_confidence[role] = "low"
            low_confidence.append(role)
            continue

        # Sensitive columns: do not re-parse redacted placeholders; treat as any.
        if _header_looks_sensitive(column):
            type_checks[role] = "ok"
            role_confidence[role] = "high"
            continue

        # Re-read raw non-empty cells for parse checks (untruncated).
        raw_values: list[str] = []
        for row in rows[: max(0, row_scan)]:
            raw = row.get(column)
            if raw is None:
                continue
            text = str(raw).strip()
            if text:
                raw_values.append(text)
            if len(raw_values) >= sample_limit:
                break

        if expected == "date":
            if not formats:
                type_checks[role] = "looks_date_unchecked"
                role_confidence[role] = "unknown"
                continue
            parsed_ok = sum(
                1 for v in raw_values if parse_date(v, formats) is not None
            )
            ratio = parsed_ok / len(raw_values) if raw_values else 0.0
            if ratio >= _MIN_PARSE_RATIO:
                type_checks[role] = "looks_date"
                role_confidence[role] = "high"
            else:
                type_checks[role] = "not_date"
                role_confidence[role] = "low"
                low_confidence.append(role)
        elif expected == "numeric":
            parsed_ok = sum(
                1 for v in raw_values if parse_float(v) is not None
            )
            ratio = parsed_ok / len(raw_values) if raw_values else 0.0
            if ratio >= _MIN_PARSE_RATIO:
                type_checks[role] = "looks_numeric"
                role_confidence[role] = "high"
            else:
                type_checks[role] = "not_numeric"
                role_confidence[role] = "low"
                low_confidence.append(role)
        else:
            type_checks[role] = "ok"
            role_confidence[role] = "high"

    return {
        "role_confidence": role_confidence,
        "sample_values": sample_values,
        "type_checks": type_checks,
        "low_confidence_roles": low_confidence,
    }


def mapping_has_problems(report: dict[str, Any]) -> bool:
    """True when missing roles, ambiguity, or low-confidence mappings exist."""
    if report.get("missing_roles"):
        return True
    if report.get("ambiguous"):
        return True
    if report.get("low_confidence_roles"):
        return True
    return False


def problems_summary(report: dict[str, Any]) -> str:
    """Human-readable one-line summary of mapping problems."""
    parts: list[str] = []
    missing = list(report.get("missing_roles") or [])
    if missing:
        parts.append("missing=" + ",".join(missing))
    amb = report.get("ambiguous") or {}
    if amb:
        parts.append("ambiguous=" + ",".join(sorted(amb.keys())))
    low = list(report.get("low_confidence_roles") or [])
    if low:
        parts.append("low_confidence=" + ",".join(low))
    return "; ".join(parts) if parts else "none"


class MappingGuideAbort(Exception):
    """User aborted guided mapping or requested a different source file."""

    def __init__(self, message: str, *, need_different_file: bool = False):
        super().__init__(message)
        self.need_different_file = need_different_file


def _roles_needing_guide(report: dict[str, Any]) -> list[str]:
    """Ordered list of roles to present in the guided session."""
    ordered: list[str] = []
    seen: set[str] = set()
    for role in list(report.get("missing_roles") or []):
        if role not in seen:
            ordered.append(role)
            seen.add(role)
    for role in (report.get("ambiguous") or {}):
        if role not in seen:
            ordered.append(role)
            seen.add(role)
    for role in list(report.get("low_confidence_roles") or []):
        if role not in seen:
            ordered.append(role)
            seen.add(role)
    # Preserve ROLE_KEYS order for stable UX
    return [r for r in ROLE_KEYS if r in seen]


def _print_header_choices(
    headers: list[str],
    rows: list[dict[str, str]] | None,
    *,
    out: TextIO,
    prefer_unused: list[str] | None = None,
) -> list[str]:
    """
    Print numbered header choices with samples; return the list shown.

    Prefers unused headers first, then remaining headers.
    """
    unused = list(prefer_unused or [])
    unused_set = set(unused)
    ordered = list(unused) + [h for h in headers if h not in unused_set]
    if not ordered:
        out.write("  (no headers available)\n")
        return []
    for idx, header in enumerate(ordered, start=1):
        samples = (
            _collect_nonempty_samples(rows, header, limit=3)
            if rows
            else []
        )
        sample_s = ", ".join(samples) if samples else "(empty/no sample)"
        mark = " [unused]" if header in unused_set else ""
        out.write(f"  {idx}. {header}{mark}  samples: {sample_s}\n")
    return ordered


def guide_mapping(
    headers: list[str],
    report: dict[str, Any],
    *,
    sample_rows: list[dict[str, str]] | None = None,
    existing_roles: dict[str, str] | None = None,
    stdin: TextIO | None = None,
    stdout: TextIO | None = None,
) -> dict[str, str]:
    """
    Interactively resolve missing / ambiguous / low-confidence roles.

    Returns a role -> column mapping suitable as profile_roles (merged with
    any prior resolutions the user keeps). Raises MappingGuideAbort on quit
    or when the user requests a different source file.

    Caller must ensure a TTY is available before calling.
    """
    inp = stdin if stdin is not None else sys.stdin
    out = stdout if stdout is not None else sys.stdout
    chosen: dict[str, str] = dict(existing_roles or {})
    # Seed with already-resolved high-confidence roles so save is complete.
    for role, col in (report.get("resolved") or {}).items():
        chosen.setdefault(role, col)

    roles_todo = _roles_needing_guide(report)
    if not roles_todo:
        return chosen

    out.write(
        "\nGuided column mapping — resolve roles for scoring.\n"
        "Commands: number or header name = map; s = skip role; "
        "f = different file; q = abort.\n\n"
    )

    headers_clean = [
        h for h in headers if h is not None and str(h).strip()
    ]

    for role in roles_todo:
        desc = ROLE_DESCRIPTIONS.get(role, role)
        reason_bits: list[str] = []
        if role in (report.get("missing_roles") or []):
            reason_bits.append("missing")
        if role in (report.get("ambiguous") or {}):
            amb_cols = (report.get("ambiguous") or {}).get(role) or []
            reason_bits.append(
                "ambiguous candidates: " + ", ".join(amb_cols)
            )
        if role in (report.get("low_confidence_roles") or []):
            tc = (report.get("type_checks") or {}).get(role, "")
            conf = (report.get("role_confidence") or {}).get(role, "")
            reason_bits.append(f"low confidence ({conf}/{tc})")
        current = (report.get("resolved") or {}).get(role)
        if current:
            reason_bits.append(f"current={current}")

        out.write(f"Role: {role}\n")
        out.write(f"  Need: {desc}\n")
        if reason_bits:
            out.write(f"  Status: {'; '.join(reason_bits)}\n")

        unused = list(report.get("unused_headers") or [])
        # If ambiguous, prefer showing those candidates first.
        amb = list((report.get("ambiguous") or {}).get(role) or [])
        prefer = list(dict.fromkeys(amb + unused))
        choices = _print_header_choices(
            headers_clean,
            sample_rows,
            out=out,
            prefer_unused=prefer,
        )

        while True:
            out.write(
                f"Map '{role}' to column "
                f"[# / name / s skip / f file / q quit]: "
            )
            out.flush()
            line = inp.readline()
            if not line:
                raise MappingGuideAbort(
                    "Guided mapping aborted: end of input."
                )
            answer = line.strip()
            if not answer:
                continue
            lower = answer.lower()
            if lower in ("q", "quit", "abort"):
                raise MappingGuideAbort("Guided mapping aborted by user.")
            if lower in ("f", "file"):
                raise MappingGuideAbort(
                    "NEED_DIFFERENT_FILE: choose another source CSV "
                    "and re-run score",
                    need_different_file=True,
                )
            if lower in ("s", "skip"):
                chosen.pop(role, None)
                out.write(f"  Skipped {role}.\n\n")
                break

            selected: str | None = None
            if answer.isdigit():
                idx = int(answer)
                if 1 <= idx <= len(choices):
                    selected = choices[idx - 1]
                else:
                    out.write(
                        f"  Invalid index {idx}; enter 1-{len(choices)}.\n"
                    )
                    continue
            else:
                # Exact or case/space-insensitive match against headers
                want_norm = normalize_header(answer)
                matches = [
                    h
                    for h in headers_clean
                    if h == answer or normalize_header(h) == want_norm
                ]
                if len(matches) == 1:
                    selected = matches[0]
                elif len(matches) > 1:
                    out.write(
                        "  Ambiguous header name; pick by number instead.\n"
                    )
                    continue
                else:
                    out.write(
                        f"  No header matching {answer!r}; try again.\n"
                    )
                    continue

            chosen[role] = selected
            out.write(f"  Mapped {role} -> {selected}\n\n")
            break

    return chosen


def offer_save_mapping_profile(
    roles: dict[str, str],
    *,
    suggest_path: str | Path,
    stdin: TextIO | None = None,
    stdout: TextIO | None = None,
) -> Path | None:
    """
    Prompt to save a mapping profile; returns path written or None if skipped.
    """
    inp = stdin if stdin is not None else sys.stdin
    out = stdout if stdout is not None else sys.stdout
    if not roles:
        return None
    default = str(Path(suggest_path))
    out.write(
        f"Save mapping profile? [Y/n] (path default: {default}): "
    )
    out.flush()
    line = inp.readline()
    if not line:
        return None
    answer = line.strip()
    if answer.lower() in ("n", "no"):
        return None
    path_s = default
    if answer and answer.lower() not in ("y", "yes"):
        path_s = answer
    try:
        written = save_mapping_profile(
            path_s,
            roles,
            description="Saved from interactive guided mapping",
        )
    except (OSError, ValueError) as exc:
        out.write(f"Could not save mapping profile: {exc}\n")
        return None
    out.write(f"Saved mapping profile: {written}\n")
    return written


def load_mapping_profile(path: str | Path) -> dict[str, str]:
    """
    Load a mapping profile JSON.

    Expected shape::

        {
          "version": "1.0",
          "description": "optional",
          "roles": {
            "service_date": "Service Date",
            "out_ins_amt": "Balance",
            ...
          }
        }

    Returns role -> source column name (as provided in the file).
    """
    p = Path(path)
    if not p.is_file():
        raise FileNotFoundError(f"Mapping profile not found: {p}")
    with p.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError("Mapping profile root must be a JSON object")
    roles = data.get("roles")
    if not isinstance(roles, dict):
        raise ValueError("Mapping profile must contain a 'roles' object")
    out: dict[str, str] = {}
    for role, col in roles.items():
        role_s = str(role).strip()
        if role_s not in ROLE_KEYS:
            raise ValueError(
                f"Unknown mapping role {role_s!r}; "
                f"expected one of {', '.join(ROLE_KEYS)}"
            )
        col_s = str(col).strip() if col is not None else ""
        if not col_s:
            raise ValueError(
                f"Mapping role {role_s!r} has an empty column name"
            )
        out[role_s] = col_s
    return out


def save_mapping_profile(
    path: str | Path,
    roles: dict[str, str],
    *,
    description: str = "",
) -> Path:
    """Write a mapping profile JSON; returns the resolved path."""
    payload: dict[str, Any] = {
        "version": MAPPING_PROFILE_VERSION,
        "description": (
            description or "Column role mapping for kpi-analytics score"
        ),
        "roles": {k: roles[k] for k in ROLE_KEYS if k in roles},
    }
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="\n") as fh:
        json.dump(payload, fh, indent=2)
        fh.write("\n")
    return out.resolve()


def resolve_roles(
    headers: list[str],
    *,
    config_fields: dict[str, str] | None = None,
    profile_roles: dict[str, str] | None = None,
) -> dict[str, Any]:
    """
    Resolve semantic roles to actual CSV header strings.

    Priority per role:
    1. Explicit mapping profile (must match a present header)
    2. Config ``fields`` value when that header is present
    3. Auto-detect via alias table / exact normalized match

    Returns a report dict with resolved, missing, ambiguous, and unused headers.
    """
    headers_clean = [
        h for h in headers if h is not None and str(h).strip()
    ]
    by_norm: dict[str, list[str]] = {}
    for h in headers_clean:
        by_norm.setdefault(normalize_header(h), []).append(h)

    alias_to_role = _alias_lookup()
    cfg_fields = config_fields or {}
    profile = profile_roles or {}

    resolved: dict[str, str] = {}
    missing: list[str] = []
    ambiguous: dict[str, list[str]] = {}
    sources: dict[str, str] = {}

    def _pick_header(candidates: list[str], role: str) -> str | None:
        uniq = list(dict.fromkeys(candidates))
        if not uniq:
            return None
        if len(uniq) > 1:
            ambiguous[role] = uniq
            preferred = cfg_fields.get(role)
            if preferred is not None:
                for cand in uniq:
                    if cand == preferred or normalize_header(
                        cand
                    ) == normalize_header(preferred):
                        return cand
            return uniq[0]
        return uniq[0]

    for role in ROLE_KEYS:
        chosen: str | None = None
        source = ""

        if role in profile:
            want = profile[role]
            norm = normalize_header(want)
            cands = by_norm.get(norm, [])
            if not cands:
                if want in headers_clean:
                    chosen = want
                    source = "profile"
                else:
                    missing.append(role)
                    sources[role] = "profile_missing"
                    continue
            else:
                chosen = _pick_header(cands, role)
                source = "profile"
        else:
            cfg_name = cfg_fields.get(role)
            if cfg_name:
                norm = normalize_header(str(cfg_name))
                cands = by_norm.get(norm, [])
                if cands:
                    chosen = _pick_header(cands, role)
                    source = "config"

            if chosen is None:
                cands = []
                for n_header, originals in by_norm.items():
                    if alias_to_role.get(n_header) == role:
                        cands.extend(originals)
                if cands:
                    chosen = _pick_header(cands, role)
                    source = "auto"

        if chosen is None:
            missing.append(role)
            sources[role] = "unresolved"
        else:
            resolved[role] = chosen
            sources[role] = source

    used = set(resolved.values())
    unused = [h for h in headers_clean if h not in used]

    return {
        "resolved": resolved,
        "missing_roles": missing,
        "ambiguous": ambiguous,
        "unused_headers": unused,
        "sources": sources,
        "headers": headers_clean,
    }


def active_metrics_for_roles(resolved_roles: dict[str, str]) -> dict[str, Any]:
    """
    Determine which priority metrics can run given resolved roles.

    Returns active metric keys and skipped map (metric -> reason).
    """
    active: list[str] = []
    skipped: dict[str, str] = {}
    for metric in METRIC_KEYS:
        if metric == "dual_deadline_urgency":
            has_appeal = "days_until_appeal_deadline" in resolved_roles
            has_repl = "days_until_replacement_deadline" in resolved_roles
            if not has_appeal and not has_repl:
                skipped[metric] = (
                    "missing role(s): days_until_appeal_deadline or "
                    "days_until_replacement_deadline"
                )
            else:
                active.append(metric)
            continue
        needed = METRIC_REQUIRED_ROLES.get(metric, ())
        miss = [r for r in needed if r not in resolved_roles]
        if miss:
            skipped[metric] = "missing role(s): " + ", ".join(miss)
        else:
            active.append(metric)
    return {
        "active_metrics": active,
        "skipped_metrics": skipped,
    }


def apply_mapping_to_config(
    cfg: dict[str, Any],
    headers: list[str],
    *,
    profile_roles: dict[str, str] | None = None,
    require_active_metric: bool = True,
    sample_rows: list[dict[str, str]] | None = None,
) -> tuple[dict[str, Any], dict[str, Any]]:
    """
    Deep-copy config, set ``fields`` from resolved roles, return (cfg, report).

    Unresolved roles are removed from ``fields`` (no silent role-name fallback).
    When *sample_rows* is provided, the report is enriched with sample values,
    type checks, and per-role confidence (advisory; does not block scoring).

    Raises ValueError when a profile column is missing, or when no metrics can
    run (if require_active_metric).
    """
    out = deepcopy(cfg)
    fields = out.setdefault("fields", {})
    if not isinstance(fields, dict):
        raise ValueError("Config 'fields' must be an object")

    report = resolve_roles(
        headers,
        config_fields={k: str(v) for k, v in fields.items()},
        profile_roles=profile_roles,
    )

    if profile_roles:
        for role, col in profile_roles.items():
            if role not in report["resolved"]:
                raise ValueError(
                    f"Mapping profile role {role!r} column {col!r} "
                    "not found in CSV headers"
                )

    for role, col in report["resolved"].items():
        fields[role] = col

    # Do not invent column names for unresolved roles (config defaults may have
    # pre-filled role-name keys; strip those so metrics skip cleanly).
    for role in ROLE_KEYS:
        if role not in report["resolved"]:
            fields.pop(role, None)

    availability = active_metrics_for_roles(report["resolved"])
    report["active_metrics"] = availability["active_metrics"]
    report["skipped_metrics"] = availability["skipped_metrics"]

    formats_raw = out.get("date_formats") or []
    formats = [str(f) for f in formats_raw] if isinstance(formats_raw, list) else []
    verification = verify_resolved_samples(
        report["resolved"],
        sample_rows,
        date_formats=formats,
    )
    report["role_confidence"] = verification["role_confidence"]
    report["sample_values"] = verification["sample_values"]
    report["type_checks"] = verification["type_checks"]
    report["low_confidence_roles"] = verification["low_confidence_roles"]

    if require_active_metric and not report["active_metrics"]:
        missing = ", ".join(report["missing_roles"]) or "(none listed)"
        raise ValueError(
            "No priority metrics can run: required columns missing "
            "for all metrics. "
            f"Unresolved roles: {missing}. "
            "Provide correctly named headers or a --mapping profile."
        )

    return out, report
