"""
Portfolio KPI claim impact quantifiers (RCM methodology).

Conceptual source: RCM_KPI_Claim_Impact_Methodology.md (proof of concept).
Naming: retain kpi_q_* / KpiTotals; independent of v1_* priority scoring.

Two families per claim:
  1) Static share / contribution — sums to portfolio % KPIs (balance-weighted)
  2) Exact quantifiable measure of change (Δ) — KPI movement if balance → 0

Days in AR:  sum_i(x_i / ADC) = T / ADC
AR > T % static: sum_i(d_i * x_i / T * 100) = N_T / T * 100
AR > T % exact Δ: closed-form; can be negative for young claims; does NOT sum to %
"""

from __future__ import annotations

from typing import Any


def _kq(cfg: dict[str, Any]) -> dict[str, Any]:
    return cfg.get("kpi_quantifiers") or {}


def _fmt(value: float, *, kind: str = "num") -> str:
    if kind == "money":
        return f"{value:.2f}"
    if kind == "pct":
        return f"{value:.6f}".rstrip("0").rstrip(".")
    if kind == "pp":
        return f"{value:.6f}".rstrip("0").rstrip(".")
    if abs(value - round(value)) < 1e-12:
        return str(int(round(value)))
    return f"{value:.6f}".rstrip("0").rstrip(".")


def _split_signed(effect: float) -> tuple[float, float]:
    if effect >= 0:
        return float(effect), 0.0
    return 0.0, float(effect)


def aged_breaks(cfg: dict[str, Any]) -> list[int]:
    """Return configured aging day thresholds (e.g. 30, 60, 90, 120)."""
    kq = _kq(cfg)
    return [int(d) for d in (kq.get("aged_day_breaks") or [30, 60, 90, 120])]


def quantifier_column_names(cfg: dict[str, Any]) -> list[str]:
    """Return ordered kpi_q_* column names for the current config."""
    kq = _kq(cfg)
    if not kq.get("enabled", True):
        return []

    cols: list[str] = []
    dual = bool(kq.get("dual_sign_columns", True))
    emit_static = bool(kq.get("emit_static_share", True))
    emit_delta = bool(kq.get("emit_exact_delta", True))

    if emit_static:
        cols.append("kpi_q_share_total_ar_pct")
        for t in aged_breaks(cfg):
            cols.append(f"kpi_q_aged{t}_contrib_pct")

    if emit_delta:
        if dual:
            cols.extend(
                [
                    "kpi_q_days_in_ar_pos",
                    "kpi_q_days_in_ar_neg",
                ]
            )
            for t in aged_breaks(cfg):
                cols.append(f"kpi_q_aged{t}_delta_pp_pos")
                cols.append(f"kpi_q_aged{t}_delta_pp_neg")
        else:
            cols.append("kpi_q_days_in_ar")
            for t in aged_breaks(cfg):
                cols.append(f"kpi_q_aged{t}_delta_pp")

    return cols


