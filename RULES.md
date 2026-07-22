---
title: Repository Maintenance Rules
description: Fundamental rules for documenting, changing, verifying, and versioning this repository.
version: "1.2.1"
status: current
audience:
  - developers
  - analysts
  - security
doc_type: other
related:
  - README.md
  - FILE-CATALOG.md
  - MARKDOWN-STANDARD.md
  - excel-toolkit/ENTERPRISE-SECURITY.md
  - kpi-analytics/ENTERPRISE-SECURITY.md
  - kpi-analytics/.pylintrc
last_updated: "2026-07-22"
---

# Repository Maintenance Rules

Fundamental rules for maintaining **workqueue-data-processor** as a professional, auditable dual-toolkit repository. These rules govern documentation, code boundaries, data contracts, git hygiene, and verification—not product tutorials.

**Document version:** 1.2.1  

**Related:** [README.md](./README.md) · [FILE-CATALOG.md](./FILE-CATALOG.md) · [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) · [kpi-analytics/.pylintrc](./kpi-analytics/.pylintrc)

---

## Summary

This repository is a **Work Queue data contract** plus two independent toolkits:

| Toolkit | Runtime | Role |
|---------|---------|------|
| `excel-toolkit\` | Windows PowerShell 5.1 + Excel COM | CSV → formatted workbook |
| `kpi-analytics\` | Python **3.13** stdlib only | CSV → priority scores + RCM KPI Q columns |

**RULES.md** is the maintenance policy. Detailed contracts live elsewhere (CLI guides, methodology, security notes). When those contracts change, update the **canonical** file in the same change set—do not leave docs, fixtures, or versions stale.

| Must | Must not |
|------|----------|
| Update canonical docs with behavior changes | Commit `output\`, caches, secrets, or real PHI |
| Use conventional commit messages that match staged files | Mix unrelated toolkits or leave CLI/security docs stale |
| Keep toolkits independent at the runtime layer | Add pip packages or network clients to **product** code |
| Run **pylint** on `kpi_modules` after Python product changes | Treat pylint as a runtime install requirement for end users |
| Preserve explainable score / dual KPI attribution | Force-kill Excel or permanently alter ExecutionPolicy |
| Verify before sharing scoring or COM changes | Silently rename schema fields or scored columns |

---

## Contents

1. [Summary](#summary)
2. [Authority map](#authority-map)
3. [Documentation rules](#documentation-rules)
4. [Formatting and style](#formatting-and-style) (includes [Python style gate (pylint)](#python-style-gate-pylint))
5. [Architecture and boundaries](#architecture-and-boundaries)
6. [Data and schema rules](#data-and-schema-rules)
7. [Security and enterprise constraints](#security-and-enterprise-constraints)
8. [Versioning and change control](#versioning-and-change-control)
9. [Git rules](#git-rules)
10. [Verification before ship](#verification-before-ship)
11. [Maintenance cadence](#maintenance-cadence)
12. [Anti-patterns](#anti-patterns)
13. [Contributor checklist](#contributor-checklist)
14. [Document history](#document-history)

---

## Authority map

Update the **owner** document for a change. Cross-link; do not duplicate full contracts.

| Concern | Canonical source |
|---------|------------------|
| Repo purpose and quick start | [README.md](./README.md) |
| Path-level file inventory | [FILE-CATALOG.md](./FILE-CATALOG.md) |
| Markdown structure, frontmatter, author checklist | [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) · [templates/](./templates/) |
| Maintenance policy (this file) | [RULES.md](./RULES.md) |
| Excel CLI (verbs, exit codes, JSON) | [excel-toolkit/CLI-GUIDE.md](./excel-toolkit/CLI-GUIDE.md) |
| KPI CLI (verbs, exit codes, JSON) | [kpi-analytics/CLI-GUIDE.md](./kpi-analytics/CLI-GUIDE.md) |
| Priority V1 + `kpi_q_*` implementation | [kpi-analytics/SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md) |
| RCM dual-attribution theory | [kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md](./kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md) |
| Priority design roadmap (V1–V3) | [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) |
| Excel enterprise / COM posture | [excel-toolkit/ENTERPRISE-SECURITY.md](./excel-toolkit/ENTERPRISE-SECURITY.md) |
| KPI enterprise / offline posture | [kpi-analytics/ENTERPRISE-SECURITY.md](./kpi-analytics/ENTERPRISE-SECURITY.md) |
| Field definitions | [wq_schema.json](./wq_schema.json) (CSV twin: [wq_schema.csv](./wq_schema.csv)) |
| Sample fact rows | [wq_data.csv](./wq_data.csv) |
| Default score config | [kpi-analytics/kpi_modules/config_default.json](./kpi-analytics/kpi_modules/config_default.json) |
| Golden tests | [kpi-analytics/fixtures/](./kpi-analytics/fixtures/) |
| KPI Python style / PEP-8 gate | [kpi-analytics/.pylintrc](./kpi-analytics/.pylintrc) (dev tooling only) |

**Rule:** Adding, removing, or renaming intentional source files requires a same-change update to [FILE-CATALOG.md](./FILE-CATALOG.md).

---

## Documentation rules

1. **Substantial documents** follow [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md): YAML frontmatter, single H1, lead, Summary before Contents, body, history when versioned.  
2. **New docs** start from [templates/](./templates/); leave no unresolved `{{PLACEHOLDERS}}`.  
3. **Behavior change ⇒ doc change** in the same commit or PR:  
   - CLI verbs, flags, exit codes, JSON shapes → matching `CLI-GUIDE.md`  
   - Scoring formulas, output columns, validation → `SCORE-METHODOLOGY.md` (+ fixtures if contract shifts)  
   - Trust boundary or execution model → matching `ENTERPRISE-SECURITY.md`  
4. **Prefer link + short summary** over pasting another document in full.  
5. **README** stays an overview; deep contracts stay in toolkit docs.  
6. **Status honesty:** set frontmatter `status` to `draft` / `current` / `deprecated` accurately.

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
| PowerShell | Target **5.1**; no PowerShell 7-only syntax in `excel-toolkit\` |
| Python | Target **3.13**; **standard library only** in product `kpi-analytics\` code |
| Python style | PEP-8 via **pylint** against [kpi-analytics/.pylintrc](./kpi-analytics/.pylintrc) — see [Python style gate (pylint)](#python-style-gate-pylint) |
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

If pylint is not installed on a developer machine, install it into the **developer environment** (user/global Python), never into a product `requirements.txt` or toolkit path meant for locked-down PCs.

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

---

## Versioning and change control

| Surface | When to bump |
|---------|----------------|
| `kpi_modules.__version__` | CLI contract, scoring behavior, or stable output column names change |
| `ExcelToolkitVersion` (module) | CLI verbs/options/JSON shapes or export behavior change |
| Document frontmatter `version` + `last_updated` | That document’s guidance or contract changes |
| Methodology **Document history** table | Material formula or interpretation changes |

Additional rules:

1. Frontmatter `version` and the in-doc status line must **match** when both exist.  
2. Toolkit docs that cite a product version must stay aligned with the code version they describe.  
3. Prefer **backward-compatible** additions (new columns, new optional flags) over silent renames. Breaking changes require explicit notes in CLI guide and methodology history.  
4. Concept doc (V2/V3) may advance design without implementing code; label implementation status clearly.

---

## Git rules

### What to track

| Track | Do not track |
|-------|----------------|
| Source (`.py`, `.ps1`, `.psm1`, `.cmd`) | `output\` |
| Schema, sample data, fixtures | `__pycache__\`, `*.pyc` |
| `import\` synthetic / non-PHI inputs | Real PHI/PII extracts under `import\` (or anywhere) |
| Docs, templates, `.gitignore` | `.venv\`, `venv\`, `.env` |
| | Secrets, IDE-only folders already ignored |
| | `kpi-analytics\diagnostics\last_diagnostics.*` (regenerable certificates) |

Respect [.gitignore](./.gitignore). Do not force-add ignored generated artifacts “for convenience.”

### Commits and history

1. **Review before commit:** `git status` and `git diff`. Confirm no accidental large CSVs, workbooks, credentials, or regenerable diagnostics certificates.  
2. **Small, focused commits** preferred over mixed unrelated changes.  
3. **Messages** follow [Commit message format](#commit-message-format) below.  
4. **Do not rewrite published shared history** (`push --force` to a shared default branch) without explicit coordination.  
5. **Branches (recommended):** `feature/…`, `fix/…`, `docs/…` when work is non-trivial.  
6. **Contract-breaking changes:** prefer review (PR) when a remote exists; call out migration notes in the commit or PR body.  
7. **No secrets in history.** If leaked, rotate credentials and treat history cleanup as an incident—not a casual amend.

### Commit message format

Use a **Conventional Commits–style** subject so history stays scannable and aligned with how this repo documents work.

```text
<type>(<scope>): <imperative summary>
```

| Part | Rule |
|------|------|
| **type** | One of the types in the table below |
| **scope** | Toolkit or area: `kpi-analytics`, `excel-toolkit`, or omit for repo-wide files (`RULES.md`, `FILE-CATALOG.md`, root README, schema) |
| **summary** | Imperative mood, specific, ≤ ~72 characters; no trailing period |
| **body** (optional) | Why the change matters; migration notes; link to canonical doc if non-obvious |

| type | Use when |
|------|----------|
| `feat` | User-visible behavior: new CLI verb/flag, scoring output, export capability, diagnostics gate |
| `fix` | Correct wrong behavior without changing the intended contract |
| `docs` | Documentation only (README, CLI-GUIDE, methodology, security, catalog, templates) |
| `chore` | Version bumps, `.gitignore`, packaging/layout hygiene with no product behavior change |
| `refactor` | Internal structure only; same CLI/score/export contracts |
| `test` | Fixtures, validation harness, sample-test probes (no product API change) |

**Examples (match this voice):**

```text
feat(kpi-analytics): add enterprise diagnostics module and gate helpers
feat(kpi-analytics): wire diagnostics command and operational gate in CLI
chore(kpi-analytics): bump package version to 1.6.0
docs(kpi-analytics): document diagnostics command, gate flags, and CLI contract
docs: catalog diagnostics module and diagnostics folder
chore: gitignore enterprise diagnostics certificate files
fix(excel-toolkit): retry Excel Quit before warning the user
```

### Documentation consistency in commits

Commit messages and **what is staged** must stay consistent with the documentation authority map.

| Situation | Commit practice |
|-----------|-----------------|
| Behavior / CLI / scoring / security model changes | Update the **canonical** doc in the **same change set** (same commit or consecutive commits in the same branch/PR). Do not ship code that leaves CLI-GUIDE, methodology, or ENTERPRISE-SECURITY stale. |
| Prefer readability of history | Prefer **one logical surface per commit** (e.g. one module, one doc file, or one tightly coupled pair such as version bump alone). Avoid “mega-commits” that mix unrelated toolkits. |
| Code + matching docs for one feature | Either (a) one commit that includes code **and** its canonical doc updates, or (b) a short stack: code → version → each doc file, with subjects that name the same feature. |
| Path add/remove/rename | Include [FILE-CATALOG.md](./FILE-CATALOG.md) in the same change set; subject may be `docs: catalog …` if catalog-only, or mention catalog in the body if bundled. |
| Toolkit version bump | Subject uses `chore(<toolkit>): bump … to X.Y.Z`. Docs that cite the product version get `docs(<toolkit>): …` commits (or the same commit) so cited versions stay aligned. |
| Docs-only edits | Use `docs` / `docs(<scope>)`. Do not use `feat` for documentation. |
| Message content | Subject describes **what changed in the staged files**, not a vague “updates”. Prefer the same nouns as the docs (`diagnostics`, `kpi_q_*`, `validate-score`, `CLI-GUIDE`). |

**Pre-commit message check:**

1. Does the subject type match the staged content (`docs` only if no product code/config behavior)?  
2. If CLI verbs, flags, exit codes, or JSON shapes changed, is [CLI-GUIDE](./kpi-analytics/CLI-GUIDE.md) / [excel-toolkit CLI-GUIDE](./excel-toolkit/CLI-GUIDE.md) updated in this change set?  
3. If trust/execution model changed, is the matching ENTERPRISE-SECURITY updated?  
4. If formulas or `v1_*` / `kpi_q_*` contracts changed, are methodology + fixtures updated?  
5. Would a reviewer find the subject by searching the feature name used in the README?

### Suggested commit workflow

```bat
git status
git diff
rem Stage one focused surface (or one logical pair), then:
git add path\to\file
git commit -m "type(scope): imperative summary of this file or surface"
git status
```

For a multi-file feature, a typical stack is: implementation → package version → docs (CLI, README, security, methodology as needed) → FILE-CATALOG / RULES if those inventories or policies changed.

### Remotes

A remote is optional. When one exists, do not assume write access to `main`/`master` without team convention. Tags for toolkit releases are optional but should match `__version__` / `ExcelToolkitVersion` if used.

---

## Verification before ship

| Change type | Minimum verification |
|-------------|----------------------|
| KPI scoring, columns, config | `kpi-analytics.cmd validate-score` (fixtures) |
| KPI Python product code style | From `kpi-analytics\`: `py -3.13 -m pylint kpi_modules` (must pass; see [Python style gate](#python-style-gate-pylint)) |
| KPI environment / packaging | `kpi-analytics.cmd probe` |
| KPI enterprise first-run / gate | `kpi-analytics.cmd diagnostics` (certificate under `diagnostics\`) |
| Excel COM / export path | `excel-toolkit.cmd probe` and/or `Test-ExcelCom.ps1 -DryRun` |
| Enterprise execution risk | `excel-toolkit\sample-test\` probes as appropriate |
| Schema or sample data | Headers match schema; score and/or export still consume sample paths |
| Docs only | [Author checklist](./MARKDOWN-STANDARD.md#author-checklist); relative links resolve |
| New/removed source files | [FILE-CATALOG.md](./FILE-CATALOG.md) updated |

Do not claim a scoring or export change is complete if the relevant probe/validation was skipped. Do not claim a Python product change is complete if the pylint gate was skipped or failed.

---

## Maintenance cadence

| Trigger | Action |
|---------|--------|
| Every source path add/remove/rename | Update [FILE-CATALOG.md](./FILE-CATALOG.md) |
| Every release-worthy toolkit behavior change | Bump code version; refresh CLI guide and status blocks |
| Every `kpi_modules` Python edit | Run pylint gate; keep exit 0 / 10.00 score |
| Security-relevant change | Update matching ENTERPRISE-SECURITY; re-run sample-test or probe |
| Fixture failure after intentional math change | Refresh expected JSON only with methodology note |
| Stale `last_updated` on heavily edited docs | Set ISO date when merging |

---

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| `pip install` “just this once” in **product** kpi-analytics | Stdlib solution or redesign the requirement |
| Shipping pylint as a product runtime dependency | Keep pylint developer-only; product remains stdlib-only |
| Skipping pylint after Python edits | Run `py -3.13 -m pylint kpi_modules` from `kpi-analytics\` |
| Force-killing Excel to “clean up” | Quit → wait → one retry → warn user |
| Committing `output\wq_scored*.csv` or `.xlsx` | Document regenerate commands in README / catalog |
| Silent field or `v1_*` / `kpi_q_*` rename | Coordinated contract bump + fixtures + docs |
| Long docs without Summary | MARKDOWN-STANDARD order |
| Duplicating security matrices into README | Link to ENTERPRISE-SECURITY |
| Merging Excel and Python into one process | Keep runtimes separate; compose via files/CLI |
| Absolute machine-only paths as the only example | Placeholder + one repo-relative example |
| Orphan files missing from the catalog | Update FILE-CATALOG in the same change |
| Vague commits (`update stuff`, `wip`) | Conventional `type(scope):` subject naming the real surface |
| Code without CLI/methodology/security docs | Same change set as the canonical doc per authority map |
| `feat` commit that only edits markdown | Use `docs` / `docs(scope)` |

---

## Contributor checklist

Before you commit or share a change:

- [ ] Behavior matches the **canonical** doc for that surface (CLI / methodology / security / README)  
- [ ] [FILE-CATALOG.md](./FILE-CATALOG.md) updated if paths changed  
- [ ] Versions and `last_updated` bumped where contracts changed  
- [ ] Required **verification** from the table above has been run  
- [ ] If `kpi_modules` Python changed: **pylint gate** passed (`py -3.13 -m pylint kpi_modules` from `kpi-analytics\`)  
- [ ] No secrets, PHI, `output\`, caches, or diagnostics certificates staged  
- [ ] Markdown follows [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) when docs were edited  
- [ ] Commit message uses `type(scope):` format and matches the staged files  
- [ ] Canonical docs for any behavior change are in the same change set  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial maintenance rules: authority map, docs, format, architecture, data, security, versioning, git, verification |
| 1.1.0 | Git commit message format, documentation-consistency rules, and commit workflow |
| 1.2.0 | Python PEP-8 style gate via pylint (`.pylintrc`); verification and checklist requirements |
| 1.2.1 | Output collision rule (unique suffix by default); workflow composition via Excel menu → kpi-analytics |
