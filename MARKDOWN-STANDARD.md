---
title: Markdown Documentation Standard
description: Cross-functional standard for consistent, professional markdown across this repository and its toolkits.
version: "1.0.0"
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
last_updated: "2026-07-22"
---

# Markdown Documentation Standard

A repeatable standard for professional, consistent markdown in this repository—usable across product toolkits, methodologies, security notes, design concepts, and runbooks.

**Standard version:** 1.0.0  
**Location:** repository root (`MARKDOWN-STANDARD.md`)  
**Templates:** [`templates/`](./templates/)

**Related:** [README.md](./README.md) · [templates/TEMPLATE-GENERIC.md](./templates/TEMPLATE-GENERIC.md)

---

## Summary

This document defines **how we structure and write markdown** so docs stay scannable, professional, and easy to maintain. It is **product-agnostic**: the same rules apply to `kpi-analytics`, `excel-toolkit`, and future packages.

Every substantial document should include **YAML frontmatter**, a clear **H1**, a short **lead**, a **status block**, a **Summary**, a linked **Contents** list, then the **body** in a type-appropriate order. Copy-paste skeletons live in [`templates/`](./templates/).

---

## Contents

1. [Summary](#summary)
2. [When to use this standard](#when-to-use-this-standard)
3. [Canonical document order](#canonical-document-order)
4. [YAML frontmatter](#yaml-frontmatter)
5. [Headings and anchors](#headings-and-anchors)
6. [Writing conventions](#writing-conventions)
7. [Tables, code, and links](#tables-code-and-links)
8. [Document types and body outlines](#document-types-and-body-outlines)
9. [Templates](#templates)
10. [Author checklist](#author-checklist)
11. [Anti-patterns](#anti-patterns)
12. [Document history](#document-history)

---

## When to use this standard

| Use for | Examples |
|---------|----------|
| Product / toolkit overview | `README.md` in a package folder |
| CLI or API contract | `CLI-GUIDE.md` |
| How formulas or processes work | Methodology, design notes |
| Security / enterprise posture | `ENTERPRISE-SECURITY.md` |
| Design concepts | Progressive design, multi-version concepts |
| Operational runbooks | Deploy, validate, recover |

| Optional / lighter treatment | Examples |
|------------------------------|----------|
| Tiny sample folders | Short README without full frontmatter if under ~30 lines |
| Generated notes | Prefer linking to a curated doc instead of free-form dump |

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

- [ ] Frontmatter complete; `status` accurate  
- [ ] Single H1; Summary present if the body is non-trivial  
- [ ] Contents links resolve and match H2 titles  
- [ ] Version in frontmatter matches status block (if both exist)  
- [ ] `last_updated` set  
- [ ] Relative links work from the file’s directory  
- [ ] Code fences have language tags  
- [ ] No unresolved `{{PLACEHOLDERS}}`  
- [ ] Tables render (header separator present)  
- [ ] “Out of scope” or “Not in this doc” used instead of silent omissions when helpful  

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

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial cross-functional standard; root placement; templates under `templates/` |
