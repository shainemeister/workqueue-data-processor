---
title: Markdown Documentation Standard
description: Cross-functional standard for consistent, professional markdown across any repository or project.
version: "1.1.0"
status: current
audience:
  - developers
  - technical-writers
  - analysts
  - security
doc_type: other
related:
  - ../README.md
  - RULES.md
  - rules/contracts.md
  - rules/authoring-and-style.md
  - templates/TEMPLATE-GENERIC.md
  - templates/TEMPLATE-README.md
last_updated: "2026-07-28"
---

# Markdown Documentation Standard

A repeatable standard for professional, consistent markdown in any repository—usable across packages, CLIs, methodologies, security notes, design concepts, and runbooks.

**Standard version:** 1.1.0  
**Location:** `kit/MARKDOWN-STANDARD.md`  
**Templates:** [`templates/`](./templates/)

**Related:** [README.md](../README.md) · [RULES.md](./RULES.md) · [contracts.md](./rules/contracts.md) · [authoring-and-style.md](./rules/authoring-and-style.md) · [templates/TEMPLATE-GENERIC.md](./templates/TEMPLATE-GENERIC.md) · [templates/TEMPLATE-README.md](./templates/TEMPLATE-README.md)

---

## Summary

This document defines **how we structure and write markdown** so docs stay scannable, professional, and easy to maintain. It is **product-agnostic**: the same rules apply to libraries, services, CLIs, data tools, monorepos, and docs-only projects.

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
8. [Cross-linking form](#cross-linking-form)
9. [Tables, code, and links](#tables-code-and-links)
10. [Platform-aware examples](#platform-aware-examples)
11. [Document types and body outlines](#document-types-and-body-outlines)
12. [Templates](#templates)
13. [Author checklist](#author-checklist)
14. [Anti-patterns](#anti-patterns)
15. [Document history](#document-history)

---

## When to use this standard

| Use for | Examples | Frontmatter |
|---------|----------|-------------|
| Product / package overview | Package `README.md` under `packages/…` or `my-service/` | **Yes** |
| CLI or API contract | `CLI-GUIDE.md`, `API.md` | **Yes** |
| How formulas or processes work | Methodology, design notes | **Yes** |
| Security / trust boundary | `SECURITY.md`, `ENTERPRISE-SECURITY.md` | **Yes** |
| Design concepts | Progressive design, multi-version concepts | **Yes** |
| Operational runbooks | Deploy, validate, recover | **Yes** |
| **Repo landing / root entry** | Root [README.md](../README.md) | **No** (by design) |

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
| Explain what the repo is for in plain language | Replace package READMEs or CLI guides |
| Lead with **Summary** and **Use cases** | Open with RULES, catalogs, or template inventories |
| Show one **Quick start** path | Paste every flag, formula, or security matrix |
| Link to deep docs by need | Duplicate another document in full |

### Required order

| # | Block | Required? | Notes |
|---|--------|-----------|--------|
| 1 | **H1** | Yes | Product-facing title |
| 2 | **Lead** | Yes | One or two sentences under the H1—no frontmatter above it |
| 3 | **Summary** | Yes | What it is, for whom, key constraints |
| 4 | **Use cases** | Yes | Table: goal · outcome · start path |
| 5 | **What’s included** | Recommended | Compact map of packages and assets—not every source file |
| 6 | **Prerequisites** | Yes if software is required | Short table only |
| 7 | **Quick start** | Yes | One realistic end-to-end example; language-tagged fence |
| 8 | **Your data** (or equivalent) | If a data or config contract exists | Schema vs rows; types in one line |
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
| Code | One primary workflow example; more examples live in package docs |

### Maintenance rules

1. When a package **entry point or recommended workflow** changes, update **Quick start** and **Use cases** in the **same change set**.  
2. When a new end-user capability ships, add a **use case row** or a **Where to go next** link—do not only update an inventory catalog.  
3. Keep **For maintainers** short; never move it above Summary / Use cases.  
4. Do not list every path in the repo; inventory belongs in a catalog file if you maintain one.  
5. Relative links only from the file’s directory (root: `./packages/my-service/README.md`).

### Relationship to package READMEs

| Document | Pattern |
|----------|---------|
| **Root landing** (`/README.md`) | This section—**no** frontmatter; use cases first |
| **Package README** (`packages/my-service/README.md`, etc.) | Full standard + frontmatter + `doc_type: readme` · [TEMPLATE-README.md](./templates/TEMPLATE-README.md) |

Do not force the landing outline onto deep package docs, and do not force full frontmatter onto the root landing page.

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
| Cross-links | Prefer relative links: `./CLI-GUIDE.md`, `../README.md` — see [Cross-linking form](#cross-linking-form) |
| Platform | When examples are OS-specific, follow [Platform-aware examples](#platform-aware-examples) |

---

## Cross-linking form

How to wire documents so humans and AI agents can navigate without duplicating full contracts. **Policy** (when to co-update, what is a contract): [rules/contracts.md](./rules/contracts.md). **This section** is **form** only.

| Mechanism | Guidance |
|-----------|----------|
| Frontmatter **`related:`** | List true peer paths (not the entire tree) |
| Visible **Related:** line | Mirror peers under the lead for scannability |
| Relative links | Always from *this file’s* directory |
| Deep anchors | Prefer linking a specific heading when citing a rule |
| Summary + link | Prefer over pasting another document’s full table |

Substantial docs should keep `related:` and Related lines current when peers move. Authority-map **owners** live in [RULES.md](./RULES.md#authority-map).

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
| `bash` / `sh` | Unix shell |

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

## Platform-aware examples

Shell, path, and build examples must match how the project is actually developed and run. Do not assume a single OS unless the project declares one.

| Rule | Guidance |
|------|----------|
| **Primary platform** | When examples are OS-specific, state the primary platform in the status block, prerequisites, or a short note (Windows, Linux, macOS, or multi). |
| **Single-platform projects** | One shell fence is enough; keep paths and commands consistent with that OS. |
| **Multi-platform or unknown host** | Prefer **dual fences** (Windows + Linux/macOS) for invocation, quick start, and validation, **or** one primary fence plus a one-line alternate. |
| **Shell language tags** | Use `bat` / `cmd`, `powershell`, or `bash` / `sh` to match the example—not a generic fence. |
| **Paths** | Placeholders (`C:\path\to\...` and `/path/to/...`) plus one concrete repo-relative example when helpful. |
| **Product OS detection** | If scripts adapt by host (`sys.platform`, `$IsWindows`, `uname`), document that behavior in the CLI or security contract—not only in prose. |
| **Verification commands** | Fill [verification table](./rules/verification-and-ops.md#verification-before-ship) rows with the command(s) used on the team’s platform(s); list both when multi-OS. |

### Dual-path pattern (illustrative)

**Windows**

```bat
cd /d C:\path\to\{{FOLDER_NAME}}
{{QUICKSTART_COMMANDS}}
```

**Linux / macOS**

```bash
cd /path/to/{{FOLDER_NAME}}
{{QUICKSTART_COMMANDS}}
```

Templates for README, CLI, and security already show this pattern where shell matters. Drop the unused OS block only when the project is deliberately single-platform.

---

## Document types and body outlines

Set `doc_type` in frontmatter. After **Summary** and **Contents**, use the body flow for that type.

### `readme` — product or package overview

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
10. Security notes (short) or link  
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

### `security` — trust boundary / enterprise posture

1. Purpose of this document  
2. Trust boundary  
3. Unacceptable patterns (and status)  
4. Required allowances  
5. Runtime / policy restrictions  
6. Recommended validation  
7. Audit snapshot / decisions  
8. Statement for reviewers  
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

There is no dedicated runbook file. For `runbook`, copy [TEMPLATE-GENERIC.md](./templates/TEMPLATE-GENERIC.md) and follow the [runbook body outline](#runbook--operational-procedure) (or freeform H2s that match When to use → Preconditions → Steps → Verification → Failure / recovery → Escalation).

### How to use a template

1. Copy the file into the target folder (e.g. `packages/my-service/README.md`).  
2. Replace all `{{PLACEHOLDERS}}`.  
3. Delete sections that do not apply; do not leave placeholder prose.  
4. Keep dual-path shell blocks when the project is multi-platform; drop the unused OS when primary platform is single and declared.  
5. Refresh **Contents** links to match final headings.  
6. Run through the [Author checklist](#author-checklist).  

### Common placeholders

| Token | Meaning |
|-------|---------|
| `{{PRODUCT_NAME}}` | Human product name |
| `{{FOLDER_NAME}}` | Directory name |
| `{{VERSION}}` | Version string |
| `{{ONE_LINE_PURPOSE}}` | Single-sentence purpose |
| `{{LAST_UPDATED}}` | `YYYY-MM-DD` |
| `{{RELATED_DOC}}` | Sibling doc filename |

Templates may use additional `{{TOKENS}}` beyond this table. Replace every token in the copied file—do not leave unresolved placeholders.

---

## Author checklist

Before merging or publishing a doc:

### All docs

- [ ] Single H1; Summary present if the body is non-trivial  
- [ ] Relative links work from the file’s directory  
- [ ] Code fences have language tags  
- [ ] Shell/path examples match [platform-aware rules](#platform-aware-examples) (primary platform declared when OS-specific)  
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
| Windows-only examples in a multi-OS project | Dual fences or declared primary platform |
| Unresolved template tokens in shipped docs | Replace every `{{TOKEN}}` |

---

## Document history

| Version | Notes |
|---------|--------|
| 1.1.0 | Cross-linking form section; kit 2.0 paths (`kit/`); links to contracts and verification modules |
| 1.0.1 | Platform-aware examples; runbook → GENERIC pointer; placeholder completeness note |
| 1.0.0 | Initial portable standard (generalized for multi-domain repos); root landing pattern; templates under `templates/` |
