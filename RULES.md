---
title: Repository Maintenance Rules
description: Fundamental rules for documenting, changing, verifying, and versioning this repository.
version: "1.6.2"
status: current
audience:
  - developers
  - analysts
  - security
doc_type: other
related:
  - README.md
  - CHANGELOG.md
  - FILE-CATALOG.md
  - MARKDOWN-STANDARD.md
  - LICENSE
  - excel-toolkit/ENTERPRISE-SECURITY.md
  - kpi-analytics/ENTERPRISE-SECURITY.md
  - kpi-analytics/.pylintrc
  - certification/README.md
  - templates/TEMPLATE-CERTIFICATION-README.md
last_updated: "2026-07-28"
---

# Repository Maintenance Rules

Policy for keeping **workqueue-data-processor** professional, auditable, and safe to change. This file is for **contributors and reviewers**—not a product tutorial.

**If you only need to score work or export Excel:** start with the root [README.md](./README.md) and the toolkit guides. Come back here when you edit code, docs, schema, or release behavior.

**Document version:** 1.6.2  

**Related:** [README.md](./README.md) · [CHANGELOG.md](./CHANGELOG.md) · [FILE-CATALOG.md](./FILE-CATALOG.md) · [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) · [kpi-analytics/.pylintrc](./kpi-analytics/.pylintrc) · [certification/README.md](./certification/README.md)

---

## Summary

The product is a **Work Queue data contract** plus two **independent** toolkits:

