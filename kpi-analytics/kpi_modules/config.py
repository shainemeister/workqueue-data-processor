"""Load and validate KPI analytics configuration (JSON, stdlib only)."""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
from typing import Any

DEFAULT_CONFIG_PATH = Path(__file__).with_name("config_default.json")

METRIC_KEYS = (
    "ar_days",
    "ar_disparity",
    "out_ins_amt",
    "billed_amount",
    "appeal_urgency",
    "wq_age",
)


def load_config(path: str | Path | None = None) -> dict[str, Any]:
    """Load config from *path*, or the package default JSON."""
    cfg_path = Path(path) if path else DEFAULT_CONFIG_PATH
    if not cfg_path.is_file():
        raise FileNotFoundError(f"Config not found: {cfg_path}")
    with cfg_path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError("Config root must be a JSON object")
    return validate_config(data)


def validate_config(cfg: dict[str, Any]) -> dict[str, Any]:
    """Return a deep-copied config with required keys present."""
    out = deepcopy(cfg)

    if "ar_day_target" not in out:
        raise ValueError("Config missing required key: ar_day_target")
    out["ar_day_target"] = float(out["ar_day_target"])

    weights = out.get("weights")
    if not isinstance(weights, dict):
        raise ValueError("Config 'weights' must be an object")
    for key in METRIC_KEYS:
        if key not in weights:
            raise ValueError(f"Config weights missing metric: {key}")
        weights[key] = float(weights[key])

    direction = out.setdefault("metric_direction", {})
    if not isinstance(direction, dict):
        raise ValueError("Config 'metric_direction' must be an object")
    for key in METRIC_KEYS:
        direction.setdefault(
            key,
            "lower" if key == "appeal_urgency" else "higher",
        )
        if direction[key] not in ("higher", "lower"):
            raise ValueError(
                f"metric_direction.{key} must be 'higher' or 'lower'"
            )

    norm = str(out.get("normalization", "minmax")).lower()
    if norm not in ("minmax", "percentile"):
        raise ValueError("normalization must be 'minmax' or 'percentile'")
    out["normalization"] = norm
    out["missing_norm_value"] = float(out.get("missing_norm_value", 0.0))

    fields = out.setdefault("fields", {})
    if not isinstance(fields, dict):
        raise ValueError("Config 'fields' must be an object")
    defaults = {
        "service_date": "service_date",
        "out_ins_amt": "out_ins_amt",
        "billed_amount": "billed_amount",
        "days_until_appeal_deadline": "days_until_appeal_deadline",
        "days_on_wq_tab": "days_on_wq_tab",
    }
    for k, v in defaults.items():
        fields.setdefault(k, v)

    formats = out.get("date_formats")
    if formats is None:
        out["date_formats"] = ["%m/%d/%Y", "%Y-%m-%d", "%m-%d-%Y", "%Y/%m/%d"]
    elif not isinstance(formats, list) or not formats:
        raise ValueError("date_formats must be a non-empty list of strings")

    chaos = out.setdefault("chaos", {})
    if not isinstance(chaos, dict):
        raise ValueError("Config 'chaos' must be an object")
    chaos.setdefault("enabled", True)
    chaos.setdefault("mean_ar_days_factor", 1.5)
    chaos.setdefault("share_ar_ge_60", 0.40)
    chaos.setdefault("share_ar_ge_90", 0.25)
    chaos.setdefault("share_ar_ge_120", 0.15)
    mult = chaos.setdefault("multipliers", {})
    if not isinstance(mult, dict):
        raise ValueError("chaos.multipliers must be an object")
    for key in METRIC_KEYS:
        mult.setdefault(key, 1.0)
        mult[key] = float(mult[key])

    poi = out.setdefault("point_of_interest", {})
    if not isinstance(poi, dict):
        raise ValueError("point_of_interest must be an object")
    poi.setdefault("name", "default")
    poi_m = poi.setdefault("multipliers", {})
    if not isinstance(poi_m, dict):
        raise ValueError("point_of_interest.multipliers must be an object")
    for key in METRIC_KEYS:
        poi_m.setdefault(key, 1.0)
        poi_m[key] = float(poi_m[key])

    output = out.setdefault("output", {})
    if not isinstance(output, dict):
        raise ValueError("output must be an object")
    output.setdefault("score_column", "v1_priority_score")
    output.setdefault("mode_column", "v1_queue_mode")
    output.setdefault("prefix", "v1_")

    # Portfolio KPI quantifiers (RCM claim impact; independent of priority score)
    kq = out.setdefault("kpi_quantifiers", {})
    if not isinstance(kq, dict):
        raise ValueError("kpi_quantifiers must be an object")
    kq.setdefault("enabled", True)
    breaks = kq.get("aged_day_breaks")
    if breaks is None:
        kq["aged_day_breaks"] = [30, 60, 90, 120]
    elif not isinstance(breaks, list) or not breaks:
        raise ValueError("kpi_quantifiers.aged_day_breaks must be a non-empty list")
    else:
        kq["aged_day_breaks"] = [int(x) for x in breaks]
    kq.setdefault("amount_field", "out_ins_amt")
    kq.setdefault("adc", None)
    kq.setdefault("adc_lookback_days", 90)
    kq.setdefault("adc_mode", "config")
    credit = str(kq.get("credit_policy", "exclude_from_T")).lower()
    if credit not in ("exclude_from_t", "exclude_from_T", "include"):
        # normalize
        pass
    kq["credit_policy"] = (
        "include" if credit == "include" else "exclude_from_T"
    )
    kq.setdefault("emit_static_share", True)
    kq.setdefault("emit_exact_delta", True)
    kq.setdefault("dual_sign_columns", True)

    return out


def effective_weights(cfg: dict[str, Any], chaos_mode: bool) -> dict[str, float]:
    """Base weights × POI multipliers × (optional) chaos multipliers, then renorm."""
    base = {k: float(cfg["weights"][k]) for k in METRIC_KEYS}
    poi_m = cfg["point_of_interest"]["multipliers"]
    chaos_m = cfg["chaos"]["multipliers"]

    raw: dict[str, float] = {}
    for k in METRIC_KEYS:
        w = base[k] * float(poi_m.get(k, 1.0))
        if chaos_mode and cfg["chaos"].get("enabled", True):
            w *= float(chaos_m.get(k, 1.0))
        raw[k] = w

    total = sum(raw.values())
    if total <= 0:
        n = len(METRIC_KEYS)
        return {k: 1.0 / n for k in METRIC_KEYS}
    return {k: raw[k] / total for k in METRIC_KEYS}
