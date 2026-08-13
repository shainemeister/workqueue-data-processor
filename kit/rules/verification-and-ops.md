---
title: Verification and Operations
description: Verification before ship, completion rule, maintenance cadence, anti-patterns, and contributor checklist.
version: "1.5.0"
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
  - ./ai-docs-workspace.md
  - ./workboard.md
  - ../MARKDOWN-STANDARD.md
  - ../UPGRADE.md
  - ../agents/README.md
  - ../agents/OPS.md
  - ../agents/BUILD.md
  - ../agents/PARAMS.md
  - ../../certification/README.md
  - ../../docs/FILE-CATALOG.md
last_updated: "2026-08-12"
---

# Verification and Operations

Ship gates, completion rules, cadence, anti-patterns, and the contributor checklist.

**Document version:** 1.5.0  

**Related:** [RULES.md](../RULES.md) · [security.md](./security.md) · [authoring-and-style.md](./authoring-and-style.md) · [contracts.md](./contracts.md) · [versioning-and-git.md](./versioning-and-git.md) · [ai-docs-workspace.md](./ai-docs-workspace.md) · [workboard.md](./workboard.md) · [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md) · [UPGRADE.md](../UPGRADE.md) · [agents/README.md](../agents/README.md) · [agents/OPS.md](../agents/OPS.md) · [certification/README.md](../../certification/README.md)

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
| **Product code, gate config, or inventory** | **Full certification package:** `.\certification\Invoke-Certification.ps1` (Domain B **and** Domain A, including pylint + Bandit + PSSA + Gitleaks + validate-score + **dynamic Security invariants** + **policy-scan**). Confirm `OverallPass`; do not stage outputs. See [renewal enforcement](./security.md#certification-renewal-enforcement-required) |
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
| Agent template / catalog change | Pack samples validate ([agents/PARAMS.md](../agents/PARAMS.md)); expertise/references present; PLAN-HOOK fields still accurate |
| BUILD regen only | Diff review; no authority path invention; respect PLAN disabled set; expertise filled |
| New project agent pack | Schema fields complete; expertise map + references; verify[] from this table only; PLAN active_models/overlays updated |
| Feature / surface / durable task-class growth (Instruct in use) | PLAN Agent models lifecycle + [BUILD](../agents/BUILD.md); co-update canonical L4 ([agents/OPS.md](../agents/OPS.md)) |
| Research / multi-step plan / non-trivial build context | Maintain relevant root `docs/` modules ([ai-docs-workspace](./ai-docs-workspace.md)); keep `docs/README.md` index honest |
| Multi-phase program / phase ship | Update `docs/WORKBOARD.md` same change set ([workboard](./workboard.md)); L4 + CHANGELOG if contracts/behavior |
| Finding becomes public product promise | Promote from `docs/` to authority-map L4 owner ([contracts](./contracts.md)); same change set |

Individual Domain A/B commands remain documented in [certification/README.md](../../certification/README.md). For ship/complete after code changes, use the **full harness**—not a subset.

---

## Completion rule

Do **not** mark a change complete, and do **not** claim ship readiness, if any **declared** Domain B (code validation / style) or Domain A (security / SAST / secrets) gate was skipped or failed. **Gitleaks is required.** Missing required developer tools is a **failed** gate, not a skip.

When product code, certification gate definitions, or inventory Status changed: certification is **stale** until `.\certification\Invoke-Certification.ps1` completes with `OverallPass = true`. Partial renewal (security-only or pylint-only) does **not** satisfy completion. Package diagnostics gates remain required for scoring/export paths as before; they do not replace Domain A/B tools or formal certification.

---

## Before marking work complete

Ordered steps for humans and AI agents:

1. Follow [Operator enforcement](../RULES.md#operator-enforcement) (verify request, validate procedure, persona when Instruct, plan + `docs/` when needed).  
2. **If Agent Instruct is in use:** follow [OPS O3](../agents/OPS.md#order-of-operations-o3)—match **one primary** expert pack, open expertise, co-maintain L4. Bare adopt (no Agent models) skips this step.  
3. **If research / multi-step plan / non-trivial build:** ensure root `docs/` modules are scaffolded/updated ([ai-docs-workspace](./ai-docs-workspace.md)). **If a multi-phase phase shipped:** `docs/WORKBOARD.md` status `done` + commit SHA ([workboard](./workboard.md)).  
4. Read **language surface inventory** (**Declared:** Python, PowerShell, **Secrets**).  
5. If product code, gate config, or inventory changed: run **full** certification (`.\certification\Invoke-Certification.ps1`) — Domain B (including **pylint**) **and** Domain A (including **Gitleaks**) together. Confirm `OverallPass`; leave outputs unstaged.  
6. Otherwise (narrow docs-only): run any applicable lightweight checks; renewal optional per exception.  
7. Run package probes/diagnostics as needed for product paths (separate from certification).  
8. Update canonical L4 docs / [CHANGELOG.md](../../CHANGELOG.md) per the [authority map](../RULES.md#authority-map); promote durable findings out of `docs/` when they become promises.  
9. **If Agent Instruct is in use** and PLAN Agent models, agent templates, authority paths, expertise, or durable feature/surface growth changed: re-run [BUILD](../agents/BUILD.md); validate packs per [PARAMS](../agents/PARAMS.md); review diffs.  
10. End work-advancing replies with a [Progress Tracker](../RULES.md#progress-tracker-minimum-shape) (commit SHA for completed committed tasks).  
11. Only then state the task is complete.

---

## Maintenance cadence

| Trigger | Action |
|---------|--------|
| Every source path add/remove/rename | Update [docs/FILE-CATALOG.md](../../docs/FILE-CATALOG.md) |
| Language surface added or removed | Update [language surface inventory](./security.md#language-surface-inventory) + `certification/checks.json` / README |
| Every release-worthy toolkit behavior change | Bump code version; refresh CLI guide and status blocks; update [CHANGELOG.md](../../CHANGELOG.md) |
| Every product code edit (`kpi_modules` or excel-toolkit product scripts) | Run **full** [certification harness](../../certification/Invoke-Certification.ps1); do not partial-recert |
| Security-relevant change | Update matching ENTERPRISE-SECURITY; full certification renewal; CHANGELOG entry |
| Formal certification | Always renew via full suite after qualifying changes; never commit outputs |
| Fixture failure after intentional math/logic change | Refresh expected outputs only with methodology note |
| Stale `last_updated` on heavily edited docs | Set ISO date when merging |
| Kit upgrade available upstream | Follow [UPGRADE.md](../UPGRADE.md); update baseline + project CHANGELOG |
| PLAN Agent models change (active/disabled/overlays/tuning) | Re-run [BUILD](../agents/BUILD.md); review generated pack diff |
| Kit agents templates / CATALOG upgrade | Merge `kit/agents/` (include OPS); preserve PLAN Agent models; BUILD regen ([UPGRADE](../UPGRADE.md)) |
| New durable project agent | Emit pack under `kit/agents/generated/` with expertise map; update PLAN; authority-map row only if durable and needed |
| New package, public surface, language, or durable task class (Instruct in use) | Update PLAN Agent models as needed; BUILD; co-update L4 contracts ([OPS lifecycle](../agents/OPS.md#lifecycle-features-and-core-tasks)) |
| Every substantive task when Instruct is in use | Primary pack match per [OPS](../agents/OPS.md); do not skip utilization |
| Research / multi-step plan / build notes | Update `docs/` modules; keep index accurate ([ai-docs-workspace](./ai-docs-workspace.md)) |
| Multi-phase phase or program ship | Workboard status + SHA; archive annex on program complete ([workboard](./workboard.md)) |
| First use of AI workspace | Scaffold `docs/README.md` + needed modules from [templates/docs](../templates/docs/) |

---

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| `pip install` “just this once” in **product** kpi-analytics | Stdlib solution or redesign the requirement |
| Shipping pylint as a product runtime dependency | Keep pylint developer-only; product remains stdlib-only |
| Skipping pylint after Python product edits | Run `py -3.13 -m pylint kpi_modules` from `kpi-analytics\` |
| Force-killing Excel to “clean up” | Quit → wait → one retry → warn user |
| Committing `output\wq_scored*.csv` or `.xlsx` | Document regenerate commands in README / catalog |
| Committing `last_diagnostics.json` / `.txt` | Leave regenerable; only track diagnostics `README.md` |
| Silent field or `v1_*` / `kpi_q_*` rename | Coordinated contract bump + fixtures + docs ([contracts.md](./contracts.md)) |
| Merging Excel and Python into one process | Keep runtimes separate; compose via files/CLI ([architecture.md](./architecture.md)) |
| Partial recert (only pylint, only Bandit, only Gitleaks) | Always run full `Invoke-Certification.ps1` after code changes |
| Merging package diagnostics into `certification/` | Keep `diagnostics/` for machine readiness; `certification/` for source-tree self-attestation only |
| Committing regenerable outputs “for convenience” | Document regenerate commands in README / catalog |
| Long docs without Summary | MARKDOWN-STANDARD order |
| Duplicating security matrices into README | Link to security doc |
| Merging unrelated runtimes into one process without design | Keep boundaries ([architecture.md](./architecture.md)) |
| Absolute machine-only paths as the only example | Placeholder + one repo-relative example |
| Orphan files missing from the inventory | Update catalog in the same change |
| Vague commits (`update stuff`, `wip`) | Conventional `type(scope):` subject ([versioning-and-git.md](./versioning-and-git.md)) |
| Code without CLI/methodology/security docs when those contracts apply | Same change set as the canonical doc; omit security when [modularity](./security.md#security-documentation-modularity) allows |
| Empty `SECURITY.md` for docs-only or pure libraries with no side effects | Omit the file and the authority-map row |
| Pasting the full multi-language SAST table into every project | Declare only tools for languages the repo ships |
| Claiming complete while skipping a **declared** style or SAST gate | Run inventory gates; see [Completion rule](#completion-rule) |
| Shipping Bandit / npm audit / Gitleaks / etc. as product runtime deps | Keep security / SAST tools developer-only |
| Committing `certification/last_certification.*` | Gitignore regenerable cert outputs; regenerate locally |
| Treating certification as a product launcher / diagnostics gate | Certification attests **source tree** policy only |
| Empty language inventory while shipping product code | Fill inventory when product languages exist |
| `feat` commit that only edits markdown | Use `docs` / `docs(scope)` |
| Leaving SETUP.md forever after adoption | Delete or archive after initiation; keep [Kit baseline](../RULES.md#kit-baseline); use [UPGRADE.md](../UPGRADE.md) |
| Language style “somehow” without a named gate | Declare tool + pass criteria in verification table |
| No project `CHANGELOG.md` | Maintain root CHANGELOG (repository H2 → version H3 → category H4) |
| Package version bump without CHANGELOG section | Add matching `### [X.Y.Z]` in the same change set |
| Shipping release-worthy behavior without CHANGELOG | Same change set: behavior + canonical docs + version + CHANGELOG |
| Kit upgrade with no baseline or CHANGELOG note | Update Adopted kit version/date and project CHANGELOG via [UPGRADE.md](../UPGRADE.md) |
| Inventing an alternate kit source URL | Use https://github.com/shainemeister/repo-kit (unless a deliberate fork) |
| Putting kit release history into a project `CHANGELOG.md` | Keep kit version only in the Kit baseline table |
| Pack body restates full domain modules | Link `authority_paths`; short procedure + expertise map ([agents](../agents/README.md)) |
| Treating Agent Instruct as a Domain A/B gate | Policy + AI convention; real gates = inventory ([Completion rule](#completion-rule)) |
| Instruct in use but skip primary-pack match | Follow [OPS O3](../agents/OPS.md) |
| Empty expertise / no references on expert packs | Curated authority_paths + references with purpose |
| External URL as overlay or substitute law | Citations only under references/expertise; L4 wins |
| Feature ships; packs unchanged (Instruct in use) | PLAN lifecycle + BUILD |
| Research only in chat; no `docs/` when multi-source work needed | Scaffold/maintain `docs/research/` ([ai-docs-workspace](./ai-docs-workspace.md)) |
| Chat-only “phase done” with no board update | Same-change-set `docs/WORKBOARD.md` ([workboard](./workboard.md)) |
| Live phase tables dumped into PLAN.md | Board + optional annex; PLAN stays doctrine |
| Public contract only under `docs/` | Promote to L4 package/kit owner |
| UPGRADE resets PLAN `active_models` | Preserve Agent models + BUILD regen ([UPGRADE](../UPGRADE.md)) |
| Full persona essays in `kit/RULES.md` | Map description + path only ([OPS](../agents/OPS.md) link) |
| Inventing pack verify tools not in RULES / inventory | `verify[]` only from declared verification table |
| Gitignoring generated packs with no rebuild path | Track thin packs under `kit/agents/generated/` or document regen |

---

## Contributor checklist

Before you commit or share a change:

- [ ] Behavior matches the **canonical** doc for that surface (CLI / API / methodology / security / README)  
- [ ] Inventory/catalog updated if paths changed (when maintained)  
- [ ] [Language surface inventory](./security.md#language-surface-inventory) still matches languages the repo ships  
- [ ] Versions and `last_updated` bumped where contracts changed  
- [ ] **CHANGELOG.md** updated when required (release-worthy behavior, version bump, security, kit adopt/upgrade)  
- [ ] Required **verification** from the table above has been run ([Completion rule](#completion-rule))  
- [ ] If product Python changed: **pylint** passed; **Bandit** passed when Python is in inventory  
- [ ] Other declared language surfaces: Domain B + Domain A gates passed for surfaces touched  
- [ ] If `certification/` is maintained: certificate regenerated; OverallPass true; outputs not staged  
- [ ] No secrets, sensitive production data, regenerable outputs, or caches staged  
- [ ] Markdown follows [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md) when docs were edited  
- [ ] Commit message uses `type(scope):` format and matches the staged files  
- [ ] Subject would still make sense years later; one logical surface preferred  
- [ ] Canonical docs for any behavior change are in the same change set ([contracts.md](./contracts.md))  
- [ ] If kit pieces changed: [Kit baseline](../RULES.md#kit-baseline) version/date updated and CHANGELOG notes the upgrade ([UPGRADE.md](../UPGRADE.md))  
- [ ] [Operator enforcement](../RULES.md#operator-enforcement) followed (request verify, procedure, plan + `docs/` when needed)  
- [ ] If research/multi-step/build context: relevant `docs/` modules updated; index honest ([ai-docs-workspace](./ai-docs-workspace.md))  
- [ ] If a multi-phase phase shipped: workboard updated (status + SHA) in the same change set ([workboard](./workboard.md))  
- [ ] If Agent Instruct used: primary pack matched per [OPS](../agents/OPS.md); expertise opened; L4 co-maintained  
- [ ] If Agent Instruct used and enablement/templates/authority paths/expertise or feature/surface growth for agents changed: [BUILD](../agents/BUILD.md) regen; thin packs reviewed  
- [ ] Agent packs do not redefine L4 law; `authority_paths` / expertise / `verify` align with RULES ([agents](../agents/README.md))  
- [ ] PLAN Agent models preserved across kit upgrade (when agents are in use)  
- [ ] Progress Tracker included on work-advancing replies ([RULES](../RULES.md#progress-tracker-minimum-shape))  
- [ ] If AI assisted: commit includes `Assisted-by` / `Compliance` / `Instructed-by` with `Instructed-by` resolved dynamically (`git config user.name` → ask+record → `User`; no `Directed-by`) ([versioning-and-git](./versioning-and-git.md#ai-assisted-commits-required-disclosure))  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.5.0 | Multi-phase workboard before-complete, cadence, anti-pattern, checklist (kit 2.4.0). Product cert/Gitleaks table preserved |
| 1.4.1 | AI disclosure checklist: dynamic Instructed-by cascade; no Directed-by (kit 2.3.1) |
| 1.4.0 | AI docs workspace verification, cadence, anti-patterns, checklist (kit 2.3.0) |
| 1.3.1 | Operator enforcement + Progress Tracker in before-complete and checklist (kit 2.2.1) |
| 1.3.0 | Instruct O3 in before-complete; lifecycle cadence; expertise anti-patterns; checklist OPS (kit 2.2.0) |
| 1.2.0 | Agent Instruct: verification rows for template/catalog/BUILD; cadence; anti-patterns; before-complete step; contributor checklist (editorial 1.1.0 intermediate folded here—not a separate kit release) |
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0 |