def apply_quantifiers_to_rows(
    out_rows: list[dict[str, Any]],
    raw_list: list[dict[str, float | None]],
    cfg: dict[str, Any],
) -> tuple[list[str], dict[str, float]]:
    """
    Attach RCM claim-impact columns; return (column_names, KpiTotals).
    """
    kq = _kq(cfg)
    cols = quantifier_column_names(cfg)
    if not cols or not out_rows:
        return cols, {}

    dual = bool(kq.get("dual_sign_columns", True))
    emit_static = bool(kq.get("emit_static_share", True))
    emit_delta = bool(kq.get("emit_exact_delta", True))
    credit_policy = str(kq.get("credit_policy", "exclude_from_T")).lower()
    breaks = aged_breaks(cfg)

    # --- collect balances and ages ---
    n = len(out_rows)
    x_list: list[float] = []
    ar_list: list[float | None] = []
    billed_list: list[float] = []

    for raw in raw_list:
        oi = raw.get("out_ins_amt")
        x = float(oi) if oi is not None else 0.0
        if credit_policy == "exclude_from_T" and x < 0:
            x_incl = 0.0  # excluded from portfolio T
        else:
            x_incl = x
        x_list.append(x_incl)
        ar = raw.get("ar_days")
        ar_list.append(float(ar) if ar is not None else None)
        bi = raw.get("billed_amount")
        billed_list.append(float(bi) if bi is not None else 0.0)

    # Portfolio T (total AR) — RCM methodology symbols (good-names in .pylintrc)
    T = sum(x_list)
    T_safe = 0.0 if T <= 0 else T

    # N[thr]: sum of balances with AR days >= threshold (methodology aging buckets)
    N: dict[int, float] = {}
    for thr in breaks:
        N[thr] = 0.0
        for i in range(n):
            ar = ar_list[i]
            if ar is not None and ar >= thr:
                N[thr] += x_list[i]

    # ADC
    adc_cfg = kq.get("adc")
    adc_source = "config"
    if adc_cfg is not None and float(adc_cfg) > 0:
        adc = float(adc_cfg)
    else:
        # Fallback: estimate from batch billed / 90-day lookback
        total_billed = sum(billed_list)
        lookback = float(kq.get("adc_lookback_days", 90) or 90)
        if total_billed > 0 and lookback > 0:
            adc = total_billed / lookback
            adc_source = "estimate_billed_90"
        else:
            # last resort: avoid div0; Days in AR quantifiers become 0
            adc = 0.0
            adc_source = "unavailable"

    days_in_ar = (T_safe / adc) if adc > 0 else 0.0

    totals: dict[str, float] = {
        "kpi_total_ar": round(T_safe, 2),
        "kpi_days_in_ar": round(days_in_ar, 6),
        "adc": round(adc, 6) if adc else 0.0,
        "adc_source": adc_source,  # type: ignore[assignment]  # mixed; cast below
    }
    # store adc_source separately as string in totals via str-compatible export
    # KpiTotals should be numeric-friendly; put meta keys as-is for JSON
    for thr in breaks:
        pct = (N[thr] / T_safe * 100.0) if T_safe > 0 else 0.0
        totals[f"kpi_ar_over_{thr}_pct"] = round(pct, 6)

    # Checksums for static contrib sums
    sum_share = 0.0
    sum_contrib: dict[int, float] = {t: 0.0 for t in breaks}
    sum_days_delta = 0.0

    for i in range(n):
        x = x_list[i]
        ar = ar_list[i]
        row = out_rows[i]

        # Static share
        if emit_static:
            if T_safe > 0:
                share = x / T_safe * 100.0
            else:
                share = 0.0
            row["kpi_q_share_total_ar_pct"] = _fmt(share, kind="pct")
            sum_share += share

            for thr in breaks:
                d_i = 1.0 if (ar is not None and ar >= thr) else 0.0
                contrib = d_i * share
                row[f"kpi_q_aged{thr}_contrib_pct"] = _fmt(contrib, kind="pct")
                sum_contrib[thr] += contrib

        # Exact quantifiable measures
        if emit_delta:
            # Days in AR: x / ADC
            if adc > 0:
                delta_days = x / adc
            else:
                delta_days = 0.0
            sum_days_delta += delta_days
            if dual:
                p, ng = _split_signed(delta_days)
                row["kpi_q_days_in_ar_pos"] = _fmt(p, kind="num")
                row["kpi_q_days_in_ar_neg"] = _fmt(ng, kind="num")
            else:
                row["kpi_q_days_in_ar"] = _fmt(delta_days, kind="num")

            # Aging % exact Δ (percentage points)
            # Δ = x * (d*T - N) / (T * (T - x)) * 100
            for thr in breaks:
                if T_safe <= 0 or abs(T_safe - x) < 1e-12:
                    delta_pp = 0.0
                else:
                    d_i = 1.0 if (ar is not None and ar >= thr) else 0.0
                    numer = x * (d_i * T_safe - N[thr])
                    denom = T_safe * (T_safe - x)
                    delta_pp = (numer / denom) * 100.0
                if dual:
                    p, ng = _split_signed(delta_pp)
                    row[f"kpi_q_aged{thr}_delta_pp_pos"] = _fmt(p, kind="pp")
                    row[f"kpi_q_aged{thr}_delta_pp_neg"] = _fmt(ng, kind="pp")
                else:
                    row[f"kpi_q_aged{thr}_delta_pp"] = _fmt(delta_pp, kind="pp")

    # Optional checksums in totals (for validation)
    totals["kpi_q_share_total_ar_pct_sum"] = round(sum_share, 6)
    totals["kpi_q_days_in_ar_sum"] = round(sum_days_delta, 6)
    for thr in breaks:
        totals[f"kpi_q_aged{thr}_contrib_pct_sum"] = round(sum_contrib[thr], 6)

    # Normalize totals dict: adc_source is str — keep for JSON consumers
    out_totals: dict[str, Any] = dict(totals)
    out_totals["adc_source"] = adc_source

    return cols, out_totals  # type: ignore[return-value]


