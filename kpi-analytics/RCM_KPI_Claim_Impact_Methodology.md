---
title: RCM KPI Claim Impact Methodology
description: Professional billing dual-attribution model for Days in AR and aging percentages with claim-level quantifiable measures.
version: "1.1"
status: current
audience:
  - analysts
  - developers
  - rcm-operations
doc_type: methodology
related:
  - README.md
  - SCORE-METHODOLOGY.md
  - CLI-GUIDE.md
last_updated: "2026-07-22"
---

# Methodology for Professional Billing RCM KPI Calculation and Individual Claim Quantifiable Measure Attribution

**Document version:** 1.1  
**Date:** July 22, 2026  
**Scope:** Professional billing (physician practices, medical groups, and outpatient professional services)  
**Role in this repository:** Conceptual **proof of concept** and theory reference for `kpi_q_*` claim impacts implemented in `kpi_modules`.

**Implementation mapping:** [SCORE-METHODOLOGY.md](./SCORE-METHODOLOGY.md) §10 · package module `kpi_quantifiers.py`  
**Product overview:** [README.md](./README.md)

This document defines industry-standard RCM formulas and dual attribution. Column names below are **conceptual**. In software they appear under the stable `kpi_q_*` / `KpiTotals` naming convention (see §9).

---

## Summary

This methodology defines how professional billing teams should measure **portfolio RCM KPIs**—especially **Days in AR** (\(T/\mathrm{ADC}\)) and **balance-weighted aging percentages** (AR > 30/60/90/120)—and how to attribute those KPIs to **individual claims** without misleading single-column sums.

It establishes a **dual-attribution** model for every claim:

| Quantity | Answers | Adds to the portfolio KPI? |
|----------|---------|----------------------------|
| **Static share / contribution** | How much of the problem is this claim *right now*? | **Yes** (dollar-weighted) |
| **Exact quantifiable measure (Δ)** | If this balance goes to zero *today*, how much does the KPI move? | **Days in AR: yes.** Aging **% Δ: no** (single-claim resolution impact; young claims can be **negative**) |

Closed-form formulas, a worked numerical example (§6), implementation guidance, and a mapping to this repository’s `kpi_q_*` column names (§9) support auditable dashboards and work-queue design. In `kpi-analytics`, these concepts are implemented by `kpi_quantifiers.py`; priority ranking (`v1_*`) remains a separate concern.

---

## Contents

