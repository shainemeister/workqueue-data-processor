---
title: "Development Plan — Post-V1 Enhancement Concepts"
description: "Living product backlog: Cluster 1 complete; optional base retune; Clusters 2–3 developing. Control surface in root PLAN.md; live multi-phase on docs/WORKBOARD.md; execution freezes in docs/plan/."
version: "0.5.1"
status: current
audience:
  - developers
  - analysts
doc_type: other
related:
  - ../README.md
  - ../PLAN.md
  - ../kit/RULES.md
  - ../CHANGELOG.md
  - README.md
  - plan/README.md
  - WQ_Priority_Matrix_Concept.md
  - ../kpi-analytics/SCORE-METHODOLOGY.md
  - ../kpi-analytics/CLI-GUIDE.md
  - ../excel-toolkit/CLI-GUIDE.md
  - ../excel-toolkit/README.md
  - ../wq_schema/wq_schema.json
last_updated: "2026-08-12"
---

# Development Plan — Post-V1 Enhancement Concepts

Living **product enhancement backlog** after V1 priority matrix, dynamic mapping, guided menu, gap-safety, scoring profiles, quality audit, certification Phase 2, and menu scoring-profile picker.

**Document version:** 0.5.1  
**Status:** Cluster 1 **complete** (CLI + menu residual **1f** shipped). Residual optional: base-weight retune (**B1.1-retune**). Clusters **2–3** still developing (not implementation-ready).  

| Kit triple surface | Path |
|--------------------|------|
| Mission, stages, **Agent models** | Root [PLAN.md](../PLAN.md) |
| Live multi-phase (open / next / SHA) | [docs/WORKBOARD.md](./WORKBOARD.md) |
| **This product backlog** | `docs/PLAN.md` (this file) |
| Execution / design-freeze notes | [docs/plan/](./plan/) |
| AI workspace index | [docs/README.md](./README.md) |
| Maintenance law | [kit/RULES.md](../kit/RULES.md) |

**Related:** [README.md](../README.md) · [root PLAN.md](../PLAN.md) · [plan index](./plan/README.md) · [kit/RULES.md](../kit/RULES.md) · [CHANGELOG.md](../CHANGELOG.md) · [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) · [kpi-analytics/SCORE-METHODOLOGY.md](../kpi-analytics/SCORE-METHODOLOGY.md) · [excel-toolkit/README.md](../excel-toolkit/README.md)

---

## Summary

### Architecture constraints (unchanged)

- Two independent toolkits: **kpi-analytics** (Python 3.13 stdlib scoring) and **excel-toolkit** (PowerShell 5.1 + Excel COM).
- Shared data contract only (`wq_schema/` schema + sample rows).
- V1 priority formulas + dual RCM `kpi_q_*` attribution already shipped and must stay explainable.
- Design-only V2/V3 roadmap in [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) (denial volume/velocity, recovery probability, capacity).

### Shipped since PLAN 0.2.0

