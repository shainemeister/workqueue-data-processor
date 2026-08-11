---
title: Contracts
description: What counts as a contract, canonical ownership, co-update rules, fixtures/schema/API, and cross-reference policy.
version: "1.2.0"
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
  - ./ai-docs-workspace.md
  - ../MARKDOWN-STANDARD.md
  - ../agents/README.md
  - ../agents/OPS.md
last_updated: "2026-08-10"
---

# Contracts

Stable promises a repository makes—behavior, shapes, exits, fields—and the rules for keeping them honest.

**Document version:** 1.2.0  

**Related:** [RULES.md](../RULES.md) · [architecture.md](./architecture.md) · [versioning-and-git.md](./versioning-and-git.md) · [verification-and-ops.md](./verification-and-ops.md) · [authoring-and-style.md](./authoring-and-style.md) · [ai-docs-workspace.md](./ai-docs-workspace.md) · [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md) · [agents/README.md](../agents/README.md) · [agents/OPS.md](../agents/OPS.md)

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

**Not contracts:**

- Agent Instruct packs under `kit/agents/` are **views** over L4 law (`kit/RULES.md`, `kit/rules/*`, product contracts). They do not own CHANGELOG, SAST, hygiene, or public API promises—see [agents/README.md](../agents/README.md).  
- Root **`docs/`** AI workspace (research, plan, project_build, resources) is **working memory for AI**—not the canonical home for public product promises. Promote durable findings to authority-map owners ([ai-docs-workspace](./ai-docs-workspace.md)).

### Agent Instruct bridge (when in use)

When Agent Instruct is adopted, the primary pack’s `authority_paths` (and Expertise map) **direct** which L4 owners to open—they do **not** replace those owners. Operators still apply this file’s same-change-set rule to the **canonical** docs. Utilization order: [OPS.md](../agents/OPS.md). On feature or surface growth, update contracts **and** evolve agents via PLAN + [BUILD](../agents/BUILD.md) when enablement or authority paths change.

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
| Pack redefines CHANGELOG, SAST, hygiene, or public API law | Short procedure + `authority_paths` to L4; fix pack/BUILD if conflict ([agents](../agents/README.md)) |
| Instruct in use but contracts updated without consulting pack authority_paths | Open primary pack expertise first ([OPS](../agents/OPS.md)); still edit L4 owners |
| Public API/CLI matrix lives only under `docs/` | Promote to package contract; leave pointer in docs if useful ([ai-docs-workspace](./ai-docs-workspace.md)) |

---

## Document history

| Version | Notes |
|---------|--------|
| 1.2.0 | AI docs workspace is not a contract; promotion anti-pattern (kit 2.3.0) |
| 1.1.0 | Instruct bridge: packs direct owners; co-maintain + lifecycle pointer (kit 2.2.0) |
| 1.0.1 | Agent Instruct packs are views, not contracts; dual-authority anti-pattern |
| 1.0.0 | New first-class module for kit 2.0; ownership rules from former “Data and contract rules”; cross-reference policy |
