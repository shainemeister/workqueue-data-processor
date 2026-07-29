"""Rank completeness evaluation for priority scoring (stdlib only).

Distinguishes full V1 ranks from partial ranks caused by missing roles,
skipped metrics, or low raw-value coverage. Used for advisory JSON fields
and optional --strict roles|full CLI enforcement.
"""

from __future__ import annotations

from typing import Any

STRICT_MODES = frozenset({"roles", "full"})

REASON_ZERO_ACTIVE = "zero_active_metrics"
REASON_MISSING_ROLES = "missing_roles"
REASON_AMBIGUOUS_ROLES = "ambiguous_roles"
REASON_SKIPPED_METRICS = "skipped_metrics"
REASON_LOW_COVERAGE = "low_coverage"


def _nonempty_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return [x for x in value if x is not None and str(x).strip()]
    return []


def _nonempty_mapping_keys(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, dict):
        return [str(k) for k in value.keys() if str(k).strip()]
    # JSON objects from some paths may be attribute bags; ignore non-dicts.
    return []


def evaluate_rank_completeness(
    *,
    active_metrics: list[str] | None,
    skipped_metrics: dict[str, Any] | None,
    missing_roles: list[str] | None,
    ambiguous_roles: dict[str, Any] | None,
    low_coverage_metrics: list[str] | None,
) -> dict[str, Any]:
    """
    Evaluate whether a score run is a full V1 rank or partial.

    Returns:
      rank_completeness: full | partial_roles | partial_coverage |
                         partial_roles_and_coverage
      incomplete_reasons: stable machine codes (ordered)
      strict_roles_ok: bool
      strict_full_ok: bool
    """
    active = _nonempty_list(active_metrics)
    skipped = skipped_metrics if isinstance(skipped_metrics, dict) else {}
    missing = _nonempty_list(missing_roles)
    ambiguous_keys = _nonempty_mapping_keys(ambiguous_roles)
    low_cov = _nonempty_list(low_coverage_metrics)

    reasons: list[str] = []

    if not active:
        reasons.append(REASON_ZERO_ACTIVE)
    if missing:
        reasons.append(REASON_MISSING_ROLES)
    if ambiguous_keys:
        reasons.append(REASON_AMBIGUOUS_ROLES)
    if skipped:
        reasons.append(REASON_SKIPPED_METRICS)
    if low_cov:
        reasons.append(REASON_LOW_COVERAGE)

    roles_blocking = {
        REASON_ZERO_ACTIVE,
        REASON_MISSING_ROLES,
        REASON_AMBIGUOUS_ROLES,
        REASON_SKIPPED_METRICS,
    }
    roles_hit = any(r in roles_blocking for r in reasons)
    coverage_hit = REASON_LOW_COVERAGE in reasons

    strict_roles_ok = not roles_hit
    strict_full_ok = strict_roles_ok and not coverage_hit

    if strict_full_ok:
        completeness = "full"
    elif roles_hit and coverage_hit:
        completeness = "partial_roles_and_coverage"
    elif roles_hit:
        completeness = "partial_roles"
    else:
        completeness = "partial_coverage"

    return {
        "rank_completeness": completeness,
        "incomplete_reasons": reasons,
        "strict_roles_ok": strict_roles_ok,
        "strict_full_ok": strict_full_ok,
    }


def strict_mode_allows(mode: str | None, evaluation: dict[str, Any]) -> bool:
    """Return True when strict *mode* is off or the evaluation passes that tier."""
    if mode is None or not str(mode).strip():
        return True
    normalized = str(mode).strip().lower()
    if normalized not in STRICT_MODES:
        raise ValueError(
            f"Invalid strict mode {mode!r}; expected one of "
            f"{sorted(STRICT_MODES)}"
        )
    if normalized == "roles":
        return bool(evaluation.get("strict_roles_ok"))
    return bool(evaluation.get("strict_full_ok"))


def format_strict_failure_message(
    mode: str,
    evaluation: dict[str, Any],
) -> str:
    """Human one-line message for strict failure."""
    reasons = evaluation.get("incomplete_reasons") or []
    reason_text = ", ".join(str(r) for r in reasons) if reasons else "unknown"
    return (
        f"Strict rank check failed (mode={mode}): {reason_text}. "
        "Provide complete headers or a mapping profile, fix date/number "
        "formats, or re-run without --strict to allow partial ranking."
    )
