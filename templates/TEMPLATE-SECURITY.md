---
title: "{{PRODUCT_NAME}} Security"
description: "{{ONE_LINE_PURPOSE}}"
version: "{{VERSION}}"
status: draft
audience:
  - security
  - developers
  - it
doc_type: security
related:
  - README.md
  - CLI-GUIDE.md
last_updated: "{{LAST_UPDATED}}"
---

# {{PRODUCT_NAME}} — Security & Execution Notes

{{ONE_LINE_PURPOSE}}

**Package version:** {{VERSION}}  
**Package folder:** `{{FOLDER_NAME}}/`  
**Runtime:** {{RUNTIME}}

**Related docs:** [README.md](./README.md) · [CLI-GUIDE.md](./CLI-GUIDE.md)

---

## Summary

{{SUMMARY_PARAGRAPH}}

---

## Contents

1. [Summary](#summary)
2. [Purpose of this document](#1-purpose-of-this-document)
3. [Trust boundary](#2-trust-boundary)
4. [Unacceptable patterns](#3-unacceptable-patterns)
5. [Required allowances](#4-required-allowances)
6. [Runtime restrictions](#5-runtime-restrictions)
7. [Recommended validation](#6-recommended-validation)
8. [Audit snapshot](#7-audit-snapshot)
9. [Statement for reviewers](#8-statement-for-reviewers)
10. [Related files](#9-related-files)
11. [Document history](#10-document-history)

---

## 1. Purpose of this document

> **Modularity:** Create this file only when the package has an execution surface, network access, elevated privilege, or handles secrets. Docs-only or pure libraries with no runtime side effects may omit `SECURITY.md` entirely—see [RULES — Security documentation modularity](../RULES.md#security-documentation-modularity).

Summarize:

1. What the product **does** from a security perspective  
2. Patterns treated as **unacceptable** (and status here)  
3. Capabilities that still require **enterprise or IT allowance**  
4. How to **validate** on a controlled machine  

---

## 2. Trust boundary

| Area | Behavior |
|------|----------|
| **Privilege** | {{PRIVILEGE}} |
| **Network** | {{NETWORK}} |
| **Identity** | {{IDENTITY}} |
| **Scope of files** | {{FILE_SCOPE}} |
| **Dependencies** | {{DEPENDENCIES}} |

---

## 3. Unacceptable patterns

| Pattern | Why sensitive | Status here |
|---------|---------------|-------------|
| {{PATTERN}} | {{WHY}} | {{STATUS}} |

---

## 4. Required allowances

> **Delete this section** if the product needs no enterprise or IT allowances beyond normal user privileges.

| Capability | Used for | Typical gate |
|------------|----------|--------------|
| {{CAPABILITY}} | {{USED_FOR}} | {{GATE}} |

---

## 5. Runtime restrictions

> **Shorten or delete** subsections that do not apply (e.g. no allowlists, single runtime only).

### 5.1 Supported runtime

| Item | Expectation |
|------|-------------|
| **Version / host** | {{RUNTIME}} |
| **Libraries** | {{LIBRARIES}} |

### 5.2 Controls (policy / allowlists)

{{CONTROLS_NOTES}}

---

## 6. Recommended validation

> **Delete unused OS blocks.** Keep both when multi-platform; drop the unused OS when primary platform is single and declared. Prefer language-specific developer gates from [RULES — Security / SAST gates](../RULES.md#security--sast-gates-advisory) only for languages this package ships.

**Windows**

```bat
{{VALIDATION_COMMANDS}}
```

**Linux / macOS**

```bash
{{VALIDATION_COMMANDS}}
```

---

## 7. Audit snapshot

| Decision | Rationale |
|----------|-----------|
| {{DECISION}} | {{RATIONALE}} |

---

## 8. Statement for reviewers

> {{REVIEWER_STATEMENT}}

---

## 9. Related files

> **Delete this section** if related paths are already clear from the authority map and Related docs line.

| Path | Role |
|------|------|
| `{{PATH}}` | {{ROLE}} |

---

## 10. Document history

| Version | Notes |
|---------|--------|
| {{VERSION}} | Initial security notes |
