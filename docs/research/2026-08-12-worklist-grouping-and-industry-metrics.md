---
title: Worklist grouping and industry-metric fit
description: Inventory of schema and scored columns vs common professional-billing RCM metrics; options for grouped follow-up worklists (planning only).
version: "1.0.0"
status: draft
audience:
  - analysts
  - developers
  - maintainers
doc_type: other
related:
  - ../README.md
  - ../PLAN.md
  - ../plan/cluster-3-analysis.md
  - ../WQ_Priority_Matrix_Concept.md
  - ../../wq_schema/wq_schema.json
  - ../../kpi-analytics/SCORE-METHODOLOGY.md
  - ../../kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md
  - ../../kpi-analytics/CLI-GUIDE.md
  - ../../PLAN.md
last_updated: "2026-08-12"
---

# Worklist grouping and industry-metric fit

Planning research only. **No product code.** Does **not** freeze Cluster 3. On conflict with L4 contracts, [SCORE-METHODOLOGY](../../kpi-analytics/SCORE-METHODOLOGY.md), schema, and [kit/RULES.md](../../kit/RULES.md) win.

**Document version:** 1.0.0  
**Status:** draft  
**Backlog home:** [docs/PLAN.md](../PLAN.md) Cluster 3 · freeze checklist [plan/cluster-3-analysis.md](../plan/cluster-3-analysis.md)  
**V2/V3 design:** [WQ_Priority_Matrix_Concept.md](../WQ_Priority_Matrix_Concept.md) (not this note)

**Related:** [wq_schema.json](../../wq_schema/wq_schema.json) · [SCORE-METHODOLOGY](../../kpi-analytics/SCORE-METHODOLOGY.md) · [RCM methodology](../../kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md)

---

## Summary

The extract already carries **identity, financial, aging, denial, provider, and site** columns. V1 scoring adds explainable **priority** (`v1_*`) and **RCM claim impact** (`kpi_q_*`). That is enough to **group claims into worklists** (payer, plan, denial type, patient, provider, location, and more) and **sort those groups** toward a Point of Interest (POI) without changing the score formula.

Many **industry RCM rates** (net collection, clean-claim, denial *rate*, appeal success) need **payments, write-offs, billed-population denominators, or outcomes** that this WQ extract does **not** have. Those stay out of scope until the schema grows.

**Recommended planning stance:** treat grouped worklists as **Cluster 3 reporting** (post-score). Keep V1 scores and `kpi_q_*` unchanged. Anything that *feeds grouping stats back into* `v1_priority_score` is **V2**, not this slice.

---

## Contents

