---
title: Verification and Operations
description: Verification before ship, completion rule, maintenance cadence, anti-patterns, and contributor checklist.
version: "1.0.1"
status: current
audience:
  - developers
  - security
doc_type: other
related:
  - ../RULES.md
  - ./security.md
  - ./authoring-and-style.md
  - ./contracts.md
  - ./versioning-and-git.md
  - ../MARKDOWN-STANDARD.md
  - ../UPGRADE.md
  - ../../certification/README.md
  - ../../docs/FILE-CATALOG.md
last_updated: "2026-07-30"
---

# Verification and Operations

Ship gates, completion rules, cadence, anti-patterns, and the contributor checklist.

**Document version:** 1.0.1  

**Related:** [RULES.md](../RULES.md) · [security.md](./security.md) · [authoring-and-style.md](./authoring-and-style.md) · [contracts.md](./contracts.md) · [versioning-and-git.md](./versioning-and-git.md) · [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md) · [UPGRADE.md](../UPGRADE.md) · [certification/README.md](../../certification/README.md)

---

## Summary

Do **not** mark work complete if any **declared** Domain B (style) or Domain A (SAST / secrets) gate was skipped or failed. **Gitleaks is required.** When product code or gate config changed, run the **full** certification harness.

---

## Contents

1. [Summary](#summary)
2. [Verification before ship](#verification-before-ship)
3. [Completion rule](#completion-rule)
4. [Before marking work complete](#before-marking-work-complete)
5. [Maintenance cadence](#maintenance-cadence)
6. [Anti-patterns](#anti-patterns)
7. [Contributor checklist](#contributor-checklist)
8. [Document history](#document-history)

---

## Verification before ship

| Change type | Minimum verification |
|-------------|----------------------|
| **Product code, gate config, or inventory** | **Full certification package:** `.\certification\Invoke-Certification.ps1` (Domain B **and** Domain A, including pylint + Bandit + PSSA + Gitleaks + validate-score). Confirm `OverallPass`; do not stage outputs. See [renewal enforcement](./security.md#certification-renewal-enforcement-required) |
| KPI scoring, columns, config | Covered by harness `validate-score`; may also run `kpi-analytics.cmd validate-score` alone while iterating |
| KPI environment / packaging | `kpi-analytics.cmd probe` |
| KPI enterprise first-run / gate | `kpi-analytics.cmd diagnostics` (certificate under `diagnostics\`) — **not** a substitute for certification |
| Excel COM / export path | `excel-toolkit.cmd probe` and/or `Test-ExcelCom.ps1 -DryRun` |
| Excel enterprise first-run / gate | `excel-toolkit.cmd diagnostics` — **not** a substitute for certification |
| Enterprise execution risk | `excel-toolkit\sample-test\` probes as appropriate |
| Schema or sample data | Headers match schema; score and/or export still consume sample paths |
| Docs only (no product/gate impact) | [Author checklist](../MARKDOWN-STANDARD.md#author-checklist); relative links resolve; certification renewal optional per narrow exception |
| New/removed source files | [docs/FILE-CATALOG.md](../../docs/FILE-CATALOG.md) updated; [language surface inventory](./security.md#language-surface-inventory) if languages added/removed |
| Release-worthy / version bump | [CHANGELOG.md](../../CHANGELOG.md) entry under the version section that ships the change |

Individual Domain A/B commands remain documented in [certification/README.md](../../certification/README.md). For ship/complete after code changes, use the **full harness**—not a subset.

---

## Completion rule

Do **not** mark a change complete, and do **not** claim ship readiness, if any **declared** Domain B (code validation / style) or Domain A (security / SAST / secrets) gate was skipped or failed. **Gitleaks is required.** Missing required developer tools is a **failed** gate, not a skip.

When product code, certification gate definitions, or inventory Status changed: certification is **stale** until `.\certification\Invoke-Certification.ps1` completes with `OverallPass = true`. Partial renewal (security-only or pylint-only) does **not** satisfy completion. Package diagnostics gates remain required for scoring/export paths as before; they do not replace Domain A/B tools or formal certification.

---

## Before marking work complete

Ordered steps for humans and AI agents:

1. Read **language surface inventory** (**Declared:** Python, PowerShell, **Secrets**).  
2. If product code, gate config, or inventory changed: run **full** certification (`.\certification\Invoke-Certification.ps1`) — this **must** re-run Domain B (including **pylint**) **and** Domain A (including **Gitleaks**) together. Confirm `OverallPass`; leave outputs unstaged.  
3. Otherwise (narrow docs-only): run any applicable lightweight checks; renewal optional per exception.  
4. Run package probes/diagnostics as needed for product paths (separate from certification).  
5. Update canonical docs / [CHANGELOG.md](../../CHANGELOG.md) per the [authority map](../RULES.md#authority-map).  
6. Only then state the task is complete.

---

## Maintenance cadence

| Trigger | Action |
|---------|--------|
| Every source path add/remove/rename | Update [docs/FILE-CATALOG.md](../../docs/FILE-CATALOG.md) |
| Language surface added or removed | Update [language surface inventory](./security.md#language-surface-inventory) + `certification/checks.json` / README |
| Every release-worthy toolkit behavior change | Bump code version; refresh CLI guide and status blocks; update [CHANGELOG.md](../../CHANGELOG.md) |
| Every product code edit (`kpi_modules` or excel-toolkit product scripts) | Run **full** [certification harness](../../certification/Invoke-Certification.ps1) (pylint + security + Gitleaks); do not partial-recert |
| Security-relevant change | Update matching ENTERPRISE-SECURITY; full certification renewal; CHANGELOG entry |
| Formal certification | Always renew via full suite after qualifying changes; never commit outputs |
| Fixture failure after intentional math change | Refresh expected JSON only with methodology note |
| Stale `last_updated` on heavily edited docs | Set ISO date when merging |
| Kit upgrade available upstream | Follow [UPGRADE.md](../UPGRADE.md); update baseline + project CHANGELOG |

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
| Silent field or `v1_*` / `kpi_q_*` rename | Coordinated contract bump + fixtures + docs ([contracts.md](./contracts.md)) |
| Long docs without Summary | MARKDOWN-STANDARD order |
| Duplicating security matrices into README | Link to ENTERPRISE-SECURITY |
| Merging Excel and Python into one process | Keep runtimes separate; compose via files/CLI ([architecture.md](./architecture.md)) |
| Absolute machine-only paths as the only example | Placeholder + one repo-relative example |
| Orphan files missing from the catalog | Update FILE-CATALOG in the same change |
| Vague commits (`update stuff`, `wip`) | Conventional `type(scope):` subject ([versioning-and-git.md](./versioning-and-git.md)) |
| Code without CLI/methodology/security docs | Same change set as the canonical doc per authority map |
| `feat` commit that only edits markdown | Use `docs` / `docs(scope)` |
| No project `CHANGELOG.md` | Maintain root CHANGELOG (repository H2 → version H3 → category H4) |
| Package version bump without CHANGELOG note | Add matching CHANGELOG entry in the same change set |
| Kit upgrade with no baseline or CHANGELOG note | Update Adopted kit version/date and project CHANGELOG via [UPGRADE.md](../UPGRADE.md) |
| Putting kit release history into project CHANGELOG | Keep kit version only in the [Kit baseline](../RULES.md#kit-baseline) table |
| Inventing an alternate kit source URL | Use https://github.com/shainemeister/repo-kit |
| Leaving SETUP.md forever after adoption | Do not re-add SETUP; keep Kit baseline; use UPGRADE |
| Empty security doc for a surface with no execution/network/privilege/secrets | Omit the file and the authority-map row ([modularity](./security.md#security-documentation-modularity)) |
| Pasting the full multi-language SAST table into this repo | Declare only tools for languages we ship ([language surface inventory](./security.md#language-surface-inventory)) |
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
| Flattening standards onto product root | Keep standards under `kit/` ([hygiene.md](./hygiene.md)) |

---

## Contributor checklist

Before you commit or share a change:

- [ ] Behavior matches the **canonical** doc for that surface (CLI / methodology / security / root README when the landing workflow changed)  
- [ ] [docs/FILE-CATALOG.md](../../docs/FILE-CATALOG.md) updated if paths changed  
- [ ] [Language surface inventory](./security.md#language-surface-inventory) still matches languages the repo ships  
- [ ] Versions and `last_updated` bumped where contracts changed  
- [ ] **CHANGELOG.md** updated when required (release-worthy behavior, version bump, security, kit adopt/upgrade)  
- [ ] Required **verification** from the table above has been run ([Completion rule](#completion-rule))  
- [ ] If product code, gate config, or inventory changed: **full** certification harness passed (`OverallPass` true) — includes **pylint**, Bandit, PSScriptAnalyzer, **Gitleaks**, validate-score  
- [ ] No partial recert; outputs not staged  
- [ ] No secrets, PHI, `output\`, caches, diagnostics certificates, or `last_certification.*` staged  
- [ ] Markdown follows [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md) when docs were edited  
- [ ] Commit message uses `type(scope):` format and matches the staged files  
- [ ] Subject would still make sense years later; one logical surface preferred  
- [ ] Canonical docs for any behavior change are in the same change set ([contracts.md](./contracts.md))  
- [ ] If kit pieces changed: [Kit baseline](../RULES.md#kit-baseline) version/date updated and CHANGELOG notes the upgrade ([UPGRADE.md](../UPGRADE.md))  
- [ ] If AI assisted: commit includes `Assisted-by` / `Compliance` / `Instructed-by` (`Assisted-by` = actual make/model; `Instructed-by` = `git config user.name`)  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.1 | Project fill: full harness verification, Gitleaks required, anti-patterns and checklist |
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0 |
