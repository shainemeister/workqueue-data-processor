---
title: "Development Plan — Post-V1 Enhancement Concepts"
description: "Living plan for post-V1 enhancements. Cluster 1 (config/profiles) is design-frozen; Clusters 2–3 remain developing concepts."
version: "0.2.0"
status: current
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
last_updated: "2026-07-30"
---

# Development Plan — Post-V1 Enhancement Concepts

Living plan for product improvements after the V1 priority matrix, dynamic mapping, guided menu, and the **gap-safety program** (excel-toolkit 1.8.0 / kpi-analytics 2.5.0: guided mapping, serial dates, coverage, rank completeness, privacy aliases).

**Document version:** 0.2.0  
**Status:** Cluster 1 **design-frozen** (ready for implementation); Clusters 2–3 still developing  
**Related:** [README.md](./README.md) · [RULES.md](./RULES.md) · [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) · [kpi-analytics/SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md)

---

## Summary

This plan organizes a backlog of enhancement ideas into three non-overlapping clusters that respect the current architecture:

- Two independent toolkits (kpi-analytics = Python 3.13 stdlib scoring; excel-toolkit = PowerShell 5.1 + Excel COM).
- Shared data contract only (`wq_schema.*` + sample rows).
- V1 priority formulas + dual RCM `kpi_q_*` attribution already shipped and must stay explainable.
- Design-only V2/V3 roadmap in `WQ_Priority_Matrix_Concept.md` (denial volume/velocity, recovery probability, capacity).

The clusters are ordered so that low-risk config/profile work can ship first, multi-file workflow improvements second, and higher-complexity grouping/analysis last (with explicit watch for V2 overlap). **Cluster 1 open questions are frozen below** so implementation may begin. Clusters 2–3 still require freezes before code.

---

## Contents