| Toolkit | Runtime | Role |
|---------|---------|------|
| `excel-toolkit\` | Windows PowerShell 5.1 + Excel COM | CSV ↔ formatted workbook; first-run diagnostics gate |
| `kpi-analytics\` | Python **3.13** stdlib only | CSV → priority scores + RCM KPI Q columns; first-run diagnostics gate |

**RULES.md** is the **maintenance policy**. Day-to-day product contracts live in CLI guides, methodology, and security notes. When those contracts change, update the **canonical** file in the **same change set**—do not leave docs, fixtures, or versions stale.

| Must | Must not |
|------|----------|
| Update the **canonical** doc with behavior changes | Commit `output\`, caches, secrets, real PHI, or diagnostics certificates |
| Maintain root **CHANGELOG.md** (Keep a Changelog) | Ship version bumps or release-worthy changes without CHANGELOG |
| Keep [Kit baseline](#kit-baseline) current after adopt/upgrade | Lose track of kit version after SETUP is gone |
| Use conventional commit messages that match staged files | Mix unrelated toolkits or leave CLI/security docs stale |
| Keep toolkits independent at the runtime layer | Add pip packages or network clients to **product** code |
| Run **pylint** on `kpi_modules` after Python product changes | Treat pylint as a runtime install for end users |
| Keep [language surface inventory](#language-surface-inventory) accurate; run declared style + SAST before complete | Paste the full multi-language SAST table without inventory evidence |
| Verify before sharing scoring or COM changes | Claim complete when a **declared** style or SAST gate was skipped or failed |
| Preserve explainable score / dual KPI attribution | Force-kill Excel or permanently alter ExecutionPolicy |
| After product/code changes: renew certification via the **full** harness (Domain B **and** Domain A, including pylint + Gitleaks) | Partial recert; skip pylint or security on renewal; hand-edit cert JSON; commit `last_certification.*`; treat certification as a product launcher gate |
| Coordinated schema / scored-column renames with fixtures + docs | Silently rename schema fields or scored columns |

---

## Contents

1. [Summary](#summary)
2. [Authority map](#authority-map)
3. [Root hygiene](#root-hygiene)
4. [Documentation rules](#documentation-rules)
5. [Formatting and style](#formatting-and-style) (includes [Python style gate (pylint)](#python-style-gate-pylint) and [Non-Python style gates](#non-python-style-gates))
6. [Architecture and boundaries](#architecture-and-boundaries)
7. [Data and schema rules](#data-and-schema-rules)
8. [Security and enterprise constraints](#security-and-enterprise-constraints) (includes [Security documentation modularity](#security-documentation-modularity), [Language surface inventory](#language-surface-inventory), [Security / SAST gates](#security--sast-gates-required-when-declared), and [Security and code-validation certification](#security-and-code-validation-certification))
9. [Versioning and change control](#versioning-and-change-control)
10. [Git rules](#git-rules)
11. [Verification before ship](#verification-before-ship) (includes [Before marking work complete](#before-marking-work-complete))
12. [Maintenance cadence](#maintenance-cadence)
13. [Anti-patterns](#anti-patterns)
14. [Contributor checklist](#contributor-checklist)
15. [Document history](#document-history)

---

## Authority map

Update the **owner** document for a change. Cross-link; do not paste full contracts into multiple places.

| Concern | Canonical source |
|---------|------------------|
| End-user purpose and quick start | [README.md](./README.md) |
| Project history (**required**) | [CHANGELOG.md](./CHANGELOG.md) |
| Standards kit baseline | [Kit baseline](#kit-baseline) in this file |
| Path-level file inventory | [FILE-CATALOG.md](./FILE-CATALOG.md) |
| Markdown structure, frontmatter, author checklist | [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) · [templates/](./templates/) |
| Maintenance policy (this file) | [RULES.md](./RULES.md) |
| Excel CLI (verbs, exit codes, JSON, diagnostics gate) | [excel-toolkit/CLI-GUIDE.md](./excel-toolkit/CLI-GUIDE.md) |
| KPI CLI (verbs, exit codes, JSON, diagnostics gate) | [kpi-analytics/CLI-GUIDE.md](./kpi-analytics/CLI-GUIDE.md) |
| Priority V1 + `kpi_q_*` implementation | [kpi-analytics/SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md) |
| RCM dual-attribution theory | [kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md](./kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md) |
| Priority design roadmap (V1–V3) | [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) |
| Excel enterprise / COM posture | [excel-toolkit/ENTERPRISE-SECURITY.md](./excel-toolkit/ENTERPRISE-SECURITY.md) |
| KPI enterprise / offline posture | [kpi-analytics/ENTERPRISE-SECURITY.md](./kpi-analytics/ENTERPRISE-SECURITY.md) |
| Excel diagnostics certificate folder | [excel-toolkit/diagnostics/README.md](./excel-toolkit/diagnostics/README.md) |
| KPI diagnostics certificate folder | [kpi-analytics/diagnostics/README.md](./kpi-analytics/diagnostics/README.md) |
| Language surface inventory | [Language surface inventory](#language-surface-inventory) in this file (Status + tool names; commands in certification) |
| Security & code-validation certification | [certification/README.md](./certification/README.md) (operator guide + harness; renewal policy in this file). Package diagnostics stay under each toolkit — do **not** merge them here |
| Field definitions | [wq_schema.json](./wq_schema.json) (CSV twin: [wq_schema.csv](./wq_schema.csv)) |
| Sample fact rows | [wq_data.csv](./wq_data.csv) |
| Default score config | [kpi-analytics/kpi_modules/config_default.json](./kpi-analytics/kpi_modules/config_default.json) |
| Golden tests | [kpi-analytics/fixtures/](./kpi-analytics/fixtures/) |
| KPI Python style / PEP-8 gate | [kpi-analytics/.pylintrc](./kpi-analytics/.pylintrc) (dev tooling only) |

**Rule:** Adding, removing, or renaming intentional source files requires a same-change update to [FILE-CATALOG.md](./FILE-CATALOG.md).

---

## Root hygiene

Keep the repository root **scannable**: entry points and policy first; purpose directories for everything else.

### What belongs at root

| File / item | Role |
|-------------|------|
| `README.md` | Landing / use-cases (no frontmatter) |
| `LICENSE` | MIT license |
| `RULES.md` | Maintenance policy + authority map + kit baseline |
| `MARKDOWN-STANDARD.md` | Writing and structure standard |
| `CHANGELOG.md` | Project history (**required**) |
| `FILE-CATALOG.md` | Path-level inventory (maintained) |
| `.gitignore` | Ignore rules |
| `Start-ExcelMenu.cmd` | Natural top-level entry shim |
| Data contract files | `wq_schema.*`, `wq_data.csv`, concept doc |

### What does not belong at root

| Concern | Preferred home |
|---------|----------------|
| Templates | `templates/` |
| Style configs | Package-local (e.g. `kpi-analytics/.pylintrc`) |
| Toolkit contracts | Inside `excel-toolkit/` or `kpi-analytics/` |
| Formal security + code-validation certificates | `certification/` (**maintained** — see [Security and code-validation certification](#security-and-code-validation-certification)); regenerable outputs gitignored — **not** package diagnostics |
| Tracked demo inputs | `import/` |
| Regenerable output | `output/` — never committed |
| Ephemeral adoption guide | Do not re-add `SETUP.md` after initiation |

### Supporting practices

1. Update the authority map in the **same change set** whenever an intentional path listed there is added, removed, or renamed.  
2. Prefer purpose directories over additional root files.  
3. Respect `.gitignore`; never force-add regenerable artifacts.  
4. Kit upgrades: [Upgrading the kit](#upgrading-the-kit-post-initiation) via https://github.com/shainemeister/repo-kit — do not leave a permanent `SETUP.md` at root.

---

## Documentation rules

1. **Substantial documents** follow [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md): YAML frontmatter, single H1, lead, Summary before Contents, body, history when versioned.  
2. **New docs** start from [templates/](./templates/); leave no unresolved `{{PLACEHOLDERS}}`.  
3. **Behavior change ⇒ doc change** in the same commit or PR:  
   - CLI verbs, flags, exit codes, JSON shapes → matching `CLI-GUIDE.md`  
   - Scoring formulas, output columns, validation → `SCORE-METHODOLOGY.md` (+ fixtures if contract shifts)  
   - Trust boundary or execution model → matching `ENTERPRISE-SECURITY.md`  
4. **Prefer link + short summary** over pasting another document in full.  
5. **Root [README.md](./README.md)** stays an **end-user landing page** (summary, use cases, one quick start). Deep contracts stay in toolkit docs.  
6. **Status honesty:** set frontmatter `status` to `draft` / `current` / `deprecated` accurately.  
7. **Platform-aware examples** follow [MARKDOWN-STANDARD — Platform-aware examples](./MARKDOWN-STANDARD.md#platform-aware-examples). This repository’s **primary platform is Windows** (PowerShell 5.1 + Excel COM for excel-toolkit; Windows-first launchers for kpi-analytics). Dual OS blocks in templates may be kept for portable skeletons; product docs may stay Windows-only when that matches reality.

---

## Formatting and style

| Area | Rule |
|------|------|
| Voice | Complete sentences; direct and professional; tables for parallel facts |
| Emphasis | **Bold** for critical terms and UI labels |
| Identifiers | `` `inline code` `` for paths, flags, column names, module names |
| Markdown structure | Per [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md); language-tagged code fences |
| Links | Relative from the file’s directory (`./CLI-GUIDE.md`, `../README.md`) |
| Paths in prose | Consistent separators within a file; Windows-style examples are fine |
| PowerShell | Target **5.1**; no PowerShell 7-only syntax in `excel-toolkit\`. Save product `.ps1`/`.psm1` as **UTF-8 with BOM** (or pure ASCII). PowerShell 5.1 reads BOM-less UTF-8 as system ANSI and can **fail to parse** on Unicode punctuation (arrows, em dashes). |
| Python | Target **3.13**; **standard library only** in product `kpi-analytics\` code |
| Python style | PEP-8 via **pylint** against [kpi-analytics/.pylintrc](./kpi-analytics/.pylintrc) — see [Python style gate (pylint)](#python-style-gate-pylint) |
| Other languages | Declare a style gate — see [Non-Python style gates](#non-python-style-gates) |
| Examples | Prefer placeholders (`C:\path\to\...`) plus one concrete repo-relative example |

### Python style gate (pylint)

All product Python under `kpi-analytics\kpi_modules\` must stay **pylint-clean** under the repo gate config before sharing scoring or packaging changes.

| Item | Rule |
|------|------|
| **Config** | [kpi-analytics/.pylintrc](./kpi-analytics/.pylintrc) — PEP-8–aligned conventions (line length 100, docstrings, names, unused imports/vars, selected errors) |
| **Scope** | `kpi_modules` package only |
| **Command** | From `kpi-analytics\`: `py -3.13 -m pylint kpi_modules` (or `python -m pylint kpi_modules`) |
| **Pass criteria** | Exit code **0** and score **10.00/10** under that config |
| **When to run** | After any edit to `kpi_modules\*.py`, `.pylintrc`, or related packaging that can affect style |
| **Product dependency** | **No.** Pylint is **developer tooling** only. Do **not** add pylint (or any pip package) to product runtime, launchers, or enterprise install steps. End users run scoring with stdlib Python only. |
| **Out of gate** | Design/refactor metrics (`too-many-*`, large-file complexity) are intentionally relaxed in `.pylintrc`; do not “fix” them by silent API rewrites. Full default pylint without the config is informational only. |

If pylint is not installed on a developer machine, install it into the **developer** environment (user/global Python), never into a product `requirements.txt` or toolkit path meant for locked-down PCs.

**Adopt / maintain steps:**

1. Keep `.pylintrc` under `kpi-analytics\` (package-local).  
2. **Must:** keep `py-version` set to the supported product Python (**3.13**).  
3. Point the verification table at `kpi_modules`.  
4. Extend `good-names` only when short identifiers are intentional and repeated.

### Non-Python style gates

Projects that ship non-Python product code declare **one primary gate per language surface**: tool name, command, and pass criteria. Non-Python gates **do not** inherit the pylint 10.00 score rule.

| Language / surface | Gate (this repo) | Pass criteria |
|--------------------|------------------|---------------|
| **Python** (`kpi_modules`) | pylint — see above | Exit 0, score 10.00/10 |
| **PowerShell** (`excel-toolkit`) | Manual / review gate: parse under **Windows PowerShell 5.1**; UTF-8 **with BOM** (or pure ASCII); no PS7-only syntax | Scripts load without parse errors; COM smoke via `excel-toolkit.cmd probe` / `Test-ExcelCom.ps1 -DryRun` as appropriate |
| Shell / other | Not a product surface here | — |

**Rules:**

1. Name the tool and pass criteria explicitly—do not leave “we lint somehow” implied.  
2. Keep style tools as **developer tooling** unless the product truly requires them at runtime.  
3. If a formal PowerShell linter (e.g. PSScriptAnalyzer) is later adopted, document the command and pass criteria here and in the verification table.

---

## Architecture and boundaries

| Rule | Detail |
|------|--------|
| **Runtime separation** | Do not call Excel COM from Python product code. Do not implement priority/KPI math in PowerShell product code. |
| **Composition** | Join toolkits at the **workflow** layer (generate/score CSV → export XLSX), not by merging engines. Interactive composition may live in `excel-toolkit\Start-ExcelMenu.ps1` (subprocess `kpi-analytics.cmd`, then Excel export). |
| **Excel entry points** | Prefer `excel-toolkit.cmd` / `ExcelToolkit.ps1` (automation) or `Import-Module ExcelToolkit.psm1` (in-process). Treat `Export-WqDataToExcel.ps1` as a legacy forwarder. |
| **KPI entry points** | Prefer `kpi-analytics.cmd` or `python -m kpi_modules`. Keep `kpi_modules` importable without side effects beyond CLI `__main__`. |
| **Dependencies** | No pip packages, no download-and-run, no credential stores, no hidden telemetry in product paths. |
| **Excel lifecycle** | Close via Quit + controlled retry + user warning. **Never** force-kill `EXCEL.EXE` in toolkit code. |
| **Output collision** | Product writers **must not** clobber an existing destination by default. Prefer a free path with a numerical suffix (`name_1.ext`). Use explicit `-Force` (or documented equivalent) only when the caller intends to replace that exact path. |
| **Domain hard-coding** | Export layout is CSV/schema-driven. Avoid hard-coded business field lists in the Excel engine. |

---

## Data and schema rules

1. **Schema owns definitions** (`field_name`, types, nullability, display names). **Data owns rows.** CSV headers must match `field_name`.  
2. **Field renames and type changes are breaking.** Update together: `wq_schema.json` / `.csv`, sample `wq_data.csv`, `config_default.json` field maps, fixtures, and affected docs.  
3. **Scored column contracts** (`v1_*`, `kpi_q_*`, summary layout) are public automation surfaces. Changing them requires methodology + CLI notes + fixture updates and a version bump.  
4. **Explainability is required:** keep intermediate priority audit columns; keep dual RCM attribution (static share vs resolution Δ). Do not collapse metrics into a single misleading sum.  
5. **Fixtures** under `kpi-analytics\fixtures\` are golden. Scoring changes must keep `validate-score` green or deliberately refresh expected JSON with a documented reason.  
6. **No real PHI/PII, credentials, tokens, or production dumps** in the repository. Samples are synthetic or non-sensitive illustrations.  
7. **Synthetic data** remains obviously non-production (existing de-identification conventions in `synthesize.py`).  
8. **`import\`** holds tracked **input** CSVs (synthetic demos or deliberately shared non-PHI extracts). Prefer synthetic data; **never** commit real PHI/PII there. Default `score` / `generate` paths target `import\wq_synthetic_data.csv`.  
9. **`output\`** is regenerable workspace only (scored CSVs, summaries, Excel)—not source of truth and not versioned.  
10. **Do not overwrite tracked or existing outputs by default.** Excel toolkit writers resolve a unique sibling path when the target exists (unless the caller passes documented `-Force`). KPI `score` receives pre-resolved unique paths from the menu pipeline so intermediate CSVs are not clobbered either.

---

## Security and enterprise constraints

Hard rules for product code and launchers. Full matrices live in the security docs.

| Rule | Excel toolkit | KPI analytics |
|------|---------------|---------------|
| Privilege | Current user only; no elevation | Current user only; no elevation |
| Network | No product downloads / remote modules | No network / package index access |
| Policy | Process-scoped Bypass on `.cmd` only; never permanent `Set-ExecutionPolicy` | No host policy mutation |
| Office | Local Excel COM when required | **No** Office automation |
| Dependencies | PowerShell + Excel COM | Python 3.13 stdlib only |
| Kill / unblock | No force-kill; no silent MOTW unblock | N/A for Office; no process kill patterns |

Canonical detail:

- [excel-toolkit/ENTERPRISE-SECURITY.md](./excel-toolkit/ENTERPRISE-SECURITY.md)  
- [kpi-analytics/ENTERPRISE-SECURITY.md](./kpi-analytics/ENTERPRISE-SECURITY.md)  

Policy-sensitive environments: run `excel-toolkit\sample-test\` probes before claiming the toolkit “works on locked-down PCs.”

### Security documentation modularity

Create or maintain a package security doc **only when** the package has an **execution surface**, **network access**, **elevated privilege**, or **handles secrets**. Pure documentation packages and pure libraries with **no runtime side effects** may **omit** security documentation entirely—do not create empty files to satisfy a template habit.

| Situation | Security doc |
|-----------|--------------|
| Docs-only / standards-only surface | **Omit** |
| Pure library, no network / privilege / secrets handling | **Omit** (optional short note in package README if helpful) |
| CLI, service, automation, or other execution surface | **Required** |
| Handles credentials, tokens, or elevated install | **Required** |
| Monorepo | Per package: required only for packages that meet the triggers above |

**This repository:** both `excel-toolkit` (PowerShell + Excel COM automation) and `kpi-analytics` (Python CLI / scoring execution surface) **require** their `ENTERPRISE-SECURITY.md` files. Keep trust-boundary detail in those canonical files—not duplicated into the root README. When a future package has no execution surface, omit its security doc and do not add a Security / trust boundary row for it in the [authority map](#authority-map).

### Language surface inventory

Declare **which product language and security surfaces this repository ships**. The inventory records **Status** and **tool identity**. **Executable commands and pass criteria** for formal certification live in [certification/README.md](./certification/README.md) and [certification/checks.json](./certification/checks.json)—do not re-paste long command tables here when only a Status or tool name changes.

| Surface | Status | Domain B — style / validation | Domain A — security / SAST | Typical pass | Notes |
|---------|--------|-------------------------------|----------------------------|--------------|--------|
| **Python** product code (`kpi_modules`) | **Declared** | **pylint** (exit 0, score **10.00/10** via `RequirePylintScore`) | **Bandit** | Style + SAST clean | Commands: [certification/README.md](./certification/README.md) |
| **PowerShell** (`excel-toolkit` product scripts) | **Declared** | PS 5.1 parse + UTF-8 **BOM** policy | **PSScriptAnalyzer** Error | Zero Error findings; scripts load | Product `*.ps1`/`*.psm1` only; **`sample-test` excluded** from Domain A and B |
| **Secrets** (whole repo) | **Declared** | — | **Gitleaks** (workdir **and** git history) | No leaks on **both** modes | **Required** for completion and every certification renewal |
| **Python** dependencies | **Not declared** | — | pip-audit | — | Product is **stdlib-only** |
| JS/TS, Go, Rust, Shell, Semgrep | **Not present** | — | — | — | Do not invent gates for surfaces this repo does not ship |

**Declared surfaces for this repository:** **Python**, **PowerShell**, and **Secrets**. Domain A/B (and Secrets) gates are **required**. Prefer the [certification harness](./certification/Invoke-Certification.ps1) so all declared surfaces run together.

**Rules:**

1. Inventory Status drives the [completion rule](#completion-rule) and [certification renewal](#certification-renewal-enforcement-required).  
2. Adding a language later updates inventory, certification `checks.json` / README, and authority map in the **same change set**.  
3. **Python product** and **Python dependencies** are separate (Bandit vs pip-audit). This repo declares product Python only.  
4. Prefer declared inventory over heuristic filesystem scans.  
5. **Secrets / Gitleaks:** **Declared and required** — skipping Gitleaks fails completion and fails certification renewal. The harness requires **two** scans: working tree (`--no-git`) and git history (default).

### Security / SAST gates (required when declared)

**Developer-tooling** gates for security-oriented static analysis. These are **not** style gates and are **not** product runtime dependencies.

**Posture:** When a language or security surface is **Declared** in the inventory, its Domain A tool is **required** before task completion and ship (see [Completion rule](#completion-rule)). Missing **required** developer tools is a **failed** gate, not a silent skip.

**Modularity rule:** Declare **only** tools for **languages and surfaces this repo ships**. Never paste unused language rows (Go, Rust, npm, etc.).

| Surface | Posture | Primary tool | Where commands live |
|---------|---------|--------------|---------------------|
| **Python** product (`kpi_modules`) | **Required** (declared) | **Bandit** (PyCQA) | [certification/checks.json](./certification/checks.json) |
| **PowerShell** (`excel-toolkit`) | **Required** (declared) | **PSScriptAnalyzer** (Microsoft) | certification package |
| **Secrets** | **Required** (declared) | **Gitleaks** (workdir + git history) | certification package (full harness) |

**Product dependency:** **No.** Bandit, PSScriptAnalyzer, Gitleaks, and similar tools are **developer tooling** only. Do **not** add them as required installs for end users of the product.

**Rules:**

1. Operational commands and pass criteria live under `certification/`—keep this section as posture + tool identity.  
2. Install tools in the **developer** environment only.  
3. Warning-level findings (e.g. PSScriptAnalyzer **Warning**) stay advisory unless the project promotes them to critical.  
4. Package diagnostics (`kpi-analytics\diagnostics\`, `excel-toolkit\diagnostics\`) answer “can **this machine** run the product?”—they are **not** Domain A/B substitutes.  
5. **Gitleaks is required.** Skipping it fails the [Completion rule](#completion-rule) and [certification renewal](#certification-renewal-enforcement-required).

### Security and code-validation certification

This repository **maintains** a formal **developer self-attestation** package under `certification/`: for git commit *C* at time *T*, declared surfaces passed **Domain A (security / SAST + secrets)** and **Domain B (code validation)** in **one** certificate pair. This is **not** a third-party audit, SOC 2, ISO seal, or product runtime diagnostics gate.

| This **is** | This **is not** |
|-------------|-----------------|
| Self-attestation of automated checks bound to a commit | Third-party certification or compliance logo |
| Security **and** code validation in one certificate pair | A second product CLI / diagnostics gate for end users |
| Suitable for IT tickets and pre-ship review packets | Proof of regulated Safe Harbor or data claims |
| Regenerable, gitignored output under one folder | A substitute for human threat modeling |

#### Single-folder rule

**All** formal certificates live under one folder:

```text
certification/
  README.md                    # operator guide + disclaimer (versioned)
  checks.json                  # declarative required checks (tracked)
  Invoke-Certification.ps1     # full-suite harness (tracked; developer-only)
  last_certification.json      # gitignored, regenerable
  last_certification.txt       # gitignored, regenerable
  logs/                        # gitignored optional tool reports
