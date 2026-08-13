---
id: maintainer
title: Maintainer
layer: role
portability: kit
activation: catalog_match
description: >
  Repository maintenance: conventional commits, CHANGELOG, hygiene,
  AI disclosure. Use when committing, releasing, or versioning.
triggers:
  - commit
  - changelog
  - release
  - version
  - git hygiene
negative_triggers:
  - pure product design with no repo metadata impact
authority_paths:
  - kit/RULES.md
  - kit/rules/versioning-and-git.md
  - kit/rules/hygiene.md
  - CHANGELOG.md
references:
  - path: kit/rules/versioning-and-git.md
    kind: repo
    purpose: Commit types, CHANGELOG, AI disclosure trailers
  - path: kit/rules/hygiene.md
    kind: repo
    purpose: kit/ vs product packaging; ignore secrets
  - path: kit/agents/OPS.md
    kind: repo
    purpose: Utilization O3 when Instruct is in use
  - url: https://keepachangelog.com/en/1.1.0/
    kind: external
    purpose: Keep a Changelog structure guidance
    trust_note: Community standard; project CHANGELOG law is versioning-and-git
  - url: https://www.conventionalcommits.org/en/v1.0.0/
    kind: external
    purpose: Conventional Commits subject format guidance
    trust_note: Community standard; project rules win on conflict
verify:
  - conventional commit subject matches staged files
  - CHANGELOG updated when release-worthy
  - no secrets or regenerable dumps staged
compose_with:
  - security
  - docs-author
# BUILD fills: workqueue-data-processor
---

# Maintainer

## Must

- Use conventional commits that match what is staged.
- Maintain project root CHANGELOG.md (Keep a Changelog).
- Include AI disclosure trailers when AI assisted (versioning-and-git).
- Co-update canonical L4 docs when this change set touches contracts.
- When Instruct is in use: follow [OPS](../OPS.md) (one primary pack; do not skip match).

## Must not

- Commit secrets, `.env`, or regenerable build outputs.
- Paste full kit release history into project CHANGELOG.
- Rewrite published shared history without coordination.
- Claim complete when a declared Domain A/B gate for the change was skipped or failed.
- Treat external citations as overriding project versioning law.
- Do not add pip packages to kpi-analytics product code.
- Do not implement priority/KPI math in PowerShell product code.
- Do not call Excel COM from Python product code.
- Do not commit real PHI or regenerable cert/diagnostics/output artifacts.
- Do not force-kill Excel or permanently change ExecutionPolicy.
- Do not start Cluster 2/3 product code until design freeze in docs/plan/.

## Expertise map

### In-repo

- `kit/RULES.md` — authority map / hub
- `kit/rules/versioning-and-git.md` — commits, CHANGELOG, AI disclosure
- `kit/rules/hygiene.md` — packaging and ignore hygiene
- `kit/agents/OPS.md` — order of operations when Instruct is in use
- `CHANGELOG.md` — project history (adopters: root; this kit: under `## repo-kit`)

### External (citations — guidance only)

- Keep a Changelog — https://keepachangelog.com/en/1.1.0/
- Conventional Commits — https://www.conventionalcommits.org/en/v1.0.0/

## Procedure

1. If Instruct is in use: confirm this pack is appropriate primary (or compose) per OPS.
2. Review `git status` and `git diff`.
3. Stage one logical surface (or intentional code+docs pair).
4. Write commit subject `type(scope): summary`.
5. If release-worthy, update CHANGELOG under the version section.
6. If AI-assisted, add disclosure trailers per versioning-and-git.
7. Confirm hygiene: no force-add of ignored artifacts.
8. If any declared gate for the change failed or was skipped → STOP; do not claim complete ([completion rule](../../rules/verification-and-ops.md#completion-rule)).

## Open for law

See authority_paths and Expertise map — do not restate full modules here.
