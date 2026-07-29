---
title: "Development Plan — Post-V1 Enhancement Concepts"
description: "Living plan for sorted enhancement concepts (KPI config, multi-file aggregation, grouping, analysis sheets, saved profiles). All items are developing concepts; details still to be worked out."
version: "0.1.0"
status: draft
audience:
  - developers
  - analysts
doc_type: other
related:
  - README.md
  - RULES.md
  - CHANGELOG.md
  - WQ_Priority_Matrix_Concept.md
  - kpi-analytics/SCORE-METHODOLOGY.md
  - kpi-analytics/CLI-GUIDE.md
  - excel-toolkit/CLI-GUIDE.md
  - excel-toolkit/README.md
  - wq_schema.json
last_updated: "2026-07-28"
---

# Development Plan — Post-V1 Enhancement Concepts

Living plan for the next set of product improvements after the shipped V1 priority matrix, dynamic mapping (kpi-analytics 2.1.0), and guided multi-select menu (excel-toolkit 1.6.0). Every item below is treated as a **developing concept**; acceptance criteria, exact CLI/menu shapes, data contracts, and implementation details remain open for discussion and refinement.

**Document version:** 0.1.0  
**Status:** draft — concepts only; no implementation committed  
**Related:** [README.md](./README.md) · [RULES.md](./RULES.md) · [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) · [kpi-analytics/SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md)

---

## Summary

This plan organizes a backlog of enhancement ideas into three non-overlapping clusters that respect the current architecture:

- Two independent toolkits (kpi-analytics = Python 3.13 stdlib scoring; excel-toolkit = PowerShell 5.1 + Excel COM).
- Shared data contract only (`wq_schema.*` + sample rows).
- V1 priority formulas + dual RCM `kpi_q_*` attribution already shipped and must stay explainable.
- Design-only V2/V3 roadmap in `WQ_Priority_Matrix_Concept.md` (denial volume/velocity, recovery probability, capacity).

The clusters are ordered so that low-risk config/profile work can ship first, multi-file workflow improvements second, and higher-complexity grouping/analysis last (with explicit watch for V2 overlap). Each concept still requires detailed design before code.

---

## Contents