```

| Rule | Detail |
|------|--------|
| One folder | No split `security-cert/` vs `validation-cert/`; no extra root purpose directories |
| One certificate pair | Both domains appear **inside** the same JSON/TXT |
| Regenerable | Never commit `last_certification.*` or `certification/logs/` |
| Maintained | This repository **keeps** `certification/`; operator guide is [certification/README.md](./certification/README.md) |
| Not package diagnostics | Do **not** merge `excel-toolkit\diagnostics\` or `kpi-analytics\diagnostics\` into `certification/` |

#### Domains and OverallPass

```text
Domains.Security.OverallPass
Domains.CodeValidation.OverallPass
OverallPass = AND of domains that apply for declared inventory surfaces
```

**OverallPass** means: every **required critical** check that ran passed, **and** no required critical tool was missing.

| Domain | Covers (this repo) |
|--------|---------------------|
| **Security** | Bandit on `kpi_modules`; PSScriptAnalyzer Error on **product** `excel-toolkit` scripts (`sample-test` excluded); **Gitleaks** workdir + git history |
| **Code validation** | pylint on `kpi_modules` (**10.00/10** via `RequirePylintScore`); PS 5.1 parse/BOM on the same product set; `validate-score` fixtures |

Commands: [certification/checks.json](./certification/checks.json).

#### Certificate shape (illustrative)

**Machine-readable** (`certification/last_certification.json`) should include: `CertificateType` (`SecurityAndCodeValidationCertification`), `OverallPass`, `Message`, timestamps, `RepoRoot`, `GitCommit` / `GitBranch` / `GitDirty`, `LanguageSurfaces[]`, `PackageVersions`, `ToolVersions`, `PassCriteria`, `Domains.Security` / `Domains.CodeValidation`, `Checks[]` (`Name`, `Domain`, `Passed`, `Severity`, `Detail`, `DurationMs`), `Disclaimer`.

**Human-readable** (`last_certification.txt`): same facts in sections. **Privacy:** paths, versions, rule ids, counts only—never secrets, passwords, PHI, or claim rows.

#### Certification renewal enforcement (required)

When this repository maintains `certification/` (it does):

1. **Renew after code changes.** Any change set that edits product Python under `kpi-analytics\kpi_modules\`, product PowerShell under `excel-toolkit\`, certification gate definitions (`checks.json`, harness, `.pylintrc`), or [language surface inventory](#language-surface-inventory) **invalidates** the prior certificate for completion purposes.  
2. **Full package only.** Renewal **must** execute the full certification package ([Invoke-Certification.ps1](./certification/Invoke-Certification.ps1) / **all** required rows in [checks.json](./certification/checks.json)):  
   - **Domain B (code validation):** **pylint** (exit 0, **10.00/10**), PowerShell parse/BOM, `validate-score`, and any other required CodeValidation checks.  
   - **Domain A (security):** Bandit, PSScriptAnalyzer Error, **Gitleaks**, and any other required Security checks.  
3. **No partial renewal.** Re-running a subset of tools (only pylint, only Bandit, only Gitleaks, or only one domain) and writing a new cert pair is a **policy violation**. Both domains must be freshly executed in the **same** renewal run.  
4. **Completion rule.** Work that made certification stale is **not complete** until the harness finishes with `OverallPass = true` (or the change is reverted). Missing required tools **fail** the run; they do not exempt renewal.  
5. **Harness path.** Preferred renewal command from repo root: `.\certification\Invoke-Certification.ps1`. Manual hand-edits of a prior cert without re-running tools are **invalid**.  
6. **Narrow docs-only exception.** Pure documentation edits that cannot affect gate results may skip renewal; if unsure, renew.  
7. **Outputs.** Leave `last_certification.*` **untracked**. Never stage or commit them.

#### Certification rule

Regenerate `last_certification.json` and `.txt` only by running the **full** suite per [Certification renewal enforcement](#certification-renewal-enforcement-required). Missing required tools yield `OverallPass = false`, not a silent skip.

---

## Versioning and change control

Every change follows these rules. They distinguish **three version surfaces**, require a project **CHANGELOG**, and keep a durable **kit baseline** so standards upgrades remain trackable.

### Three version surfaces

| Surface | What it is | Authority |
|---------|------------|-----------|
| **Kit version** | Semver of the Repository Standards Kit | Upstream [CHANGELOG under `## repo-kit`](https://github.com/shainemeister/repo-kit/blob/main/CHANGELOG.md); recorded here in [Kit baseline](#kit-baseline) |
| **Project / package version** | Toolkit product semver | `kpi_modules.__version__`, `ExcelToolkitVersion`, and root [CHANGELOG.md](./CHANGELOG.md) |
| **Document version** | Per-document frontmatter `version` + `last_updated` | That document only—not automatically equal to package or kit version |