def check_kpi_quantifier_integrity(
    rows: list[dict[str, Any]],
    *,
    columns: list[str] | None = None,
    epsilon: float = 1e-3,
    expected_totals: dict[str, Any] | None = None,
) -> tuple[dict[str, float], list[dict[str, Any]]]:
    """
    Validate RCM-style kpi_q columns.

    Checks:
    - sum(share) ≈ 100 when T>0
    - sum(agedT_contrib_pct) ≈ kpi_ar_over_T_pct
    - sum(days_in_ar pos+neg) ≈ kpi_days_in_ar
    - dual pos >= 0, neg <= 0
    """
    if not rows:
        return {}, []

    failures: list[dict[str, Any]] = []
    if columns is None:
        columns = [k for k in rows[0].keys() if str(k).startswith("kpi_q_")]

    def col_sum(name: str) -> float:
        s = 0.0
        for r in rows:
            try:
                s += float(str(r.get(name, "0") or "0").replace(",", ""))
            except ValueError:
                failures.append({"Issue": "kpi_q_parse_error", "Column": name})
        return s

    logical: dict[str, float] = {}

    # Share sum
    if any(c == "kpi_q_share_total_ar_pct" for c in columns):
        ss = col_sum("kpi_q_share_total_ar_pct")
        logical["kpi_q_share_total_ar_pct_sum"] = round(ss, 6)
        # allow empty portfolio
        if ss > 0 and abs(ss - 100.0) > max(epsilon, 0.05):
            # floating claims; soft check only if expected has total_ar > 0
            if expected_totals and float(expected_totals.get("kpi_total_ar") or 0) > 0:
                if abs(ss - 100.0) > 0.5:
                    failures.append(
                        {
                            "Issue": "share_sum_not_100",
                            "Sum": ss,
                        }
                    )

    # Days in AR sum
    if any("days_in_ar" in c for c in columns):
        if "kpi_q_days_in_ar_pos" in columns:
            ds = col_sum("kpi_q_days_in_ar_pos") + col_sum("kpi_q_days_in_ar_neg")
        else:
            ds = col_sum("kpi_q_days_in_ar")
        logical["kpi_q_days_in_ar_sum"] = round(ds, 6)
        if expected_totals and "kpi_days_in_ar" in expected_totals:
            exp = float(expected_totals["kpi_days_in_ar"])
            if abs(ds - exp) > max(epsilon, 1e-3):
                failures.append(
                    {
                        "Issue": "days_in_ar_sum_mismatch",
                        "Sum": ds,
                        "Expected": exp,
                    }
                )

    # Aged contrib sums
    for c in columns:
        if c.startswith("kpi_q_aged") and c.endswith("_contrib_pct"):
            # kpi_q_aged90_contrib_pct
            mid = c[len("kpi_q_aged") : -len("_contrib_pct")]
            if mid.isdigit():
                thr = int(mid)
                cs = col_sum(c)
                logical[f"kpi_q_aged{thr}_contrib_pct_sum"] = round(cs, 6)
                key = f"kpi_ar_over_{thr}_pct"
                if expected_totals and key in expected_totals:
                    exp = float(expected_totals[key])
                    if abs(cs - exp) > max(epsilon, 0.05):
                        failures.append(
                            {
                                "Issue": "aged_contrib_sum_mismatch",
                                "Threshold": thr,
                                "Sum": cs,
                                "Expected": exp,
                            }
                        )

    # Dual sign rules for pos/neg columns
    for c in columns:
        if not c.endswith("_pos") and not c.endswith("_neg"):
            continue
        for i, r in enumerate(rows):
            try:
                v = float(str(r.get(c, "0") or "0").replace(",", ""))
            except ValueError:
                continue
            if c.endswith("_pos") and v < -epsilon:
                failures.append(
                    {"RowIndex": i, "Issue": "kpi_q_pos_negative", "Column": c, "Value": v}
                )
            if c.endswith("_neg") and v > epsilon:
                failures.append(
                    {"RowIndex": i, "Issue": "kpi_q_neg_positive", "Column": c, "Value": v}
                )

    # Pass through expected portfolio totals for reporting
    if expected_totals:
        for k, v in expected_totals.items():
            if isinstance(v, (int, float)):
                logical.setdefault(str(k), float(v))

    return logical, failures
