# Changelog

All notable changes to **workqueue-data-processor** are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/).  
**Structure:** `## workqueue-data-processor` → dated `### [X.Y.Z] - YYYY-MM-DD` → `#### Added` / `#### Changed` / …  
Dates are ISO 8601. There is no Unreleased section—record each change under the version section that ships it.

**Package versions** (`kpi_modules.__version__`, `ExcelToolkitVersion`) are independent of repository changelog versions unless a release intentionally aligns them.  
**Standards kit version** lives only in [kit/RULES.md — Kit baseline](./kit/RULES.md#kit-baseline) (not as kit release history here). Upstream: https://github.com/shainemeister/repo-kit

---

## workqueue-data-processor

### [1.22.0] - 2026-08-13

#### Changed

- **excel-toolkit 1.15.0:** Express / `-PoiScoreSheetOnly` copies original score-input source columns when present (`out_ins_amt`, `billed_amount`, deadline days, `days_on_wq_tab`, `denial_count`, `last_worked_date`) plus identity and the four scores. Still no `v1_raw_*`. Copy only; no scoring math.

### [1.21.2] - 2026-08-13

#### Changed

- **excel-toolkit 1.14.2:** Process my data **[5]** label is **Express score** only, same DarkGray as [1]–[4]. Extra Express hint line removed. All five actions remain.

### [1.21.1] - 2026-08-13

#### Changed

- **excel-toolkit 1.14.1:** Process my data action list after file pick prints the toolkit version and highlights **[5] Express score** (Cyan). Type `5` — Enter still runs Full pipeline. Close and relaunch the menu after upgrade.

### [1.21.0] - 2026-08-13

#### Added

- **excel-toolkit 1.14.0:** Process my data **Express score** scores `--output-mode slim` and writes one Excel sheet `POI_Scores` (identity + four POI scores). Skips profile, password, and Full/Slim picks. Summary CSV stays; no summary xlsx. CLI: `export-csv -PoiScoreSheetOnly` (copy only; no scoring math).

### [1.20.1] - 2026-08-12

#### Added

- **`Remove-MaintainerDocs.cmd`:** optional post-clone working-copy slim. Deletes maintainer trees (`kit\`, `docs\`, `certification\`, `PLAN.md`, CHANGELOG, kpi fixtures, excel sample-test). Does not rewrite git; restore with `git checkout -- .`. Toolkit user guides stay.

### [1.20.0] - 2026-08-12

#### Added

- **kpi-analytics 2.10.0:** `score --output-mode slim` writes WQ columns plus balanced `v1_priority_score` and one score per shipped POI (`v1_score_protect_writeoffs`, `v1_score_maximize_cash`, `v1_score_suppress_aging`). One normalize pass; not four batches. Default remains `full`. Slim cannot be combined with `--profile` / `--config`. Summary CSV still written.
- **excel-toolkit 1.13.0:** Process my data **Score output** Full / Slim; Slim passes `--output-mode slim` (no profile pick).

### [1.19.1] - 2026-08-12

#### Fixed

- **excel-toolkit 1.12.1:** Worklist GROUP/CLAIM match is case-sensitive (same trim / `(blank)` rule as kpi-analytics). Mixed-case keys no longer attach one claim to two groups.

### [1.19.0] - 2026-08-12

#### Added

- **excel-toolkit 1.12.0 (Cluster 2 / P8):** Process my data multi-file preview (name, WQ stem, row count, max `out_ins_amt`; no `score`). Excel deliverable names `[WQ]_MM-DD-YYYY.xlsx`. File-level **Totals** sheet via `export-csv -TotalsCsv` (copy of existing scored columns; no new score). Per-file only; groups do not span files.

### [1.18.1] - 2026-08-12

#### Changed

- Cluster **2** design freeze signed (P7): per-file scoring; WQ identity = filename stem / optional `wq_label`; groups do not span files; no required schema WQ field. Product code is P8.

### [1.18.0] - 2026-08-12

#### Added

- **excel-toolkit 1.11.0:** Process my data **Build worklist** scores with `kpi-analytics --group-preset` / `--groups`, then `export-csv -GroupsCsv -Worklist`. Composition only (no scoring math in PowerShell).

### [1.17.0] - 2026-08-12

#### Added

- **excel-toolkit 1.10.0:** `export-csv -GroupsCsv` writes a Groups sheet from kpi-analytics `*_groups.csv`. `-Worklist` adds a two-level GROUP/CLAIM sheet by matching key columns (no scoring math).

### [1.16.0] - 2026-08-12

#### Added

- **kpi-analytics 2.9.0:** `score --group-by` / `--group-preset` / `--groups` writes a reporting `*_groups.csv` (count, sum AR / billed / `kpi_q` share, max priority, min appeal days). Default remains no groups file. V1 / `kpi_q_*` claim values unchanged.

#### Changed

- Cluster 3.1 **group CSV shape** frozen (post-score; `payer_category` straw man). Patient/account grouping and Excel sheets still developing.

### [1.15.0] - 2026-08-12

#### Added

- **kpi-analytics 2.8.0:** `score --sort` and `--sort-preset` (`priority` / `deadline` / `cash`) reorder the **detail** CSV only. Default remains input order. V1 formulas and `kpi_q_*` unchanged. JSON: `SortSpec`, `SortPreset`, `SortApplied`.

#### Changed

- Cluster 3.2 **sort keys** frozen (post-score; stable input-index last). Grouping (3.1) and analysis sheet (3.3) still developing.

### [1.14.2] - 2026-08-12

#### Changed

- Upgraded repo-kit baseline to **2.4.0** (workboard + optional continuity; PLAN triple surface)
  - Portable policy: `kit/rules/workboard.md`, `kit/rules/continuity.md`; UPGRADE 1.6.0 preserve list
  - Adopted filled `docs/WORKBOARD.md`; Agent Instruct packs regen for workboard co-maintain
  - Root PLAN **1.2.0** points at the board; no live phase tables
  - FILE-CATALOG **1.10.4**; product packages unchanged (kpi **2.7.0** / excel **1.9.0**)

### [1.14.1] - 2026-08-12

#### Changed

- **kpi-analytics ENTERPRISE-SECURITY 2.7.0:** align toolkit version with package (default unique output paths unless `--force`; diagnostics import-smoke note)
- **Agent Instruct packs:** repair generated YAML frontmatter (BUILD `must_not_extra` leak); fold extras into Must not, including Cluster 2/3 freeze
- **FILE-CATALOG 1.10.2:** research note for RULES gap audit; fix `kpi-analytics.cmd` catalog link; `__version__` row 2.7.0

#### Removed

- Empty untracked local trees `vendor/` and `excel-toolkit/menus/` (not source)

### [1.14.0] - 2026-08-10

#### Changed

- Upgraded repo-kit baseline to **2.3.1** (Operator enforcement, Instructed-by cascade, AI docs workspace policy, Agent Instruct)
  - Merged domain modules / UPGRADE / MARKDOWN-STANDARD / templates into project `kit/`
  - Adopted **Agent Instruct** (`kit/agents/`); root `PLAN.md` owns Agent models; generated packs under `kit/agents/generated/`
  - Scaffolded AI docs workspace (`docs/README.md`, `research/`, `plan/`, `project_build/`, `resources/`) without clobbering product `docs/PLAN.md`, FILE-CATALOG, or concept doc
  - Product authority map, language inventory, and certification verify commands preserved
- **Plan dual-surface compliance** ([kit/RULES.md](./kit/RULES.md) / [ai-docs-workspace](./kit/rules/ai-docs-workspace.md))
  - Root `PLAN.md` **1.1.0**: mission, stages, non-goals, plan map, stage gates + Agent models
  - `docs/PLAN.md` **0.5.0**: product backlog only; links freezes under `docs/plan/`
  - Execution plans: Cluster 2 / Cluster 3 / B1.1-retune checklists; repo-kit upgrade note marked complete
  - `docs/README.md` + `docs/resources/` curated plan map; FILE-CATALOG **1.10.1**

### [1.13.0] - 2026-08-09

#### Added

- **excel-toolkit 1.9.0:** interactive menu **scoring profile** picker (Cluster 1 residual **1f**)
  - Process my data → Full pipeline / Score only: optional POI focus / named profile once per batch
  - Passes sibling `kpi-analytics.cmd score --profile …` on preflight dry-run, full score, guided mapping, and rank-enrich dry-run (no scoring math in PowerShell)
  - Advanced → **Scoring profiles (list / CLI help)** via `profile-list` only
  - Package default remains omit `--profile` (Balanced)

#### Changed

- excel-toolkit docs (README, CLI-GUIDE, ENTERPRISE-SECURITY) for 1.9.0 menu composition
- `docs/PLAN.md`: residual **1f** marked shipped; baseline packages refreshed

### [1.12.0] - 2026-07-30

#### Added

- **Certification Phase 2 — required dynamic Security checks** (full suite; 16 Standard checks):
  - `invariant-privacy-score` — score with privacy on masks patient / blanks DOB
  - `invariant-profile-denylist` — profiles reject claim-dump keys
  - `invariant-diagnostics-keys` — diagnostics certificate has no PHI/claim shapes
  - `invariant-automation-security` — `AutomationSecurity = 3` present in ExcelCom
  - `invariant-password-json-contract` — JSON exposes `PasswordUsed` boolean only
  - `policy-banned-patterns` — banned automation patterns over product trees
  - Harness kinds: `python-assert`, `powershell-assert`, `policy-scan`
  - `certification/scripts/`, `policies/banned-patterns.json`, `fixtures/privacy_score_input.csv`

#### Fixed

- **kpi-analytics diagnostics:** stop importing `kpi_modules.__main__` during package import smoke (it re-entered the CLI via `SystemExit`); verify `__main__.py` presence instead

#### Changed

- Operator guide, `kit/rules/security.md`, FILE-CATALOG for dynamic/policy certification checks

### [1.11.0] - 2026-07-30

#### Added

- **Certification engine hardening (SchemaVersion 1.1):**
  - `schema-validate` check (manifest structure, known Kinds, process executable allowlist)
  - Harness self-check: parse/BOM + PSScriptAnalyzer Error on `certification\*.ps1`
  - Bandit JSON evidence under `certification/logs/bandit.json`
  - `-Mode Ship` with `ShipOnly` clean-git gate (`ship-clean-git`)
  - Certificate fields: `Mode`, `Policy`, `Coverage`, per-check `Category`
  - Documented manifest schema at `certification/schema/checks.schema.json`

#### Changed

- `certification/checks.json` and `Invoke-Certification.ps1` enforce process allowlist; rooted arbitrary process executables rejected
- Operator guide and `kit/rules/security.md` updated for modes and engine integrity

### [1.10.0] - 2026-07-30

#### Fixed

- **kpi-analytics 2.7.0:** honor `kpi_quantifiers.amount_field` for portfolio balance (was always `out_ins_amt`)
- **kpi-analytics 2.7.0:** implement `adc_mode` (`auto` \| `config` \| `estimate`; default `auto` matches prior effective behavior); reject invalid `credit_policy`
- **kpi-analytics 2.7.0:** diagnostics import-smoke includes `kpi_modules.profiles` and stdlib `re`
- **kpi-analytics 2.7.0:** `score_csv(config=…)` always runs `validate_config`
- **excel-toolkit 1.8.1:** partial-rank banner/confirm after guided mapping (was skipped when RankCompleteness missing on synthetic JSON)

#### Changed

- **kpi-analytics 2.7.0:** `score` / `generate` do not overwrite existing destinations by default; use free path with numerical suffix unless `--force` (`--append` still targets the exact path). JSON reports `RequestedOutputPath` / `OutputPathAdjusted` (and summary counterparts for score)

#### Docs

- CLI-GUIDE, SCORE-METHODOLOGY, RCM methodology for amount_field, adc_mode, output collision; excel CLI-GUIDE 1.8.1 guided partial-rank note

### [1.9.0] - 2026-07-30

#### Added

- **kpi-analytics 2.6.0:** scoring profiles (Cluster 1 slices 1a–1e)
  - `score --profile <name-or-path>` deep-merges profile `config` onto package default; mutually exclusive with `--config`
  - CLI `profile-list`, `profile-show`, `profile-save` (metadata / weights summary; no claim rows in profiles)
  - Shipped thin POI focus presets under `kpi-analytics/profiles/`: `protect_writeoffs`, `maximize_cash`, `suppress_aging` (directional emphasis only; not outcome-optimized)
  - Module `kpi_modules/profiles.py`; score JSON adds `ProfilePath`, `ProfileName`, `MappingSource`
  - Explicit `--mapping` overrides profile-embedded mapping; guided mapping preserves profile-resolved config

#### Changed

- Docs: CLI-GUIDE, SCORE-METHODOLOGY, kpi README, FILE-CATALOG for profiles and POI presets

### [1.8.6] - 2026-07-30

#### Changed

- **Data contract paths:** moved `wq_schema.json`, `wq_schema.csv`, and `wq_data.csv` into `wq_schema/`; product defaults (kpi-analytics `--schema` / `--template-csv`, Excel schema lookup) resolve under that directory
- Migration for external scripts: prefix former root schema/sample paths with `wq_schema\`

### [1.8.5] - 2026-07-30

#### Changed

- **Root cleanup:** moved maintainer/design docs into `docs/` (`PLAN.md`, `FILE-CATALOG.md`, `WQ_Priority_Matrix_Concept.md`); root keeps entry shim and required project files only

### [1.8.4] - 2026-07-30

#### Changed

- Upgraded repo-kit baseline to **2.0.1** (standards under `kit/`; hub + domain modules; 1.x root-layout migration per [kit/UPGRADE.md](./kit/UPGRADE.md))
- Moved `RULES.md`, `MARKDOWN-STANDARD.md`, and `templates/` into `kit/`; certification harness root detection accepts `kit/RULES.md`

### [1.8.3] - 2026-07-30

#### Changed

- **Hygiene (RULES.md):** `.gitignore` blocks local numbered `import\wq_synthetic_data_N.*`, `import\*_mapping.json`, and `kpi-analytics/profiles/user_*.json`; FILE-CATALOG refreshed (kit baseline **1.2.1**, certification RCM check, ignored-path inventory)

### [1.8.2] - 2026-07-30

#### Changed

- **PLAN.md 0.2.0:** Cluster 1 (KPI POI presets + saved scoring profiles) **design-frozen** for implementation; baseline aligned to kpi 2.5.0 / excel 1.8.0 after gap-safety close

### [1.8.1] - 2026-07-28

#### Added

- **kpi-analytics 2.5.0:** privacy column alias resolution (`Patient Name`, `Date of Birth`, …)
- Certification Domain B: **validate-score-rcm** (RCM dual-attribution golden fixtures)

#### Changed

- **kpi-analytics 2.5.0:** default privacy patient `token_digits` **3 → 4** (`DOE0001,JOH0001`; max 9999 uniques per batch)
- Score JSON reports `PrivacyPatientField` / `PrivacyDobField` / sources / `PrivacyTokenDigits`

### [1.8.0] - 2026-07-28

#### Added

- **kpi-analytics 2.4.0:** rank completeness + optional fail-closed scoring
  - JSON always includes `RankCompleteness` and `IncompleteReasons`
  - CLI `score --strict roles|full` fails without writing files when incomplete
  - `roles` = missing/ambiguous roles or skipped metrics; `full` also requires raw-value coverage
  - Module `kpi_modules/completeness.py`; summary rows for rank completeness
- **excel-toolkit 1.8.0:** after score, partial ranks show a banner and require confirm to keep outputs / export Excel (decline deletes just-written CSVs)

### [1.7.4] - 2026-07-28

#### Added

- **kpi-analytics 2.3.0:** metric value coverage on every score run
  - JSON: `MetricValueCoverage`, `LowCoverageMetrics`, `LowCoverageThreshold`
  - Summary CSV Priority batch rows for coverage and low-coverage metrics
  - Distinguishes “role column resolved” (ActiveMetrics) from “raw values present”

#### Changed

- **excel-toolkit 1.7.3:** Process my data forces guided mapping only for **missing** or **ambiguous** roles
  - Low-confidence samples warn and continue (optional remap no longer required)

### [1.7.3] - 2026-07-28

#### Fixed

- **excel-toolkit 1.7.2:** Process my data listed each `.xlsx` twice
  - Cause: Windows `Get-ChildItem -Filter '*.xls'` also matches `.xlsx` (legacy Win32 wildcard)
  - Menu discovery added both `*.xlsx` and `*.xls` filters; true `.xls` is now extension-checked

### [1.7.2] - 2026-07-28

#### Fixed

- **kpi-analytics 2.2.0:** date cells accept Windows Excel serial day numbers (default on)
  - Root cause of incomplete aging KPIs / empty `v1_raw_claim_age_*` on Excel→CSV files such as `import\wq_synthetic_data_1.csv` (`46103` style dates)
  - Column **names** were already mapped correctly; values failed `parse_date` → blank claim age → 0% AR aging buckets
  - Sample verification treats serials as `looks_date` (no false low-confidence guided mapping for correct headers)
  - Config: `date_excel_serial` (default `true`); shared `date_to_excel_serial` / `excel_serial_to_date` in `metrics.py`
  - Fixture sample: `kpi-analytics/fixtures/excel_serial_dates_input.csv`

### [1.7.1] - 2026-07-28

#### Fixed

- **excel-toolkit 1.7.1:** Guided mapping no longer crashes the menu with `The property 'ExitCode' cannot be found`
  - Interactive score used `& kpi-analytics.cmd`, so Python console output entered the PowerShell pipeline and polluted the return value
  - Interactive path now uses `Start-Process` without stream redirects (TTY preserved; single result object)
  - Callers normalize multi-object results via `Select-KpiScoreInvokeResult`

### [1.7.0] - 2026-07-28

#### Added

- **excel-toolkit 1.7.0:** Process my data score path — mapping preflight and guided column mapping
  - Dry-run score inspects missing / ambiguous / low-confidence roles before writing outputs
  - Interactive console: launches kpi-analytics `--interactive-mapping` with a real TTY (no stdout redirect hang)
  - Auto-applies sibling `<stem>_mapping.json` next to the input CSV when present
  - Non-interactive hosts fail clearly with guidance to use a mapping profile or interactive CLI
  - Schema-aligned synthetic / known headers still score without prompts

#### Changed

- `ExcelToolkitVersion` **1.7.0**; menu README / CLI-GUIDE / ENTERPRISE-SECURITY aligned
- FILE-CATALOG: `Start-ExcelMenu.ps1` documents mapping preflight helpers

### [1.6.3] - 2026-07-28

#### Changed

- Upgraded repo-kit baseline to **1.2.1** (upgrade procedure starts from Kit baseline Kit source; upstream AI prompt deep link `#upgrade-repo-kit`)

### [1.6.2] - 2026-07-28

#### Fixed

- Package diagnostics certificates now persist `ReportJsonPath` / `ReportTextPath` on disk (kpi-analytics and excel-toolkit)
- KPI diagnostics stdlib import list includes `importlib` and `platform` used by diagnostics/probe

#### Changed

- Excel diagnostics readiness adds critical **ToolkitModuleExports** check (high-level ExcelToolkit.psm1 API surface)
- Diagnostics folder READMEs clarify separation from root `certification/` (machine readiness vs source-tree Domain A/B)
- kpi-analytics ENTERPRISE-SECURITY document version aligned to toolkit **2.1.0**

### [1.6.1] - 2026-07-28

#### Added

- Root **MIT** [LICENSE](./LICENSE)
- Certification certificate fields: `PackageVersions`, per-check `DurationMs`, top-level `Message`

#### Changed

- **Certification quality hardening** (`certification/` harness + `checks.json`)
  - PSScriptAnalyzer Domain A scans the **same product** PowerShell set as parse/BOM (`sample-test` excluded)
  - **Gitleaks** requires both working-tree (`--no-git`) and **git history** scans
  - Pylint **10.00/10** enforced via declarative `RequirePylintScore` (no hard-coded check Id)
- RULES.md **1.6.1**, certification README **1.0.1**, FILE-CATALOG / root README pointers

#### Security

- Documented advisory PSScriptAnalyzer **Warning** `PSAvoidUsingPlainTextForPassword` on automation password bridges (not an Error gate; SecureString product hardening remains a follow-up)

### [1.6.0] - 2026-07-28

#### Added

- **Security and code-validation certification package** under `certification/`
  - Operator guide (`README.md`), declarative `checks.json`, and full-suite harness `Invoke-Certification.ps1`
  - One certificate pair covers Domain A (Bandit, PSScriptAnalyzer Error, **Gitleaks**) and Domain B (pylint 10.00/10, PS parse/BOM, `validate-score`)
  - Regenerable `last_certification.json` / `.txt` remain gitignored (not package diagnostics)

#### Changed

- **Secrets / Gitleaks** promoted to **Declared** and **required** for completion and every certification renewal
- **RULES.md 1.6.0:** certification renewal enforcement — after product/code or gate changes, renew only via the **full** harness (no partial recert; pylint and security always together); operational commands live in `certification/`; verification, checklist, and anti-patterns aligned
- FILE-CATALOG and root README point maintainers at the certification package

#### Security

- Bandit B311 on synthetic PRNG in `kpi_modules/synthesize.py` documented with `# nosec B311` (demo data only, not cryptography)

### [1.5.4] - 2026-07-28

#### Changed

- Upgraded repo-kit baseline to **1.2.0** (language surface inventory; SAST required when declared for Python + PowerShell; Gitleaks opt-in only; optional certification schema deferred; completion rule; TEMPLATE-CERTIFICATION-README)

### [1.5.3] - 2026-07-28

#### Changed

- Upgraded repo-kit baseline to **1.1.7** (security documentation modularity + advisory language-scoped SAST gates in RULES; upgrade-path CHANGELOG discipline; TEMPLATE-SECURITY modularity notes)

### [1.5.2] - 2026-07-25

#### Changed

- Upgraded repo-kit baseline to **1.1.2** (required AI-assisted commit disclosure in RULES git rules: `Assisted-by` / `Compliance` / `Instructed-by`)

### [1.5.1] - 2026-07-25

#### Removed

- Root `PLAN.md` (dynamic schema adaptation / guided mapping plan). Repo **1.5.0** / kpi-analytics **2.1.0** shipped; delivery history remains in this CHANGELOG and git history. FILE-CATALOG updated.

### [1.5.0] - 2026-07-25

#### Added

- **kpi-analytics 2.1.0:** dynamic schema adaptation and guided mapping
  - Sample-based verification of resolved role columns (date / numeric heuristics)
  - Richer mapping report on every `score` run: `AmbiguousRoles`, `LowConfidenceRoles`, `MappingSources`, `RoleConfidence`, `TypeChecks`
  - `score --interactive-mapping`: TTY guided column assignment for missing / ambiguous / low-confidence roles; optional save of a mapping profile next to the input CSV
  - Non-TTY + `--interactive-mapping` with mapping problems fails clearly (no hang on `input()`)
  - `NEED_DIFFERENT_FILE` message when the operator aborts guided mapping to choose another source

#### Changed

- Unresolved roles are no longer silently filled with the role name in config `fields` (metrics skip cleanly; weights renorm over active metrics as before)
- `metrics._field` returns empty string when a role is unmapped (no accidental role-name column lookup)
- Root `PLAN.md` status marked implemented for this release
- CLI-GUIDE, SCORE-METHODOLOGY, FILE-CATALOG, and kpi-analytics README updated for mapping verification and interactive mode

#### Unchanged

- excel-toolkit remains **1.6.0** (menu does not yet pass `--interactive-mapping`; automation CLIs unchanged except new score flag)
- Priority formulas and `kpi_q_*` contracts unchanged when all roles resolve

### [1.4.1] - 2026-07-25

#### Removed

- Root `PLAN.md` (menu simplification / dynamic processing plan). Repo **1.4.0** / excel-toolkit **1.6.0** shipped; delivery history remains in this CHANGELOG and git history. FILE-CATALOG updated.

### [1.4.0] - 2026-07-25

#### Added

- **excel-toolkit 1.6.0:** guided interactive menu and flexible file selection
  - Main menu: **Process my data** / Advanced tools / Exit
  - Unified discovery of `.csv`, `.xlsx`, and `.xls` under `import\`
  - Print-style multi-select: `1`, `1,2,3`, `1-3`, `1,3-5,8`, or a full path
  - Action choice after selection: full pipeline, score only, or export only
  - Excel selections import to CSV first (open-password prompt when needed), then continue
  - Optional workbook **open password** on every menu path that produces Excel (SecureString; never logged)
- Root `PLAN.md` for menu simplification / dynamic processing (this release)

#### Changed

- Interactive happy path no longer forces the user to choose pipeline vs score vs export before seeing files
- Advanced tools retain schema-header export, import, folders, schema, diagnostics (export uses in-process path with password prompt)
- Automation CLIs (`excel-toolkit.cmd`, `kpi-analytics.cmd`) unchanged; kpi-analytics remains **2.0.0**

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