| Surface | When to bump |
|---------|----------------|
| `kpi_modules.__version__` | CLI contract, scoring behavior, or stable output column names change |
| `ExcelToolkitVersion` (module) | CLI verbs/options/JSON shapes or export behavior change |
| Document frontmatter `version` + `last_updated` | That document’s guidance or contract changes |
| Methodology **Document history** table | Material formula or interpretation changes |
| Project `CHANGELOG.md` | See [Mandatory project CHANGELOG](#mandatory-project-changelog) |
| Kit baseline (adopted kit version) | On first adopt and every kit upgrade — see [Kit baseline](#kit-baseline) |

### Mandatory project CHANGELOG

This repository **must** maintain a root **`CHANGELOG.md`**.

| Rule | Detail |
|------|--------|
| **Required file** | Root [CHANGELOG.md](./CHANGELOG.md) — listed in the [authority map](#authority-map) and [root hygiene](#root-hygiene) |
| **Format** | [Keep a Changelog](https://keepachangelog.com/) categories; dates ISO 8601 (`YYYY-MM-DD`) |
| **Structure** | `## workqueue-data-processor` → dated `### [X.Y.Z] - YYYY-MM-DD` → `#### Added` / `#### Changed` / … |
| **Categories** | Use as needed: **Added**, **Changed**, **Deprecated**, **Removed**, **Fixed**, **Security** |
| **Same change set** | Release-worthy behavior or contract changes include the CHANGELOG entry with the code/docs that ship them |

There is **no Unreleased section**. Record each change under the `### [X.Y.Z]` version section that ships it.

**When a CHANGELOG entry is required**

| Change | CHANGELOG |
|--------|-----------|
| Package / public contract version bump | **Required** — note toolkit and version under the repository H2 section that ships it |
| Behavior, CLI, schema, security-model change | **Required** under the version section that ships the change |
| Kit adoption or kit upgrade | **Required** (note kit version; do **not** paste kit release history) |
| Security fix | **Required** |
| Pure typo or non-contract wording | Optional; **must not** ship a package version bump without a matching CHANGELOG note |

Do not ship a package version tag or release without a matching CHANGELOG entry for that release.

### Kit baseline

Durable record of **which kit version** this project adopted and **where upgrades come from**.

| Field | Value |
|-------|--------|
| Adopted kit version | **1.2.1** |
| Adopted on | **2026-07-28** |
| Kit source | https://github.com/shainemeister/repo-kit |

**Kit source** is always **https://github.com/shainemeister/repo-kit** for this standards kit. Update **Adopted kit version** and **Adopted on** on every kit upgrade.

### Upgrading the kit (post-initiation)

1. Read this project’s [Kit baseline](#kit-baseline) (**Adopted kit version**, **Kit source**). Open **Kit source** (canonical for this kit: **https://github.com/shainemeister/repo-kit**) and read `CHANGELOG.md` (and releases if present).  
2. Compare this file’s **Adopted kit version** to the latest kit version under `## repo-kit`.  
3. **Read only** the kit CHANGELOG entries since the current Adopted kit version; merge only what you need; **never** copy the full kit history into the project CHANGELOG.  
4. Copy or merge wanted pieces (`RULES.md` policy sections, `MARKDOWN-STANDARD.md`, `templates/`, pylintrc patterns, `.gitignore`). **Preserve** this project’s authority-map paths, verification commands, architecture, data, and security tables.  
5. Update **Adopted kit version** and **Adopted on**; keep Kit source unchanged.  
6. Add a project CHANGELOG entry (e.g. under Changed: “Upgraded repo-kit baseline to X.Y.Z”).  
7. Re-check authority map, verification table, and any new kit contracts.  
8. Do **not** leave a permanent root `SETUP.md` after initiation.

No automation is required—policy and the [contributor checklist](#contributor-checklist) enforce the practice. Upstream upgrade prompt: [repo-kit README — Upgrade repo-kit](https://github.com/shainemeister/repo-kit#upgrade-repo-kit).

### Consistency rules

1. Frontmatter `version` and the in-doc status line must **match** when both exist.  
2. Toolkit docs that cite a product version must stay aligned with the code version they describe.  
3. Prefer **backward-compatible** additions (new columns, new optional flags) over silent renames. Breaking changes require explicit notes in CLI guide, methodology history, and CHANGELOG.  
4. Concept doc (V2/V3) may advance design without implementing code; label implementation status clearly.  
5. Behavior or contract changes, their **canonical** docs, the appropriate **version bump**, and the **CHANGELOG** entry belong in the **same change set** when the change is release-worthy.  
6. Kit version and package version are **independent**. Adopting a new kit does not force a product version bump unless product behavior also changes.

---

## Git rules

### What to track

| Track | Do not track |
|-------|----------------|
| Source (`.py`, `.ps1`, `.psm1`, `.cmd`) | `output\` |
| Schema, sample data, fixtures | `__pycache__\`, `*.pyc` |
| `import\` synthetic / non-PHI inputs | Real PHI/PII extracts under `import\` (or anywhere) |
| Docs, templates, `.gitignore`, style configs | `.venv\`, `venv\`, `.env` |
| Diagnostics folder **README** files | Secrets, IDE-only folders already ignored |
| | `kpi-analytics\diagnostics\last_diagnostics.*` (regenerable package diagnostics) |
| | `excel-toolkit\diagnostics\last_diagnostics.*` (regenerable package diagnostics) |
| | `certification\last_certification.*` (regenerable formal cert outputs, if folder exists) |

Respect [.gitignore](./.gitignore). Do not force-add ignored generated artifacts “for convenience.”

### Commits and history

1. **Review before commit:** `git status` and `git diff`. Confirm no accidental large CSVs, workbooks, credentials, or regenerable diagnostics certificates.  
2. **Small, focused commits** preferred over mixed unrelated changes—one logical concern / one authority-map surface when practical. Prefer a **short stack** over a single mixed mega-commit.  
3. **Messages** follow [Commit message format](#commit-message-format) below.  
4. **Do not rewrite published shared history** (`push --force` to a shared default branch) without explicit coordination.  
5. **Branches (recommended):** `feature/…`, `fix/…`, `docs/…` when work is non-trivial.  
6. **Contract-breaking changes:** prefer review (PR) when a remote exists; call out migration notes in the commit or PR body.  
7. **No secrets in history.** If leaked, rotate credentials and treat history cleanup as an incident—not a casual amend.

### Commit message format

**Principle:** The commit subject (and body, when present) should remain understandable **years later** when searching history—name the real surface and intent, not a temporary mood.

Use a **Conventional Commits–style** subject so history stays scannable and aligned with how this repo documents work.

```text
<type>(<scope>): <imperative summary>
```

| Part | Rule |
|------|------|
| **type** | One of the types in the table below |
| **scope** | Toolkit or area: `kpi-analytics`, `excel-toolkit`, or omit for repo-wide files (`RULES.md`, `FILE-CATALOG.md`, root README, schema, CHANGELOG) |
| **summary** | Imperative mood, specific, ≤ ~72 characters; no trailing period |
| **body** (optional) | For non-trivial commits: **why** the change matters and any **migration** notes; link to the canonical doc if non-obvious. Tiny one-line docs fixes may omit a body |

| type | Use when |
|------|----------|
| `feat` | User-visible behavior: new CLI verb/flag, scoring output, export capability, diagnostics gate |
| `fix` | Correct wrong behavior without changing the intended contract |
| `docs` | Documentation only (README, CLI-GUIDE, methodology, security, catalog, templates, CHANGELOG wording) |
| `chore` | Version bumps, `.gitignore`, packaging/layout hygiene with no product behavior change |
| `refactor` | Internal structure only; same CLI/score/export contracts |
| `test` | Fixtures, validation harness, sample-test probes (no product API change) |

#### Scope conventions

| Context | Preferred scopes | Notes |
|---------|------------------|--------|
| **Toolkits** | `kpi-analytics`, `excel-toolkit` | Use when the change is limited to that surface |
| **Standards / policy** | omit or name the file area | Root-wide RULES, MARKDOWN-STANDARD, CHANGELOG, catalog |
| **Omit scope** | — | Root-wide files with no single toolkit owner |

Scopes are advisory: consistency within this repo matters more than matching any external table exactly.

#### Optional footers

Useful when needed; **not** mandatory (except the AI disclosure block, which is **required when applicable**):

| Footer | Use when |
|--------|----------|
| `BREAKING CHANGE: <description>` | Public contract breaks; describe migration |
| `Refs: <issue-or-doc>` | Link a tracker item or canonical doc |
| `Co-authored-by: Name <email>` | Shared authorship |
| AI disclosure block (`Assisted-by` / `Compliance` / `Instructed-by`) | **Required** when AI meaningfully assisted; `Assisted-by` = actual make/model; `Instructed-by` = `git config user.name`; see [AI-assisted commits](#ai-assisted-commits-required-disclosure) |

#### AI-assisted commits (required disclosure)

When an AI system meaningfully assists with the **change itself** (code, docs, configuration, or the commit message), the commit **must** include the following footer block. Pure human-only commits omit it.

| Trailer | Required content |
|---------|------------------|
| `Assisted-by:` | AI make / model (and optional tool) that assisted **this** commit — fill at commit time |
| `Compliance:` | Explicit reference to this file (`RULES.md`) |
| `Instructed-by:` | Directing human — **value of** `git config user.name` for the committer |

**Template form** (copy structure; resolve fields at commit time):

```text
Assisted-by: <AI make / model>
Compliance: RULES.md
Instructed-by: <git config user.name>
```

**How to resolve fields**

| Field | Resolution |
|-------|------------|
| `Assisted-by` | Name the AI make/model/tool that actually performed the work for this commit (examples below). Do not hardcode a vendor from documentation. |
| `Instructed-by` | Run `git config user.name` and use that exact string. If unset, configure it before committing so disclosure matches Git author identity. |

```text
git config user.name
```

**Example values for `Assisted-by`** (use the one that actually did the work):

| Situation | Example value |
|-----------|----------------|
| xAI Grok assistant | `Grok (xAI)` |
| Anthropic Claude | `Claude 4 Sonnet` (or the exact model name used) |
| GitHub Copilot | `GitHub Copilot` |
| Cursor agent | `Cursor Agent` |
| Other | Name the primary assistant for this commit |

**Rules**

1. Place the three lines at the end of the commit message (after any body or other footers).
2. **`Assisted-by` is dynamic:** use the real AI make/model (and tool if useful) that performed the work for **this** commit. Never treat a single brand in the docs as the only allowed value.
3. **`Instructed-by` is dynamic:** set it to the output of `git config user.name`. Never omit it; do not invent a different name unless it is also the configured Git user for that commit.
4. The presence of this block asserts that the human (Git-configured committer) reviewed the result and that the change follows the contracts in this RULES.md.
5. Do **not** put the AI disclosure in the subject line. Keep the subject focused on the change.

**When it is required**

| Situation | Disclosure |
|-----------|------------|
| AI wrote or substantially edited product code, docs, or config | **Required** |
| AI drafted the commit message itself | **Required** |
| AI only suggested a one-line fix that the human rewrote | Optional (prefer to include) |
| Pure human work | Omit |

**Good example** (illustrative AI only; `Instructed-by` must match `git config user.name` on the machine that commits — `Shaine Meister` is the current local Git user name when this policy shipped):

```text
docs: upgrade repo-kit baseline to 1.1.2 with AI disclosure rules

Add Assisted-by / Compliance / Instructed-by trailers so AI
participation is transparent and auditable years later.

Assisted-by: Grok (xAI)
Compliance: RULES.md
Instructed-by: Shaine Meister
```

#### Examples (match this voice)

**Good:**

```text
feat(kpi-analytics): add enterprise diagnostics module and gate helpers
feat(kpi-analytics): wire diagnostics command and operational gate in CLI
chore(kpi-analytics): bump package version to 1.6.0
docs(kpi-analytics): document diagnostics command, gate flags, and CLI contract
docs: catalog diagnostics module and diagnostics folder
chore: gitignore enterprise diagnostics certificate files
fix(excel-toolkit): retry Excel Quit before warning the user
docs: adopt repo-kit 1.1.1 baseline and add CHANGELOG
docs: upgrade repo-kit baseline to 1.1.2 with AI disclosure rules
docs: upgrade repo-kit baseline to 1.1.7 with security modularity
docs: upgrade repo-kit baseline to 1.2.0 with inventory and certification
docs: upgrade repo-kit baseline to 1.2.1 with kit-source upgrade path
```

**Bad → good:**

| Avoid | Prefer |
|-------|--------|
| `update stuff` | `docs(kpi-analytics): document validate-score exit codes` |
| `wip` | Finish then commit a clear subject |
| `fix bugs` | `fix(excel-toolkit): handle missing CSV path without crash` |
| `feat: updates` (docs-only staged) | `docs: …` — do not use `feat` for documentation-only changes |

### Documentation consistency in commits

Commit messages and **what is staged** must stay consistent with the documentation authority map.

| Situation | Commit practice |
|-----------|-----------------|
| Behavior / CLI / scoring / security model changes | Update the **canonical** doc in the **same change set** (same commit or consecutive commits in the same branch/PR). Do not ship code that leaves CLI-GUIDE, methodology, or ENTERPRISE-SECURITY stale. |
| Prefer readability of history | Prefer **one logical surface per commit** (e.g. one module, one doc file, or one tightly coupled pair such as version bump alone). Avoid “mega-commits” that mix unrelated toolkits. |
| Code + matching docs for one feature | Either (a) one commit that includes code **and** its canonical doc updates, or (b) a short stack: code → version → each doc file, with subjects that name the same feature. |
| Path add/remove/rename | Include [FILE-CATALOG.md](./FILE-CATALOG.md) in the same change set; subject may be `docs: catalog …` if catalog-only, or mention catalog in the body if bundled. |
| Toolkit version bump | Subject uses `chore(<toolkit>): bump … to X.Y.Z`. Docs that cite the product version get `docs(<toolkit>): …` commits (or the same commit) so cited versions stay aligned. Include CHANGELOG. |
| Docs-only edits | Use `docs` / `docs(<scope>)`. Do not use `feat` for documentation. |
| Message content | Subject describes **what changed in the staged files**, not a vague “updates”. Prefer the same nouns as the docs (`diagnostics`, `kpi_q_*`, `validate-score`, `CLI-GUIDE`). |

**Pre-commit message check:**

1. Does the subject type match the staged content (`docs` only if no product code/config behavior)?  
2. Is this **one logical surface** (or an intentional code+docs pair for the same feature)?  
3. If CLI verbs, flags, exit codes, or JSON shapes changed, is [CLI-GUIDE](./kpi-analytics/CLI-GUIDE.md) / [excel-toolkit CLI-GUIDE](./excel-toolkit/CLI-GUIDE.md) updated in this change set?  
4. If trust/execution model changed, is the matching ENTERPRISE-SECURITY updated?  
5. If formulas or `v1_*` / `kpi_q_*` contracts changed, are methodology + fixtures updated?  
6. If product code or gate config changed: will the **full** certification harness pass (pylint + security + Gitleaks)?  
7. Is partial recert avoided (no security-only or pylint-only cert rewrite)?  
8. If release-worthy: is [CHANGELOG.md](./CHANGELOG.md) updated?  
9. Would a reviewer find the subject by searching the feature name used in the README?  
10. Would this subject still make sense **two years** from now without the PR description?  
11. If AI assisted: are `Assisted-by` / `Compliance` / `Instructed-by` present? Does `Assisted-by` name the AI that did the work? Does `Instructed-by` match `git config user.name`?

### Suggested commit workflow

```bat
git status
git diff
rem Stage one focused surface (or one logical pair), then:
git add path\to\file
git commit -m "type(scope): imperative summary of this file or surface"
git status
```

Git accepts `/` in paths on Windows as well. For a multi-file feature, a typical stack is: implementation → package version → docs (CLI, README, security, methodology as needed) → CHANGELOG → FILE-CATALOG / RULES if those inventories or policies changed.

### Remotes

A remote is optional. When one exists, do not assume write access to `main`/`master` without team convention. Tags for toolkit releases are optional but should match `__version__` / `ExcelToolkitVersion` if used.

---

## Verification before ship

| Change type | Minimum verification |
|-------------|----------------------|
| **Product code, gate config, or inventory** | **Full certification package:** `.\certification\Invoke-Certification.ps1` (Domain B **and** Domain A, including pylint + Bandit + PSSA + Gitleaks + validate-score). Confirm `OverallPass`; do not stage outputs. See [renewal enforcement](#certification-renewal-enforcement-required) |
| KPI scoring, columns, config | Covered by harness `validate-score`; may also run `kpi-analytics.cmd validate-score` alone while iterating |
| KPI environment / packaging | `kpi-analytics.cmd probe` |
| KPI enterprise first-run / gate | `kpi-analytics.cmd diagnostics` (certificate under `diagnostics\`) — **not** a substitute for certification |
| Excel COM / export path | `excel-toolkit.cmd probe` and/or `Test-ExcelCom.ps1 -DryRun` |
| Excel enterprise first-run / gate | `excel-toolkit.cmd diagnostics` — **not** a substitute for certification |
| Enterprise execution risk | `excel-toolkit\sample-test\` probes as appropriate |
| Schema or sample data | Headers match schema; score and/or export still consume sample paths |
| Docs only (no product/gate impact) | [Author checklist](./MARKDOWN-STANDARD.md#author-checklist); relative links resolve; certification renewal optional per narrow exception |
| New/removed source files | [FILE-CATALOG.md](./FILE-CATALOG.md) updated; [language surface inventory](#language-surface-inventory) if languages added/removed |
| Release-worthy / version bump | [CHANGELOG.md](./CHANGELOG.md) entry under the version section that ships the change |

Individual Domain A/B commands remain documented in [certification/README.md](./certification/README.md). For ship/complete after code changes, use the **full harness**—not a subset.

### Completion rule

Do **not** mark a change complete, and do **not** claim ship readiness, if any **declared** Domain B (code validation / style) or Domain A (security / SAST / secrets) gate was skipped or failed. **Gitleaks is required.** Missing required developer tools is a **failed** gate, not a skip.

When product code, certification gate definitions, or inventory Status changed: certification is **stale** until `.\certification\Invoke-Certification.ps1` completes with `OverallPass = true`. Partial renewal (security-only or pylint-only) does **not** satisfy completion. Package diagnostics gates remain required for scoring/export paths as before; they do not replace Domain A/B tools or formal certification.

### Before marking work complete

Ordered steps for humans and AI agents:

1. Read **language surface inventory** (**Declared:** Python, PowerShell, **Secrets**).  
2. If product code, gate config, or inventory changed: run **full** certification (`.\certification\Invoke-Certification.ps1`) — this **must** re-run Domain B (including **pylint**) **and** Domain A (including **Gitleaks**) together. Confirm `OverallPass`; leave outputs unstaged.  
3. Otherwise (narrow docs-only): run any applicable lightweight checks; renewal optional per exception.  
4. Run package probes/diagnostics as needed for product paths (separate from certification).  
5. Update canonical docs / [CHANGELOG.md](./CHANGELOG.md) per the authority map.  
6. Only then state the task is complete.

---

## Maintenance cadence

| Trigger | Action |
|---------|--------|
| Every source path add/remove/rename | Update [FILE-CATALOG.md](./FILE-CATALOG.md) |
| Language surface added or removed | Update [language surface inventory](#language-surface-inventory) + `certification/checks.json` / README |
| Every release-worthy toolkit behavior change | Bump code version; refresh CLI guide and status blocks; update [CHANGELOG.md](./CHANGELOG.md) |
| Every product code edit (`kpi_modules` or excel-toolkit product scripts) | Run **full** [certification harness](./certification/Invoke-Certification.ps1) (pylint + security + Gitleaks); do not partial-recert |
| Security-relevant change | Update matching ENTERPRISE-SECURITY; full certification renewal; CHANGELOG entry |
| Formal certification | Always renew via full suite after qualifying changes; never commit outputs |
| Fixture failure after intentional math change | Refresh expected JSON only with methodology note |
| Stale `last_updated` on heavily edited docs | Set ISO date when merging |
| Kit upgrade available upstream | Follow [Upgrading the kit](#upgrading-the-kit-post-initiation); update baseline + project CHANGELOG |

---

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| `pip install` “just this once” in **product** kpi-analytics | Stdlib solution or redesign the requirement |
| Shipping pylint as a product runtime dependency | Keep pylint developer-only; product remains stdlib-only |
| Skipping pylint after Python edits | Run `py -3.13 -m pylint kpi_modules` from `kpi-analytics\` |
| Force-killing Excel to “clean up” | Quit → wait → one retry → warn user |
| Committing `output\wq_scored*.csv` or `.xlsx` | Document regenerate commands in README / catalog |
| Committing `last_diagnostics.json` / `.txt` | Leave regenerable; only track diagnostics `README.md` |
| Silent field or `v1_*` / `kpi_q_*` rename | Coordinated contract bump + fixtures + docs |
| Long docs without Summary | MARKDOWN-STANDARD order |
| Duplicating security matrices into README | Link to ENTERPRISE-SECURITY |
| Merging Excel and Python into one process | Keep runtimes separate; compose via files/CLI |
| Absolute machine-only paths as the only example | Placeholder + one repo-relative example |
| Orphan files missing from the catalog | Update FILE-CATALOG in the same change |
| Vague commits (`update stuff`, `wip`) | Conventional `type(scope):` subject naming the real surface |
| Code without CLI/methodology/security docs | Same change set as the canonical doc per authority map |
| `feat` commit that only edits markdown | Use `docs` / `docs(scope)` |
| No project `CHANGELOG.md` | Maintain root CHANGELOG (repository H2 → version H3 → category H4) |
| Package version bump without CHANGELOG note | Add matching CHANGELOG entry in the same change set |
| Kit upgrade with no baseline or CHANGELOG note | Update Adopted kit version/date and project CHANGELOG |
| Putting kit release history into project CHANGELOG | Keep kit version only in the [Kit baseline](#kit-baseline) table |
| Inventing an alternate kit source URL | Use https://github.com/shainemeister/repo-kit |
| Leaving SETUP.md forever at root after adoption | Do not re-add SETUP; keep Kit baseline instead |
| Empty security doc for a surface with no execution/network/privilege/secrets | Omit the file and the authority-map row ([modularity](#security-documentation-modularity)) |
| Pasting the full multi-language SAST table into this repo | Declare only tools for languages we ship ([language surface inventory](#language-surface-inventory)) |
| Claiming complete while skipping a **declared** style or SAST gate | Run inventory gates / full harness; see [Completion rule](#completion-rule) |
| Skipping Gitleaks or treating Secrets as opt-in | Secrets is **Declared**; Gitleaks required on every renewal |
| Partial recert (only pylint, only Bandit, only Gitleaks) | Always run full `Invoke-Certification.ps1` after code changes |
| Hand-editing `last_certification.*` without re-running tools | Invalid; only harness-produced outputs count |
| Claiming complete with a pre-change certificate | Renew after product/code/gate/inventory changes |
| Shipping Bandit / PSScriptAnalyzer / Gitleaks as product runtime deps | Keep security / SAST tools developer-only |
| Committing `certification/last_certification.*` | Gitignore regenerable cert outputs; regenerate locally |
| Treating certification as a product launcher / diagnostics gate | Certification attests **source tree** policy only; package diagnostics stay under each toolkit |
| Empty language inventory while shipping product code | Keep inventory filled for Python, PowerShell, and Secrets |
| Merging package diagnostics into `certification/` | Keep `diagnostics/` for machine readiness; `certification/` for source-tree self-attestation only |

---

## Contributor checklist

Before you commit or share a change:

- [ ] Behavior matches the **canonical** doc for that surface (CLI / methodology / security / root README when the landing workflow changed)  
- [ ] [FILE-CATALOG.md](./FILE-CATALOG.md) updated if paths changed  
- [ ] [Language surface inventory](#language-surface-inventory) still matches languages the repo ships  
- [ ] Versions and `last_updated` bumped where contracts changed  
- [ ] **CHANGELOG.md** updated when required (release-worthy behavior, version bump, security, kit adopt/upgrade)  
- [ ] Required **verification** from the table above has been run ([Completion rule](#completion-rule))  
- [ ] If product code, gate config, or inventory changed: **full** certification harness passed (`OverallPass` true) — includes **pylint**, Bandit, PSScriptAnalyzer, **Gitleaks**, validate-score  
- [ ] No partial recert; outputs not staged  
- [ ] No secrets, PHI, `output\`, caches, diagnostics certificates, or `last_certification.*` staged  
- [ ] Markdown follows [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) when docs were edited  
- [ ] Commit message uses `type(scope):` format and matches the staged files  
- [ ] Subject would still make sense years later; one logical surface preferred  
- [ ] Canonical docs for any behavior change are in the same change set  
- [ ] If kit pieces changed: [Kit baseline](#kit-baseline) version/date updated and CHANGELOG notes the upgrade  
- [ ] If AI assisted: commit includes `Assisted-by` / `Compliance` / `Instructed-by` (`Assisted-by` = actual make/model; `Instructed-by` = `git config user.name`)  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial maintenance rules: authority map, docs, format, architecture, data, security, versioning, git, verification |
| 1.1.0 | Git commit message format, documentation-consistency rules, and commit workflow |
| 1.2.0 | Python PEP-8 style gate via pylint (`.pylintrc`); verification and checklist requirements |
| 1.2.1 | Output collision rule (unique suffix by default); workflow composition via Excel menu → kpi-analytics |
| 1.2.2 | End-user pointer in lead; dual diagnostics certificates (KPI + Excel) in authority map / git rules; clearer README role |
| 1.3.0 | Aligned with repo-kit **1.1.1**: root hygiene, mandatory CHANGELOG, three version surfaces, kit baseline + upgrade path, non-Python style gates, stronger checklists/anti-patterns |
| 1.3.1 | Aligned with repo-kit **1.1.2**: required AI-assisted commit disclosure footers (`Assisted-by` / `Compliance` / `Instructed-by`); pre-commit and contributor checklist updates |
| 1.4.0 | Aligned with repo-kit **1.1.7**: security documentation modularity; advisory language-scoped SAST gates (Python/PowerShell/secrets only); upgrade procedure CHANGELOG discipline (read only since baseline; never paste full kit history); kit baseline **1.1.7** |
| 1.5.0 | Aligned with repo-kit **1.2.0**: language surface inventory (Python + PowerShell **Declared**); SAST **required when declared** (Bandit, PSScriptAnalyzer); Secrets/Gitleaks **opt-in only**; security & code-validation certification schema (optional `certification/` deferred); completion rule + before-complete steps; kit baseline **1.2.0** |
| 1.5.1 | Kit reflection pass: inventory Status column (Declared vs Not declared); Gitleaks explicitly non-blocking; verification/checklist/anti-pattern alignment |
| 1.6.0 | Certification **maintained**: full package under `certification/`; Secrets/Gitleaks **Declared** and required; [certification renewal enforcement](#certification-renewal-enforcement-required) (full Domain A+B every renewal after code changes; no partial recert); operational commands live in certification; verification/checklist/anti-patterns aligned |
| 1.6.1 | Certification quality hardening: PSSA product-only scope (align with parse/BOM; `sample-test` excluded); dual-mode Gitleaks (workdir + git history); declarative pylint `RequirePylintScore`; cert schema `PackageVersions` / `DurationMs` / `Message`; root **MIT** `LICENSE` |
| 1.6.2 | Aligned with repo-kit **1.2.1**: upgrade procedure starts from Kit baseline (Adopted kit version + Kit source); upstream prompt deep link → `#upgrade-repo-kit`; kit baseline **1.2.1** |
