---
title: Markdown Documentation Standard
description: Cross-functional standard for consistent, professional markdown across this repository and its toolkits.
version: "1.1.0"
status: current
audience:
  - developers
  - technical-writers
  - analysts
  - security
doc_type: other
related:
  - README.md
  - templates/TEMPLATE-GENERIC.md
  - templates/TEMPLATE-README.md
last_updated: "2026-07-22"
---

# Markdown Documentation Standard

A repeatable standard for professional, consistent markdown in this repository—usable across product toolkits, methodologies, security notes, design concepts, and runbooks.

**Standard version:** 1.1.0  
**Location:** repository root (`MARKDOWN-STANDARD.md`)  
**Templates:** [`templates/`](./templates/)

**Related:** [README.md](./README.md) · [templates/TEMPLATE-GENERIC.md](./templates/TEMPLATE-GENERIC.md) · [templates/TEMPLATE-README.md](./templates/TEMPLATE-README.md)

---

## Summary

This document defines **how we structure and write markdown** so docs stay scannable, professional, and easy to maintain. It is **product-agnostic**: the same rules apply to `kpi-analytics`, `excel-toolkit`, and future packages.

Most **substantial** documents use **YAML frontmatter**, a clear **H1**, a short **lead**, a **status block**, a **Summary**, a linked **Contents** list, then the **body** in a type-appropriate order. Copy-paste skeletons live in [`templates/`](./templates/).

