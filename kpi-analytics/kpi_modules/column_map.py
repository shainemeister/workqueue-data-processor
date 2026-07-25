"""
Role-based column identification and mapping profiles for score inputs.

Maps arbitrary CSV headers to config field roles without mutating wq_schema.json.
Stdlib only.
"""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
from typing import Any

from .config import METRIC_KEYS

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
) -> tuple[dict[str, Any], dict[str, Any]]:
    """
    Deep-copy config, set ``fields`` from resolved roles, return (cfg, report).

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

    for role in ROLE_KEYS:
        if role not in report["resolved"]:
            fields.setdefault(role, role)

    availability = active_metrics_for_roles(report["resolved"])
    report["active_metrics"] = availability["active_metrics"]
    report["skipped_metrics"] = availability["skipped_metrics"]

    if require_active_metric and not report["active_metrics"]:
        missing = ", ".join(report["missing_roles"]) or "(none listed)"
        raise ValueError(
            "No priority metrics can run: required columns missing "
            "for all metrics. "
            f"Unresolved roles: {missing}. "
            "Provide correctly named headers or a --mapping profile."
        )

    return out, report
