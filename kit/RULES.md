---
title: Repository Maintenance Rules
description: Maintenance policy hub—authority map, kit baseline, and index to domain rule modules for workqueue-data-processor.
version: "2.4.0"
status: current
audience:
  - developers
  - analysts
  - security
doc_type: other
related:
  - ../README.md
  - ../CHANGELOG.md
  - ../PLAN.md
  - ../docs/FILE-CATALOG.md
  - ../docs/README.md
  - UPGRADE.md
  - MARKDOWN-STANDARD.md
  - agents/README.md
  - agents/OPS.md
  - rules/hygiene.md
  - rules/authoring-and-style.md
  - rules/architecture.md
  - rules/contracts.md
  - rules/security.md
  - rules/versioning-and-git.md
  - rules/verification-and-ops.md
  - rules/ai-docs-workspace.md
  - rules/workboard.md
  - rules/continuity.md
  - ../kpi-analytics/.pylintrc
  - ../certification/README.md
  - templates/TEMPLATE-CERTIFICATION-README.md
last_updated: "2026-08-12"
---

# Repository Maintenance Rules

Policy for keeping **workqueue-data-processor** professional, auditable, and safe to change. This file is the **hub**: authority map, kit baseline, Operator enforcement, and Must / Must not. Domain detail lives in [rules/](./rules/).

**If you only need to score work or export Excel:** start with the root [README.md](../README.md) and the toolkit guides. Come back here when you edit code, docs, schema, or release behavior.

**Document version:** 2.4.0  

**Related:** [README.md](../README.md) · [CHANGELOG.md](../CHANGELOG.md) · [PLAN.md](../PLAN.md) · [docs/FILE-CATALOG.md](../docs/FILE-CATALOG.md) · [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) · [UPGRADE.md](./UPGRADE.md) · [agents/OPS.md](./agents/OPS.md) · [rules/](./rules/) · [kpi-analytics/.pylintrc](../kpi-analytics/.pylintrc) · [certification/README.md](../certification/README.md)

---

## Summary

The product is a **Work Queue data contract** plus two **independent** toolkits:

