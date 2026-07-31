---
title: Repository Maintenance Rules
description: Maintenance policy hub—authority map, kit baseline, and index to domain rule modules for workqueue-data-processor.
version: "2.0.0"
status: current
audience:
  - developers
  - analysts
  - security
doc_type: other
related:
  - ../README.md
  - ../CHANGELOG.md
  - ../docs/FILE-CATALOG.md
  - UPGRADE.md
  - MARKDOWN-STANDARD.md
  - rules/hygiene.md
  - rules/authoring-and-style.md
  - rules/architecture.md
  - rules/contracts.md
  - rules/security.md
  - rules/versioning-and-git.md
  - rules/verification-and-ops.md
  - ../kpi-analytics/.pylintrc
  - ../certification/README.md
  - templates/TEMPLATE-CERTIFICATION-README.md
last_updated: "2026-07-30"
---

# Repository Maintenance Rules

Policy for keeping **workqueue-data-processor** professional, auditable, and safe to change. This file is the **hub**: authority map, kit baseline, and Must / Must not. Domain detail lives in [rules/](./rules/).

**If you only need to score work or export Excel:** start with the root [README.md](../README.md) and the toolkit guides. Come back here when you edit code, docs, schema, or release behavior.

**Document version:** 2.0.0  

**Related:** [README.md](../README.md) · [CHANGELOG.md](../CHANGELOG.md) · [docs/FILE-CATALOG.md](../docs/FILE-CATALOG.md) · [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) · [UPGRADE.md](./UPGRADE.md) · [rules/](./rules/) · [kpi-analytics/.pylintrc](../kpi-analytics/.pylintrc) · [certification/README.md](../certification/README.md)

---

## Summary

The product is a **Work Queue data contract** plus two **independent** toolkits:

