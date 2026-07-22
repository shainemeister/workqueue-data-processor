---
title: "{{PRODUCT_NAME}}"
description: "{{ONE_LINE_PURPOSE}}"
version: "{{VERSION}}"
status: draft
audience:
  - users
  - developers
doc_type: readme
related:
  - CLI-GUIDE.md
  - ENTERPRISE-SECURITY.md
last_updated: "{{LAST_UPDATED}}"
---

# {{PRODUCT_NAME}} (`{{FOLDER_NAME}}`)

{{ONE_LINE_PURPOSE}}

**Toolkit version:** {{VERSION}}  
**Folder:** `{{FOLDER_NAME}}\`  

**Related docs:** [CLI-GUIDE.md](./CLI-GUIDE.md) · [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md)

---

## Summary

{{SUMMARY_PARAGRAPH}}

| You want… | Start here |
|-----------|------------|
| Quick start | [Recommended workflow](#recommended-workflow) |
| Commands | [CLI-GUIDE.md](./CLI-GUIDE.md) |
| Security | [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md) |

---

## Contents

1. [Summary](#summary)
2. [Who should use what](#who-should-use-what)
3. [Recommended workflow](#recommended-workflow)
4. [What it produces](#what-it-produces)
5. [Prerequisites](#prerequisites)
6. [Data and configuration](#data-and-configuration)
7. [Layout and architecture](#layout-and-architecture)
8. [Using from other code](#using-from-other-code)
9. [CLI quick reference](#cli-quick-reference)
10. [Validation](#validation)
11. [Enterprise notes](#enterprise-notes)
12. [Troubleshooting](#troubleshooting)
13. [Out of scope](#out-of-scope)

---

## Who should use what

| Audience | Entry point |
|----------|-------------|
| Interactive / cmd | `{{ENTRY_CMD}}` |
| Automation | See [CLI-GUIDE.md](./CLI-GUIDE.md) |
| Library consumers | `{{LIBRARY_ENTRY}}` |

---

## Recommended workflow

```bat
cd /d C:\path\to\{{FOLDER_NAME}}
{{QUICKSTART_COMMANDS}}
```

---

## What it produces

| Output | Description |
|--------|-------------|
| {{OUTPUT_NAME}} | {{OUTPUT_DESCRIPTION}} |

---

## Prerequisites

| Need | Notes |
|------|--------|
| {{PREREQ}} | {{PREREQ_NOTES}} |

---

## Data and configuration

| Input | Role |
|-------|------|
| {{INPUT}} | {{INPUT_ROLE}} |

---

## Layout and architecture

```text
{{FOLDER_NAME}}/
  README.md
  {{MAIN_ENTRY}}
```

```text
{{ARCHITECTURE_FLOW}}
```

---

## Using from other code

```{{CODE_LANG}}
{{CODE_EXAMPLE}}
```

---

## CLI quick reference

| Command | Purpose |
|---------|---------|
| {{CMD}} | {{CMD_PURPOSE}} |

| Exit code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | Validation / usage |
| 2 | Runtime (if applicable) |

---

## Validation

{{VALIDATION_NOTES}}

---

## Enterprise notes

| Topic | Behavior |
|-------|----------|
| Elevation | {{ELEVATION}} |
| Network | {{NETWORK}} |

Full write-up: [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md).

---

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| {{SYMPTOM}} | {{RESOLUTION}} |

---

## Out of scope

- {{OUT_OF_SCOPE_ITEM}}