- Scoring **profiles** (`score --profile`, `profile-list` / `profile-show` / `profile-save`).
- Three **POI focus presets** (`protect_writeoffs`, `maximize_cash`, `suppress_aging`) under `kpi-analytics/profiles/`.
- Default path (no profile) unchanged vs 2.5.0 fixtures; full certification at ship.
- See [CHANGELOG.md](../CHANGELOG.md) **[1.9.0]** and [CLI-GUIDE — scoring profiles](../kpi-analytics/CLI-GUIDE.md#scoring-profiles-260).
- **excel-toolkit 1.9.0 / repo 1.13.0:** menu residual **1f** — Process my data scoring-profile picker + Advanced list/help (subprocess only).

### Active backlog

| Tier | Items | Execution plan |
|------|--------|----------------|
| **Pending (optional)** | Evidence-based base-weight retune (**B1.1-retune**) | [plan/b1.1-base-weight-retune.md](./plan/b1.1-base-weight-retune.md) |
| **Developing (needs freeze before code)** | **Cluster 2** multi-file / naming / default xlsx / preview / by-WQ totals | [plan/cluster-2-multi-file.md](./plan/cluster-2-multi-file.md) |
| **Developing (needs freeze before code)** | **Cluster 3** grouping / multi-sort / denial analysis sheet (reporting-only vs V2) | [plan/cluster-3-analysis.md](./plan/cluster-3-analysis.md) |

Do not start Cluster 2/3 product code until open questions are design-frozen (update the matching `docs/plan/` file and this backlog in the same change set).

---

## Contents

1. [Summary](#summary)
2. [Background and current baseline](#background-and-current-baseline)
3. [Shared principles and hard constraints](#shared-principles-and-hard-constraints)
4. [Cluster 1 — KPI config optimization and saved profiles](#cluster-1--kpi-config-optimization-and-saved-profiles) (**complete; optional retune only**)
5. [Cluster 2 — Multi-file ingest, aggregation, and output conventions](#cluster-2--multi-file-ingest-aggregation-and-output-conventions) (**developing**)
6. [Cluster 3 — Grouping, sorting, and denial analysis sheet](#cluster-3--grouping-sorting-and-denial-analysis-sheet) (**developing**)
7. [Recommended sequencing](#recommended-sequencing)
8. [Compliance, versioning, and change control](#compliance-versioning-and-change-control)
9. [Cross-cutting open questions](#cross-cutting-open-questions)
10. [Out of scope / non-goals for this plan](#out-of-scope--non-goals-for-this-plan)
11. [Document history](#document-history)

---

## Background and current baseline

| Area | Current state (as of repo **1.14.2** / kpi **2.7.0** / excel **1.9.0** / repo-kit **2.4.0**) |
|------|--------------------------------------------------------------------------------|
| Priority scoring | V1 foundation fully implemented; batch-relative minmax/percentile; full audit columns; chaos + POI multipliers (presets selectable) |
| RCM impact | Dual attribution (`kpi_q_*`) independent of priority; RCM golden in certification; `amount_field` / `adc_mode` honored |
| Column mapping | Auto-detect + mapping profile + interactive guided mapping (menu TTY-safe) |
| Rank quality signals | `MetricValueCoverage`, `RankCompleteness`, optional `--strict roles\|full`; menu partial-rank confirm |
| Privacy | Score-output masking; header aliases; default **4-digit** patient tokens |
| Config | `config_default.json` (weights, chaos, POI, privacy, kpi_quantifiers); CLI `--config` **or** `--profile` (mutually exclusive); `profile-list` / `show` / `save` |
| Profiles / POI | Shipped thin presets under `kpi-analytics/profiles/`; user `user_*.json` gitignored; focus defaults **not** outcome-optimized; **menu picker** (excel 1.9.0) |
| Multi-file | Menu multi-selects CSV/XLSX under `import\`; processes **per file** (no cross-file aggregation) |
| Summary | Vertical summary **CSV**; Excel export separate |
| Output naming | Free `name_N` suffix on collision (score/generate non-clobber unless `--force`) |
| Schema | No dedicated “WQ name” field (`wq_schema/`) |
| Layout | Product under toolkit folders; standards under `kit/` (repo-kit **2.3.1**); Agent Instruct under `kit/agents/`; AI docs workspace + maintainer docs under `docs/`; root `PLAN.md` owns Agent models |
| Gap-safety program | **Closed** (H1–H3, D1–D3, M1) |
| Certification | Schema 1.1 engine + required dynamic Security invariants (repo 1.11–1.12) |
| Roadmap | V2/V3 design targets only in `WQ_Priority_Matrix_Concept.md` |

Previous living `PLAN.md` files for efficiency releases, menu simplification, and dynamic mapping were removed after those items shipped.

---

## Shared principles and hard constraints

These apply to every concept in this plan.

| Principle | Requirement |
|-----------|-------------|
| Toolkit independence | No Excel COM from Python product code; no priority/KPI math in PowerShell product code. Composition stays at the workflow layer (files + subprocess CLI). |
| Explainability | Intermediate audit columns and dual RCM attribution must remain; never collapse into a single opaque number. |
| Stdlib / offline | kpi-analytics remains Python 3.13 standard library only. No pip packages, no network clients in product paths. |
| Additive first | Prefer new optional flags, columns, sheets, or profiles over silent renames or breaking contract changes. |
| Schema ownership | Field definitions live in `wq_schema/wq_schema.json` / `wq_schema/wq_schema.csv`. Renames or new required roles are coordinated with fixtures + docs. |
| Output safety | Never clobber existing destinations by default; continue unique-suffix policy. |
| Privacy | Existing PHI masking on score output stays configurable; new features must not re-introduce raw patient identifiers into tracked samples. Profiles must not embed claim rows. |
| Certification | Any product code or gate change requires full `certification/Invoke-Certification.ps1` (Domain A + Domain B) before completion. |
| Documentation | Behavior change ⇒ canonical doc update in the **same change set** (CLI-GUIDE, SCORE-METHODOLOGY, README, ENTERPRISE-SECURITY as applicable). |
| Versioning | Package version bump + root CHANGELOG entry required for release-worthy behavior or contract changes. PLAN-only docs commits need not bump package versions. |

---

## Cluster 1 — KPI config optimization and saved profiles

**Status:** **Complete** (CLI 2026-07-30, kpi-analytics **2.6.0** / repo **1.9.0**; menu residual **1f** 2026-08-09, excel-toolkit **1.9.0** / repo **1.13.0**). Optional retune only.  
**Primary surface:** kpi-analytics (CLI) + excel-toolkit menu composition  
**Risk to existing contracts:** low (menu is subprocess only)  
**Shipped package versions:** kpi-analytics **2.6.0+** (profiles); excel-toolkit **1.9.0** (menu pick)  
**Execution residual:** [plan/b1.1-base-weight-retune.md](./plan/b1.1-base-weight-retune.md)

### Shipped (as-built)

| Deliverable | Location / note |
|-------------|-----------------|
| Profile module | `kpi-analytics/kpi_modules/profiles.py` |
| POI presets | `kpi-analytics/profiles/poi_protect_writeoffs.json`, `poi_maximize_cash.json`, `poi_suppress_aging.json` (no `poi_default.json`; default = no `--profile`) |
| CLI | `score --profile`, `profile-list`, `profile-show`, `profile-save` |
| Menu **1f** | `excel-toolkit/Start-ExcelMenu.ps1` — Process my data profile pick; Advanced list/help |
| Docs | [KPI CLI-GUIDE](../kpi-analytics/CLI-GUIDE.md), [Excel README](../excel-toolkit/README.md), [SCORE-METHODOLOGY](../kpi-analytics/SCORE-METHODOLOGY.md), [CHANGELOG 1.9.0](../CHANGELOG.md) / [1.13.0](../CHANGELOG.md) |
| Acceptance (CLI + 1f) | See checkboxes below — **done** |

> **Note:** Design freezes in §1.1–1.2 describe the **shipped** CLI contract. Treat them as as-built reference, not an open implementation TODO. Day-to-day usage: [CLI-GUIDE — scoring profiles](../kpi-analytics/CLI-GUIDE.md#scoring-profiles-260) · [Excel menu](../excel-toolkit/README.md).

### Outstanding / pending (Cluster 1 residual)

| ID | Item | Status | Notes |
|----|------|--------|-------|
| **1f** | excel-toolkit menu scoring-profile picker | **Shipped** (excel **1.9.0** / repo **1.13.0**) | Subprocess `score --profile` / `profile-list` only |
| **B1.1-retune** | Analyst-backed base weight / chaos retune | **Pending (optional)** | Requires documented rationale, fixture note if needed, CHANGELOG under Changed; separate from focus presets |

### 1.1 Optimize KPI config for real-world use cases

**Intent**  
Improve ranking usefulness for typical professional-billing denial/follow-up queues **without changing V1 formulas** (same metric keys, audit columns, renorm rules).

#### Frozen decisions (B1.1) — shipped contract

| Decision | Freeze / as-built |
|----------|-------------------|
| Default weights / chaos in `config_default.json` | **Kept** as POI name `default` until an optional analyst-backed retune ships later |
| Named focus presets | **Shipped:** three additive POI presets (multipliers only; base weights unchanged) |
| Chaos thresholds | **No change** in Cluster 1 CLI ship |
| Metric keys / directions | **Unchanged** |
| How presets apply | `point_of_interest.multipliers` × base weights × chaos multipliers → renorm over active metrics |
| Validation | Handcalc + RCM fixtures green with default; each preset loads and scores synthetic without error; no hard-coded patient order goldens |
| Documentation | SCORE-METHODOLOGY preset table + CLI-GUIDE selection |

#### Named POI presets (as shipped)

Multipliers apply on top of existing base weights. Values are **product defaults for focus**, not a claim of optimized cash recovery. Operators may override via full config or saved profile.

| Preset id | Display name | Intent | Multiplier highlights (others = 1.0) |
|-----------|--------------|--------|--------------------------------------|
| `default` | Balanced (package default) | No `--profile` | All 1.0 |
| `protect_writeoffs` | Protect write-offs | Emphasize aging past target, dual deadlines, appeal urgency | `claim_age_days` 1.2, `claim_age_disparity` 1.4, `appeal_urgency` 1.5, `dual_deadline_urgency` 1.5, `balance_weighted_days_outstanding` 1.2 |
| `maximize_cash` | Maximize cash | Emphasize dollars and BWDO | `out_ins_amt` 1.5, `billed_amount` 1.2, `balance_weighted_days_outstanding` 1.4, `denial_count` 1.1 |
| `suppress_aging` | Suppress aging | Emphasize stalled / high denial / short deadline over pure age | `days_since_last_worked` 1.4, `denial_count` 1.3, `appeal_urgency` 1.3, `dual_deadline_urgency` 1.3, `claim_age_days` 0.85, `claim_age_disparity` 0.85 |

**Optional later retune of base weights (B1.1-retune):** requires (a) documented rationale from real or synthetic distributions, (b) deliberate fixture refresh note if expected values change, (c) CHANGELOG under Changed. Not required for residual menu work.

#### Implementation shape (B1.1) — as shipped

| Artifact | Role |
|----------|------|
| *(omit `poi_default.json`)* | Package default already `default` when no profile |
| `kpi-analytics/profiles/poi_protect_writeoffs.json` | Thin profile; `point_of_interest` set |
| `kpi-analytics/profiles/poi_maximize_cash.json` | Same |
| `kpi-analytics/profiles/poi_suppress_aging.json` | Same |
| CLI | `score --profile protect_writeoffs` resolves `profiles\<name>.json` or `profiles\poi_<name>.json` |

---

### 1.2 Save / load configurations as JSON (profiles)

**Intent**  
Persist a scoring configuration (and optional column mapping) under a logical name so the same settings reapply on subsequent extracts.

#### Frozen decisions (B1.2) — shipped contract

| Decision | Freeze / as-built |
|----------|-------------------|
| Storage root | **`kpi-analytics\profiles\`** for shipped presets; user-writable same folder |
| Never store under | `output\`, `import\` (extracts), gitignored cert/diagnostics folders |
| Git policy | **Shipped presets** tracked. **User-created:** `kpi-analytics/profiles/user_*.json` gitignored; no claim rows |
| Profile vs mapping | Profile may embed `mapping` or `mapping_path`. Explicit `--mapping` overrides profile mapping; `--config` and `--profile` are **mutually exclusive** |
| Full vs partial config | Deep-merge onto `config_default` then `validate_config` |
| Metadata | Required: `profile_schema_version` (`"1.0"`), `name`, non-empty `description`. Optional: `min_toolkit_version` (fail if package older), `wq_label`, `created_at` |
| WQ identity in profile | Operator-supplied `wq_label` only (no schema field) |
| PHI | Deny-list: `rows`, `data`, `claims`, `records` |
| Failure mode | Missing / invalid profile → fail clearly; no silent fallback to default |
| Menu | **Shipped (1f):** Process my data pick + Advanced list/help; subprocess only |

#### Profile JSON shape (as-built)

```json
{
  "profile_schema_version": "1.0",
  "name": "protect_writeoffs",
  "description": "Emphasize aging and deadline risk",
  "min_toolkit_version": "2.6.0",
  "wq_label": optional,
  "config": {
    "point_of_interest": { "name": "protect_writeoffs", "multipliers": { } },
    "weights": { },
    "chaos": { },
    "claim_age_target": null,
    "privacy": { },
    "fields": { },
    "as_of_date": null
  },
  "mapping": {
    "version": "1.0",
    "roles": { "service_date": "DOS", "out_ins_amt": "Balance" }
  },
  "mapping_path": null
}
```

- `config`: optional; deep-merged onto package default. Omit or `{}` means package default.  
- `mapping` / `mapping_path`: optional; explicit CLI `--mapping` wins.  
- Unknown top-level keys: **reject** (strict).

#### CLI surface (as-built)

| Command / flag | Behavior |
|----------------|----------|
| `score --profile <name-or-path>` | Resolve name to `profiles\<name>.json` or `profiles\poi_<name>.json`; or path if `\` / `.json` |
| `score --config` + `--profile` | **Error** (mutually exclusive) |
| `profile-list` | List JSON under `profiles\` (metadata; no PHI) |
| `profile-save --name <slug> …` | Write `profiles\<slug>.json`; refuse overwrite without `--force` |
| `profile-show <name-or-path>` | Metadata + effective weight summary |

Exit codes: 0 success, 1 validation, 2 runtime. Profile list/show/save are **not** diagnostics-gated.

#### Menu surface (1f — shipped)

| Action | Behavior |
|--------|----------|
| Process my data → Full pipeline / Score only | Optional “Scoring profile: [1 default] [list…] [P path]” once per batch |
| Advanced | List profiles / CLI help (`profile-list`; no score) |

Menu calls the same `kpi-analytics.cmd score --profile …` (no scoring math in PowerShell).

#### Acceptance criteria

**B1.1 / presets (CLI) — done**

- [x] Three named POI presets load via `--profile` and score synthetic data successfully  
- [x] Default (no `--profile`) unchanged vs 2.5.0 behavior on handcalc + RCM fixtures  
- [x] SCORE-METHODOLOGY documents each preset intent and multipliers  
- [x] CHANGELOG notes additive presets  

**B1.2 / profiles (CLI) — done**

- [x] `profile-list`, `profile-save`, `profile-show`, `score --profile` work as specified  
- [x] Invalid profile fails with clear message; no silent default  
- [x] `--config` and `--profile` mutually exclusive  
- [x] Explicit `--mapping` overrides profile mapping  
- [x] No claim rows allowed in profile JSON  
- [x] CLI-GUIDE + FILE-CATALOG + version bump; full certification at ship  

**1f menu — done**

- [x] **1f:** Menu offers profile pick and passes `--profile` into score subprocess (all score invokes in the batch)  
- [x] Advanced list/help without scoring  
- [x] excel-toolkit **1.9.0** + CHANGELOG **1.13.0** + docs  

**Still optional**

- [ ] **B1.1-retune (optional):** Only when evidence-backed; fixtures + CHANGELOG if weights change  

**Non-goals for Cluster 1**

- Changing V1 formulas or metric keys  
- Cross-file aggregation or WQ schema field  
- Cloud sync of profiles  
- Encrypting profiles  

#### Implementation order (within Cluster 1)

| Step | Work | Status |
|------|------|--------|
| 1 | Profile load/merge helper + CLI `--profile` + schema validation | **Done** |
| 2 | Shipped POI preset files under `kpi-analytics/profiles\` | **Done** |
| 3 | `profile-list` / `profile-save` / `profile-show` | **Done** |
| 4 | Docs + fixtures smoke + cert | **Done** |
| 5 | Menu profile picker (**1f**) | **Done** |

---

## Cluster 2 — Multi-file ingest, aggregation, and output conventions

**Status:** developing concept  
**Execution freeze checklist:** [plan/cluster-2-multi-file.md](./plan/cluster-2-multi-file.md)  
**Primary surface:** excel-toolkit menu / workflow (with light kpi-analytics support if needed)  
**Risk to existing contracts:** medium (new aggregation paths; must preserve per-file score semantics)

| Gate | State |
|------|--------|
| Implementation-ready? | **No** — freeze open questions first |
| Role in backlog | Primary multi-file / delivery UX track after Cluster 1 residual |

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
**Execution freeze checklist:** [plan/cluster-3-analysis.md](./plan/cluster-3-analysis.md)  
**Research (options, not a freeze):** [research/2026-08-12-worklist-grouping-and-industry-metrics.md](./research/2026-08-12-worklist-grouping-and-industry-metrics.md)  
**Primary surface:** both toolkits (post-score reporting preferred)  
**Risk to existing contracts:** higher — closest to V2 design territory

| Gate | State |
|------|--------|
| Implementation-ready? | **No** — freeze open questions first; keep reporting-only vs V2 boundary explicit |
| Role in backlog | Post-score analysis / presentation; higher risk of V2 overlap |

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

| Order | Item | Status | Rationale |
|-------|------|--------|-----------|
| 1 | **1f** Menu profile picker | **Shipped** | Low risk; uses shipped CLI |
| 2 | **B1.1-retune** Base weights | **Pending** (optional) | Data / analyst gated |
| 3 | Cluster **2.2–2.4** Naming, default xlsx, multi-file preview | Developing | Freeze before code |
| 4 | Cluster **2.1** Cross-file / by-WQ totals | Developing | Needs WQ-identity freeze |
| 5 | Cluster **3.2** Multi-sort | Developing | Low-risk post-score |
| 6 | Cluster **3.1** Group qualifier | Developing | Privacy care |
| 7 | Cluster **3.3** Denial analysis sheet | Developing | Reporting-only until V2 |

**Next recommended product slice**

- Prefer a **Cluster 2 design freeze** if multi-file delivery is the priority.  
- Prefer **B1.1-retune** only with analyst evidence.  
- Do **not** start Cluster 2/3 code without freezes.

---

## Compliance, versioning, and change control

All work under this plan must follow [kit/RULES.md](../kit/RULES.md) and `kit/rules/`:

- **Triple PLAN surface:** mission / stages / **Agent models** only in root [PLAN.md](../PLAN.md); live multi-phase on [docs/WORKBOARD.md](./WORKBOARD.md); long freezes and option matrices in [docs/plan/](./plan/); this file stays the product Cluster backlog ([ai-docs-workspace](../kit/rules/ai-docs-workspace.md)).
- **Agent Instruct:** when implementing, match one primary pack and follow [OPS](../kit/agents/OPS.md) O3; packs are views—L4 contracts win.
- **Operator enforcement:** Progress Tracker on work-advancing replies; promote durable findings from `docs/` to L4 in the same change set.
- Conventional Commits (`type(scope): …`) with scopes `kpi-analytics`, `excel-toolkit`, `docs`, `plan`, or omitted for root-wide files.
- AI-assisted commits: `Assisted-by` / `Compliance: RULES.md` / `Instructed-by` (dynamic `Instructed-by` cascade in [versioning-and-git](../kit/rules/versioning-and-git.md)); no `Directed-by` trailer.
- Same change set: code + canonical docs + CHANGELOG entry (under the version that ships the change) + FILE-CATALOG if paths are added or removed.
- After any product code or gate change: full certification harness must pass (`OverallPass = true`); outputs remain untracked.
- Package version bumps (`kpi_modules.__version__` or `ExcelToolkitVersion`) only when the public contract or observable behavior changes; document the bump in CHANGELOG.
- Prefer feature branches (`feature/…`, `docs/…`) for non-trivial work.
- PLAN-only documentation updates do not require a package version bump.

When a concept moves from “developing” to “ready for implementation”, freeze open questions in the matching [docs/plan/](./plan/) file **and** update this backlog status in the same change set—before product code.

---

## Cross-cutting open questions

| # | Question | Status |
|---|----------|--------|
| 1 | **WQ identity** for multi-file / naming | **Open** (Cluster 2). Profiles may carry optional free-text `wq_label` only |
| 2 | **Combined vs. per-file scoring** | **Open** (Cluster 2). Default assumption: per-file only |
| 3 | **Profile storage** | **Shipped** — `kpi-analytics\profiles\`; shipped presets tracked; user `user_*.json` gitignored; no PHI |
| 4 | **Analysis vs. V2 boundary** | **Open** (Cluster 3): reporting-only until V2 opened |
| 5 | **Default artifact** CSV vs Excel | **Open** (Cluster 2.3) |
| 6 | **Schema evolution** for WQ name | **Open** (Cluster 2) |
| 7 | **Menu profile UX (1f)** | **Shipped** (excel **1.9.0** / repo **1.13.0**) |

---

## Out of scope / non-goals for this plan

- Implementing Priority Matrix V2 or V3 formulas (those remain design targets in `WQ_Priority_Matrix_Concept.md`).
- Adding pip packages or network access to kpi-analytics product code.
- Merging the two toolkits into a single process or language.
- Changing the dual RCM attribution model or removing audit columns.
- Committing real PHI, production extracts, or regenerable `output\` / certification artifacts.
- Permanent changes to PowerShell execution policy or force-killing Excel.
- Third-party compliance claims (HIPAA Safe Harbor, SOC 2, etc.).
- Re-opening shipped Cluster 1 CLI contracts without a versioned change set.

---

## Document history

| Version | Notes |
|---------|--------|
| 0.1.0 | Initial living plan. Captures sorted enhancement concepts from operator discussion; all items marked developing; details still to be worked out. |
| 0.2.0 | Baseline updated to kpi 2.5.0 / excel 1.8.0 after gap-safety close. **Cluster 1 design-frozen** (POI presets + profile schema/CLI). |
| 0.3.0 | Baseline → repo **1.9.0** / kpi **2.6.0** / excel **1.8.0**. Cluster 1 CLI + POI presets marked **shipped**. Residual: menu **1f**, optional base retune. Sequencing reframed; Clusters 2–3 remain developing (not implementation-ready). |
| 0.4.0 | Baseline → repo **1.13.0** / kpi **2.7.0** / excel **1.9.0**. Menu residual **1f** shipped. Cluster 1 complete except optional B1.1-retune. Clusters 2–3 still developing. |
| 0.5.1 | Kit triple surface (repo-kit **2.4.0**): `docs/WORKBOARD.md` for live multi-phase; Clusters 2–3 still developing |
| 0.5.0 | Kit dual-surface compliance (repo-kit **2.3.1**): links to root PLAN stages/Agent models; execution freezes under `docs/plan/`; compliance section for OPS/Operator/Instructed-by; baseline notes repo **1.14.0**. |
