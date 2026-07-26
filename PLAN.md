---
title: Work Queue Data Processor – Menu Simplification & Dynamic Processing Plan
description: Living plan for a context-aware main menu, unified CSV/XLSX discovery with print-style multi-select ranges, guided processing, and optional workbook password on every Excel export path.
version: "0.2.0"
status: current
audience:
  - developers
  - analysts
doc_type: other
related:
  - README.md
  - RULES.md
  - FILE-CATALOG.md
  - CHANGELOG.md
  - excel-toolkit/README.md
  - excel-toolkit/CLI-GUIDE.md
  - excel-toolkit/ENTERPRISE-SECURITY.md
last_updated: "2026-07-25"
---

# Work Queue Data Processor – Menu Simplification & Dynamic Processing Plan

Living plan for the interactive Excel menu: context-aware Process my data flow, unified CSV/Excel discovery with print-style multi-select, guided processing, and optional workbook password on every Excel export path. **Shipped in repo 1.4.0 / excel-toolkit 1.6.0.**

**Document version:** 0.2.0  
**Status:** current (S1–S4 implemented for repo **1.4.0** / excel-toolkit **1.6.0**)  
**Related:** [README.md](./README.md) · [RULES.md](./RULES.md) · [FILE-CATALOG.md](./FILE-CATALOG.md) · [CHANGELOG.md](./CHANGELOG.md) · excel-toolkit docs

---

## Summary

After the successful R1–R3 efficiency releases (mapping, metric contract 2.0, pipeline-first menu), the interactive experience still requires the user to decide architecture up front (full pipeline vs score-only vs export) and only discovers CSVs on the main path.

This plan delivers a **context-aware, guided “Process my data” flow** that:

1. Dynamically discovers both `.csv` and `.xlsx`/`.xls` under `import\`.
2. Supports flexible multi-select with print-style range syntax (`1`, `1,2,3`, `1-3`, `1,3-5,8`).
3. Routes intelligently based on file type and a single clarifying question.
4. Offers an optional workbook open password on **any** path that produces an Excel file.
5. Keeps Advanced tools available but secondary.

**No architecture overhaul.** Runtime separation, stdlib-only KPI, diagnostics gates, unique output paths, and privacy rules remain unchanged. The COM layer already supports `SaveAs` with password; this plan only surfaces the choice in the menu.

**Target versions (single coordinated release):**

| Surface              | Current | Target   |
|----------------------|---------|----------|
| Repository           | 1.3.1   | **1.4.0** |
| excel-toolkit        | 1.5.0   | **1.6.0** |
| kpi-analytics        | 2.0.0   | unchanged (no API break) |

---

## Contents

1. [Summary](#summary)
2. [Current state and pain points](#1-current-state-and-pain-points)
3. [Guiding principles](#2-guiding-principles)
4. [Track 1 – Dynamic discovery & range selection](#3-track-1--dynamic-discovery--range-selection)
5. [Track 2 – Guided “Process my data” flow](#4-track-2--guided-process-my-data-flow)
6. [Track 3 – Optional password on every Excel export](#5-track-3--optional-password-on-every-excel-export)
7. [Track 4 – Menu simplification & documentation](#6-track-4--menu-simplification--documentation)
8. [Phased delivery (implementation steps)](#7-phased-delivery-implementation-steps)
9. [Success criteria and verification](#8-success-criteria-and-verification)
10. [Risks and non-goals](#9-risks-and-non-goals)
11. [Immediate next actions](#10-immediate-next-actions)
12. [Document history](#11-document-history)

---

## 1. Current state and pain points

### 1.1 Menu still forces architectural decisions

Current main menu (after R3):

```
1) Run full pipeline (Score CSV -> Excel)
2) Score only (CSV -> scored + summary CSV)
3) Export CSV to Excel
4) Advanced tools...
0) Exit
```

Users must understand the difference between the three processing paths before selecting a file.

### 1.2 File discovery is CSV-only on the happy path

`Select-CsvInputsForPipeline` only lists `.csv` under `import\`. Excel workbooks are handled only inside Advanced → Import. Mixed inventories force the user to switch menus.

### 1.3 Selection syntax is limited

Current acceptance: single index, comma list, or full path.  
Missing: contiguous ranges (`1-3`) and mixed lists (`1,3-5,8`) that users already understand from print dialogs.

### 1.4 Password is available but not offered on export

- `ExcelCom.psm1` `Save-ExcelWorkbook` already accepts `[SecureString]$Password` and applies it on `SaveAs`.
- Import path already prompts interactively for open passwords.
- Menu export paths (pipeline and pure export) never ask the user whether they want to protect the resulting workbook.

---

## 2. Guiding principles

These constraints come directly from [RULES.md](./RULES.md) and the existing architecture and must not be violated:

| Principle | Implication for this plan |
|-----------|---------------------------|
| Runtime separation | Python scores; PowerShell/Excel only formats and presents. No scoring logic moves into the menu. |
| Stdlib-only product code | No change to kpi-analytics. |
| Full explainability | Unchanged. |
| Offline / enterprise | No network, no elevation, no permanent policy changes. Diagnostics gates remain. |
| No real PHI | Password is never logged, never written to JSON reports, never echoed. SecureString only. |
| Unique outputs by default | Existing files are never clobbered without explicit force (menu never uses Force). |
| Password handling | Interactive SecureString prompt or optional CLI parameter; never stored or logged. |
| Breaking changes are explicit | Menu shape change is UX-only; automation CLIs remain stable. Version bump + CHANGELOG + docs in the same change set. |

---

## 3. Track 1 – Dynamic discovery & range selection

### Goal

Present a single unified list of processable files and accept flexible multi-select syntax.

### Design

1. **Discovery**
   - Scan `import\` for `*.csv`, `*.xlsx`, `*.xls`.
   - Sort by name; show type, size, last-write time.
   - Example display:

     ```
     Files under import\:
        1) wq_synthetic_data.csv          (CSV,  98 KB, 2026-07-22)
        2) wq_synthetic_data.xlsx         (Excel, 72 KB, 2026-07-22)
        3) claims_july.csv                (CSV, 1.2 MB, 2026-07-24)
        4) protected_extract.xlsx         (Excel, protected)
     ```

2. **Selection parser** (new helper, e.g. `Parse-SelectionRange`)
   - Accepts:
     - Single: `1`
     - List: `1,2,3` or `1 2 3`
     - Range: `1-3`
     - Mixed: `1,3-5,8`
     - Full path (fallback when input contains path separators or ends in `.csv`/`.xlsx`/`.xls`)
   - Validates indices against the current list; rejects out-of-range or inverted ranges (`5-2`).
   - Returns ordered unique full paths.

3. **Reuse**
   - Replace / generalize the existing `Select-CsvInputsForPipeline` so both the new guided flow and any remaining Advanced paths share the same parser.

---

## 4. Track 2 – Guided “Process my data” flow

### Goal

One primary entry point that asks the minimum necessary questions.

### New main menu shape

```
================================================
  Work Queue Data Tools
