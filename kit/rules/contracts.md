---
title: Contracts
description: What counts as a contract, canonical ownership, co-update rules, fixtures/schema/API, and cross-reference policy.
version: "1.0.1"
status: current
audience:
  - developers
  - technical-writers
  - analysts
doc_type: other
related:
  - ../RULES.md
  - ./architecture.md
  - ./versioning-and-git.md
  - ./verification-and-ops.md
  - ./authoring-and-style.md
  - ../MARKDOWN-STANDARD.md
last_updated: "2026-07-28"
---

# Contracts

Stable promises a repository makes—behavior, shapes, exits, fields—and the rules for keeping them honest.

**Document version:** 1.0.1  

**Related:** [RULES.md](../RULES.md) · [architecture.md](./architecture.md) · [versioning-and-git.md](./versioning-and-git.md) · [verification-and-ops.md](./verification-and-ops.md) · [authoring-and-style.md](./authoring-and-style.md) · [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md)

---

## Summary

| Must | Must not |
|------|----------|
| Give every contract one **canonical** owner (authority map) | Duplicate full contracts across README / guides |
| Update canonical docs with behavior in the **same change set** | Silently rename public APIs, CLI fields, or schema columns |
| Cross-link with relative paths and deep anchors | Leave contracts empty until “docs later” after behavior ships |

**Authority map** answers: *which file owns this concern?*  
**This file** answers: *what counts as a contract, when it breaks, and what must move together?*

---

## Contents

1. [Summary](#summary)
2. [What counts as a contract](#what-counts-as-a-contract)
3. [Ownership rules](#ownership-rules)
4. [Same-change-set rule](#same-change-set-rule)
5. [Cross-reference rules](#cross-reference-rules)
6. [Anti-patterns](#anti-patterns)
7. [Document history](#document-history)

---

## What counts as a contract

| Surface | Typical canonical doc | Examples |
|---------|----------------------|----------|
| CLI / automation | `CLI-GUIDE.md` | verbs, flags, exit codes, JSON stdout |
| Library / API | `API.md` or package README | public functions, types, errors |
| Schema / data | schema path | names, types, nullability |
| Methodology / scoring | `METHODOLOGY.md` | formulas, output columns |
| Security / trust | `SECURITY.md` (when required) | privilege, network, secrets model |
| Fixtures / golden tests | fixtures path | expected rows/outputs |
| Style / SAST gates | language inventory + verification | declared tools and pass criteria |
| Kit / maintenance policy | [RULES.md](../RULES.md) + [rules/](./) | authority map, baseline, gates |

Package structure and runtime boundaries are **architecture** ([architecture.md](./architecture.md)); the promises those packages make are **contracts**.

---

## Ownership rules

1. **Schema or API owns definitions** (names, types, nullability, display names). **Samples own example rows.** Headers and field names must match the contract.  
2. **Field renames and type changes are breaking.** Update together: schema, samples, default config, fixtures, and affected docs.  
3. **Public automation surfaces** (CLI flags, exit codes, stable output columns, JSON shapes) require guide updates and a version bump when they change.  
4. **Explainability** (if the product scores, ranks, or attributes metrics): keep intermediate audit fields; do not collapse into a single misleading total without documentation.  
5. **Fixtures / golden tests** are contracts. Behavior changes must keep validation green or deliberately refresh expected outputs with a documented reason.  
6. **No real credentials, tokens, regulated personal data, or production dumps** in the repository. Samples are synthetic or non-sensitive illustrations.  
7. **Regenerable output directories** (e.g. `output/`, build artifacts, diagnostics certificates) are workspace only—not source of truth and not versioned.

Owner paths live in the [authority map](../RULES.md#authority-map). When a concern has no row, add one before shipping the surface.

### This repository — data and schema

1. **Schema owns definitions** (`field_name`, types, nullability, display names). **Data owns rows.** CSV headers must match `field_name`.  
2. **Field renames and type changes are breaking.** Update together: `wq_schema/wq_schema.json` / `wq_schema/wq_schema.csv`, sample `wq_schema/wq_data.csv`, `config_default.json` field maps, fixtures, and affected docs.  
3. **Scored column contracts** (`v1_*`, `kpi_q_*`, summary layout) are public automation surfaces. Changing them requires methodology + CLI notes + fixture updates and a version bump.  
4. **Explainability is required:** keep intermediate priority audit columns; keep dual RCM attribution (static share vs resolution Δ). Do not collapse metrics into a single misleading sum.  
5. **Fixtures** under `kpi-analytics\fixtures\` are golden. Scoring changes must keep `validate-score` green or deliberately refresh expected JSON with a documented reason.  
6. **No real PHI/PII, credentials, tokens, or production dumps** in the repository. Samples are synthetic or non-sensitive illustrations.  
7. **Synthetic data** remains obviously non-production (existing de-identification conventions in `synthesize.py`).  
8. **`import\`** holds tracked **input** CSVs (synthetic demos or deliberately shared non-PHI extracts). Prefer synthetic data; **never** commit real PHI/PII there. Default `score` / `generate` paths target `import\wq_synthetic_data.csv`.  
9. **`output\`** is regenerable workspace only (scored CSVs, summaries, Excel)—not source of truth and not versioned.  
10. **Do not overwrite tracked or existing outputs by default.** Excel toolkit writers resolve a unique sibling path when the target exists (unless the caller passes documented `-Force`). KPI `score` receives pre-resolved unique paths from the menu pipeline so intermediate CSVs are not clobbered either.

---

## Same-change-set rule

When behavior or a public contract changes, ship together (as applicable):

1. Code (if any)  
2. The **canonical** doc from the authority map  
3. Version bump when a public surface changes  
4. Project `CHANGELOG.md` when the change is release-worthy  

Details: [versioning-and-git.md](./versioning-and-git.md). Proof before “done”: [verification-and-ops.md](./verification-and-ops.md).

---

## Cross-reference rules

Every substantial markdown file should remain navigable for humans and AI agents.

### Mechanisms

| Mechanism | Use when |
|-----------|----------|
| **Authority map** ([hub](../RULES.md#authority-map)) | Establishing *owner path* for a concern |
| Frontmatter **`related:`** | Peer docs (not the entire tree) |
| In-body **Related:** line under the lead | Same peers, human-scannable |
| **Relative links** | Always from *this file’s* directory (`./`, `../`) |
| **Deep anchors** | Point at a specific rule (e.g. `#same-change-set-rule`) |
| **One-sentence summary + link** | Prefer over pasting another document’s full table |

### Form vs policy

| Doc | Role |
|-----|------|
| **This file** | Policy: when/why to cross-link; what must co-update |
| [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md) | Form: frontmatter fields, Related line pattern, relative link style |

### Do not

- Fork a second full copy of a CLI matrix into the root README  
- Use absolute machine-only paths as the only example  
- Leave bidirectional pairs one-way for critical peers (hub ↔ domain rules; contracts ↔ versioning/verification)

---

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| README as the only API/CLI contract | Canonical package guide + short README summary |
| Empty `SECURITY.md` “for the template” | Omit when [security modularity](./security.md#security-documentation-modularity) allows |
| Code ships, guide “later” | Same change set as the canonical doc |
| Silent public field or API rename | Coordinated contract bump + fixtures + docs + CHANGELOG |
| Duplicating full matrices into every doc | Link + short summary |

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.1 | Project fill: WQ schema, scored columns, fixtures, import/output rules |
| 1.0.0 | New first-class module for kit 2.0; ownership rules from former “Data and contract rules”; cross-reference policy |