1. [Summary](#summary)
2. [Background and current baseline](#background-and-current-baseline)
3. [Shared principles and hard constraints](#shared-principles-and-hard-constraints)
4. [Cluster 1 — KPI config optimization and saved profiles](#cluster-1--kpi-config-optimization-and-saved-profiles)
5. [Cluster 2 — Multi-file ingest, aggregation, and output conventions](#cluster-2--multi-file-ingest-aggregation-and-output-conventions)
6. [Cluster 3 — Grouping, sorting, and denial analysis sheet](#cluster-3--grouping-sorting-and-denial-analysis-sheet)
7. [Recommended sequencing](#recommended-sequencing)
8. [Compliance, versioning, and change control](#compliance-versioning-and-change-control)
9. [Cross-cutting open questions](#cross-cutting-open-questions)
10. [Out of scope / non-goals for this plan](#out-of-scope--non-goals-for-this-plan)
11. [Document history](#document-history)

---

## Background and current baseline

| Area | Current state (as of repo 1.6.0 / kpi 2.1.0 / excel 1.6.0) |
|------|-----------------------------------------------------------|
| Priority scoring | V1 foundation fully implemented; batch-relative minmax/percentile; full audit columns; chaos + POI multipliers |
| RCM impact | Dual attribution (`kpi_q_*` static share + exact resolution Δ) independent of priority |
| Column mapping | Auto-detect + optional profile + interactive guided mapping |
| Config | Single `config_default.json` (weights, chaos, POI, privacy, kpi_quantifiers) |
| Multi-file | Menu already multi-selects CSV/XLSX under `import\`; processes **per file** (no cross-file aggregation) |
| Summary | Vertical summary **CSV** only (`*_summary.csv`); Excel export is a separate formatted workbook |
| Output naming | Free `name_N` suffix on collision; no enforced `[WQ]_MM-DD-YYYY` convention |
| Schema | Contains `patient`, `service_date`, `out_ins_amt`, `code_category`, `reason_code_list`, `remittance_code`, `denial_count`, `wq_status`, etc. No dedicated “WQ name” field |
| Roadmap | V2 (operational intelligence) and V3 (advanced decision support) are design targets only |

Previous living `PLAN.md` files for efficiency releases, menu simplification, and dynamic mapping were removed after those items shipped. This document restarts the living-plan pattern for the next wave.

---

## Shared principles and hard constraints

These apply to every concept in this plan.

| Principle | Requirement |
|-----------|-------------|
| Toolkit independence | No Excel COM from Python product code; no priority/KPI math in PowerShell product code. Composition stays at the workflow layer (files + subprocess CLI). |
| Explainability | Intermediate audit columns and dual RCM attribution must remain; never collapse into a single opaque number. |
| Stdlib / offline | kpi-analytics remains Python 3.13 standard library only. No pip packages, no network clients in product paths. |
| Additive first | Prefer new optional flags, columns, sheets, or profiles over silent renames or breaking contract changes. |
| Schema ownership | Field definitions live in `wq_schema.json` / `.csv`. Renames or new required roles are coordinated with fixtures + docs. |
| Output safety | Never clobber existing destinations by default; continue unique-suffix policy. |
| Privacy | Existing PHI masking on score output stays configurable; new features must not re-introduce raw patient identifiers into tracked samples. |
| Certification | Any product code or gate change requires full `certification/Invoke-Certification.ps1` (Domain A + Domain B) before completion. |
| Documentation | Behavior change ⇒ canonical doc update in the **same change set** (CLI-GUIDE, SCORE-METHODOLOGY, README, ENTERPRISE-SECURITY as applicable). |
| Versioning | Package version bump + root CHANGELOG entry required for release-worthy behavior or contract changes. |

---

## Cluster 1 — KPI config optimization and saved profiles

**Status:** developing concept  
**Primary surface:** kpi-analytics  
**Risk to existing contracts:** low (tunable defaults or additive profile load/save)

### 1.1 Optimize KPI config for real-world use cases

**Intent**  
Retune default weights, chaos multipliers, claim-age target, and/or Point-of-Interest profiles so typical professional-billing denial/follow-up queues produce more useful ranking without changing V1 formulas.

**Open design points (still to be worked out)**
- Which real-world signals should drive the retune? (e.g., relative importance of high-dollar vs. appeal-deadline vs. repeat-denial)
- Whether to keep a single default or ship 2–3 named POI profiles (“Protect write-offs”, “Maximize cash”, “Suppress aging”)
- How to validate the new defaults (hand-calc fixtures, synthetic distributions, analyst review)
- Whether chaos detection thresholds themselves need adjustment

**Possible acceptance sketch (draft)**
- New or adjusted values documented in SCORE-METHODOLOGY with rationale.
- Golden fixtures either remain green or are deliberately refreshed with a methodology note.
- Default behavior change is called out in CHANGELOG under the shipping version.
- No change to metric keys or audit column names.

### 1.2 Save / load configurations as JSON, logically separated by WQ and preference

**Intent**  
Allow an operator to persist a full or partial scoring configuration (weights, POI, privacy, thresholds, field-role overrides) under a logical name (WQ identifier or preference set) so the same settings can be reapplied quickly on subsequent extracts.

**Open design points**
- Storage location (user-chosen folder vs. a conventional `configs\` or `profiles\` under the repo, still never under `output\`)
- Exact JSON schema for a “profile” (subset of `config_default.json` + optional mapping + metadata)
- How WQ identity is expressed (filename stem, explicit metadata field, operator-supplied label)
- CLI surface (`--config-profile`, `--save-profile`, etc.) and menu surface
- Interaction with existing `--mapping` profiles (merge, replace, or keep separate)
- Whether profiles are versioned or carry a `min_toolkit_version`

**Possible acceptance sketch (draft)**
- Load and save work from both CLI and interactive menu.
- Profiles never contain PHI or production extracts.
- Missing or incompatible profile fails clearly (no silent fallback to wrong weights).

---

## Cluster 2 — Multi-file ingest, aggregation, and output conventions

**Status:** developing concept  
**Primary surface:** excel-toolkit menu / workflow (with light kpi-analytics support if needed)  
**Risk to existing contracts:** medium (new aggregation paths; must preserve per-file score semantics)

### 2.1 Ingest multiple files and parse / total by WQ

**Intent**  
When the operator selects several CSV or XLSX files, produce combined totals (and optionally a combined scored view) keyed by Work Queue identity, in addition to (or instead of) purely per-file processing.

**Open design points**
- Source of WQ identity when the schema has no dedicated WQ-name field (filename convention? `wq_status`? operator label? new optional role?)
- Whether scoring remains strictly per-file (batch-relative norms) or whether a combined batch is ever scored together
- Where aggregation lives (post-score in excel-toolkit, new kpi-analytics `aggregate` verb, or both)
- What “totals” means (row counts, sum of `out_ins_amt`, sum of selected `kpi_q_*`, average priority, etc.)

### 2.2 Output naming convention `[WQ]_MM-DD-YYYY.xlsx`

**Intent**  
Generate or enforce a predictable workbook name that encodes the Work Queue and the processing date.

**Open design points**
- Exact date source (`as_of_date`, system date, operator override)
- How collisions and multi-WQ runs are handled while still respecting the unique-suffix safety rule
- Whether the same convention applies to intermediate CSVs or only to final Excel

### 2.3 Improve aggregation process; default export to `.xlsx` only

**Intent**  
Make the formatted Excel workbook the primary deliverable of the full pipeline. Keep CSV available for score-only or automation, but stop treating dual CSV+XLSX as the default happy path.

**Open design points**
- Menu wording and action labels
- Whether intermediate scored CSV is still written (and if so, under what path policy)
- Impact on existing automation that expects the current CSV paths

### 2.4 Multi-file preview: list names per WQ / file and maximum amount by key KPI

**Intent**  
After file discovery and before the operator chooses Full pipeline / Score only / Export only, show a compact preview: file or WQ name, row count, and the maximum value of a chosen key metric (default `out_ins_amt` or another configurable KPI interest).

**Open design points**
- Which metrics are offered as “key KPI interest”
- Whether the preview is optional or always shown for multi-select
- Performance on very large extracts (preview should not force a full score)

---

## Cluster 3 — Grouping, sorting, and denial analysis sheet

**Status:** developing concept  
**Primary surface:** both toolkits (post-score reporting preferred)  
**Risk to existing contracts:** higher — closest to V2 design territory

### 3.1 Group qualifier (break by filters: DOS or dollar amount by Patient name)

**Intent**  
Allow the operator to partition or highlight rows that pass simple group-level filters—for example, patients whose total outstanding balance exceeds a threshold, or whose service dates fall in a chosen window—while still preserving the underlying scored detail.

**Open design points**
- Exact filter language (threshold on sum of `out_ins_amt` per patient, min/max `service_date`, combination rules)
- Whether grouping is a score-time feature, a post-score CSV transform, or an Excel sheet/filter only
- Interaction with privacy masking (patient tokens vs. original names)
- Output shape (extra columns, separate grouped summary, or filtered workbook sheets)

### 3.2 Multiple ways of sorting data

**Intent**  
Beyond the default priority-score ranking, offer explicit sort keys (balance, claim age, dual-deadline urgency, denial count, etc.) on the scored output or the Excel export.

**Open design points**
- Stable secondary keys and deterministic ordering
- Whether the original input order is also preserved as an option
- CLI vs. menu vs. Excel-only presentation

### 3.3 Analysis sheet on the summary Excel workbook

**Intent**  
Add a second (or additional) worksheet to the summary Excel that identifies and summarizes common denial types / categories together with key metrics for each category (count, total outstanding, average priority, aging distribution, etc.).

**Open design points**
- Category source column(s): `code_category`, `reason_code_list`, `remittance_code`, or a configurable role
- Metrics to show per category
- Whether this stays pure reporting or begins to feed priority (the latter would start implementing V2 concepts and should be explicitly scoped)
- How the sheet relates to the existing vertical summary CSV

**V2 alignment note**  
`WQ_Priority_Matrix_Concept.md` already sketches “Denial Category Volume”, “Category Financial Exposure”, and related signals for Version 2. Any analysis sheet that remains reporting-only can ship under this plan. Any change that alters the priority score formula or introduces new weighted metrics should be re-scoped as formal V2 work instead of a parallel path.

---

## Recommended sequencing

| Order | Cluster / item | Rationale |
|-------|----------------|-----------|
| 1 | 1.1 Config optimization | Purely tunable; improves real-world usefulness of existing V1 with minimal contract risk |
| 2 | 1.2 Saved profiles | Additive; reuses existing config/mapping patterns; high operator value |
| 3 | 2.2 + 2.3 + 2.4 Naming, default-xlsx, multi-file preview | Workflow / UX improvements on top of the already-shipped multi-select menu |
| 4 | 2.1 Cross-file / by-WQ totals | Builds on the above; requires clear WQ-identity decision |
| 5 | 3.2 Multi-sort | Low-risk post-score or Excel-side feature |
| 6 | 3.1 Group qualifier | Needs careful filter definition and privacy review |
| 7 | 3.3 Denial analysis sheet | Highest design complexity; keep reporting-only until V2 is intentionally opened |

Each step should be designed in detail (acceptance criteria, CLI/menu mock, data-contract impact) before implementation begins. This document records the concepts; it is not yet a sprint backlog.

---

## Compliance, versioning, and change control

All work under this plan must follow `RULES.md`:

- Conventional Commits (`type(scope): …`) with scopes `kpi-analytics`, `excel-toolkit`, or omitted for root-wide files.
- AI-assisted commits include the required footer block (`Assisted-by` / `Compliance: RULES.md` / `Instructed-by`).
- Same change set: code + canonical docs + CHANGELOG entry (under the version that ships the change) + FILE-CATALOG if paths are added or removed.
- After any product code or gate change: full certification harness must pass (`OverallPass = true`); outputs remain untracked.
- Package version bumps (`kpi_modules.__version__` or `ExcelToolkitVersion`) only when the public contract or observable behavior changes; document the bump in CHANGELOG.
- Prefer feature branches (`feature/…`, `docs/…`) for non-trivial work.

When a concept moves from “developing” to “ready for implementation”, a short design note or updated section in this PLAN (or a focused follow-on PLAN) should freeze the open questions before code starts.

---

## Cross-cutting open questions

These affect more than one cluster and should be resolved early.

1. **WQ identity** — What is the canonical way to label a Work Queue when the current schema has no dedicated name field?
2. **Combined vs. per-file scoring** — Under what conditions (if any) may multiple files be scored as a single batch? (Affects batch-relative norms.)
3. **Profile storage convention** — Where do saved config / preference JSON files live, and are they ever committed to the repo?
4. **Analysis vs. V2 boundary** — Exact criteria that keep an analysis sheet in “reporting only” territory versus triggering formal V2 design.
5. **Default artifact** — Is the primary operator deliverable the Excel workbook, the scored CSV, or both with a clear preference order?
6. **Schema evolution** — Will any of these concepts require new optional roles in `wq_schema.json`, and if so, how are they introduced without breaking existing extracts?

---

## Out of scope / non-goals for this plan

- Implementing Priority Matrix V2 or V3 formulas (those remain design targets in `WQ_Priority_Matrix_Concept.md`).
- Adding pip packages or network access to kpi-analytics product code.
- Merging the two toolkits into a single process or language.
- Changing the dual RCM attribution model or removing audit columns.
- Committing real PHI, production extracts, or regenerable `output\` / certification artifacts.
- Permanent changes to PowerShell execution policy or force-killing Excel.
- Third-party compliance claims (HIPAA Safe Harbor, SOC 2, etc.).

---

## Document history

| Version | Notes |
|---------|--------|
| 0.1.0 | Initial living plan. Captures sorted enhancement concepts from operator discussion; all items marked developing; details still to be worked out. |