**Exception:** the **repository root landing README** (and similar end-user entry pages) intentionally **omit frontmatter** and follow a lighter outline focused on summary and use cases—see [Landing / root README](#landing--root-readme-no-frontmatter).

---

## Contents

1. [Summary](#summary)
2. [When to use this standard](#when-to-use-this-standard)
3. [Landing / root README (no frontmatter)](#landing--root-readme-no-frontmatter)
4. [Canonical document order](#canonical-document-order)
5. [YAML frontmatter](#yaml-frontmatter)
6. [Headings and anchors](#headings-and-anchors)
7. [Writing conventions](#writing-conventions)
8. [Tables, code, and links](#tables-code-and-links)
9. [Document types and body outlines](#document-types-and-body-outlines)
10. [Templates](#templates)
11. [Author checklist](#author-checklist)
12. [Anti-patterns](#anti-patterns)
13. [Document history](#document-history)

---

## When to use this standard

| Use for | Examples | Frontmatter |
|---------|----------|-------------|
| Product / toolkit overview | Package `README.md` (`kpi-analytics\`, `excel-toolkit\`) | **Yes** |
| CLI or API contract | `CLI-GUIDE.md` | **Yes** |
| How formulas or processes work | Methodology, design notes | **Yes** |
| Security / enterprise posture | `ENTERPRISE-SECURITY.md` | **Yes** |
| Design concepts | Progressive design, multi-version concepts | **Yes** |
| Operational runbooks | Deploy, validate, recover | **Yes** |
| **Repo landing / root entry** | Root [README.md](./README.md) | **No** (by design) |

| Optional / lighter treatment | Examples |
|------------------------------|----------|
| Tiny sample folders | Short README without full frontmatter if under ~30 lines |
| Generated notes | Prefer linking to a curated doc instead of free-form dump |
| Root landing README | Full pattern in [Landing / root README](#landing--root-readme-no-frontmatter) |

---

## Landing / root README (no frontmatter)

Use this pattern for the **repository root `README.md`** (and any similar **end-user landing page**). Goal: a professional first impression that is easy to scan—not a maintainer catalog, not a CLI contract, not a methodology dump.

### Purpose

| This page does | This page does not |
|----------------|--------------------|
| Explain what the repo is for in plain language | Replace toolkit READMEs or CLI guides |
| Lead with **Summary** and **Use cases** | Open with RULES, FILE-CATALOG, or template inventories |
| Show one **Quick start** path | Paste every flag, formula, or security matrix |
| Link to deep docs by need | Duplicate another document in full |

### Required order

| # | Block | Required? | Notes |
|---|--------|-----------|--------|
| 1 | **H1** | Yes | Product-facing title (e.g. Work Queue Data Processor) |
| 2 | **Lead** | Yes | One or two sentences under the H1—no frontmatter above it |
| 3 | **Summary** | Yes | What it is, for whom, key constraint (e.g. offline / stdlib) |
| 4 | **Use cases** | Yes | Table: goal · outcome · start path |
| 5 | **What’s included** | Recommended | Compact map of toolkits and data—not every source file |
| 6 | **Prerequisites** | Yes if software is required | Short table only |
| 7 | **Quick start** | Yes | One realistic end-to-end example; language-tagged fence |
| 8 | **Your data** (or equivalent) | If a data contract exists | Schema vs rows; types in one line |
| 9 | **Where to go next** | Yes | Links by user need |
| 10 | **For maintainers** | Optional, last | RULES, catalog, this standard—keep thin |

**Contents:** optional. Prefer **no** Contents block when there are fewer than about six H2 sections so the landing page stays light.

**YAML frontmatter:** **omit**. Do not add version/status badges that require frontmatter sync on a landing page; keep identity in the H1 and lead.

### Tone and length

| Guidance | Detail |
|----------|--------|
| Voice | Professional, direct, second person (“you”) where natural |
| Jargon | Pair product terms with a plain phrase the first time |
| Length | Prefer roughly **under 120 lines**; link out for depth |
| Tables | Use for use cases, prerequisites, and “start here” maps |
| Code | One primary workflow example; more examples live in toolkit docs |

### Maintenance rules

1. When a toolkit **entry point or recommended workflow** changes, update **Quick start** and **Use cases** in the **same change set**.  
2. When a new end-user capability ships, add a **use case row** or a **Where to go next** link—do not only update FILE-CATALOG.  
3. Keep **For maintainers** short; never move it above Summary / Use cases.  
4. Do not list every path in the repo; inventory belongs in [FILE-CATALOG.md](./FILE-CATALOG.md).  
5. Relative links only from the file’s directory (root: `./kpi-analytics/README.md`).

### Relationship to toolkit READMEs

| Document | Pattern |
|----------|---------|
| **Root landing** (`/README.md`) | This section—**no** frontmatter; use cases first |
| **Toolkit README** (`kpi-analytics\README.md`, etc.) | Full standard + frontmatter + `doc_type: readme` · [TEMPLATE-README.md](./templates/TEMPLATE-README.md) |

Do not force the landing outline onto deep toolkit docs, and do not force full frontmatter onto the root landing page.

---

## Canonical document order

Use this order unless a template of a specific `doc_type` omits an optional block.

| # | Block | Required? | Purpose |
|---|--------|-----------|---------|
| 1 | **YAML frontmatter** | Yes (for standard docs) | Machine-readable metadata |
| 2 | **H1 title** | Yes | Single document title |
| 3 | **Lead** | Yes | One or two sentences: what this doc is |
| 4 | **Status / identity block** | Recommended | Version, path, related links, key facts |
| 5 | **Summary** | Yes if body is long | Orientation before navigation |
| 6 | **Contents** | Yes if ≥ ~3 H2 sections | Numbered in-document hyperlinks |
| 7 | **Body** | Yes | Type-specific sections (see below) |
| 8 | **Related files** | Optional | Paths and roles |
| 9 | **Out of scope** | Optional | Explicit non-goals |
| 10 | **Document history** | Recommended for versioned methodology/security | Version / notes table |

### Why this order

1. **Frontmatter + title** establish identity for humans and tools.  
2. **Summary first** answers “is this the right doc?” without scrolling past a TOC.  
3. **Contents next** supports jump navigation once the reader commits.  
4. **Body** goes deep; **history / out of scope** stay at the end so they never bury the main path.

Separate major blocks with a horizontal rule (`---`) when it improves scanability (after Summary, after Contents, before History).

---

## YAML frontmatter

Place at the very top of the file, between `---` fences.

```yaml
---
title: "Human-readable title"
description: "One-line description of what this document covers."
version: "1.0.0"
status: current
audience:
  - developers
related:
  - README.md
  - CLI-GUIDE.md
doc_type: readme
last_updated: "2026-07-22"
---
```

### Field reference

| Field | Required | Allowed values / notes |
|-------|----------|-------------------------|
| `title` | **Yes** | Short title (may match H1 without decoration) |
| `description` | **Yes** | Single sentence; no marketing fluff |
| `version` | **Yes** | Semver or doc version string; keep in sync with status block |
| `status` | **Yes** | `draft` · `current` · `deprecated` |
| `audience` | **Yes** | YAML list, e.g. `users`, `developers`, `security`, `it`, `analysts`, `automation` |
| `related` | Recommended | Sibling or root-relative filenames |
| `doc_type` | Recommended | See [Document types](#document-types-and-body-outlines) |
| `last_updated` | **Yes** | ISO date `YYYY-MM-DD` |

---

## Headings and anchors

| Rule | Guidance |
|------|----------|
| One H1 | Only the document title |
| H2 | Major sections (appear in Contents) |
| H3 | Subsections only when needed |
| Numbered H2 | Optional for long methodology/security (`## 1. Title`); README often unnumbered |
| Anchors | Prefer plain ASCII titles so GitHub-style anchors stay stable |
| Contents | Numbered list of `[Label](#anchor)` links matching H2s |

### Contents pattern

```markdown
## Contents

1. [Summary](#summary)
2. [Section name](#section-name)
3. [Another section](#another-section)
```

Include **Summary** as item 1 when Summary exists as an H2.

---

## Writing conventions

| Topic | Guidance |
|-------|----------|
| Voice | Complete sentences; direct and professional |
| Length | Prefer short paragraphs; put parallel facts in tables |
| Emphasis | **Bold** for critical terms and UI labels |
| Code | `` `inline` `` for paths, flags, identifiers, column names |
| Placeholders | `{{LIKE_THIS}}` in templates; `C:\path\to\...` or `/path/to/...` in examples |
| Dates | Prefer ISO in metadata; human dates OK in narrative |
| Versioning | Bump `version` + `last_updated` when behavior or contract changes |
| Cross-links | Prefer relative links: `./CLI-GUIDE.md`, `../README.md` |

---

## Tables, code, and links

### Tables

Use for enumerable facts (options, fields, audiences, exit codes).

```markdown
| Column A | Column B |
|----------|----------|
| Value | Description |
```

Keep cells short. Put long guidance in the Summary, a paragraph, or an “explanation” column—not multi-sentence cells when avoidable.

### Code fences

Always specify a language when possible:

| Language tag | Typical use |
|--------------|-------------|
| `bat` / `cmd` | Windows batch |
| `powershell` | PowerShell |
| `python` | Python |
| `json` | Config / sample JSON |
| `yaml` | Frontmatter examples |
| `text` | Architecture diagrams, plain trees |
| `markdown` | Nested examples of markdown itself |

### Architecture / trees

```text
product-folder/
  README.md
  module-or-package/
```

### Links

- Sibling: `[CLI Guide](./CLI-GUIDE.md)`  
- In-doc: `[Summary](#summary)`  
- Avoid bare URLs when a descriptive label is clearer  

---

## Document types and body outlines

Set `doc_type` in frontmatter. After **Summary** and **Contents**, use the body flow for that type.

### `readme` — product or toolkit overview

Use for **package** READMEs (with frontmatter). For the **repository root** landing page, use [Landing / root README](#landing--root-readme-no-frontmatter) instead—do not force this full outline on the root file.

1. Who should use what  
2. Recommended / quick start  
3. What it produces (or features)  
4. Prerequisites  
5. Data / configuration (if any)  
6. Layout and architecture  
7. How to consume (API / import)  
8. CLI quick reference (or link out)  
9. Validation / tests  
10. Enterprise notes (short) or link  
11. Troubleshooting  
12. Out of scope  

### `cli` — command-line or automation contract

1. Architecture  
2. When CLI vs library  
3. Invocation  
4. Exit codes  
5. Global options  
6. Commands (one subsection per verb)  
7. Example use cases  
8. Data contract  
9. Constraints  
10. Troubleshooting  
11. Version policy  

### `methodology` — formulas and “how it works”

1. Purpose and scope  
2. Pipeline / overview  
3. Definitions and formulas  
4. Worked example  
5. Outputs / column contracts  
6. Validation  
7. Common false alarms  
8. Out of scope  
9. Document history  

### `security` — enterprise / trust boundary

1. Purpose of this document  
2. Trust boundary  
3. Unacceptable patterns (and status)  
4. Required allowances  
5. Runtime / policy restrictions  
6. Recommended validation  
7. Audit snapshot / decisions  
8. Statement for IT / security reviewers  
9. Related files  
10. Document history  

### `concept` — design concept (progressive or multi-version)

1. Overview  
2. Shared principles  
3. Version or phase sections (progressive complexity)  
4. Implementation notes  
5. Document control / history  

### `runbook` — operational procedure

1. When to use  
2. Preconditions  
3. Steps  
4. Verification  
5. Failure / recovery  
6. Escalation  

### `other` / generic

Use **Summary → Contents → logical H2s → History**. Prefer `TEMPLATE-GENERIC.md`.

---

## Templates

| Template | `doc_type` | Path |
|----------|------------|------|
| Product README | `readme` | [templates/TEMPLATE-README.md](./templates/TEMPLATE-README.md) |
| CLI reference | `cli` | [templates/TEMPLATE-CLI.md](./templates/TEMPLATE-CLI.md) |
| Methodology | `methodology` | [templates/TEMPLATE-METHODOLOGY.md](./templates/TEMPLATE-METHODOLOGY.md) |
| Security | `security` | [templates/TEMPLATE-SECURITY.md](./templates/TEMPLATE-SECURITY.md) |
| Concept / design | `concept` | [templates/TEMPLATE-CONCEPT.md](./templates/TEMPLATE-CONCEPT.md) |
| Minimal / any | `other` | [templates/TEMPLATE-GENERIC.md](./templates/TEMPLATE-GENERIC.md) |

### How to use a template

1. Copy the file into the target folder (e.g. `my-toolkit\README.md`).  
2. Replace all `{{PLACEHOLDERS}}`.  
3. Delete sections that do not apply; do not leave placeholder prose.  
4. Refresh **Contents** links to match final headings.  
5. Run through the [Author checklist](#author-checklist).  

### Common placeholders

| Token | Meaning |
|-------|---------|
| `{{PRODUCT_NAME}}` | Human product name |
| `{{FOLDER_NAME}}` | Directory name |
| `{{VERSION}}` | Version string |
| `{{ONE_LINE_PURPOSE}}` | Single-sentence purpose |
| `{{LAST_UPDATED}}` | `YYYY-MM-DD` |
| `{{RELATED_DOC}}` | Sibling doc filename |

---

## Author checklist

Before merging or publishing a doc:

### All docs

- [ ] Single H1; Summary present if the body is non-trivial  
- [ ] Relative links work from the file’s directory  
- [ ] Code fences have language tags  
- [ ] No unresolved `{{PLACEHOLDERS}}`  
- [ ] Tables render (header separator present)  
- [ ] “Out of scope” or “Not in this doc” used instead of silent omissions when helpful  

### Standard docs (frontmatter required)

- [ ] Frontmatter complete; `status` accurate  
- [ ] Contents links resolve and match H2 titles (if Contents present)  
- [ ] Version in frontmatter matches status block (if both exist)  
- [ ] `last_updated` set  

### Landing / root README (no frontmatter)

- [ ] No YAML frontmatter  
- [ ] Summary and **Use cases** appear near the top  
- [ ] Quick start shows one end-to-end path  
- [ ] Does **not** open with maintainer-only inventory (RULES, catalog, templates)  
- [ ] Maintainer links (if any) stay at the end and stay short  
- [ ] Deep contracts linked, not pasted  

---

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| No Summary on a long doc | Add Summary before Contents |
| Contents without Summary on long docs | Summary → Contents → body |
| Multiple H1s | One H1, then H2+ |
| Frontmatter `version` ≠ badge line | Keep them identical |
| TOC entries that don’t exist | Regenerate Contents after edits |
| Only absolute machine paths | Placeholders + one concrete example |
| Walls of prose for option lists | Tables |
| Emoji-heavy headings | Plain headings for stable anchors |
| Duplicating another doc in full | Link and summarize |
| Root README that is only a file dump | Use cases + quick start + “where to go next” |
| Frontmatter on a deliberately simple landing page | Omit frontmatter; H1 + lead + Summary |
| Root page that opens with RULES / catalog / templates | Put maintainers last |
| Pasting full CLI-GUIDE into the root README | One example + link |

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial cross-functional standard; root placement; templates under `templates/` |
| 1.1.0 | Landing / root README pattern (no frontmatter); use cases and checklist; anti-patterns |
