---
title: Excel Toolkit Diagnostics Folder
description: Purpose of the enterprise diagnostics report directory for first-run and gated execution.
version: "1.4.0"
status: current
audience:
  - users
  - it
  - security
doc_type: other
related:
  - ../README.md
  - ../CLI-GUIDE.md
  - ../ENTERPRISE-SECURITY.md
last_updated: "2026-07-22"
---

# Diagnostics folder

This directory holds the **enterprise readiness diagnostics** certificate for the Excel Toolkit.

## Summary

Operational commands (`export-csv`, `import-excel`) and menu Excel actions require a valid **pass** report for the current toolkit version. If the report is missing, stale, or failed, the toolkit **auto-runs** diagnostics and only continues when all **critical** checks pass.

| File | Tracked? | Role |
|------|----------|------|
| `README.md` (this file) | Yes | Explains the folder |
| `last_diagnostics.json` | No (gitignored) | Machine-readable certificate (gate reads this) |
| `last_diagnostics.txt` | No (gitignored) | Human-readable PASS/FAIL list for IT tickets |

## How to run

From `excel-toolkit\`:

```bat
excel-toolkit.cmd diagnostics
excel-toolkit.cmd diagnostics -Force -Json
```

Menu: **Diagnostics → 1) Check readiness (dry-run + pass certificate)**.

## What is checked

PowerShell 5.1+, temp writable, ExcelCom module surface, Excel COM create/quit, diagnostics folder writable. No permanent workbooks. No claim rows or PHI.

## After delete

If you delete `last_diagnostics.json` / `.txt`, the next gated command **auto-runs** diagnostics again and recreates the files on pass (same model as kpi-analytics).

## Related

- [CLI-GUIDE.md](../CLI-GUIDE.md) — `diagnostics` command and gate flags  
- [ENTERPRISE-SECURITY.md](../ENTERPRISE-SECURITY.md) — trust boundary and IT validation  
