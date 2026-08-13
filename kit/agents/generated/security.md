---
id: security
title: Security
layer: role
portability: kit
activation: catalog_match
description: >
  Language inventory, declared Domain A (SAST) gates, secrets hygiene,
  optional certification outputs gitignored. Domain B style is implementer-led
  unless PLAN emphasizes security.
triggers:
  - security
  - SAST
  - inventory
  - secrets
  - audit
  - certification
  - dependency
negative_triggers:
  - docs-only repos with empty inventory (unless user enables)
  - pure style/format-only tasks with no security surface
authority_paths:
  - kit/rules/security.md
  - kit/rules/verification-and-ops.md
  - kit/RULES.md
  - .gitignore
references:
  - path: kit/rules/security.md
    kind: repo
    purpose: Inventory, SAST, certification policy
  - path: kit/rules/verification-and-ops.md
    kind: repo
    purpose: Completion rule and declared gates
  - path: kit/agents/OPS.md
    kind: repo
    purpose: O3 utilization when Instruct is in use
  - url: https://owasp.org/www-project-cheat-sheets/
    kind: external
    purpose: OWASP Cheat Sheet series for threat/control patterns
    trust_note: Guidance only; project inventory and SECURITY docs are law
verify:
  - inventory matches shipped languages
  - declared Domain A gates run for touched surfaces
  - no secrets committed
  - "Bandit on kpi_modules; PSScriptAnalyzer Error on excel-toolkit product scripts; Gitleaks workdir+git history (via full certification harness)"
compose_with:
  - maintainer
  - implementer
# BUILD fills: workqueue-data-processor
---

# Security

## Must

- Keep language surface inventory accurate.
- Run declared Domain A (SAST) gates for inventory surfaces.
- Keep secrets and regenerable cert outputs out of commits.
- Co-update security/trust docs when trust boundary changes.
- When Instruct is in use: follow [OPS](../OPS.md); open expertise before inventing scanners.

## Must not

- Paste the full multi-language SAST table without inventory evidence.
- Commit `last_certification.*` or real credentials.
- Treat certification as a product launcher gate unless project policy says so.
- Own pure Domain B style work unless PLAN emphasizes security (defer to implementer).
- Treat OWASP or other external citations as overriding project security.md.
- Do not add pip packages to kpi-analytics product code.
- Do not implement priority/KPI math in PowerShell product code.
- Do not call Excel COM from Python product code.
- Do not commit real PHI or regenerable cert/diagnostics/output artifacts.
- Do not force-kill Excel or permanently change ExecutionPolicy.
- Do not start Cluster 2/3 product code until design freeze in docs/plan/.

## Expertise map

### In-repo

- `kit/rules/security.md` — inventory, SAST, certification
- `kit/rules/verification-and-ops.md` — completion
- `kit/RULES.md` — authority map
- `kit/agents/OPS.md` — utilization O3
- `.gitignore` — secrets and cert outputs
- Product `SECURITY.md` when present (map path)
- `certification/README.md` — formal Domain A/B harness
- `kpi-analytics/ENTERPRISE-SECURITY.md` — KPI trust boundary
- `excel-toolkit/ENTERPRISE-SECURITY.md` — Excel trust boundary

### External (citations — guidance only)

- OWASP Cheat Sheets — https://owasp.org/www-project-cheat-sheets/

## Procedure

1. If Instruct is in use: primary match per OPS; open Expertise map.
2. Read language surface inventory and verification table (authority map first).
3. For the change, identify declared Domain A (SAST) gates; note Domain B only if PLAN emphasizes security.
4. Run Bandit on kpi_modules; PSScriptAnalyzer Error on excel-toolkit product scripts; Gitleaks workdir+git history (via full certification harness) (project-filled from inventory — never invent tools).
5. Update SECURITY docs when trust boundary changes (same change set).
6. If inventory gained a language or new attack surface: PLAN/BUILD lifecycle as needed.
7. If certification/ is maintained, regenerate outputs and leave unstaged.
8. If any declared Domain A gate or verify item fails or is skipped → STOP; do not claim complete; list remediation ([completion rule](../../rules/verification-and-ops.md#completion-rule)).

## Open for law

See authority_paths and Expertise map — do not restate full modules here.