1. [Summary](#summary)
2. [Background and current baseline](#background-and-current-baseline)
3. [Shared principles and hard constraints](#shared-principles-and-hard-constraints)
4. [Cluster 1 — KPI config optimization and saved profiles](#cluster-1--kpi-config-optimization-and-saved-profiles) (**design-frozen**)
5. [Cluster 2 — Multi-file ingest, aggregation, and output conventions](#cluster-2--multi-file-ingest-aggregation-and-output-conventions)
6. [Cluster 3 — Grouping, sorting, and denial analysis sheet](#cluster-3--grouping-sorting-and-denial-analysis-sheet)
7. [Recommended sequencing](#recommended-sequencing)
8. [Compliance, versioning, and change control](#compliance-versioning-and-change-control)
9. [Cross-cutting open questions](#cross-cutting-open-questions)
10. [Out of scope / non-goals for this plan](#out-of-scope--non-goals-for-this-plan)
11. [Document history](#document-history)

---

## Background and current baseline

| Area | Current state (as of repo **1.8.1** / kpi **2.5.0** / excel **1.8.0**) |
|------|-----------------------------------------------------------|
| Priority scoring | V1 foundation fully implemented; batch-relative minmax/percentile; full audit columns; chaos + POI multipliers |
| RCM impact | Dual attribution (`kpi_q_*`) independent of priority; RCM golden in certification |
| Column mapping | Auto-detect + mapping profile + interactive guided mapping (menu TTY-safe) |
| Rank quality signals | `MetricValueCoverage`, `RankCompleteness`, optional `--strict roles\|full`; menu partial-rank confirm |
| Privacy | Score-output masking; header aliases; default **4-digit** patient tokens |
| Config | Single `config_default.json` (weights, chaos, POI, privacy, kpi_quantifiers); CLI `--config` only |
| Multi-file | Menu multi-selects CSV/XLSX under `import\`; processes **per file** (no cross-file aggregation) |
| Summary | Vertical summary **CSV**; Excel export separate |
| Output naming | Free `name_N` suffix on collision |
| Schema | No dedicated “WQ name” field |
| Gap-safety program | **Closed** (H1–H3, D1–D3, M1) |
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
| Schema ownership | Field definitions live in `wq_schema.json` / `.csv`. Renames or new required roles are coordinated with fixtures + docs. |
| Output safety | Never clobber existing destinations by default; continue unique-suffix policy. |
| Privacy | Existing PHI masking on score output stays configurable; new features must not re-introduce raw patient identifiers into tracked samples. |
| Certification | Any product code or gate change requires full `certification/Invoke-Certification.ps1` (Domain A + Domain B) before completion. |
| Documentation | Behavior change ⇒ canonical doc update in the **same change set** (CLI-GUIDE, SCORE-METHODOLOGY, README, ENTERPRISE-SECURITY as applicable). |
| Versioning | Package version bump + root CHANGELOG entry required for release-worthy behavior or contract changes. |

---

## Cluster 1 — KPI config optimization and saved profiles

**Status:** **design-frozen** (2026-07-30) — ready for implementation  
**Primary surface:** kpi-analytics (menu composition optional in same or follow-on release)  
**Risk to existing contracts:** low (additive POI presets + profile load/save; default weights unchanged until data-backed retune)  
**Target package version (indicative):** kpi-analytics **2.6.0** when implemented  

### 1.1 Optimize KPI config for real-world use cases

**Intent**  
Improve ranking usefulness for typical professional-billing denial/follow-up queues **without changing V1 formulas** (same metric keys, audit columns, renorm rules).

#### Frozen decisions (B1.1)

| Decision | Freeze |
|----------|--------|
| Default weights / chaos in `config_default.json` | **Keep current values** as POI name `default` until an analyst-backed retune ships in a later change set |
| Named focus presets | Ship **three additive POI presets** (multipliers only; base weights unchanged) |
| Chaos thresholds | **No change** in first implementation of Cluster 1 |
| Metric keys / directions | **Unchanged** |
| How presets apply | Same path as today: `point_of_interest.multipliers` × base weights × chaos multipliers → renorm over active metrics |
| Validation | Handcalc + RCM fixtures must stay green with default profile; each preset must load and score synthetic without error; document expected *directional* ranking shift (not hard-coded patient order) |
| Documentation | SCORE-METHODOLOGY table of presets + rationale; CLI-GUIDE how to select |

#### Named POI presets (initial multipliers)

Multipliers apply on top of existing base weights. Values are **product defaults for focus**, not a claim of optimized cash recovery. Operators may override via full config or saved profile.

| Preset id | Display name | Intent | Multiplier highlights (others = 1.0) |
|-----------|--------------|--------|--------------------------------------|
| `default` | Balanced (package default) | Current behavior | All 1.0 |
| `protect_writeoffs` | Protect write-offs | Emphasize aging past target, dual deadlines, appeal urgency | `claim_age_days` 1.2, `claim_age_disparity` 1.4, `appeal_urgency` 1.5, `dual_deadline_urgency` 1.5, `balance_weighted_days_outstanding` 1.2 |
| `maximize_cash` | Maximize cash | Emphasize dollars and BWDO | `out_ins_amt` 1.5, `billed_amount` 1.2, `balance_weighted_days_outstanding` 1.4, `denial_count` 1.1 |
| `suppress_aging` | Suppress aging | Emphasize recently stalled / high denial / short deadline work over pure age | `days_since_last_worked` 1.4, `denial_count` 1.3, `appeal_urgency` 1.3, `dual_deadline_urgency` 1.3, `claim_age_days` 0.85, `claim_age_disparity` 0.85 |

**Later retune of base weights** (optional second slice of B1.1): requires (a) documented rationale from real or synthetic distributions, (b) deliberate fixture refresh note, (c) CHANGELOG under Changed. Not blocking first Cluster 1 ship.

#### Implementation shape (B1.1)

| Artifact | Role |
|----------|------|
| `kpi-analytics/profiles/poi_default.json` | Optional thin file or omit (package default already `default`) |
| `kpi-analytics/profiles/poi_protect_writeoffs.json` | Full or partial config with `point_of_interest` set |
| `kpi-analytics/profiles/poi_maximize_cash.json` | Same |
| `kpi-analytics/profiles/poi_suppress_aging.json` | Same |
| CLI | Prefer unified profile load (see 1.2): `score --profile protect_writeoffs` resolves shipped POI files and user profiles |

---

### 1.2 Save / load configurations as JSON (profiles)

**Intent**  
Persist a scoring configuration (and optional column mapping) under a logical name so the same settings reapply on subsequent extracts.

#### Frozen decisions (B1.2)

| Decision | Freeze |
|----------|--------|
| Storage root | Convention: **`profiles\`** under **kpi-analytics toolkit root** (`kpi-analytics\profiles\`) for shipped presets; user-writable same folder or path via flag |
| Never store under | `output\`, `import\` (extracts), gitignored cert/diagnostics folders |
| Git policy | **Shipped presets** (POI files) may be tracked. **User-created** profiles: allowed locally; prefer `.gitignore` pattern `kpi-analytics/profiles/user_*.json` or document “do not commit PHI/config with secrets” — profiles must not embed claim rows |
| Profile vs mapping | **Separate concerns, one load path:** profile JSON may *reference* a mapping file path or embed a `mapping` object (role→header). Existing `--mapping` remains; if both supplied, **CLI order wins:** explicit `--mapping` overrides profile mapping; explicit `--config` overrides profile config body |
| Full vs partial config | Profile is a **JSON object** that is deep-merged onto `config_default` then validated via existing `validate_config` / `load_config` rules. Partial profiles only need keys they override |
| Metadata | Required: `profile_schema_version` (start `"1.0"`), `name` (slug), `description` (string). Optional: `min_toolkit_version` (semver string; warn or fail if package older), `wq_label` (operator free text — **not** PHI), `created_at` (ISO date) |
| WQ identity in profile | **Operator-supplied `wq_label` only** for Cluster 1 (no schema field). Filename stem may be suggested in menu later; not required for CLI |
| PHI | Profiles must not contain patient rows, account lists, or raw extracts. Validation: reject keys `rows`, `data`, or arrays of claim objects if introduced by mistake (simple deny-list) |
| Failure mode | Missing file / invalid JSON / validate_config error → **fail clearly**, no silent fallback to default |
| Menu | **Phase 1 CLI-only** is acceptable for first ship; menu “pick profile” can follow in excel-toolkit patch. If menu in same release: Advanced or Process-my-data optional profile list from `profiles\*.json` |

#### Profile JSON shape (frozen)

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

- `config`: optional object; deep-merged onto package default. Omit or `{}` means package default config.  
- `mapping`: optional inline role map (same semantics as existing mapping profile roles).  
- `mapping_path`: optional path string relative to profile file or absolute; ignored if `mapping` object present.  
- Unknown top-level keys: **reject** (strict) to avoid silent misconfig.

#### CLI surface (frozen)

| Command / flag | Behavior |
|----------------|----------|
| `score --profile <name-or-path>` | Resolve `name` to `profiles\<name>.json` or `profiles\poi_<name>.json` under toolkit root; or use path if it contains `\` / ends with `.json` |
| `score --config` + `--profile` | **Error** unless documented merge: freeze = **mutually exclusive** with full `--config` (pick one). `--profile` supplies config merge; optional `--mapping` still overrides profile mapping |
| `profile-list` (new subcommand) | List JSON files in `profiles\` with `name` + `description` from metadata (no PHI) |
| `profile-save --name <slug> [--from-config path] [--from-mapping path] [--description …]` | Write `profiles\<slug>.json` merging current default + optional sources; refuse overwrite without `--force` |
| `profile-show <name-or-path>` | Print resolved metadata + effective key summary (not full PHI) as JSON |

Exit codes: align with existing CLI (0 success, 1 validation, 2 runtime).

#### Menu surface (optional same release / follow-on)

| Action | Behavior |
|--------|----------|
| Process my data → after file select | Optional “Scoring profile: [1 default] [2 list…]” |
| Advanced | “List / export profile path help” |

Menu must call the same `kpi-analytics.cmd score --profile …` (no scoring math in PowerShell).

#### Acceptance criteria (Cluster 1 done)

**B1.1 / presets**

- [ ] Three named POI presets load via `--profile` and score synthetic data successfully  
- [ ] Default (no `--profile`) unchanged vs 2.5.0 behavior on handcalc + RCM fixtures  
- [ ] SCORE-METHODOLOGY documents each preset intent and multipliers  
- [ ] CHANGELOG notes additive presets  

**B1.2 / profiles**

- [ ] `profile-list`, `profile-save`, `profile-show`, `score --profile` work as specified  
- [ ] Invalid profile fails with clear message; no silent default  
- [ ] `--config` and `--profile` mutually exclusive  
- [ ] Explicit `--mapping` overrides profile mapping  
- [ ] No claim rows allowed in profile JSON  
- [ ] CLI-GUIDE + FILE-CATALOG + version bump; full certification  

**Non-goals for Cluster 1**

- Changing V1 formulas or metric keys  
- Cross-file aggregation or WQ schema field  
- Cloud sync of profiles  
- Encrypting profiles  

#### Implementation order (within Cluster 1)

| Step | Work |
|------|------|
| 1 | Profile load/merge helper + CLI `--profile` + schema validation |
| 2 | Shipped POI preset files under `kpi-analytics/profiles\` |
| 3 | `profile-list` / `profile-save` / `profile-show` |
| 4 | Docs + fixtures smoke + cert |
| 5 | Optional: menu profile picker |

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

| Order | Cluster / item | Status | Rationale |
|-------|----------------|--------|-----------|
| 1 | **1.1 + 1.2 Config presets + profiles** | **Design-frozen — implement next** | Additive; high operator value; low formula risk |
| 2 | 2.2 + 2.3 + 2.4 Naming, default-xlsx, multi-file preview | Developing | UX on multi-select menu |
| 3 | 2.1 Cross-file / by-WQ totals | Developing | Needs WQ-identity freeze |
| 4 | 3.2 Multi-sort | Developing | Low-risk post-score |
| 5 | 3.1 Group qualifier | Developing | Privacy care |
| 6 | 3.3 Denial analysis sheet | Developing | Reporting-only until V2 |

**Next implementation slice:** Cluster 1 (presets + profile CLI) per frozen acceptance above.

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

| # | Question | Status |
|---|----------|--------|
| 1 | **WQ identity** for multi-file / naming | **Open** (Cluster 2). Cluster 1 uses optional free-text `wq_label` on profiles only |
| 2 | **Combined vs. per-file scoring** | **Open** (Cluster 2). Default assumption: per-file only |
| 3 | **Profile storage** | **Frozen in Cluster 1:** `kpi-analytics\profiles\`; shipped presets tracked; no PHI |
| 4 | **Analysis vs. V2 boundary** | **Open** (Cluster 3): reporting-only until V2 opened |
| 5 | **Default artifact** CSV vs Excel | **Open** (Cluster 2.3) |
| 6 | **Schema evolution** for WQ name | **Open** (Cluster 2); not required for Cluster 1 |

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
| 0.2.0 | Baseline updated to kpi 2.5.0 / excel 1.8.0 after gap-safety close. **Cluster 1 design-frozen** (POI presets + profile schema/CLI). |