1. [Summary](#summary)
2. [Introduction](#1-introduction)
3. [Core KPI Definitions and Aggregate Formulas](#2-core-kpi-definitions-and-aggregate-formulas)
4. [Why a Single Aggregate Column Is Insufficient](#3-why-a-single-aggregate-column-is-insufficient)
5. [Dual-Attribution Methodology](#4-dual-attribution-methodology)
6. [Recommended Claims-Level Data Model for Professional Billing](#5-recommended-claims-level-data-model-for-professional-billing)
7. [Worked Numerical Example (Professional Billing Context)](#6-worked-numerical-example-professional-billing-context)
8. [Practical Implementation Guidance for Professional Billing](#7-practical-implementation-guidance-for-professional-billing)
9. [Summary of Best Approach for Professional Billing](#8-summary-of-best-approach-for-professional-billing)
10. [Implementation mapping in `kpi-analytics`](#9-implementation-mapping-in-kpi-analytics-naming-retained)
11. [Document history](#10-document-history)

---

## 1. Introduction

In professional billing RCM, aggregate KPIs such as Days in AR and the percentage of AR aged over 90 days are essential for monitoring cash-flow velocity and collection risk within physician practices and medical groups. Operational decision-making, however, requires more than the headline number: billing staff and managers must understand *which claims* drive the metric and the *quantifiable measure* by which resolving (or failing to resolve) a specific claim will move the KPI.

A naïve approach of simply summing claim balances into a single column fails for several reasons:

- Percentage metrics involve both a numerator and a denominator; changing one claim alters both.
- Resolving a young claim can *worsen* the AR > 90 percentage (by shrinking the denominator while the aged AR remains).
- New claims continuously dilute percentages even when no collection work occurs.
- Negative balances (credits, overpayments) reverse the direction of the quantifiable measure.
- Days in AR behaves differently from pure aging percentages because the denominator (Average Daily Charges) is typically fixed from historical data.

This document therefore defines:

1. Standard formulas for the core KPIs tailored to professional billing.  
2. A dual-attribution model (static share + exact quantifiable measure of change).  
3. Closed-form equations for each claim’s contribution and the change that occurs if the claim is fully resolved.  
4. Recommended data-model columns and practical implementation notes for physician practice and medical group environments.  

---

## 2. Core KPI Definitions and Aggregate Formulas

### 2.1 Days in Accounts Receivable (AR Days / Days Receivable Outstanding)

\[
\text{Days in AR} = \frac{T}{\text{ADC}}
\]

where

- \( T \) = Total outstanding AR balance as of the snapshot date (usually the sum of all positive patient and insurance balances; credits are handled according to practice policy—commonly excluded or netted separately).
- \( \text{ADC} \) = Average Daily Charges = \(\dfrac{\text{Total Net Charges over look-back period}}{\text{Number of days in look-back period}}\)  
  (Industry practice for professional billing most often uses a 90-day look-back.)

**Typical benchmarks for professional billing / physician practices:**

| Performance Level | Days in AR Target |
|-------------------|-------------------|
| Strong / Best-in-class | < 25–30 days |
| Acceptable | 30–40 days |
| Needs improvement | > 40–45 days |

### 2.2 AR Aging Percentages

AR is partitioned into standard aging buckets (commonly 0–30, 31–60, 61–90, 91–120, 120+ days). For any threshold or bucket \( B \):

\[
\% \text{ AR in } B = \frac{N_B}{T} \times 100
\]

where \( N_B \) is the sum of balances whose age falls inside bucket \( B \).

The most frequently monitored thresholds in professional billing are:

- AR > 30  
- AR > 60  
- AR > 90  
- AR > 120  

**Illustrative targets for AR > 90 in physician practices and medical groups:**

| Performance Level | AR > 90 Target |
|-------------------|----------------|
| Strong / Best-in-class | < 8–10 % |
| Acceptable | < 12–15 % |
| Needs improvement | > 15–20 % |

---

## 3. Why a Single Aggregate Column Is Insufficient

Consider a simple percentage metric \( p = N/T \). When a claim of balance \( x \) is removed:

- Both numerator and denominator change.
- The new value is \( (N - d\cdot x)/(T - x) \), where \( d = 1 \) if the claim belongs to the measured bucket and \( 0 \) otherwise.
- The absolute change in percentage points is therefore *not* equal to \( x/T \).

Moreover:

- Resolving a claim that is *not* in the aged bucket actually *increases* the aged percentage (producing a negative quantifiable measure relative to the KPI goal).
- Continuous arrival of new claims increases \( T \) and thereby dilutes every aging percentage even if collection performance is unchanged.
- Days in AR is affected only through the numerator (ADC is historical), so every positive-balance claim has a strictly favorable quantifiable measure on the metric when resolved.

Consequently, two distinct quantities must be maintained for every claim:

1. **Static share** – the claim’s current weight in the portfolio (useful for ranking and prioritization).  
2. **Exact quantifiable measure of change** – the precise movement in the KPI that would occur if the claim’s balance were set to zero today.  

---

## 4. Dual-Attribution Methodology

### 4.1 Notation

| Symbol | Meaning |
|--------|---------|
| \( T \) | Current total AR |
| \( N_{90} \) | Current AR balance aged > 90 days |
| \( x_i \) | Current balance of claim \( i \) |
| \( d_i \) | Indicator: 1 if claim \( i \) is aged > 90, else 0 |
| \( \text{ADC} \) | Average Daily Charges (fixed for the snapshot) |

(The same logic extends immediately to any other threshold—30, 60, 120—by substituting the appropriate numerator.)

### 4.2 Static Contribution (Share)

\[
\text{Share}_i = \frac{x_i}{T} \times 100 \quad (\%)
\]

\[
\text{Contribution to AR}>90_i = d_i \times \text{Share}_i
\]

This is the figure most often quoted operationally (“this claim represents 1.5 % of total AR / of AR > 90”).

**Additivity:** \(\sum_i \text{Contribution to AR}>90_i = \%\text{AR}>90\).

### 4.3 Exact Quantifiable Measure of Change on AR > 90 Percentage

If claim \( i \) is fully resolved (balance → 0):

\[
\text{New AR}>90\% = \frac{N_{90} - d_i x_i}{T - x_i} \times 100
\]

The change in the KPI (in percentage points) is:

\[
\Delta_{90,i} = \left( \frac{N_{90}}{T} - \frac{N_{90} - d_i x_i}{T - x_i} \right) \times 100
\]

Algebraic simplification yields the closed-form expression:

\[
\Delta_{90,i} = \frac{x_i \bigl( d_i \, T - N_{90} \bigr)}{T \,(T - x_i)} \times 100
\]

**Interpretation of the quantifiable measure:**

- When \( d_i = 1 \) (aged claim): \( \Delta_{90,i} > 0 \) → resolving the claim *reduces* AR > 90 % (favorable movement of the metric).  
- When \( d_i = 0 \) (young claim): \( \Delta_{90,i} < 0 \) → resolving the claim *increases* AR > 90 % (unfavorable movement of the metric).  

This is the mathematical origin of the “negative quantifiable measure” that newer claims can exert on the aging percentage.

**Note:** \(\sum_i \Delta_{90,i}\) is **not** equal to the AR > 90 % KPI. These values answer single-claim resolution impact, not static portfolio composition.

### 4.4 Exact Quantifiable Measure of Change on Days in AR

Because ADC is independent of the current AR balance:

\[
\Delta_{\text{Days},i} = \frac{x_i}{\text{ADC}}
\]

Resolving any positive-balance claim always reduces Days in AR by exactly this amount. (Negative-balance claims increase Days in AR.)

**Additivity:** \(\sum_i \Delta_{\text{Days},i} = T/\text{ADC} = \text{Days in AR}\).

### 4.5 Extension to Other Aging Thresholds

Replace \( N_{90} \) and \( d_i \) with the corresponding values for the desired threshold (e.g., \( N_{120} \), \( d_i^{(120)} \)). The formulas remain identical.

---

## 5. Recommended Claims-Level Data Model for Professional Billing

Maintain the following columns (or calculated fields) on every open claim:

| Conceptual column | Description / Formula |
|-------------------|------------------------|
| `claim_id` | Unique identifier |
| `balance` (\( x_i \)) | Current outstanding amount |
| `age_days` | Days since service / statement date |
| `aging_bucket` | 0-30 / 31-60 / 61-90 / 91-120 / 120+ |
| `is_over_90` (\( d_i \)) | Boolean or 0/1 |
| `share_of_total_ar_pct` | \( x_i / T \times 100 \) |
| `contribution_to_ar90_pct` | \( d_i \times \) share_of_total_ar_pct |
| `quantifiable_measure_ar90_pp` | Exact \( \Delta_{90,i} \) (percentage points) |
| `quantifiable_measure_ar_days` | \( x_i / \text{ADC} \) |
| `quantifiable_measure_ar120_pp` | Analogous exact delta for the 120-day threshold |
| … | Additional thresholds as required |

A separate summary row (or dashboard card) always displays the current aggregate KPIs:

- Total AR \( T \)  
- AR > 90 % = \( N_{90}/T \times 100 \)  
- Days in AR = \( T / \text{ADC} \)  

When a claim is worked and its balance changes, the entire set of contribution and quantifiable-measure columns is recomputed from the new snapshot. Because the formulas are closed-form, recomputation is inexpensive and suitable for daily practice dashboards.

---

## 6. Worked Numerical Example (Professional Billing Context)

**Snapshot data from a physician practice**

| Claim | Balance \( x \) | Age (days) | In >90? |
|-------|-----------------|------------|---------|
| A | 10 000 | 120 | Yes |
| B | 5 000 | 45 | No |
| C | 20 000 | 15 | No |
| D | 15 000 | 105 | Yes |

\[
T = 50\,000, \quad N_{90} = 25\,000, \quad \text{AR}>90\% = 50\%
\]

Assume \(\text{ADC} = 2\,000\) → Days in AR = 25 (within a strong professional billing range).

**Claim A (aged)**

- Share of total AR = \( 10\,000 / 50\,000 = 20\% \)  
- Contribution to AR > 90 = 20 %  
- Exact quantifiable measure \(\Delta_{90}\) = \(\dfrac{10\,000 \times (1\cdot 50\,000 - 25\,000)}{50\,000 \times (50\,000-10\,000)} \times 100 = 12.5\) percentage points  
  (New AR > 90 % would be 37.5 %)  
- Quantifiable measure on Days = \( 10\,000 / 2\,000 = 5 \) days  

**Claim B (young)**

- Share of total AR = 10 %  
- Contribution to AR > 90 = 0 %  
- Exact quantifiable measure \(\Delta_{90}\) = \(\dfrac{5\,000 \times (0\cdot 50\,000 - 25\,000)}{50\,000 \times 45\,000} \times 100 \approx -5.56\) percentage points  
  (Resolving B would *raise* AR > 90 % to 55.56 %)  
- Quantifiable measure on Days = 2.5 days  

This example demonstrates why the two quantities must be kept separate: the static contribution of Claim B to the AR > 90 metric is zero, yet its quantifiable measure of change is unfavorable.

**Repository fixture:** `fixtures\rcm_impact_example.csv` + `fixtures\rcm_impact_config.json` reproduce these numbers under `kpi_q_*` naming (see §9).

---

## 7. Practical Implementation Guidance for Professional Billing

1. **Snapshot consistency** – All calculations must use balances and ages as of the same close-of-business date. Recalculate after every significant posting run or daily claim status update common in physician practice billing systems.

2. **Treatment of credits** – Decide practice policy on whether negative balances are:
   - Excluded from \( T \) and all numerators,  
   - Included (they then produce opposite-signed quantifiable measures), or  
   - Reported in a separate “credit AR” metric.  

3. **Prioritization scoring** – A practical work-queue score for professional billing staff can combine:

   \[
   \text{Score}_i = w_1 \cdot |\Delta_{90,i}| + w_2 \cdot \Delta_{\text{Days},i} + w_3 \cdot \text{collectability probability} - w_4 \cdot \text{effort}
   \]

   Claims with large positive \(\Delta_{90}\) should surface first in the queue.  
   *(In this repository, Priority Matrix V1 is a separate, configurable ranking model; it may later incorporate \(\Delta\) features but is not required to.)*

4. **Sequential versus simultaneous resolution** – The exact formulas assume a single claim is removed from the current snapshot. When many claims are resolved in one day (typical in high-volume professional billing), either:
   - Recompute the full set of quantifiable measures after each batch, or  
   - Use a simultaneous approximation (sum of individual \(\Delta\) values) for ranking purposes only.  

5. **New-claim dilution** – Because new claims increase \( T \), the AR > 90 percentage can improve passively. Tracking the pure collection effect therefore requires a secondary view that holds the denominator constant or reports absolute aged dollars rather than percentages.

6. **Auditability** – Store the values of \( T \), \( N_{90} \) and \(\text{ADC}\) used for each daily snapshot so that any historical claim-level quantifiable measure can be reconstructed—important for compliance and performance reviews in medical groups.

---

## 8. Summary of Best Approach for Professional Billing

| Goal | Recommended Quantity | Rationale |
|------|----------------------|-----------|
| Rank claims for work queues | Static share + exact quantifiable measure \(\Delta_{90}\) | Balances size with true KPI movement |
| Forecast KPI movement after work | Exact quantifiable measure of change formulas | Accounts for numerator/denominator interaction |
| Monitor overall performance | Aggregate Days in AR and aging % | Industry-standard for physician practices |
| Avoid misleading single-column sums | Maintain separate contribution and quantifiable-measure columns | Prevents conflation of young-claim and aged-claim effects |

By separating the static portfolio weight from the exact quantifiable measure of change, professional billing teams obtain both an intuitive “this claim is X % of the problem” view and a mathematically precise “resolving this claim will move the KPI by Y points” view. The equations provided above are closed-form, computationally cheap, and fully auditable—making them suitable for practice management system dashboards, work-queue engines, and medical group executive reporting.

---

## 9. Implementation mapping in `kpi-analytics` (naming retained)

This section bridges theory (above) to the software contract. **Do not rename product columns to the long conceptual names** unless a future major version intentionally does so.

| Concept (this document) | Software name |
|-------------------------|---------------|
| Total AR \(T\) | `KpiTotals.kpi_total_ar` |
| Days in AR | `KpiTotals.kpi_days_in_ar` |
| AR > T % | `KpiTotals.kpi_ar_over_{T}_pct` |
| ADC | `KpiTotals.adc` (+ `adc_source`) |
| Share of total AR | `kpi_q_share_total_ar_pct` |
| Contribution to AR > T | `kpi_q_aged{T}_contrib_pct` |
| \(\Delta\) Days in AR | `kpi_q_days_in_ar_pos` / `_neg` (or single column if dual off) |
| \(\Delta\) AR > T (pp) | `kpi_q_aged{T}_delta_pp_pos` / `_neg` |
| Balance \(x_i\) | Config `amount_field` (default `out_ins_amt`) |
| Age days | Computed AR days (`as_of − service_date`) |

**Checksums** in the vertical summary under **Portfolio KPI Q checksum** re-sum claim-level static and Days-in-AR quantifiers to prove they rebuild portfolio KPIs.

**Default ADC behavior in software:** if `kpi_quantifiers.adc` is unset, ADC may be estimated as total batch billed ÷ lookback days (typically 90), labeled `adc_source = estimate_billed_90`. Production use should set true practice ADC in config.

**Work-queue priority** remains `v1_priority_score` and related `v1_*` columns—orthogonal to this methodology unless deliberately combined later.

---

## 10. Document history

| Version | Notes |
|---------|--------|
| 1.0 | Initial dual-attribution methodology for professional billing |
| 1.1 | Added repository implementation mapping (`kpi_q_*`); fixture cross-reference; YAML frontmatter for toolkit doc set |

---

*End of document.*
