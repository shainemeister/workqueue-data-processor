# Changelog

All notable changes to **workqueue-data-processor** are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/).  
**Structure:** `## workqueue-data-processor` → dated `### [X.Y.Z] - YYYY-MM-DD` → `#### Added` / `#### Changed` / …  
Dates are ISO 8601. There is no Unreleased section—record each change under the version section that ships it.

**Package versions** (`kpi_modules.__version__`, `ExcelToolkitVersion`) are independent of repository changelog versions unless a release intentionally aligns them.  
**Standards kit version** lives only in [RULES.md — Kit baseline](./RULES.md#kit-baseline) (not as kit release history here). Upstream: https://github.com/shainemeister/repo-kit

---

## workqueue-data-processor

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
