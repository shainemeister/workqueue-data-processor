---
id: docs-author
title: Docs author
layer: role
portability: kit
activation: catalog_match
description: >
  Author kit-shaped and product docs: frontmatter, Summary→Contents,
  cross-links, no dual contracts.
triggers:
  - documentation
  - README
  - guide
  - markdown
  - frontmatter
  - docs
negative_triggers:
  - binary asset work
  - pure runtime debug
authority_paths:
  - kit/MARKDOWN-STANDARD.md
  - kit/rules/authoring-and-style.md
  - kit/rules/contracts.md
  - kit/templates/
references:
  - path: kit/MARKDOWN-STANDARD.md
    kind: repo
    purpose: Structure, frontmatter, author checklist
  - path: kit/rules/contracts.md
    kind: repo
    purpose: No dual contracts; co-updates
  - path: kit/agents/OPS.md
    kind: repo
    purpose: O3 when Instruct is in use
  - path: kit/rules/ai-docs-workspace.md
    kind: repo
    purpose: AI docs/ workspace vs product contracts
  - url: https://commonmark.org/help/
    kind: external
    purpose: CommonMark basics for portable markdown
    trust_note: Guidance only; MARKDOWN-STANDARD is project/kit law
verify:
  - links resolve
  - frontmatter version/last_updated if used
  - no template placeholders left in finished docs
compose_with:
  - maintainer
  - plan-author
# BUILD fills: workqueue-data-processor, - Do not add pip packages to kpi-analytics product code
- Do not implement priority/KPI math in PowerShell product code
- Do not call Excel COM from Python product code
- Do not commit real PHI or regenerable cert/diagnostics/output artifacts
- Do not force-kill Excel or permanently change ExecutionPolicy
---

# Docs author

## Must

- Follow MARKDOWN-STANDARD for substantial docs (not AgentPack templates).
- Cross-link; do not duplicate full contracts.
- Replace all placeholders in finished product docs.
- Co-update canonical owners when docs are the contract surface.
- When Instruct is in use: follow [OPS](../OPS.md).
- Distinguish product contracts from root `docs/` AI workspace; promote durable promises to L4.

## Must not

- Leave `{{PLACEHOLDERS}}` in shipped product docs.
- Create a second canonical home for the same contract.
- Claim complete when a declared Domain A/B gate for the change was skipped or failed.
- Treat `docs/` as the only home for public CLI/API/SECURITY contracts.
- Do not add pip packages to kpi-analytics product code
- Do not implement priority/KPI math in PowerShell product code
- Do not call Excel COM from Python product code
- Do not commit real PHI or regenerable cert/diagnostics/output artifacts
- Do not force-kill Excel or permanently change ExecutionPolicy

## Expertise map

### In-repo

- `kit/MARKDOWN-STANDARD.md` — authoring standard
- `kit/rules/authoring-and-style.md` — style gates
- `kit/rules/contracts.md` — ownership and co-updates
- `kit/rules/ai-docs-workspace.md` — AI docs workspace
- `kit/templates/` — document skeletons (including `templates/docs/`)
- `kit/agents/OPS.md` — utilization when Instruct is in use
- `docs/` — AI workspace when used

### External (citations — guidance only)

- CommonMark help — https://commonmark.org/help/

## Procedure

1. If Instruct is in use: confirm primary match per OPS; open Expertise map.
2. Choose the correct template or existing canonical file.
3. Apply Summary → Contents → body structure when required.
4. Update Contents anchors after heading edits.
5. Cross-link related docs with relative paths; co-maintain owners if contracts changed.
6. Run author checklist from MARKDOWN-STANDARD.
7. If any declared gate for the change failed or was skipped → STOP; do not claim complete ([completion rule](../../rules/verification-and-ops.md#completion-rule)).

## Open for law

See authority_paths and Expertise map — do not restate full modules here.
  - docs/FILE-CATALOG.md
  - kpi-analytics/README.md
  - excel-toolkit/README.md