| Toolkit | Runtime | Role |
|---------|---------|------|
| `excel-toolkit\` | Windows PowerShell 5.1 + Excel COM | CSV ↔ formatted workbook; first-run diagnostics gate |
| `kpi-analytics\` | Python **3.13** stdlib only | CSV → priority scores + RCM KPI Q columns; first-run diagnostics gate |

**Standards** live under **`kit/`**. Product code, data, and project history stay **outside** `kit/`. When contracts change, update the **canonical** file in the **same change set**—see [contracts.md](./rules/contracts.md).

| Must | Must not |
|------|----------|
| Update the **canonical** doc with behavior changes ([contracts](./rules/contracts.md)) | Commit `output\`, caches, secrets, real PHI, or diagnostics / certification certificates |
| Maintain root **CHANGELOG.md** (Keep a Changelog) | Ship version bumps or release-worthy changes without CHANGELOG |
| Keep standards under **`kit/`**; product outside ([hygiene](./rules/hygiene.md)) | Flatten RULES / standards onto product root as default |
| Keep [Kit baseline](#kit-baseline) current after adopt/upgrade | Lose track of kit version after SETUP is gone |
| Use conventional commit messages that match staged files ([versioning-and-git](./rules/versioning-and-git.md)) | Mix unrelated toolkits or leave CLI/security docs stale |
| Keep toolkits independent at the runtime layer ([architecture](./rules/architecture.md)) | Add pip packages or network clients to **product** code |
| Run **pylint** on `kpi_modules` after Python product changes ([authoring-and-style](./rules/authoring-and-style.md)) | Treat pylint as a runtime install for end users |
| Keep [language surface inventory](./rules/security.md#language-surface-inventory) accurate; run declared style + SAST before complete | Paste the full multi-language SAST table without inventory evidence |
| Verify before sharing scoring or COM changes ([verification-and-ops](./rules/verification-and-ops.md)) | Claim complete when a **declared** style or SAST gate was skipped or failed |
| Preserve explainable score / dual KPI attribution ([contracts](./rules/contracts.md)) | Force-kill Excel or permanently alter ExecutionPolicy |
| After product/code changes: renew certification via the **full** harness (Domain B **and** Domain A, including pylint + Gitleaks) | Partial recert; skip pylint or security on renewal; hand-edit cert JSON; commit `last_certification.*`; treat certification as a product launcher gate |
| Coordinated schema / scored-column renames with fixtures + docs | Silently rename schema fields or scored columns |

**Later kit upgrades:** [UPGRADE.md](./UPGRADE.md) (durable). Do **not** re-add permanent `SETUP.md`.

---

## Contents

1. [Summary](#summary)
2. [Authority map](#authority-map)
3. [Domain modules](#domain-modules)
4. [Kit baseline](#kit-baseline)
5. [Upgrading the kit](#upgrading-the-kit)
6. [Document history](#document-history)

---

## Authority map

Update the **owner** document for a change. Cross-link; do not paste full contracts into multiple places ([contracts.md](./rules/contracts.md)).

| Concern | Canonical source |
|---------|------------------|
| End-user purpose and quick start | [README.md](../README.md) |
| Project history (**required**) | [CHANGELOG.md](../CHANGELOG.md) |
| Path-level file inventory | [docs/FILE-CATALOG.md](../docs/FILE-CATALOG.md) |
| Kit upgrade / migration (durable) | [UPGRADE.md](./UPGRADE.md) |
| Markdown structure, frontmatter, author checklist | [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) · [templates/](./templates/) |
| Maintenance policy hub (this file) | **`kit/RULES.md`** ([RULES.md](./RULES.md)) |
| Contract policy (breaking changes, co-updates, cross-links) | [rules/contracts.md](./rules/contracts.md) |
| Root hygiene / packaging (`kit/` vs product) | [rules/hygiene.md](./rules/hygiene.md) |
| Authoring + style gates | [rules/authoring-and-style.md](./rules/authoring-and-style.md) |
| Architecture boundaries | [rules/architecture.md](./rules/architecture.md) |
| Security, inventory, SAST, certification | [rules/security.md](./rules/security.md) |
| Versioning, CHANGELOG rules, git | [rules/versioning-and-git.md](./rules/versioning-and-git.md) |
| Verification, completion, checklist | [rules/verification-and-ops.md](./rules/verification-and-ops.md) |
| Standards kit baseline | [Kit baseline](#kit-baseline) in this file |
| Kit version history (upstream) | Kit source `kit/CHANGELOG.md` under `## repo-kit` |
| Excel CLI (verbs, exit codes, JSON, diagnostics gate) | [excel-toolkit/CLI-GUIDE.md](../excel-toolkit/CLI-GUIDE.md) |
| KPI CLI (verbs, exit codes, JSON, diagnostics gate) | [kpi-analytics/CLI-GUIDE.md](../kpi-analytics/CLI-GUIDE.md) |
| Priority V1 + `kpi_q_*` implementation | [kpi-analytics/SCORE-METHODOLOGY.md](../kpi-analytics/SCORE-METHODOLOGY.md) |
| RCM dual-attribution theory | [kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md](../kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md) |
| Priority design roadmap (V1–V3) | [docs/WQ_Priority_Matrix_Concept.md](../docs/WQ_Priority_Matrix_Concept.md) |
| Excel enterprise / COM posture | [excel-toolkit/ENTERPRISE-SECURITY.md](../excel-toolkit/ENTERPRISE-SECURITY.md) |
| KPI enterprise / offline posture | [kpi-analytics/ENTERPRISE-SECURITY.md](../kpi-analytics/ENTERPRISE-SECURITY.md) |
| Excel diagnostics certificate folder | [excel-toolkit/diagnostics/README.md](../excel-toolkit/diagnostics/README.md) |
| KPI diagnostics certificate folder | [kpi-analytics/diagnostics/README.md](../kpi-analytics/diagnostics/README.md) |
| Language surface inventory | [Language surface inventory](./rules/security.md#language-surface-inventory) (Status + tool names; commands in certification) |
| Security & code-validation certification | [certification/README.md](../certification/README.md) (operator guide + harness; renewal policy in [security.md](./rules/security.md)). Package diagnostics stay under each toolkit — do **not** merge them here |
| Field definitions | [wq_schema/wq_schema.json](../wq_schema/wq_schema.json) (CSV twin: [wq_schema/wq_schema.csv](../wq_schema/wq_schema.csv)) |
| Sample fact rows | [wq_schema/wq_data.csv](../wq_schema/wq_data.csv) |
| Default score config | [kpi-analytics/kpi_modules/config_default.json](../kpi-analytics/kpi_modules/config_default.json) |
| Golden tests | [kpi-analytics/fixtures/](../kpi-analytics/fixtures/) |
| KPI Python style / PEP-8 gate | [kpi-analytics/.pylintrc](../kpi-analytics/.pylintrc) (dev tooling only; kit starter: [configs/pylintrc](./configs/pylintrc)) |

**Rule:** Adding, removing, or renaming intentional source files requires a same-change update to [docs/FILE-CATALOG.md](../docs/FILE-CATALOG.md).

---

## Domain modules

| Module | Topic |
|--------|--------|
| [rules/hygiene.md](./rules/hygiene.md) | Packaging: standards under `kit/`; product outside; SETUP/UPGRADE lifecycle |
| [rules/authoring-and-style.md](./rules/authoring-and-style.md) | Docs rules; formatting; pylint; PowerShell style |
| [rules/architecture.md](./rules/architecture.md) | Entry points, composition, runtime separation, dependencies |
| [rules/contracts.md](./rules/contracts.md) | What is a contract; co-updates; data/schema; cross-reference policy |
| [rules/security.md](./rules/security.md) | Trust baseline; inventory; SAST; certification renewal |
| [rules/versioning-and-git.md](./rules/versioning-and-git.md) | Version surfaces; CHANGELOG; commits; AI disclosure |
| [rules/verification-and-ops.md](./rules/verification-and-ops.md) | Verify table; completion; cadence; anti-patterns; checklist |

---

## Kit baseline

Durable record of **which kit version** this project adopted and **where upgrades come from**.

| Field | Value |
|-------|--------|
| Adopted kit version | **2.0.1** |
| Adopted on | **2026-07-30** |
| Kit source | https://github.com/shainemeister/repo-kit |

**Kit source** is always **https://github.com/shainemeister/repo-kit** for this standards kit. Update **Adopted kit version** and **Adopted on** on every kit upgrade.

---

## Upgrading the kit

**Do not use SETUP after initiation.** Follow the durable guide:

→ **[UPGRADE.md](./UPGRADE.md)** — routine upgrade procedure, **1.x / root-layout → 2.x** migration, merge options, and copy-paste AI prompts.

Short reminder: read Kit baseline in `kit/RULES.md` → open Kit source `kit/CHANGELOG.md` under `## repo-kit` → merge deltas into project `kit/` → preserve product paths and verification → update baseline + project root CHANGELOG note.

Upstream prompt: [repo-kit README — Upgrade repo-kit](https://github.com/shainemeister/repo-kit#upgrade-repo-kit).

---

## Document history

| Version | Notes |
|---------|--------|
| 2.0.0 | Migrated to repo-kit **2.0.1**: standards under `kit/`; hub + domain modules; filled authority map and product Must/Must not preserved; upgrade deferred to UPGRADE.md |
| 1.6.2 | (pre-split, root layout) Aligned with repo-kit **1.2.1**; see project CHANGELOG and prior root RULES history |
| 1.6.x–1.0.0 | Monolithic root RULES lineage before kit 2.x layout |