================================================
  1) Process my data
  2) Advanced tools...
  0) Exit
================================================
```

### Flow for option 1

1. Discover files (Track 1).
2. If none found → prompt for a full path or open `import\` folder.
3. User selects files with range syntax.
4. **Action decision** (single clarifying question, only when needed):

   ```
   What should I do with the selected file(s)?
     [1] Full pipeline (Score → Excel)     ← recommended for CSV
     [2] Score only (CSV results)
     [3] Export / Import only (no scoring)
   ```

   - Pre-select sensible default based on majority file type.
   - For pure Excel selection, default to “Import to CSV” then optionally continue.

5. Execute using existing engines:
   - CSV + full pipeline → `Invoke-KpiScoreExportMenu` (current path)
   - CSV + score only → same with `-ScoreOnly`
   - CSV + export only → existing export helper
   - XLSX → existing import helper, then optional hand-off to scoring

6. After success, offer to open `output\` (existing behavior).

Automation CLIs (`excel-toolkit.cmd`, `kpi-analytics.cmd`) stay completely unchanged.

---

## 5. Track 3 – Optional password on every Excel export

### Goal

Whenever the menu is about to produce an `.xlsx`, give the user a clear choice to protect it with a workbook open password.

### Design

1. **Prompt point** (all export paths):
   - Full pipeline (after scoring, before `Export-ExcelFromCsv`)
   - Pure “Export CSV to Excel”
   - Advanced “Export with schema display headers”
   - Any future path that calls `Save-ExcelWorkbook` / `Export-ExcelFromCsv`

2. **Interaction**

   ```
   Protect the Excel workbook with a password?
     [Y] Yes – set open password
     [N] No  – leave unprotected (default)
   ```

   - If Yes → `Read-Host -AsSecureString` (masked). Confirm by re-entry (optional but recommended for safety).
   - Empty / cancel → treat as No.
   - Password is passed as `SecureString` into the existing `Save-ExcelWorkbook -Password` path.
   - Never written to console, logs, JSON diagnostics, or summary files.

3. **CLI / automation**
   - Existing `-Password` parameter on import remains.
   - Export CLI may gain an optional `-Password` for parity (non-breaking); menu is the primary surface.

4. **Security notes** (already aligned with ENTERPRISE-SECURITY)
   - SecureString only.
   - Cleared after use.
   - No force-kill, no elevation, no permanent policy change.

---

## 6. Track 4 – Menu simplification & documentation

### Changes

- Replace current 4-item main menu with the 2-item shape above.
- Keep Advanced tools as a secondary menu (slightly cleaned if needed).
- Update:
  - Root `README.md` (quick-start happy path)
  - `excel-toolkit/README.md`
  - `excel-toolkit/CLI-GUIDE.md` (selection examples, password)
  - `excel-toolkit/ENTERPRISE-SECURITY.md` (password surface)
  - `FILE-CATALOG.md`
  - Root `CHANGELOG.md` under **1.4.0**
- Bump toolkit version constant / badge to **1.6.0**.

---

## 7. Phased delivery (implementation steps)

Single coordinated release. Internal steps are ordered for safe incremental delivery and review.

| Step | Focus | Version impact | Notes |
|------|-------|----------------|-------|
| **S1** | Range-aware multi-select parser + unified discovery (csv + xlsx/xls) | (dev only) | New helper; unit-testable; no menu change yet |
| **S2** | Guided “Process my data” flow + new main menu shape | excel-toolkit → 1.6.0-pre | Replaces options 1/2/3 with single entry; Advanced retained |
| **S3** | Optional password prompt on every Excel export path | excel-toolkit → 1.6.0-pre | Surfaces existing COM capability; SecureString only |
| **S4** | Documentation, CHANGELOG, version bumps, FILE-CATALOG | **repo 1.4.0 / excel-toolkit 1.6.0** | Ship point |

**Why this order:**  
Parser first (foundation). Guided flow next (biggest UX win). Password is a small, isolated addition once export paths are centralized. Docs and version bump last so the CHANGELOG accurately reflects the final surface.

**Why one release instead of three:**  
All changes are menu/UX + one already-supported COM feature. No metric contract, no schema change, no kpi-analytics API break. Shipping them together keeps the menu coherent.

---

## 8. Success criteria and verification

| Track | Success looks like | Minimum verification |
|-------|--------------------|----------------------|
| Discovery & ranges | Both CSV and Excel appear; `1-3`, `1,3-5` select correctly | Manual matrix of selection strings + edge cases (empty, out-of-range, inverted) |
| Guided flow | User can go from “files in import\” to finished workbooks with ≤ 2 decisions | Walkthrough with mixed inventory |
| Password | Any export path offers Y/N; Yes produces password-protected .xlsx; password never logged | Manual export + open with/without password; inspect no password in diagnostics JSON |
| Menu shape | Main menu has 2 choices; Advanced still reaches every prior capability | Side-by-side old vs new |
| Overall | RULES constraints hold; CLIs unchanged; diagnostics gates still fire | Contributor checklist + existing diagnostics / validate-score |

---

## 9. Risks and non-goals

**Risks**

- Range parser edge cases (leading zeros, spaces, inverted ranges) → strict validation + clear error messages.
- Password confirmation friction → default to single entry; optional confirm can be added later if users request it.
- Users who loved the old 1/2/3 split → Advanced still exposes pure export; full pipeline remains the recommended default.

**Non-goals**

- Changing kpi-analytics scoring, metrics, or mapping.
- Adding network, elevation, or permanent ExecutionPolicy changes.
- Force-killing Excel.
- Storing or logging passwords.
- Replacing the schema or making mapping interactive in this release.
- Breaking automation CLI contracts.

---

## 10. Immediate next actions

1. ~~Implement **S1** – `Parse-SelectionRange` + unified file discovery helper.~~ **Done**
2. ~~Implement **S2** – new main menu + `Invoke-ProcessMyData` guided flow.~~ **Done**
3. ~~Implement **S3** – password prompt helper called from every export path.~~ **Done**
4. ~~**S4** – update docs, bump versions to repo **1.4.0** / excel-toolkit **1.6.0**, write CHANGELOG entry, refresh FILE-CATALOG.~~ **Done**
5. Manual verification matrix (selection, mixed files, password on/off, diagnostics still green) — run before sharing the release.

---

## 11. Document history

| Version | Notes |
|---------|-------|
| 0.1.0 | Initial plan after R1–R3 retirement. Covers dynamic discovery, print-style ranges, guided Process-my-data flow, optional export password, and version targets 1.4.0 / 1.6.0. |
| 0.2.0 | S1–S4 implemented: guided menu, ranges, optional export password, docs/version ship (1.4.0 / excel-toolkit 1.6.0). |
