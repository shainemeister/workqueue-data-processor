---
title: Work Queue Data Processor – Dynamic Schema Adaptation & Guided Mapping Plan
description: Living plan for stronger header discrepancy detection, sample-based verification, interactive/guided column-role mapping, and safe integration with the score path so missing or mismatched schema dependencies no longer produce silent incorrect results.
version: "0.2.0"
status: implemented
audience:
  - developers
  - analysts
doc_type: other
related:
  - README.md
  - RULES.md
  - FILE-CATALOG.md
  - CHANGELOG.md
  - kpi-analytics/CLI-GUIDE.md
  - kpi-analytics/SCORE-METHODOLOGY.md
  - kpi-analytics/kpi_modules/column_map.py
last_updated: "2026-07-25"
---

# Work Queue Data Processor – Dynamic Schema Adaptation & Guided Mapping Plan

Living plan to stop silent incorrect scoring when CSV headers do not match expected schema roles. Delivers stronger discrepancy detection, data-content verification, interactive/guided mapping, and clear reporting while preserving the existing auto-detect + profile path for clean extracts.

**Document version:** 0.2.0  
**Status:** implemented (repo **1.5.0** / kpi-analytics **2.1.0**)  
**Related:** [README.md](./README.md) · [RULES.md](./RULES.md) · [FILE-CATALOG.md](./FILE-CATALOG.md) · [CHANGELOG.md](./CHANGELOG.md) · kpi-analytics docs and `column_map.py`

---

## Summary

The current role-mapping layer (`kpi_modules.column_map`) resolves headers via mapping profile → config fields → aliases, then **silently falls back** unresolved roles to the role name itself. Metrics that receive empty or wrong columns produce `None` values; scoring continues with partial data and incorrect priority / KPI results. Discrepancies are not clearly identified to the user.

This plan delivers:

1. **Hardened detection** — stop silent fallbacks for required roles; report missing / ambiguous / low-confidence mappings with evidence.
2. **Sample-based verification** — after header resolution, inspect actual cell values (dates look like dates, amounts look numeric) so mapping quality is not header-name-only.
3. **Interactive / guided mapping** — when unresolved or low-confidence roles exist and a TTY is available, walk the user through aligning columns (or accept suggestions), optionally save a reusable profile, and re-verify.
4. **Safe integration** — score path uses the improved resolution; automation / non-TTY remains non-interactive and fails clearly when critical roles are missing; optional later surface from the Excel “Process my data” menu.

**No architecture overhaul.** Runtime separation, stdlib-only KPI, diagnostics gates, unique output paths, privacy rules, and the canonical `wq_schema.json` remain unchanged. Mapping stays a runtime adapter only — it never mutates the schema.

**Target versions (single coordinated release):**

| Surface              | Current | Target   |
|----------------------|---------|----------|
| Repository           | 1.4.1   | **1.5.0** |
| kpi-analytics        | 2.0.0   | **2.1.0** |
| excel-toolkit        | 1.6.0   | unchanged (or 1.7.0 only if menu is wired in the same release) |

---

## Contents

