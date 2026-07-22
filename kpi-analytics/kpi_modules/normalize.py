"""Normalize raw metrics to 0.0–1.0 (minmax or percentile ranks)."""

from __future__ import annotations

from typing import Any

from .config import METRIC_KEYS


def _minmax_scale(
    values: list[float | None],
    *,
    higher_is_priority: bool,
    missing: float,
) -> list[float]:
    present = [float(v) for v in values if v is not None]
    if not present:
        return [missing for _ in values]
    lo = min(present)
    hi = max(present)
    out: list[float] = []
    for v in values:
        if v is None:
            out.append(missing)
            continue
        if hi == lo:
            unit = 0.5
        else:
            unit = (float(v) - lo) / (hi - lo)
        if not higher_is_priority:
            unit = 1.0 - unit
        # Clamp numerical noise
        if unit < 0.0:
            unit = 0.0
        elif unit > 1.0:
            unit = 1.0
        out.append(unit)
    return out


def _percentile_scale(
    values: list[float | None],
    *,
    higher_is_priority: bool,
    missing: float,
) -> list[float]:
    """Average rank percentile in [0, 1]; ties share average rank."""
    indexed = [(i, float(v)) for i, v in enumerate(values) if v is not None]
    result = [missing] * len(values)
    n = len(indexed)
    if n == 0:
        return result
    if n == 1:
        result[indexed[0][0]] = 0.5
        return result

    # Sort ascending by value
    indexed.sort(key=lambda t: t[1])
    ranks = [0.0] * n  # parallel to indexed order after sort
    i = 0
    while i < n:
        j = i
        while j + 1 < n and indexed[j + 1][1] == indexed[i][1]:
            j += 1
        # ranks i..j inclusive are 1-based positions; average them
        avg_rank = (i + 1 + j + 1) / 2.0
        for k in range(i, j + 1):
            ranks[k] = avg_rank
        i = j + 1

    for pos, (orig_i, _) in enumerate(indexed):
        # rank 1..n → percentile roughly 0..1
        unit = (ranks[pos] - 1.0) / (n - 1.0)
        if not higher_is_priority:
            unit = 1.0 - unit
        if unit < 0.0:
            unit = 0.0
        elif unit > 1.0:
            unit = 1.0
        result[orig_i] = unit
    return result


def normalize_metric_column(
    values: list[float | None],
    *,
    method: str,
    direction: str,
    missing: float,
) -> list[float]:
    higher = direction == "higher"
    if method == "percentile":
        return _percentile_scale(
            values, higher_is_priority=higher, missing=missing
        )
    return _minmax_scale(values, higher_is_priority=higher, missing=missing)


def normalize_all(
    raw_list: list[dict[str, float | None]],
    cfg: dict[str, Any],
) -> list[dict[str, float]]:
    """Normalize each V1 metric across the batch; return per-row ratio maps."""
    method = str(cfg.get("normalization", "minmax"))
    missing = float(cfg.get("missing_norm_value", 0.0))
    direction = cfg["metric_direction"]

    columns: dict[str, list[float]] = {}
    for key in METRIC_KEYS:
        series = [row.get(key) for row in raw_list]
        columns[key] = normalize_metric_column(
            series,
            method=method,
            direction=str(direction[key]),
            missing=missing,
        )

    n = len(raw_list)
    out: list[dict[str, float]] = []
    for i in range(n):
        out.append({key: columns[key][i] for key in METRIC_KEYS})
    return out
