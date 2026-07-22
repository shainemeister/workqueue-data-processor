---
title: Repository Maintenance Rules
description: Fundamental rules for documenting, changing, verifying, and versioning this repository.
version: "1.0.0"
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
last_updated: "2026-07-22"
---

# Repository Maintenance Rules

Fundamental rules for maintaining **workqueue-data-processor** as a professional, auditable dual-toolkit repository. These rules govern documentation, code boundaries, data contracts, git hygiene, and verification—not product tutorials.

**Document version:** 1.0.0  

**Related:** [README.md](./README.md) · [FILE-CATALOG.md](./FILE-CATALOG.md) · [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md)

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
| Keep toolkits independent at the runtime layer | Add pip packages or network clients to product code |
| Preserve explainable score / dual KPI attribution | Force-kill Excel or permanently alter ExecutionPolicy |
| Verify before sharing scoring or COM changes | Silently rename schema fields or scored columns |

---

## Contents

1. [Summary](#summary)
2. [Authority map](#authority-map)
3. [Documentation rules](#documentation-rules)
4. [Formatting and style](#formatting-and-style)
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
| Python | Target **3.13**; **standard library only** in `kpi-analytics\` |
| Examples | Prefer placeholders (`C:\path\to\...`) plus one concrete repo-relative example |

---

## Architecture and boundaries

| Rule | Detail |
|------|--------|
| **Runtime separation** | Do not call Excel COM from Python product code. Do not implement priority/KPI math in PowerShell product code. |
| **Composition** | Join toolkits at the **workflow** layer (generate/score CSV → export XLSX), not by merging engines. |
| **Excel entry points** | Prefer `excel-toolkit.cmd` / `ExcelToolkit.ps1` (automation) or `Import-Module ExcelToolkit.psm1` (in-process). Treat `Export-WqDataToExcel.ps1` as a legacy forwarder. |
| **KPI entry points** | Prefer `kpi-analytics.cmd` or `python -m kpi_modules`. Keep `kpi_modules` importable without side effects beyond CLI `__main__`. |
| **Dependencies** | No pip packages, no download-and-run, no credential stores, no hidden telemetry in product paths. |
| **Excel lifecycle** | Close via Quit + controlled retry + user warning. **Never** force-kill `EXCEL.EXE` in toolkit code. |
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
8. **`output\`** is regenerable workspace only—not source of truth and not versioned.

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
| Docs, templates, `.gitignore` | `.venv\`, `venv\`, `.env` |
| | Secrets, IDE-only folders already ignored |

Respect [.gitignore](./.gitignore). Do not force-add ignored generated artifacts “for convenience.”

### Commits and history

1. **Review before commit:** `git status` and `git diff`. Confirm no accidental large CSVs, workbooks, or credentials.  
2. **Small, focused commits** preferred over mixed unrelated changes.  
3. **Messages:** imperative, specific subjects (e.g. `Document KPI Q dual attribution in methodology`). Optional body for *why*.  
4. **Do not rewrite published shared history** (`push --force` to a shared default branch) without explicit coordination.  
5. **Branches (recommended):** `feature/…`, `fix/…`, `docs/…` when work is non-trivial.  
6. **Contract-breaking changes:** prefer review (PR) when a remote exists; call out migration notes in the commit or PR body.  
7. **No secrets in history.** If leaked, rotate credentials and treat history cleanup as an incident—not a casual amend.

### Remotes

A remote is optional. When one exists, do not assume write access to `main`/`master` without team convention. Tags for toolkit releases are optional but should match `__version__` / `ExcelToolkitVersion` if used.

---

## Verification before ship

| Change type | Minimum verification |
|-------------|----------------------|
| KPI scoring, columns, config | `kpi-analytics.cmd validate-score` (fixtures) |
| KPI environment / packaging | `kpi-analytics.cmd probe` |
| KPI enterprise first-run / gate | `kpi-analytics.cmd diagnostics` (certificate under `diagnostics\`) |
| Excel COM / export path | `excel-toolkit.cmd probe` and/or `Test-ExcelCom.ps1 -DryRun` |
| Enterprise execution risk | `excel-toolkit\sample-test\` probes as appropriate |
| Schema or sample data | Headers match schema; score and/or export still consume sample paths |
| Docs only | [Author checklist](./MARKDOWN-STANDARD.md#author-checklist); relative links resolve |
| New/removed source files | [FILE-CATALOG.md](./FILE-CATALOG.md) updated |

Do not claim a scoring or export change is complete if the relevant probe/validation was skipped.

---

## Maintenance cadence

| Trigger | Action |
|---------|--------|
| Every source path add/remove/rename | Update [FILE-CATALOG.md](./FILE-CATALOG.md) |
| Every release-worthy toolkit behavior change | Bump code version; refresh CLI guide and status blocks |
| Security-relevant change | Update matching ENTERPRISE-SECURITY; re-run sample-test or probe |
| Fixture failure after intentional math change | Refresh expected JSON only with methodology note |
| Stale `last_updated` on heavily edited docs | Set ISO date when merging |

---

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| `pip install` “just this once” in kpi-analytics | Stdlib solution or redesign the requirement |
| Force-killing Excel to “clean up” | Quit → wait → one retry → warn user |
| Committing `output\wq_scored*.csv` or `.xlsx` | Document regenerate commands in README / catalog |
| Silent field or `v1_*` / `kpi_q_*` rename | Coordinated contract bump + fixtures + docs |
| Long docs without Summary | MARKDOWN-STANDARD order |
| Duplicating security matrices into README | Link to ENTERPRISE-SECURITY |
| Merging Excel and Python into one process | Keep runtimes separate; compose via files/CLI |
| Absolute machine-only paths as the only example | Placeholder + one repo-relative example |
| Orphan files missing from the catalog | Update FILE-CATALOG in the same change |

---

## Contributor checklist

Before you commit or share a change:

- [ ] Behavior matches the **canonical** doc for that surface (CLI / methodology / security / README)  
- [ ] [FILE-CATALOG.md](./FILE-CATALOG.md) updated if paths changed  
- [ ] Versions and `last_updated` bumped where contracts changed  
- [ ] Required **verification** from the table above has been run  
- [ ] No secrets, PHI, `output\`, or caches staged  
- [ ] Markdown follows [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) when docs were edited  
- [ ] Commit message explains the change clearly  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial maintenance rules: authority map, docs, format, architecture, data, security, versioning, git, verification |
