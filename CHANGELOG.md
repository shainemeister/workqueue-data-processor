# Changelog

All notable changes to **workqueue-data-processor** are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/).  
**Structure:** `## workqueue-data-processor` → dated `### [X.Y.Z] - YYYY-MM-DD` → `#### Added` / `#### Changed` / …  
Dates are ISO 8601. There is no Unreleased section—record each change under the version section that ships it.

**Package versions** (`kpi_modules.__version__`, `ExcelToolkitVersion`) are independent of repository changelog versions unless a release intentionally aligns them.  
**Standards kit version** lives only in [RULES.md — Kit baseline](./RULES.md#kit-baseline) (not as kit release history here). Upstream: https://github.com/shainemeister/repo-kit

---

## workqueue-data-processor

### [1.3.1] - 2026-07-25

#### Removed

- Root `PLAN.md` (living development plan for R1–R3). All three efficiency releases shipped; delivery history remains in this CHANGELOG and git history. FILE-CATALOG updated.

### [1.3.0] - 2026-07-25

#### Changed

- **excel-toolkit 1.5.0:** simplify interactive `Start-ExcelMenu.ps1` main menu
  - **1** Run full pipeline (Score CSV → Excel)
  - **2** Score only (scored + summary CSV; no Excel COM)
  - **3** Export CSV to Excel
  - **4** Advanced tools… (schema-header export, import, folders, env, schema, diagnostics)
  - **0** Exit
- Root README and excel-toolkit README / FILE-CATALOG / PLAN updated for the new menu shape
- Automation CLIs (`excel-toolkit.cmd`, `kpi-analytics.cmd`) unchanged

### [1.2.0] - 2026-07-25

#### Added

- **kpi-analytics 2.0.0:** High-priority AR follow-up metrics with full audit columns
  - `balance_weighted_days_outstanding` — `(balance / billed) × claim_age_days`; queue aggregate in chaos/summary stats
  - `denial_count` — repeat-denial signal
  - `days_since_last_worked` — staleness from `last_worked_date`
  - `dual_deadline_urgency` — min of appeal and replacement days remaining (or whichever is present)
- New default field roles: `last_worked_date`, `denial_count`, `days_until_replacement_deadline`

#### Changed

- **Breaking (kpi-analytics 2.0.0):** priority metric keys and audit columns
  - `ar_days` → **`claim_age_days`** (`v1_raw_claim_age_days`, etc.)
  - `ar_disparity` → **`claim_age_disparity`**
  - Config target: `claim_age_target` (legacy `ar_day_target` still accepted)
  - Chaos stats/reasons: `mean_claim_age_days`, `share_claim_age_ge_*` (legacy config keys accepted)
  - Default weight table redistributed across ten metrics (sum 1.0)
- Golden fixtures and SCORE-METHODOLOGY updated for the 2.0 contract
- PLAN.md marks R2 metric contract as shipped

#### Migration

- Update automation that reads `v1_raw_ar_days` / `v1_contrib_ar_days` (and disparity) to the new column names
- Refresh custom weight JSON to include all ten `METRIC_KEYS` (loader migrates old `ar_days` / `ar_disparity` keys when present)
- Portfolio RCM **Days in AR** (`kpi_q_*`) is unchanged in meaning; only claim-level age naming moved

### [1.1.0] - 2026-07-25

#### Added

- **kpi-analytics 1.9.0:** dynamic column role mapping for `score`
  - New `kpi_modules.column_map`: role catalog, header aliases (case/space tolerant), mapping profile JSON load/save
  - CLI `score --mapping PATH` to bind semantic roles to extract column names
  - Auto-detect when headers match schema-style names or common synonyms without a profile
  - Availability-aware priority: metrics whose required roles are missing are skipped; weights re-normalized over active metrics
  - Score summary CSV and CLI JSON report `ActiveMetrics`, `SkippedMetrics`, `FieldRoles`, `MissingRoles`
- Living development plan updates in `PLAN.md` (v0.2.0): efficiency releases R1–R3; locked `claim_age_days` and Balance-Weighted Days Outstanding for R2

#### Changed

- Score path always resolves field roles before raw metrics (config `fields` rewritten to actual headers for the run)
- FILE-CATALOG inventory for `column_map.py` and toolkit version **1.9.0**

### [1.0.2] - 2026-07-25

#### Changed

- **kpi-analytics 1.8.1:** retune default chaos entry and weight multipliers in `config_default.json`
  - `mean_ar_days_factor`: **1.5 → 1.0** (chaos when mean AR days exceeds `ar_day_target`, default 45)
  - chaos multipliers: `ar_days` **1.0 → 1.2**, `out_ins_amt` **1.0 → 1.5** (still boosts disparity ×1.4 and appeal ×1.5)
  - `config.py` incomplete-config fallback for `mean_ar_days_factor` matches the new default
  - SCORE-METHODOLOGY and toolkit version badges aligned; golden fixtures keep pinned configs

### [1.0.1] - 2026-07-25

#### Changed

- Excel toolkit docs: align ENTERPRISE-SECURITY toolkit version badge with **1.4.0**; refresh CLI guide illustrative JSON `Version` fields to **1.4.0**
- Excel toolkit README: add Summary, Contents, and `doc_type: readme` for MARKDOWN-STANDARD compliance
- KPI package README: add `doc_type: readme`

### [1.0.0] - 2026-07-25

#### Added

- Root `CHANGELOG.md` (Keep a Changelog; repository H2 → version H3 → category H4)
- Kit baseline in `RULES.md` (repo-kit **1.1.1** from https://github.com/shainemeister/repo-kit)
- Root hygiene, mandatory project CHANGELOG policy, three version surfaces, and kit upgrade procedure in `RULES.md`
- Non-Python style-gate guidance for PowerShell product code in `RULES.md`
- Platform-aware examples section in `MARKDOWN-STANDARD.md`

#### Changed

- Aligned `RULES.md`, `MARKDOWN-STANDARD.md`, `templates/`, and `.gitignore` with [repo-kit 1.1.1](https://github.com/shainemeister/repo-kit)
- Authority map, contributor checklist, anti-patterns, and maintenance cadence now cover CHANGELOG and kit baseline
- `kpi-analytics/.pylintrc` header comments aligned with kit adopter guidance (`py-version` must match supported Python)
