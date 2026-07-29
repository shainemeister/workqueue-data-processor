---
title: KPI Analytics Diagnostics Folder
description: Purpose of the enterprise diagnostics report directory for first-run and gated execution.
version: "2.2.0"
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
  - ../../certification/README.md
last_updated: "2026-07-28"
---

# Diagnostics folder

This directory holds the **enterprise dry-run diagnostics** certificate for KPI Analytics.

## Summary

Operational commands (`score`, `generate`, `validate-score`) require a valid **pass** report for the current toolkit version and Python interpreter. If the report is missing, stale, or failed, the CLI **auto-runs** diagnostics and only continues when all **critical** checks pass.

| File | Tracked? | Role |
|------|----------|------|
| `README.md` (this file) | Yes | Explains the folder |
| `last_diagnostics.json` | No (gitignored) | Machine-readable certificate (gate reads this) |
| `last_diagnostics.txt` | No (gitignored) | Human-readable PASS/FAIL list for IT tickets |

**Not formal certification:** package diagnostics answer “can **this machine** run kpi-analytics?” Source-tree Domain A/B self-attestation lives under repo root [`certification/`](../../certification/README.md) and must **not** be merged here.

## What is checked

Python **3.13+**, executable path, stdlib + all `kpi_modules` package imports (including `column_map` / interactive mapping surfaces), default config load, diagnostics folder writable. No claim rows or PHI.

## How to run

From `kpi-analytics\`:

```bat
kpi-analytics.cmd diagnostics
kpi-analytics.cmd diagnostics --force --json
```

## Privacy

Reports record environment and import results only (Python version, executable path, check names, toolkit version, report paths). They do **not** include claim rows or PHI.

## Related

- [CLI-GUIDE.md](../CLI-GUIDE.md) — `diagnostics` command and gate flags  
- [ENTERPRISE-SECURITY.md](../ENTERPRISE-SECURITY.md) — trust boundary and IT validation  
- [certification/README.md](../../certification/README.md) — formal security + code-validation certificate (developer-only)  