1. [Summary](#summary)
2. [Goal](#goal)
3. [Column inventory](#column-inventory)
4. [Industry metrics vs what we can compute](#industry-metrics-vs-what-we-can-compute)
5. [Grouping keys already in the extract](#grouping-keys-already-in-the-extract)
6. [Group-level calculations (candidates)](#group-level-calculations-candidates)
7. [Solution options](#solution-options)
8. [POI-aligned worklist sort](#poi-aligned-worklist-sort)
9. [Privacy, architecture, and V2 boundary](#privacy-architecture-and-v2-boundary)
10. [Suggested planning sequence](#suggested-planning-sequence)
11. [Open questions (do not freeze here)](#open-questions-do-not-freeze-here)
12. [Document history](#document-history)

---

## Goal

A follow-up representative should be able to work a **list of groups**, not only a flat claim sort:

| Need | Example |
|------|---------|
| Same contact / script | All claims for one **payer + plan + denial category** |
| One phone call | All open items for one **patient / account** |
| Same documentation owner | All items for one **billing or rendering provider** or **location** |
| Target leadership focus | Groups ranked by the active **POI** (cash, write-off risk, stall) using **aggregates** of existing `v1_*` / `kpi_q_*` / dollars |

Detail rows stay scored and explainable. Groups are a **presentation / work-order layer**.

---

## Column inventory

### Source extract (`wq_schema` — 40 fields)

Canonical names: [wq_schema.json](../../wq_schema/wq_schema.json). Sample headers match ([wq_data.csv](../../wq_schema/wq_data.csv)).

| Theme | Fields | Typical use |
|-------|--------|-------------|
| **Queue / workflow** | `wq_status`, `deferral_reason`, `days_on_wq_tab`, `last_worked_date`, `follow_up_priority`, `follow_up_record_id`, `crd_record_id`, `wq_defer_user_comment`, `wq_transfer_user_comment` | Status, stall, source-system rank (not V1) |
| **Identity (PHI-adjacent)** | `patient`, `dob`, `account`, `sub_id`, `group_num`, `invoice_num` | Patient/account grouping; masking applies on **score output** for `patient` / `dob` only |
| **Money** | `out_ins_amt`, `billed_amount`, `score` (source integer; not `v1_priority_score`) | AR dollars, charge; V1 + `kpi_q_*` use `out_ins_amt` by default |
| **Aging / deadlines** | `service_date`, `days_until_appeal_deadline`, `days_until_replacement_deadline` | Claim age, timely-filing / appeal windows |
| **Payer / product** | `payer`, `plan` | Payer-mix groups; same portal / phone tree |
| **Denial** | `denial_status`, `code_category`, `reason_code_list`, `remittance_code`, `denial_count`, `related_charge_lines` | Denial-type groups; repeat-denial signal |
| **Clinical** | `cpt_codes`, `modifiers`, `diagnosis_codes` | Procedure / dx clusters (often multi-value strings) |
| **Provider / site** | `svc_provider`, `billing_provider`, `billing_provider_npi`, `billing_provider_tax_id`, `location`, `department` | Provider and site worklists |
| **Ops flags** | `suspended_nrp_status`, `pending_remittance_run` | Hold / remittance filters |

**Not in the schema today:** work-queue **name**, assigned follow-up **owner**, payment / adjustment / write-off amounts, allowed amount, claim **submit** date, payment date, appeal **outcome**, or a billed-population denominator.

### Produced on every `score` run (appended)

| Family | Columns (shape) | Role |
|--------|-----------------|------|
| **Priority V1** | `v1_as_of_date`, `v1_queue_mode`, `v1_poi_name`, `v1_normalization`, `v1_raw_*`, `v1_norm_*`, `v1_weight_*`, `v1_contrib_*`, `v1_priority_score` | Rank + audit |
| **RCM Q** | `kpi_q_share_total_ar_pct`, `kpi_q_aged{30,60,90,120}_contrib_pct`, `kpi_q_days_in_ar_pos` / `_neg`, `kpi_q_aged{T}_delta_pp_pos` / `_neg` | Portfolio share and resolution impact |
| **Privacy** | Transformed `patient` (token); blank `dob` when enabled | Operational mask, not Safe Harbor |

V1 raw metrics (when roles exist): claim age, age vs target, outstanding, billed, appeal urgency, WQ age, BWDO, denial count, days since last worked, dual-deadline urgency. See [SCORE-METHODOLOGY §3–8](../../kpi-analytics/SCORE-METHODOLOGY.md).

**Batch-relative warning:** `v1_priority_score` and norms change if the **row set** changes. Group **sums of dollars** and **sums of `kpi_q_*` static share** are more stable than averaging priority across changing batches.

---

## Industry metrics vs what we can compute

Guidance only (HFMA MAP-style professional-billing measures). Not a compliance claim.

| Industry-style measure | Usable from this extract? | How / gap |
|------------------------|---------------------------|-----------|
| **Total AR / outstanding** | **Yes** | Sum `out_ins_amt` (or configured `amount_field`) |
| **Days in AR** | **Yes (batch)** | Already `kpi_days_in_ar` via ADC (config or billed÷lookback) |
| **AR aging % (30/60/90/120)** | **Yes (batch + claim)** | `kpi_q_aged{T}_contrib_pct` and portfolio % |
| **Claim / AR days** | **Yes** | `v1_raw_claim_age_days` from `service_date` |
| **Balance-weighted days outstanding** | **Yes** | V1 BWDO raw / contrib |
| **Payer / plan mix ($ and count)** | **Yes** | Group by `payer`, `plan` |
| **Denial category mix ($ and count)** | **Partial** | Group by `code_category` / `remittance_code` / `reason_code_list` (strings; may be multi-code) |
| **Repeat denial** | **Partial** | `denial_count` on the WQ row, not a lifetime payer history |
| **Timely filing / appeal window** | **Yes** | `days_until_*_deadline`; V1 urgency metrics |
| **Stall / touches** | **Partial** | `last_worked_date`, `days_on_wq_tab`; no touch log |
| **Provider / location concentration** | **Yes** | Group by provider / NPI / `location` / `department` |
| **Net / gross collection rate** | **No** | Need payments, adjustments, contractuals |
| **Denial rate / clean-claim / FPRR** | **No** | Need billed-claim **denominator**, not only WQ denials |
| **Write-off / bad-debt rate** | **No** | No write-off amount or reason |
| **Appeal success / recovery %** | **No** | No outcome; V3 concept |
| **Cost to collect / productivity** | **No** | No staff time or owner |
| **Charge lag (DOS → bill)** | **No** | No bill/submit date |
| **Credit-balance AR** | **Partial** | Credits only if present in `out_ins_amt`; policy `credit_policy` |

**Implication:** group worklists should advertise **inventory and impact on this file** (count, $, aging, deadlines, V1/POI, `kpi_q_*`). Do not label them “denial rate” or “collection rate” unless new fields arrive.

---

## Grouping keys already in the extract

Priority for **efficient follow-up** (same action, one contact):

| Priority | Group key(s) | Why it helps a rep |
|----------|--------------|--------------------|
| **High** | `payer` + `plan` | Same portal, phone tree, and payer rules |
| **High** | `code_category` or `remittance_code` | Same appeal packet / script |
| **High** | `payer` + `code_category` | Best default “work the same problem” |
| **High** | `patient` or `account` | One call / one statement; **PHI** |
| **Medium** | `billing_provider` / NPI / `svc_provider` | Same clinic for notes / auth |
| **Medium** | `location` / `department` | Same site queue |
| **Medium** | `denial_status` | Same lifecycle step |
| **Lower / optional** | `cpt_codes`, `diagnosis_codes` | Clinical clusters; parse multi-value first |
| **Filter, not group** | `wq_status`, `suspended_nrp_status`, `pending_remittance_run` | Drop holds before ranking |
| **Avoid as primary key** | `invoice_num`, record IDs | Too granular (one claim) |

`reason_code_list` is often a **comma-separated list** — grouping on the raw string splits the same CARC family. A later freeze should decide: raw string vs first code vs exploded rows.

There is **no WQ-name field** (also a Cluster 2 open question). Cross-file “by work queue” needs a filename/operator label first.

---

## Group-level calculations (candidates)

All are **aggregates of existing columns**. None require new V1 metrics.

| Aggregate | Source | Use |
|-----------|--------|-----|
| `claim_count` | Row count | Volume |
| `sum_out_ins` | `out_ins_amt` | Cash / AR impact |
| `sum_billed` | `billed_amount` | Charge exposure |
| `sum_kpi_q_share` | `kpi_q_share_total_ar_pct` | Share of **this batch’s** AR |
| `sum_kpi_q_days` | `kpi_q_days_in_ar_pos` | Contribution to Days in AR |
| `sum_aged90_contrib` | `kpi_q_aged90_contrib_pct` | Aging concentration |
| `max_v1_priority` / `p90` | `v1_priority_score` | Hottest claim in the group |
| `min_appeal_days` | `days_until_appeal_deadline` | Nearest write-off risk |
| `max_claim_age` | `v1_raw_claim_age_days` | Oldest in group |
| `max_denial_count` | `denial_count` | Worst repeat |
| `max_days_since_worked` | `v1_raw_days_since_last_worked` | Stale group |
| `unique_patients` / `unique_invoices` | identity columns | Complexity |

**Do not average `v1_priority_score` as the only group rank** — it is batch-relative and not dollar-weighted. Prefer **dollar or `kpi_q_*` sums**, then use max priority or min deadline as a **tie-break**.

---

## Solution options

None of these are chosen. All stay **post-score** unless a later freeze says otherwise.

| ID | Option | What the operator gets | Pros | Cons | Fits |
|----|--------|------------------------|------|------|------|
| **A** | **Excel-only** (PivotTable / sort on scored `.xlsx`) | Manual groups now | Zero product code; uses current export | Not repeatable; easy to break PHI / unique paths | Spike / interim |
| **B** | **Post-score group CSV** (new kpi verb or `score --group-by`) | `*_groups.csv`: one row per key + aggregates | Stdlib, automatable, toolkit-independent | New CLI contract; still CSV-centric | Cluster 3 reporting |
| **C** | **Excel analysis sheet** on export | Sheet “Groups” + keep detail sheet | Matches Cluster **3.3**; good for leadership | Excel-only; COM still no scoring math | Cluster 3.3 |
| **D** | **Two-level worklist** | Group **header** then member claims (CSV or two sheets) | Rep works a **list** then drills in | Harder UX; sort-within-group rules | 3.1 + 3.2 |
| **E** | **Menu “Build worklist”** | Pick keys + POI-aligned sort, then export | Matches how people use Process my data | Composition only (subprocess + Excel); freeze UX first | After B or C |
| **F** | **Feed group stats into V1 score** | Category volume/velocity in `v1_priority_score` | True V2 intelligence | **Not Cluster 3**; new metrics + fixtures + methodology | [V2 concept](../WQ_Priority_Matrix_Concept.md) |

**Planning recommendation (not a freeze):** **B then C**, with **D** as the worklist shape. **A** is fine as a manual rehearsal. **E** after the CSV/sheet contract exists. **F** stays S5 / V2.

Cluster 3.2 (multi-sort on **detail** rows) is still useful *inside* a group: e.g. group by payer+category, then sort members by `v1_priority_score` desc, `days_until_appeal_deadline` asc.

---

## POI-aligned worklist sort

Profiles already change **claim-level** weights only ([SCORE-METHODOLOGY — focus presets](../../kpi-analytics/SCORE-METHODOLOGY.md#focus-presets-poi-multipliers-260)). Group ranking can **reuse the same POI** without new math:

| Active POI (`v1_poi_name`) | Suggested **group** sort (primary → tie-break) |
|----------------------------|--------------------------------------------------|
| `default` / Balanced | `sum_out_ins` desc → `max_v1_priority` desc → `min_appeal_days` asc |
| `maximize_cash` | `sum_out_ins` desc → `sum_kpi_q_share` desc → BWDO-related raw max |
| `protect_writeoffs` | `min_appeal_days` asc → `max_claim_age` desc → `sum_aged90_contrib` desc |
| `suppress_aging` | `max_days_since_worked` desc → `max_denial_count` desc → `min_appeal_days` asc |

The scored file already carries `v1_poi_name`. A worklist builder can read that and pick the sort recipe — still **reporting**, not a new score.

---

## Privacy, architecture, and V2 boundary

| Constraint | Implication |
|------------|-------------|
| Patient grouping | Default score output **masks** `patient` and blanks `dob`. Group-by-patient then uses **tokens** (or needs an explicit unmask policy — do not do that in git/samples). `account` / `sub_id` / comments can still identify. |
| Runtime split | No grouping math in PowerShell beyond sort/sheet layout; no Excel COM from Python. Join at files/CLI. |
| Explainability | Do not collapse groups into one opaque number. Keep `claim_count`, `$`, and named aggregates. |
| `kpi_q_*` | Dual attribution stays claim-level; group sums of **static** share are valid. Do not sum aging **Δ pp** as if they were additive %. |
| V2 | Category volume/velocity **inside the priority formula** = V2. Category **summaries** = Cluster 3. |

---

## Suggested planning sequence

1. Confirm this note’s inventory (schema + score columns) with an analyst.  
2. Pick **default group keys** (proposal: `payer` + `code_category`, plus optional `patient` / `billing_provider`).  
3. Pick **aggregates + POI sort recipes** (table above).  
4. Freeze Cluster 3 in [plan/cluster-3-analysis.md](../plan/cluster-3-analysis.md): post-score vs Excel-only; output shape (B/C/D); privacy for patient groups.  
5. Rehearse **option A** on a synthetic scored workbook to validate keys (no code).  
6. Only then implement B/C (implementer + full certification).  
7. Leave **F / V2** on S5 until leadership wants category volume *in the score*.

Do **not** start Cluster 3 product code until that freeze. Cluster 2 (multi-file / WQ identity) is a separate freeze if groups must span files.

---

## Open questions (do not freeze here)

Carry into Cluster 3 freeze when ready:

| # | Question | Straw man |
|---|----------|-----------|
| 1 | Default group key | `payer` + `code_category` |
| 2 | Multi-value `reason_code_list` / CPT | First token vs explode vs raw |
| 3 | Patient groups vs tokens | Tokens only on scored output |
| 4 | Output shape | Groups CSV **and** Excel sheet; detail preserved |
| 5 | Group rank vs average priority | Dollar / `kpi_q` sum; never average-only |
| 6 | Empty / null keys | Bucket `(blank)` |
| 7 | Cross-file groups | Blocked until Cluster 2 WQ identity |
| 8 | Source `score` / `follow_up_priority` | Display only; do not mix into V1 |

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial inventory, industry-metric fit, and worklist options (planning only) |
