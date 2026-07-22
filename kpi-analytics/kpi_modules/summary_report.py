"""
Vertical (transposed) summary CSV for score runs.

Layout: each metric/KPI is a row with adjacent columns for value and explanation.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from . import __version__
from .io_csv import write_csv_rows

SUMMARY_FIELDNAMES = [
    "section",
    "metric",
    "value",
    "unit",
    "formula",
    "explanation",
]


def _row(
    section: str,
    metric: str,
    value: Any,
    *,
    unit: str = "",
    formula: str = "",
    explanation: str = "",
) -> dict[str, str]:
    if value is None:
        val_s = ""
    elif isinstance(value, float):
        if abs(value - round(value)) < 1e-9:
            val_s = str(int(round(value)))
        else:
            val_s = f"{value:.6f}".rstrip("0").rstrip(".")
    else:
        val_s = str(value)
    return {
        "section": section,
        "metric": metric,
        "value": val_s,
        "unit": unit,
        "formula": formula,
        "explanation": explanation,
    }


def default_summary_path(scored_output_path: str | Path) -> Path:
    """e.g. wq_scored_pro250.csv -> wq_scored_pro250_summary.csv"""
    p = Path(scored_output_path)
    return p.with_name(f"{p.stem}_summary{p.suffix or '.csv'}")


def build_summary_rows(
    summary: dict[str, Any],
    *,
    input_path: str | Path | None = None,
    output_path: str | Path | None = None,
    config_path: str | Path | None = None,
) -> list[dict[str, str]]:
    """Build vertical summary rows from a score_rows summary dict."""
    rows: list[dict[str, str]] = []
    kpi = summary.get("kpi_totals") or {}
    chaos = summary.get("chaos") or {}
    weights = summary.get("weights") or {}

    # --- Run context ---
    rows.append(
        _row(
            "Run",
            "toolkit_version",
            __version__,
            explanation="Version of the kpi-analytics toolkit that produced this file.",
        )
    )
    rows.append(
        _row(
            "Run",
            "input_csv",
            str(input_path) if input_path else "",
            explanation="Original Work Queue data file used as input for scoring.",
        )
    )
    rows.append(
        _row(
            "Run",
            "scored_csv",
            str(output_path) if output_path else "",
            explanation=(
                "Detail file with one row per claim: original fields, priority scores (v1_*), "
                "and claim-level KPI impact columns (kpi_q_*)."
            ),
        )
    )
    if config_path:
        rows.append(
            _row(
                "Run",
                "config",
                str(config_path),
                explanation=(
                    "JSON config for priority weights and RCM KPI settings "
                    "(ADC, aging thresholds, etc.)."
                ),
            )
        )
    rows.append(
        _row(
            "Run",
            "as_of_date",
            summary.get("as_of_date"),
            unit="date",
            formula="config as_of_date, otherwise today's date",
            explanation=(
                "Snapshot date for the run. Claim age in days is this date minus the service date."
            ),
        )
    )
    rows.append(
        _row(
            "Run",
            "row_count",
            summary.get("row_count"),
            unit="claims",
            explanation="How many claim rows were included in this batch.",
        )
    )
    rows.append(
        _row(
            "Run",
            "column_count",
            summary.get("column_count"),
            unit="columns",
            explanation=(
                "Number of columns in the scored detail CSV "
                "(source data plus score and KPI fields)."
            ),
        )
    )

    # --- Portfolio RCM KPIs ---
    rows.append(
        _row(
            "Portfolio KPI",
            "kpi_total_ar",
            kpi.get("kpi_total_ar"),
            unit="currency",
            formula="Total AR = sum of claim balances",
            explanation=(
                "Portfolio total outstanding AR at the snapshot. "
                "By default each claim uses out_ins_amt (outstanding insurance). "
                "Negative balances may be excluded depending on credit_policy."
            ),
        )
    )
    rows.append(
        _row(
            "Portfolio KPI",
            "adc",
            kpi.get("adc"),
            unit="currency/day",
            formula="From config, or total billed in batch / lookback days (often 90)",
            explanation=(
                f"Average Daily Charges used to turn dollars into Days in AR. "
                f"Source for this run: {kpi.get('adc_source', 'n/a')}."
            ),
        )
    )
    rows.append(
        _row(
            "Portfolio KPI",
            "adc_source",
            kpi.get("adc_source"),
            explanation=(
                "Where ADC came from: 'config' means you set it; 'estimate_billed_90' means it was "
                "estimated from this file's billed amounts over a 90-day lookback."
            ),
        )
    )
    rows.append(
        _row(
            "Portfolio KPI",
            "kpi_days_in_ar",
            kpi.get("kpi_days_in_ar"),
            unit="days",
            formula="Days in AR = Total AR / ADC",
            explanation=(
                "Standard RCM Days in Accounts Receivable for the whole portfolio. "
                "If you resolve a claim, Days in AR falls by that claim's kpi_q_days_in_ar amount. "
                "Adding all claim-level days-in-AR impacts rebuilds this total."
            ),
        )
    )

    aged_keys = sorted(
        (k for k in kpi.keys() if str(k).startswith("kpi_ar_over_") and str(k).endswith("_pct")),
        key=lambda s: int(str(s).replace("kpi_ar_over_", "").replace("_pct", "") or 0),
    )
    for key in aged_keys:
        thr = str(key).replace("kpi_ar_over_", "").replace("_pct", "")
        rows.append(
            _row(
                "Portfolio KPI",
                key,
                kpi.get(key),
                unit="percent",
                formula=(
                    f"AR over {thr} % = (sum of balances aged {thr}+ days) / Total AR * 100"
                ),
                explanation=(
                    f"Percent of portfolio AR that is {thr} or more days old (weighted by dollars, "
                    f"not claim count). Claims that age into this bucket contribute via "
                    f"kpi_q_aged{thr}_contrib_pct; summing those claim columns should match this %."
                ),
            )
        )

    # --- Portfolio KPI Q checksums ---
    if "kpi_q_share_total_ar_pct_sum" in kpi:
        rows.append(
            _row(
                "Portfolio KPI Q checksum",
                "kpi_q_share_total_ar_pct_sum",
                kpi.get("kpi_q_share_total_ar_pct_sum"),
                unit="percent",
                formula="Sum of each claim's share of total AR (%)",
                explanation=(
                    "Audit total of claim-level kpi_q_share_total_ar_pct. "
                    "Should be about 100 when the portfolio has positive total AR—"
                    "confirms shares add up."
                ),
            )
        )
    if "kpi_q_days_in_ar_sum" in kpi:
        rows.append(
            _row(
                "Portfolio KPI Q checksum",
                "kpi_q_days_in_ar_sum",
                kpi.get("kpi_q_days_in_ar_sum"),
                unit="days",
                formula="Sum of each claim's Days-in-AR impact (balance / ADC)",
                explanation=(
                    "Audit total of claim-level kpi_q_days_in_ar (pos + neg). "
                    "Must match kpi_days_in_ar above—confirms per-claim quantifiers "
                    "rebuild the portfolio KPI."
                ),
            )
        )
    for key in sorted(k for k in kpi if str(k).endswith("_contrib_pct_sum")):
        thr = str(key).replace("kpi_q_aged", "").replace("_contrib_pct_sum", "")
        rows.append(
            _row(
                "Portfolio KPI Q checksum",
                key,
                kpi.get(key),
                unit="percent",
                formula=(
                    f"Sum of claim-level aged-{thr} contribution % "
                    f"(only claims aged {thr}+ days contribute)"
                ),
                explanation=(
                    f"Audit total of kpi_q_aged{thr}_contrib_pct across all claims. "
                    f"Must match the portfolio KPI kpi_ar_over_{thr}_pct—"
                    "confirms dollar-weighted aging adds up."
                ),
            )
        )

    # --- Claim-level column guide ---
    rows.append(
        _row(
            "Claim column guide",
            "kpi_q_share_total_ar_pct",
            "",
            unit="percent",
            formula="Claim balance / Total AR * 100",
            explanation=(
                "How large this claim is relative to the whole AR portfolio right now. "
                "Useful for size ranking; not the same as how much the aging % would move if paid."
            ),
        )
    )
    rows.append(
        _row(
            "Claim column guide",
            "kpi_q_aged{T}_contrib_pct",
            "",
            unit="percent",
            formula="If claim age >= T: same as share of total AR; otherwise 0",
            explanation=(
                "This claim's current dollar weight inside the AR-over-T problem. "
                "Only aged claims get a non-zero value. "
                "Adding these across claims rebuilds AR-over-T %."
            ),
        )
    )
    rows.append(
        _row(
            "Claim column guide",
            "kpi_q_days_in_ar_pos / _neg",
            "",
            unit="days",
            formula="Claim balance / ADC (split into positive and negative parts)",
            explanation=(
                "How many Days in AR this claim accounts for. "
                "If the balance is paid to zero, portfolio Days in AR improves "
                "by about this amount. Pos holds favorable (usual) amounts; "
                "neg is used if balances can be negative."
            ),
        )
    )
    rows.append(
        _row(
            "Claim column guide",
            "kpi_q_aged{T}_delta_pp_pos / _neg",
            "",
            unit="percentage points",
            formula=(
                "Closed-form change in AR-over-T % if this claim balance goes to 0"
            ),
            explanation=(
                "Estimated movement in the AR-over-T percentage if this claim is "
                "fully resolved today. Aged claims usually show a positive impact "
                "(metric improves). Younger claims can show a negative impact "
                "(paying them can raise the aged % by shrinking total AR). "
                "These deltas do not add up to the aging % itself—"
                "they answer 'what if we resolve this claim?'"
            ),
        )
    )
    rows.append(
        _row(
            "Claim column guide",
            "v1_priority_score",
            "",
            unit="0-1 score",
            formula="Weighted sum of normalized priority metrics",
            explanation=(
                "Work-queue priority score for who to work next (0 to 1, higher = more urgent). "
                "Separate from RCM portfolio KPIs and kpi_q_* impact columns. "
                "See SCORE-METHODOLOGY.md for the priority matrix."
            ),
        )
    )
    rows.append(
        _row(
            "Claim column guide",
            "v1_raw_* / v1_norm_* / v1_weight_* / v1_contrib_*",
            "",
            explanation=(
                "Priority score audit trail: original metric values, "
                "values scaled 0-1 within the batch, weights applied this run, "
                "and each metric's contribution to v1_priority_score."
            ),
        )
    )

    # --- Priority batch summary ---
    rows.append(
        _row(
            "Priority batch",
            "queue_mode",
            summary.get("queue_mode"),
            explanation=(
                "healthy or chaos based on overall AR aging of the batch. "
                "Chaos only changes priority weights—it does not change RCM kpi_q_* formulas."
            ),
        )
    )
    rows.append(
        _row(
            "Priority batch",
            "normalization",
            summary.get("normalization"),
            explanation=(
                "Method used to scale priority metrics across claims in this file "
                "(minmax or percentile) before weighting."
            ),
        )
    )
    rows.append(
        _row(
            "Priority batch",
            "poi_name",
            summary.get("poi_name"),
            explanation="Named priority focus profile (point of interest) applied to base weights.",
        )
    )
    rows.append(
        _row(
            "Priority batch",
            "score_min",
            summary.get("score_min"),
            unit="0-1",
            explanation="Lowest work-queue priority score among claims in this batch.",
        )
    )
    rows.append(
        _row(
            "Priority batch",
            "score_max",
            summary.get("score_max"),
            unit="0-1",
            explanation="Highest work-queue priority score among claims in this batch.",
        )
    )
    rows.append(
        _row(
            "Priority batch",
            "score_mean",
            summary.get("score_mean"),
            unit="0-1",
            explanation="Average work-queue priority score across all claims in this batch.",
        )
    )
    for mk, wv in weights.items():
        rows.append(
            _row(
                "Priority weights",
                f"weight_{mk}",
                wv,
                formula="Base weight x focus x chaos factors, then scaled so all weights sum to 1",
                explanation=(
                    f"Share of the priority score driven by the '{mk}' metric for this batch. "
                    "All priority weights together equal 1.0."
                ),
            )
        )

    if chaos:
        rows.append(
            _row(
                "Priority chaos",
                "chaos_enabled",
                chaos.get("enabled"),
                explanation="True if chaos detection was turned on in config for this run.",
            )
        )
        if chaos.get("mean_ar_days") is not None:
            rows.append(
                _row(
                    "Priority chaos",
                    "mean_ar_days",
                    chaos.get("mean_ar_days"),
                    unit="days",
                    explanation=(
                        "Average claim age (AR days) in the batch; "
                        "used when deciding chaos mode."
                    ),
                )
            )
        for key in ("share_ar_ge_60", "share_ar_ge_90", "share_ar_ge_120"):
            if key in chaos:
                bucket = key.replace("share_ar_ge_", "")
                rows.append(
                    _row(
                        "Priority chaos",
                        key,
                        chaos.get(key),
                        unit="fraction (0-1)",
                        explanation=(
                            f"Fraction of claims aged {bucket}+ days. "
                            "High values can trigger chaos mode and raise "
                            "permanent-loss priority weights."
                        ),
                    )
                )
        reasons = chaos.get("reasons") or []
        if reasons:
            rows.append(
                _row(
                    "Priority chaos",
                    "chaos_reasons",
                    " | ".join(str(r) for r in reasons),
                    explanation=(
                        "Which aging/volume rules fired to set queue_mode to chaos. "
                        "Empty when the queue is healthy."
                    ),
                )
            )

    rows.append(
        _row(
            "Reference",
            "rcm_methodology",
            "RCM_KPI_Claim_Impact_Methodology.md",
            explanation=(
                "Full RCM theory: Days in AR, aging percentages, static share vs "
                "exact impact when a claim is resolved (including why young claims "
                "can show a negative aging impact)."
            ),
        )
    )
    rows.append(
        _row(
            "Reference",
            "score_methodology",
            "SCORE-METHODOLOGY.md",
            explanation=(
                "How priority scoring works and how kpi_q_* columns are named "
                "and implemented in this toolkit."
            ),
        )
    )

    return rows


def write_summary_csv(
    path: str | Path,
    summary: dict[str, Any],
    *,
    input_path: str | Path | None = None,
    output_path: str | Path | None = None,
    config_path: str | Path | None = None,
) -> str:
    """Write vertical summary CSV; return resolved path string."""
    rows = build_summary_rows(
        summary,
        input_path=input_path,
        output_path=output_path,
        config_path=config_path,
    )
    p = Path(path)
    write_csv_rows(p, SUMMARY_FIELDNAMES, rows)
    return str(p.resolve())