| Toolkit | Runtime | Role |
|---------|---------|------|
| `excel-toolkit\` | Windows PowerShell 5.1 + Excel COM | CSV ↔ formatted workbook; first-run diagnostics gate |
| `kpi-analytics\` | Python **3.13** stdlib only | CSV → priority scores + RCM KPI Q columns; first-run diagnostics gate |

**Standards** live under **`kit/`**. Product code, data, project history, and the AI docs workspace stay **outside** `kit/`. When contracts change, update the **canonical** file in the **same change set**—see [contracts.md](./rules/contracts.md).

| Must | Must not |
|------|----------|
| Update the **canonical** doc with behavior changes ([contracts](./rules/contracts.md)) | Commit `output\`, caches, secrets, real PHI, or diagnostics / certification certificates |
| Maintain root **CHANGELOG.md** (Keep a Changelog) | Ship version bumps or release-worthy changes without CHANGELOG |
| Keep standards under **`kit/`**; product outside ([hygiene](./rules/hygiene.md)) | Flatten RULES / standards onto product root as default |
| Keep [Kit baseline](#kit-baseline) current after adopt/upgrade | Lose track of kit version after SETUP is gone |
| Use conventional commit messages that match staged files; when AI assisted include `Assisted-by` / `Compliance` / `Instructed-by` ([versioning-and-git](./rules/versioning-and-git.md#ai-assisted-commits-required-disclosure)) | Mix unrelated toolkits, omit AI disclosure when assisted, or invent a `Directed-by` trailer |
| Keep toolkits independent at the runtime layer ([architecture](./rules/architecture.md)) | Add pip packages or network clients to **product** code |
| Run **pylint** on `kpi_modules` after Python product changes ([authoring-and-style](./rules/authoring-and-style.md)) | Treat pylint as a runtime install for end users |
| Keep [language surface inventory](./rules/security.md#language-surface-inventory) accurate; run declared style + SAST before complete | Paste the full multi-language SAST table without inventory evidence |
| Verify before sharing scoring or COM changes ([verification-and-ops](./rules/verification-and-ops.md)) | Claim complete when a **declared** style or SAST gate was skipped or failed |
| Preserve explainable score / dual KPI attribution ([contracts](./rules/contracts.md)) | Force-kill Excel or permanently alter ExecutionPolicy |
| After product/code changes: renew certification via the **full** harness (Domain B **and** Domain A, including pylint + Gitleaks) | Partial recert; skip pylint or security on renewal; hand-edit cert JSON; commit `last_certification.*`; treat certification as a product launcher gate |
| Coordinated schema / scored-column renames with fixtures + docs | Silently rename schema fields or scored columns |
| Treat Agent Instruct packs as **views** over this hub + domain modules ([agents](./agents/README.md)) | Embed full persona bodies in this hub; invent a second RULES tree in packs |
| **When Agent Instruct is in use:** match the user task to **one primary** expert pack; follow [OPS](./agents/OPS.md) O3 | Ignore active packs and improvise durable policy only in chat |
| **When Instruct is in use:** open pack expertise; co-update **canonical L4** in the same change set | Load all generated packs, or use remote URLs as overlays/law |
| **When Instruct is in use:** evolve agents (PLAN + [BUILD](./agents/BUILD.md)) when features, packages, surfaces, languages, or durable task classes appear | Leave packs stale after authority map / inventory / enablement change |
| Follow [Operator enforcement](#operator-enforcement) on every maintenance turn | Skip request verify, procedure check, or Progress Tracker when advancing repo work |
| Dynamically build and maintain root **`docs/`** AI workspace when research/plan/build context is needed ([ai-docs-workspace](./rules/ai-docs-workspace.md)) | Put project research under `kit/`; use `docs/` as dual home for public contracts; abandon stale critical plans without status |
| Track **multi-phase** work on [docs/WORKBOARD.md](../docs/WORKBOARD.md) ([workboard](./rules/workboard.md)) | Start multi-phase work only in chat or unlinked folders; paste live phase tables into PLAN.md |
| Prefer surgical edits when a [continuity](./rules/continuity.md) overlay is in use | Full-file rewrite of a named protected surface without an explicit restore ask |

**Later kit upgrades:** [UPGRADE.md](./UPGRADE.md) (durable). Do **not** re-add permanent `SETUP.md`. **Agent Instruct:** [agents/README.md](./agents/README.md) · [agents/OPS.md](./agents/OPS.md). **AI workspace:** [docs/README.md](../docs/README.md) · [ai-docs-workspace](./rules/ai-docs-workspace.md). **Multi-phase execution:** [workboard](./rules/workboard.md) · `docs/WORKBOARD.md`.

---

## Operator enforcement

Standing checklist for AI and humans **maintaining this repository**. Domain detail stays in linked modules—do **not** treat this list as a second RULES tree.

| # | Must | Detail / owner |
|---|------|----------------|
| 1 | **Verify the user request** and comply with this hub + domain modules | Open the [authority map](#authority-map); do not invent policy outside L4 |
| 2 | **Validate the procedure** before execution | When Instruct: [OPS O3](./agents/OPS.md). Always: declared gates and completion ([verification-and-ops](./rules/verification-and-ops.md)) |
| 3 | **Apply the appropriate Agent / Persona** for the task | When Instruct is in use: one primary expert pack ([OPS](./agents/OPS.md), [When Instruct is in use](#when-agent-instruct-is-in-use)). Bare adopt: this hub + domain modules only |
| 4 | **Plan + AI `docs/` workspace** when work is multi-step, research, or durable | Root [PLAN.md](../PLAN.md) for mission/Agent models (not a todo list). **Multi-phase:** register and update **`docs/WORKBOARD.md`** ([workboard](./rules/workboard.md)) before phase code. Product backlog → [docs/PLAN.md](../docs/PLAN.md); detailed plans / optional annex → `docs/plan/`; research → `docs/research/`; build context → `docs/project_build/`; curated refs → `docs/resources/` ([ai-docs-workspace](./rules/ai-docs-workspace.md)). Scaffold modules **when needed**. Skip for trivial single-step replies |
| 5 | **Git format + confirm complete** | Conventional commits match staged files ([versioning-and-git](./rules/versioning-and-git.md)); when AI assisted, end the message with `Assisted-by` / `Compliance` / `Instructed-by` (dynamic `Instructed-by`: git `user.name` → ask+record → `User` — [AI disclosure](./rules/versioning-and-git.md#ai-assisted-commits-required-disclosure)); confirm L4 co-updates and declared gates before “done” ([completion rule](./rules/verification-and-ops.md#completion-rule)); promote durable findings from `docs/` to L4 when they become promises |
| 6 | **Progress Tracker** at the end of each reply that advances work | Ordered tasks with status; **commit SHA** for each completed task that was committed; `—` if not committed. Durable notes belong in `docs/`, not only the tracker |

### Progress Tracker (minimum shape)

End every reply that advances repository work with:

```markdown
### Progress Tracker
| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | … | done | `abc1234` |
| 2 | … | in progress | — |
```

| Field | Values / rule |
|-------|----------------|
| **Status** | `done` · `in progress` · `blocked` · `skipped` |
| **Commit** | Short or full SHA when that ordered task produced a git commit; otherwise `—` |
| Pure Q&A (no repo work) | One line is enough: `Progress: no repo changes` |

Do not invent commit SHAs. Do not require a commit for every tracker row.

---

## Contents

1. [Summary](#summary)
2. [Operator enforcement](#operator-enforcement)
3. [Authority map](#authority-map)
4. [Domain modules](#domain-modules)
5. [When Agent Instruct is in use](#when-agent-instruct-is-in-use)
6. [Kit baseline](#kit-baseline)
7. [Upgrading the kit](#upgrading-the-kit)
8. [Document history](#document-history)

---

## Authority map

Update the **owner** document for a change. Cross-link; do not paste full contracts into multiple places ([contracts.md](./rules/contracts.md)).

| Concern | Canonical source |
|---------|------------------|
| End-user purpose and quick start | [README.md](../README.md) |
| Project history (**required**) | [CHANGELOG.md](../CHANGELOG.md) |
| Project control surface + Agent models | Root [PLAN.md](../PLAN.md) |
| Product enhancement backlog | [docs/PLAN.md](../docs/PLAN.md) |
| Path-level file inventory | [docs/FILE-CATALOG.md](../docs/FILE-CATALOG.md) |
| AI docs workspace index | [docs/README.md](../docs/README.md) |
| AI docs workspace policy | [rules/ai-docs-workspace.md](./rules/ai-docs-workspace.md) |
| Active multi-phase work / next phase | [docs/WORKBOARD.md](../docs/WORKBOARD.md) — [workboard](./rules/workboard.md); skip if no multi-phase work |
| Workboard / annex / archive policy | [rules/workboard.md](./rules/workboard.md) |
| Code continuity overlay (optional) | Portable policy [rules/continuity.md](./rules/continuity.md); filled overlay **not recorded** (deferred) |
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
| Agent Instruct (framework, catalog, BUILD, runtime, OPS) | [agents/README.md](./agents/README.md) |
| Agent utilization (order of operations) | [agents/OPS.md](./agents/OPS.md) |
| Generated agent packs | [agents/generated/](./agents/generated/) |
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
| [rules/ai-docs-workspace.md](./rules/ai-docs-workspace.md) | Root `docs/` AI resource workspace (research, workboard, plan, project_build, resources) |
| [rules/workboard.md](./rules/workboard.md) | Multi-phase execution: single board, phase ship, annex archive, agent resume |
| [rules/continuity.md](./rules/continuity.md) | Optional surgical-edit overlay policy (no product paths in kit defaults) |

### Optional Instruct (not foldable)

| Path | Topic |
|------|--------|
| [agents/](./agents/) | Agent Instruct — L3 **views** over this hub + `rules/*`; **not** a replacement for domain modules |
| [agents/OPS.md](./agents/OPS.md) | Utilization O3 when Instruct is in use |

**Do not fold** full Agent Instruct personas, templates, or generated packs into this hub. Keep **description + link only** in the [authority map](#authority-map).

---

## When Agent Instruct is in use

This repository **uses Agent Instruct**. Root [PLAN.md](../PLAN.md) owns the **Agent models** section. Generated packs live under [agents/generated/](./agents/generated/).

When working in this repository:

1. Match the user task to **one primary** expert pack (see [OPS](./agents/OPS.md)).  
2. Open pack expertise (`authority_paths` + references); do not invent law outside L4.  
3. Co-update canonical L4 docs/rules in the same change set when behavior changes.  
4. Evolve agents via PLAN Agent models + [BUILD](./agents/BUILD.md) when features, packages, surfaces, languages, or durable task classes appear.  
5. On conflict between a pack and this hub / domain modules / product contracts, **L4 wins**.

**Disabled** packs listed in PLAN must not be used as primary. External `https://` citations in expertise are guidance only—not overlays or law.

---

## Kit baseline

Durable record of **which kit version** this project adopted and **where upgrades come from**.

| Field | Value |
|-------|--------|
| Adopted kit version | **2.4.0** |
| Adopted on | **2026-08-12** |
| Kit source | https://github.com/shainemeister/repo-kit |

**Kit source** is always **https://github.com/shainemeister/repo-kit** for this standards kit. Update **Adopted kit version** and **Adopted on** on every kit upgrade.

---

## Upgrading the kit

**Do not use SETUP after initiation.** Follow the durable guide:

→ **[UPGRADE.md](./UPGRADE.md)** — routine upgrade procedure, **1.x / root-layout → 2.x** migration, Agent Instruct preserve/regen, merge options, and copy-paste AI prompts.

Short reminder: read Kit baseline in `kit/RULES.md` → open Kit source `kit/CHANGELOG.md` under `## repo-kit` → merge deltas into project `kit/` → preserve product paths, verification, PLAN Agent models, root `docs/` content, and any filled `docs/WORKBOARD.md` → update baseline + project root CHANGELOG note → re-run BUILD when agents are in use.

Upstream prompt: [repo-kit README — Upgrade repo-kit](https://github.com/shainemeister/repo-kit#upgrade-repo-kit).

---

## Document history

| Version | Notes |
|---------|--------|
| 2.4.0 | Plan control: workboard + optional continuity; Operator step 4 names the board; authority-map and domain index (kit 2.4.0). Product fills preserved |
| 2.3.1 | Upgraded repo-kit **2.3.1**: Operator enforcement, AI docs workspace, Agent Instruct adoption, Instructed-by cascade; product authority map and Must/Must not preserved |
| 2.0.0 | Migrated to repo-kit **2.0.1**: standards under `kit/`; hub + domain modules; filled authority map and product Must/Must not preserved; upgrade deferred to UPGRADE.md |
| 1.6.2 | (pre-split, root layout) Aligned with repo-kit **1.2.1**; see project CHANGELOG and prior root RULES history |
| 1.6.x–1.0.0 | Monolithic root RULES lineage before kit 2.x layout |
