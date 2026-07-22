---
title: "{{PRODUCT_NAME}} CLI Reference"
description: "{{ONE_LINE_PURPOSE}}"
version: "{{VERSION}}"
status: draft
audience:
  - developers
  - automation
doc_type: cli
related:
  - README.md
  - ENTERPRISE-SECURITY.md
last_updated: "{{LAST_UPDATED}}"
---

# {{PRODUCT_NAME}} — CLI Reference

{{ONE_LINE_PURPOSE}}

**Toolkit version:** {{VERSION}}  

**Related docs:** [README.md](./README.md) · [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md)

| Item | Value |
|------|--------|
| **Toolkit folder** | `{{FOLDER_NAME}}\` |
| **CLI entry** | `{{CLI_ENTRY}}` |
| **Library** | `{{LIBRARY_ENTRY}}` |

---

## Summary

{{SUMMARY_PARAGRAPH}}

| Command | Produces |
|---------|----------|
| `{{COMMAND}}` | {{COMMAND_OUTPUT}} |

---

## Contents

1. [Summary](#summary)
2. [Architecture](#architecture)
3. [When to use the CLI vs the library](#when-to-use-the-cli-vs-the-library)
4. [Invocation](#invocation)
5. [Exit codes](#exit-codes)
6. [Global options](#global-options)
7. [Commands](#commands)
8. [Example use cases](#example-use-cases)
9. [Data contract](#data-contract)
10. [Constraints](#constraints)
11. [Troubleshooting](#troubleshooting)
12. [Version](#version)

---

## Architecture

```text
{{ARCHITECTURE_FLOW}}
```

---

## When to use the CLI vs the library

| Caller | Recommended API |
|--------|-----------------|
| Same-process scripts | {{LIBRARY_ENTRY}} |
| Task Scheduler / cmd / other languages | CLI |

---

## Invocation

### From Command Prompt

```bat
cd /d C:\path\to\{{FOLDER_NAME}}
{{CLI_ENTRY}} {{EXAMPLE_COMMAND}}
```

### General form

```text
{{CLI_ENTRY}} <command> [options]
```

---

## Exit codes

| Code | Meaning |
|------|---------|
| **0** | Success |
| **1** | Validation / usage / preflight |
| **2** | Runtime failure (if used) |

---

## Global options

| Option | Description |
|--------|-------------|
| `{{GLOBAL_OPTION}}` | {{GLOBAL_OPTION_DESC}} |

---

## Commands

### `{{COMMAND}}`

{{COMMAND_DESCRIPTION}}

```text
{{CLI_ENTRY}} {{COMMAND}} [options]
```

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `{{OPTION}}` | No | {{DEFAULT}} | {{OPTION_DESC}} |

**Example**

```bat
{{EXAMPLE_INVOCATION}}
```

**JSON shape (illustrative)**

```json
{
  "Success": true,
  "Command": "{{COMMAND}}",
  "Version": "{{VERSION}}"
}
```

---

## Example use cases

### {{USE_CASE_TITLE}}

```bat
{{USE_CASE_COMMANDS}}
```

---

## Data contract

| Input / output | Role |
|----------------|------|
| {{IO_NAME}} | {{IO_ROLE}} |

---

## Constraints

| Topic | Behavior |
|-------|----------|
| {{CONSTRAINT}} | {{CONSTRAINT_BEHAVIOR}} |

See [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md).

---

## Troubleshooting

| Symptom | What to check |
|---------|----------------|
| {{SYMPTOM}} | {{CHECK}} |

---

## Version

CLI and product version are aligned at **{{VERSION}}**. Bump when changing verbs, exit codes, or machine-readable field names.
