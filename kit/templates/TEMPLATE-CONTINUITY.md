---
title: "Code Continuity and Quality ({{PROJECT_NAME}})"
description: Project overlay for surgical changes, named protected surfaces, git continuity, and quality gates.
version: "1.0.1"
status: draft
audience:
  - developers
  - maintainers
doc_type: other
related:
  - ../../kit/RULES.md
  - ../../kit/rules/continuity.md
  - ../../kit/rules/workboard.md
  - ../../kit/rules/architecture.md
  - ../../kit/rules/contracts.md
  - ../../kit/rules/verification-and-ops.md
  - ../WORKBOARD.md
last_updated: "{{ISO_DATE}}"
---

# Code Continuity and Quality ({{PROJECT_NAME}})

Project overlay on repo-kit continuity policy ([kit/rules/continuity.md](../../kit/rules/continuity.md)). Generic kit rules still apply. Typical home after copy: `docs/project_build/continuity.md` (or another recorded path — **not** the portable `kit/rules/continuity.md` module). Hrefs in this skeleton are written for **`docs/project_build/continuity.md`**. They will not resolve from `kit/templates/`. After copy, fill every `{{PLACEHOLDER}}`. If you record a different overlay path, fix relative links from that file. This file is adopter data — preserve it on kit upgrade.

**Document version:** 1.0.1

---

## Summary

| Must | Must not |
|------|----------|
| Prefer **surgical** edits | Full-file rewrite of a named protected surface unless the user explicitly requests restore |
| Leave **{{PROTECTED_THEME}}** alone unless the task names it | “While I’m here” refactors of other protected surfaces |
| Run declared verification before “done” | Claim complete on a shallow probe alone |
| Update L4 + CHANGELOG when contracts change | Behavior-only commits for release-worthy surfaces |
| Update [docs/WORKBOARD.md](../WORKBOARD.md) when multi-phase work advances | Claim phase complete only in chat |

---

## Protected surfaces

Touch only when the user task **names** them. One protected surface per change set unless the user requests a multi-surface fix and each step is committed.

| Surface | Paths (canonical) | Risk if mishandled |
|---------|-------------------|--------------------|
| {{SURFACE_1}} | `{{PATHS_1}}` | {{RISK_1}} |
| {{SURFACE_2}} | `{{PATHS_2}}` | {{RISK_2}} |

---

## Quality gates (this project)

Declared inventory: {{LANGUAGE_INVENTORY_SUMMARY}}.

| After changing… | Run at least |
|-----------------|--------------|
| {{SURFACE_CLASS}} | {{VERIFY_COMMAND}} |

Do **not** mark complete if {{PROJECT_SMOKE_FAILURE}} after a product edit.

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.1 | Hrefs written for `docs/project_build/continuity.md` after copy |
| 1.0.0 | Filled from kit TEMPLATE-CONTINUITY |