1. [Summary](#summary)
2. [Current state and pain points](#1-current-state-and-pain-points)
3. [Guiding principles](#2-guiding-principles)
4. [Track 1 – Detection & verification hardening](#3-track-1--detection--verification-hardening)
5. [Track 2 – Interactive / guided mapping](#4-track-2--interactive--guided-mapping)
6. [Track 3 – Score-path integration & re-select](#5-track-3--score-path-integration--re-select)
7. [Track 4 – Documentation, versions, catalog](#6-track-4--documentation-versions-catalog)
8. [Phased delivery (implementation steps)](#7-phased-delivery-implementation-steps)
9. [Success criteria and verification](#8-success-criteria-and-verification)
10. [Risks and non-goals](#9-risks-and-non-goals)
11. [AI execution instructions](#10-ai-execution-instructions)
12. [Immediate next actions](#11-immediate-next-actions)
13. [Document history](#12-document-history)

---

## 1. Current state and pain points

### 1.1 Silent fallback produces incorrect results

In `column_map.apply_mapping_to_config`:

- Unresolved roles receive `fields.setdefault(role, role)`.
- `metrics._field` also falls back to the role name.
- Parsers return `None` for missing/invalid cells → raw metrics become empty → normalization and weighted score still run on partial data.
- Score only fails when *zero* metrics can run. Partial mismatches are silent.

### 1.2 Header-only resolution is insufficient

Aliases catch many common labels, but:

- Novel extract layouts still miss roles.
- Ambiguous matches (multiple headers normalize to the same alias) pick the first without strong user visibility.
- No check that the chosen column actually contains plausible data for the role (date vs free text, numeric vs empty).

### 1.3 No guided recovery path

- `--mapping` profile is the only explicit override; it must be authored offline.
- No interactive walk-through when discrepancies appear.
- Excel menu “Process my data” calls score without a pre-flight mapping quality gate.

### 1.4 Reporting exists but is under-used

CLI JSON already surfaces `ActiveMetrics`, `SkippedMetrics`, `FieldRoles`, `MissingRoles`. These need to become first-class, human-visible signals and to drive interactive recovery.

---

## 2. Guiding principles

These constraints come directly from [RULES.md](./RULES.md) and the existing architecture and must not be violated:

| Principle | Implication for this plan |
|-----------|---------------------------|
| Runtime separation | Python scores; PowerShell/Excel only formats and presents. Guided mapping logic lives in `kpi_modules`. Menu may invoke it via CLI. |
| Stdlib-only product code | No new packages. Interactive input uses only `input()` / `sys.stdin` when a TTY is present. |
| Schema owns definitions | `wq_schema.json` is never mutated by mapping. Mapping is a runtime adapter only. |
| Full explainability | Mapping report (resolved / missing / sources / sample evidence) must be visible in CLI JSON and human output. |
| Offline / enterprise | No network. Diagnostics gates remain. |
| No real PHI | Sample values shown in guided mode must be truncated / redacted if they look like patient identifiers; never log full rows. |
| Unique outputs by default | Unchanged. |
| Breaking changes are explicit | Existing clean auto-detect + `--mapping` path must continue to work without interaction. New strictness is opt-in or TTY-only by default. |
| Same-change-set discipline | Code + CLI-GUIDE + methodology note + FILE-CATALOG + CHANGELOG + version bump ship together. |

---

## 3. Track 1 – Detection & verification hardening

### Goal

Make discrepancies visible and stop silent incorrect scoring for required roles.

### Design

1. **Stop (or strictly control) the silent fallback**
   - In `apply_mapping_to_config`, do **not** `setdefault(role, role)` for roles that are required by any *active* metric when a strict mode is on.
   - Prefer: leave the role unresolved, mark it missing, and let `active_metrics_for_roles` skip the dependent metrics. Raise only when the resulting active set is empty (existing behaviour) **or** when a new `require_resolved_roles` / interactive path demands it.

2. **Richer mapping report**
   - Extend the dict returned by `resolve_roles` / `apply_mapping_to_config` with:
     - `confidence` or per-role evidence
     - `sample_values` (first few non-empty cells, truncated)
     - `type_hints` (looks_date, looks_numeric, mostly_empty)
   - Keep existing keys (`resolved`, `missing_roles`, `ambiguous`, `unused_headers`, `sources`, `active_metrics`, `skipped_metrics`) for backward compatibility.

3. **Sample-based heuristics** (stdlib only)
   - After headers are chosen, read a small sample of rows (existing `read_csv_rows` or a lightweight peek).
   - For date roles: attempt the same `date_formats` already used by metrics.
   - For amount / count / days roles: attempt `parse_float` / `parse_int` style checks.
   - Flag low-confidence mappings in the report without blocking clean files.

4. **CLI / JSON visibility**
   - Ensure `score` JSON and human summary always surface the enhanced mapping report when any role was missing, ambiguous, or low-confidence.

---

## 4. Track 2 – Interactive / guided mapping

### Goal

When discrepancies exist and a TTY is available, guide the user to a correct mapping instead of producing wrong scores.

### Design

1. **New helper** in `column_map.py` (name suggestion: `guide_mapping` or `interactive_resolve_roles`)
   - Input: headers, optional sample rows, current report, config.
   - For each missing / low-confidence role:
     - Show role name + short description of what scoring needs.
     - List unused (or all) headers with 1–3 sample values (truncated).
     - Accept user choice by index, header name, or “skip this role”.
     - Re-run resolution + sample verification after each choice or at the end.
   - Offer to save a mapping profile JSON (`save_mapping_profile`) with a suggested path (next to the CSV or under a standard location).

2. **CLI surface** (preferred primary entry)
   - `score --interactive-mapping` (or `--guide-mapping`)
     - When TTY and (missing roles or low-confidence) → enter guided session.
     - When non-TTY → behave as strict non-interactive (clear failure if critical roles missing).
   - Optional dedicated verb `map` that only runs the guided session and writes a profile (useful for automation setup).

3. **Non-interactive contract preserved**
   - Existing `score` (no interactive flag) continues to auto-detect + honour `--mapping`.
   - With the hardened detection, it will now *fail clearly* (or skip more metrics) instead of silently scoring on wrong columns when roles are unresolved.

4. **Privacy in guided mode**
   - Never print full patient / DOB / account values. Truncate samples aggressively. Prefer showing only the header list + type hints when values look sensitive.

---

## 5. Track 3 – Score-path integration & re-select

### Goal

Wire the improved resolution into every `score` path and allow recovery by choosing a different source file when critical dependencies remain missing.

### Design

1. **`score_csv` / `score` CLI**
   - Always run the enhanced `apply_mapping_to_config` (Track 1).
   - If `--interactive-mapping` and TTY and problems exist → call guided helper (Track 2), then proceed with the confirmed mapping.
   - After guided (or profile) resolution, re-verify sample values before computing metrics.

2. **Re-select source (optional but valuable)**
   - In guided mode, if the user cannot map critical roles from the current headers, offer “choose a different file”.
   - Implementation options (keep simple):
     - Print a clear message and exit with a dedicated code / message so the Excel menu can re-prompt, **or**
     - Accept a new path interactively and restart resolution on that file.
   - Prefer the first option for the initial release to avoid deep file-dialog logic inside pure Python KPI code.

3. **Excel menu (optional same-release or follow-on)**
   - After file selection in “Process my data”, invoke `kpi-analytics.cmd score ... --interactive-mapping` (or a lightweight `map` pre-check).
   - Surface any guided questions in the same console.
   - If the KPI process signals “need different file”, return to the existing discovery / range selector.
   - Only bump excel-toolkit if this surface is included.

---

## 6. Track 4 – Documentation, versions, catalog

### Changes required in the same release

- Bump `kpi_modules.__version__` → **2.1.0**
- Root CHANGELOG under **[1.5.0]**
- Update [kpi-analytics/CLI-GUIDE.md](./kpi-analytics/CLI-GUIDE.md): new flag(s), mapping report fields, interactive behaviour, exit conditions
- Short note in [kpi-analytics/SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md) or a dedicated mapping subsection: resolution order, verification, what “skipped metric” means after hardening
- [FILE-CATALOG.md](./FILE-CATALOG.md) for any new helpers or profile examples
- Root README and kpi-analytics README quick pointers if the happy-path description changes
- This PLAN.md status → implemented when S1–S4 complete

---

## 7. Phased delivery (implementation steps)

Single coordinated release. Internal steps ordered for safe incremental delivery and review.

| Step | Focus | Version impact | Notes |
|------|-------|----------------|-------|
| **S1** | Detection & verification hardening (stop silent fallback, sample heuristics, richer report) | (dev only) | Pure `column_map.py` + call sites in `score_v1.py`; unit-testable; no CLI flag yet |
| **S2** | Interactive guided mapper + CLI flag (`--interactive-mapping` or dedicated `map`) | kpi-analytics → 2.1.0-pre | TTY-only interaction; save profile; non-TTY remains strict |
| **S3** | Score-path integration, re-verify after guide, optional “different file” signal | kpi-analytics → 2.1.0-pre | Ensure clean extracts still auto-succeed with zero interaction |
| **S4** | Docs, CHANGELOG, version bumps, FILE-CATALOG, PLAN status | **repo 1.5.0 / kpi-analytics 2.1.0** | Ship point. Excel menu wiring only if explicitly included |

**Why this order:**  
Hardening first (foundation and safety). Guided experience next (biggest user win for real extracts). Integration and polish last so the public contract is coherent.

---

## 8. Success criteria and verification

| Track | Success looks like | Minimum verification |
|-------|--------------------|----------------------|
| Detection | Unresolved required roles no longer silently become the role name; report shows missing / ambiguous / sample evidence | Manual runs with deliberately mismatched headers; inspect JSON `MissingRoles`, `FieldRoles`, `SkippedMetrics` |
| Verification | Columns that parse as empty/non-date/non-numeric are flagged low-confidence | Synthetic CSV with wrong-type columns under correct header names |
| Guided mapping | TTY session lets user map every missing role, save profile, and produce a correct score | Walk-through with a real-world-style extract that uses non-schema headers |
| Non-interactive | Clean schema-aligned CSV still scores with zero prompts; bad CSV fails clearly | Existing fixtures + `validate-score` remain green |
| Overall | RULES constraints hold; pylint 10.00; diagnostics gate still fires; no PHI leakage in guided samples | Contributor checklist + `py -3.13 -m pylint kpi_modules` + `kpi-analytics.cmd validate-score` |

---

## 9. Risks and non-goals

**Risks**

- Over-strict defaults could break existing automation that relied on partial mapping → mitigate by keeping non-interactive auto path working for files that previously succeeded, and making the hard fail + interactive opt-in via flag or TTY detection.
- Guided mode showing sample values could surface PHI → mitigate with aggressive truncation and preference for header-only display when values look sensitive.
- Ambiguous multi-header matches → always surface the list and prefer explicit user choice in interactive mode.

**Non-goals**

- Mutating or replacing `wq_schema.json`.
- Adding pip packages, network calls, or GUI dialogs inside KPI.
- Changing priority formulas, metric keys, or `kpi_q_*` contracts.
- Force-killing Excel or changing ExecutionPolicy.
- Making interactive mode the only way to score (automation must remain non-interactive).
- Full Excel-menu redesign (only a thin call-out if included).

---

## 10. AI execution instructions

Any AI agent implementing this plan **must** follow these rules:

1. **Ground every change in this PLAN.md and [RULES.md](./RULES.md).** Do not invent new architecture.
2. **Work in the order S1 → S2 → S3 → S4.** Do not jump to interactive UI before detection is hardened.
3. **Primary files to touch:**
   - `kpi-analytics/kpi_modules/column_map.py` (core logic)
   - `kpi-analytics/kpi_modules/score_v1.py` (call site)
   - `kpi-analytics/kpi_modules/cli.py` (new flag / verb)
   - `kpi-analytics/kpi_modules/__init__.py` (version)
   - Docs listed in Track 4
4. **Before any edit:** read the current file contents via GitHub tools or local checkout.
5. **After Python edits:** run from `kpi-analytics\`:
   ```bat
   py -3.13 -m pylint kpi_modules
   ```
   Must exit 0 and score 10.00/10 under the repo `.pylintrc`.
6. **After behaviour changes:** run
   ```bat
   kpi-analytics.cmd validate-score --json
   kpi-analytics.cmd score --dry-run --json
   ```
   (and additional manual mismatched-header cases).
7. **Version and docs in the same change set** as the code that ships the public contract.
8. **Commit style:** Conventional Commits with scope `kpi-analytics` (or omit for root docs). Example subjects:
   - `feat(kpi-analytics): harden column role resolution and add sample verification`
   - `feat(kpi-analytics): add interactive guided mapping for unresolved roles`
   - `chore(kpi-analytics): bump package version to 2.1.0`
   - `docs: add PLAN.md for dynamic schema adaptation (target 1.5.0)`
9. **Never** commit real PHI, `output\` artefacts, or diagnostics certificates.
10. **When in doubt about strictness vs compatibility,** prefer the non-interactive path remaining as permissive as today’s successful cases, and put new strictness behind the interactive flag or explicit “strict” option.

---

## 11. Immediate next actions

**Shipped in 1.5.0 / kpi-analytics 2.1.0.** Optional follow-ons:

1. Wire Excel “Process my data” to `score --interactive-mapping` (excel-toolkit bump if included).
2. Optional dedicated `map` CLI verb for profile-only sessions.
3. Manual TTY walk-through on real-world extract layouts as they appear.

---

## 12. Document history

| Version | Notes |
|---------|-------|
| 0.1.0 | Initial plan after observation that header discrepancies produce silent incorrect scores. Covers detection hardening, sample verification, interactive guided mapping, score-path integration, and version targets 1.5.0 / kpi-analytics 2.1.0. |
| 0.2.0 | Marked **implemented**: silent fallback removed, sample verification + report fields, `--interactive-mapping` guided recovery, docs/version 1.5.0 / kpi 2.1.0. Excel menu wiring deferred. |
