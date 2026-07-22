---
title: KPI Analytics Enterprise Security
description: Security review notes and execution restrictions for KPI Analytics on controlled corporate PCs.
version: "1.6.0"
status: current
audience:
  - security
  - developers
  - it
doc_type: security
related:
  - README.md
  - CLI-GUIDE.md
  - diagnostics/README.md
last_updated: "2026-07-22"
---

# KPI Analytics — Enterprise Security & Execution Notes

Reference for security reviews, AppLocker/WDAC discussions, and controlled corporate desktops.

**Toolkit version:** 1.6.0  
**Toolkit folder:** `kpi-analytics\`  
**Python package:** `kpi_modules\`  
**Runtime:** Python **3.13** standard library only (no third-party packages)

**Related docs:** [README.md](./README.md) · [CLI-GUIDE.md](./CLI-GUIDE.md) · [diagnostics/README.md](./diagnostics/README.md)

## Summary

KPI Analytics is designed for **locked-down corporate desktops**. It processes Work Queue CSVs **locally** with **Python 3.13 standard library only**: no pip installs, no network calls, no credential access, no privilege elevation, and no Microsoft Office automation. Allowed behavior is limited to reading user-supplied data/config, writing scored/summary/synthetic CSVs under user-chosen paths, writing an optional **enterprise diagnostics certificate** under `kpi-analytics\diagnostics\`, and process-local CLI launch via `kpi-analytics.cmd`.

Operational commands (`score`, `generate`, `validate-score`) are **gated** on a valid diagnostics pass for the current toolkit and Python version. Diagnostics auto-run when the certificate is missing or stale and document each check as PASS/FAIL for IT without reading claim PHI.

This document states the **trust boundary**, lists high-risk patterns the toolkit **does not** use (download-and-run, force-kill, policy bypass, etc.), what IT still must allow (Python + script path + write to `diagnostics\`), and a minimal validation sequence for security review. Sibling Excel export risks live under `excel-toolkit\ENTERPRISE-SECURITY.md`, not here.

---

## Contents

1. [Summary](#summary)
2. [Purpose of this document](#1-purpose-of-this-document)
3. [Trust boundary](#2-trust-boundary-what-the-toolkit-is-allowed-to-do)
4. [Patterns often treated as unacceptable](#3-patterns-often-treated-as-unacceptable-and-status-here)
5. [Remaining capabilities that require enterprise allowance](#4-remaining-capabilities-that-require-enterprise-allowance)
6. [Python execution restrictions](#5-python-execution-restrictions)
7. [Recommended enterprise validation](#6-recommended-enterprise-validation-minimal)
8. [Audit snapshot](#7-audit-snapshot-implementation-decisions)
9. [What to tell IT / security reviewers](#8-what-to-tell-it--security-reviewers)
10. [Related files](#9-related-files)
11. [Document history](#10-document-history)

---

## 1. Purpose of this document

Summarize:

1. What the toolkit **does** from a security perspective  
2. Patterns enterprises often treat as **unacceptable** (and how this toolkit avoids them)  
3. Capabilities that remain **required** for local analytics  
4. Python runtime / allowlisting expectations  
5. Guidance when something is blocked  

This is a design audit, not a penetration-test report. It mirrors the trust model of `excel-toolkit\ENTERPRISE-SECURITY.md` for a **no-Office, no-pip** runtime.

---

## 2. Trust boundary (what the toolkit is allowed to do)

| Area | Behavior |
|------|----------|
| **Privilege** | Runs as the **current user**. No UAC elevation. |
| **Policy** | Does **not** change execution policy, GPO, or registry policy. |
| **Network** | No downloads, HTTP clients, remote modules, or package index access. |
| **Identity** | Does not read credentials, tokens, or browser stores. |
| **Scope of files** | Reads user-supplied CSV/config/schema; writes scored, summary, and synthetic CSVs under chosen paths (default repo `output\`); writes diagnostics certificates under `kpi-analytics\diagnostics\`; may use `%TEMP%` for probe checks. |
| **Office** | **Does not** automate Microsoft Excel or other Office apps. |
| **Dependencies** | **Standard library only** for Python 3.13. |
| **Surfaces** | CLI (`kpi-analytics.cmd` / `python -m kpi_modules`), importable package, fixtures under `fixtures\`, diagnostics under `diagnostics\`. |
| **Diagnostics privacy** | Certificate records environment and import results only — **no claim rows or PHI**. |

Processing includes priority scoring, RCM claim-impact columns, vertical summary reporting, synthetic data generation, enterprise diagnostics, and local validation—all offline.

---

## 3. Patterns often treated as unacceptable (and status here)

| Pattern | Why sensitive | Status in `kpi-analytics` |
|---------|---------------|---------------------------|
| **`pip install` / third-party wheels** | Supply-chain risk | **Not used.** Stdlib only. |
| **Download-and-run** | Malware delivery pattern | **Not present.** |
| **Force-kill Office / processes** | High-risk automation | **Not present.** |
| **`eval` / dynamic code on untrusted input** | Arbitrary execution | **Not used** for scoring or generation. |
| **Credential / secret scraping** | Theft pattern | **Not present.** |
| **HKLM / permanent policy writes** | Admin surface | **Not present.** |
| **Silent MOTW unblock** | Clears security labels | **Not present.** |
| **Telemetry / hidden network** | Exfiltration concern | **Not present.** |

Excel export, if needed, is a separate step via **`excel-toolkit\`** (its own enterprise close policy).

Synthetic `generate` creates **fake** WQ rows (`Doe,John*` / `Doe,Jane*`, DOB day fixed to 01) for testing only.

---

## 4. Remaining capabilities that require enterprise allowance

| Capability | Used for | Typical gate |
|------------|----------|--------------|
| Run `python.exe` / `py.exe` 3.13 | Execute toolkit | Python allowlisted for user or path |
| Local import of `kpi_modules` | Load package | Path allowlisting if AppLocker/WDAC is strict |
| Read CSV / JSON | Inputs | User file ACLs |
| Write scored / summary / synthetic CSV | Outputs | Write access to output folder |
| Write `kpi-analytics\diagnostics\` | Enterprise pass/fail certificate | Write access to toolkit diagnostics folder |
| Optional `.cmd` launcher | Convenience | Batch allowlisting if restricted |

---

## 5. Python execution restrictions

### 5.1 Supported runtime

| Item | Expectation |
|------|-------------|
| **Version** | Python **3.13.x** (developed against 3.13.0) |
| **Libraries** | Standard library only |
| **Optional tooling** | None required for scoring |

### 5.2 AppLocker / WDAC / ASR

If scripts never start:

- Allowlist `...\kpi-analytics\**` and approved `python.exe` / `py.exe`  
- Confirm outbound network is **not** required  

The toolkit will **not** add flags or alternate runtimes to defeat controls.

### 5.3 Mark of the Web (MOTW)

Files from zip/email may be blocked. The toolkit does **not** auto-unblock. Use Properties → Unblock or enterprise content-trust tooling.

### 5.4 PowerShell policy

KPI Analytics does not depend on PowerShell execution policy. The `.cmd` shim only starts Python. PowerShell constraints apply only when chaining to `excel-toolkit`.

---

## 6. Recommended enterprise validation (minimal)

1. Confirm Python: `py -3.13 --version` → 3.13.x  
2. From `kpi-analytics\`:

```bat
kpi-analytics.cmd version
kpi-analytics.cmd diagnostics --json
rem If OverallPass is false, collect diagnostics\last_diagnostics.txt for IT
kpi-analytics.cmd probe --csv ..\wq_data.csv --json
kpi-analytics.cmd validate-score --json
kpi-analytics.cmd score --csv fixtures\rcm_impact_example.csv --config fixtures\rcm_impact_config.json --output ..\output\rcm_demo_scored.csv --json
```

3. Confirm:  
   - `diagnostics\last_diagnostics.txt` shows **OverallPass: PASS** (or auto-created on first gated command)  
   - Detail CSV contains `v1_priority_score` and `kpi_q_*`  
   - Summary CSV is vertical (section / metric / value / explanation)  
   - Optional: `validate-score` against `fixtures\rcm_impact_expected.json`  

**Diagnostics gate:** `score` / `generate` / `validate-score` auto-run diagnostics when the certificate is missing or does not match the current toolkit/Python versions. They do not proceed when critical checks fail. Emergency bypass: `--skip-diagnostics-gate` (support only).  

---

## 7. Audit snapshot (implementation decisions)

| Decision | Rationale |
|----------|-----------|
| Stdlib only | Fits locked-down desktops without package approval |
| Package name `kpi_modules` | Avoids confusing nested `kpi-analytics` / `kpi_analytics` names |
| No Excel in this package | Separates analytics from Office COM risk |
| No network | Removes supply-chain and exfil patterns |
| Config-driven weights and ADC | Business tuning without code changes |
| Dual RCM attribution (`kpi_q_*`) | Explainable static share + exact resolution impact |
| Vertical summary CSV | Audit-friendly KPI explanations without wide sheets |
| Full priority audit columns | Reconstructable scores |
| Exit codes 0 / 1 / 2 | Aligns with `excel-toolkit` automation style |
| Enterprise diagnostics + gate | First-run proof of runtime/imports; durable IT-friendly PASS/FAIL report |

---

## 8. What to tell IT / security reviewers

> KPI Analytics scores and analyzes Work Queue CSV data locally using only the Python 3.13 standard library. It runs as the logged-on user, does not elevate, does not install packages, does not download code, does not access credentials, and does not automate Microsoft Office. Implementation lives under `kpi-analytics\kpi_modules\` with a thin CLI. On first operational use it can write an enterprise diagnostics report under `kpi-analytics\diagnostics\` (environment and import checks only—no claim PHI). Outputs are scored claim CSVs, optional vertical summary CSVs, optional synthetic test data, and that diagnostics certificate. Excel export, if required, is a separate documented step via `excel-toolkit\`.

---

## 9. Related files

| Path | Role |
|------|------|
| `kpi-analytics\README.md` | Product overview |
| `kpi-analytics\CLI-GUIDE.md` | CLI reference |
| `kpi-analytics\SCORE-METHODOLOGY.md` | Priority + kpi_q implementation |
| `kpi-analytics\RCM_KPI_Claim_Impact_Methodology.md` | RCM theory (proof of concept) |
| `kpi-analytics\kpi_modules\` | Python package |
| `kpi-analytics\kpi-analytics.cmd` | Windows shim |
| `kpi-analytics\fixtures\` | Validation fixtures |
| `kpi-analytics\diagnostics\` | Enterprise dry-run certificate (generated reports gitignored) |
| `excel-toolkit\ENTERPRISE-SECURITY.md` | Sibling Excel toolkit notes |
| This file | Security / restriction reference |

---

## 10. Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial enterprise notes; stdlib-only Python 3.13; CSV scoring; no Office |
| 1.1.0 | Package renamed to `kpi_modules`; synthetic `generate` |
| 1.2.0 | SCORE-METHODOLOGY; validate-score; handcalc fixtures |
| 1.3.0–1.4.0 | Portfolio `kpi_q_*` evolution |
| 1.5.0 | RCM dual-attribution alignment (static + exact Δ; Days in AR; balance-weighted aging) |
| 1.5.1 | Vertical summary CSV; documentation refresh |
| 1.6.0 | Enterprise `diagnostics` command, durable pass/fail report, operational command gate |
