---
title: "Work Queue Data Processor — Security and code-validation certification"
description: "Operator guide for the formal regenerable self-attestation certificate (Domain A security + Domain B code validation, including Gitleaks)."
version: "1.0.0"
status: current
audience:
  - developers
  - security
  - it
doc_type: other
related:
  - ../RULES.md
  - ../CHANGELOG.md
  - checks.json
  - Invoke-Certification.ps1
last_updated: "2026-07-28"
---

# Work Queue Data Processor — Certification

Operator guide for the **formal, regenerable** security and code-validation certificate for this repository. One package covers **Domain A (security / SAST + secrets)** and **Domain B (code validation)** in a single certificate pair.

**Document version:** 1.0.0  
**Status:** current  

**Related:** [RULES — Security and code-validation certification](../RULES.md#security-and-code-validation-certification) · [Language surface inventory](../RULES.md#language-surface-inventory) · [checks.json](./checks.json) · [Invoke-Certification.ps1](./Invoke-Certification.ps1)

---

## Summary

| Item | Decision |
|------|----------|
| **What** | Developer **self-attestation** certificate (JSON + TXT) for Domain A **and** Domain B |
| **Where** | This folder only: `certification/` |
| **Who runs it** | Developers / release reviewers — **not** end-user product launchers |
| **Product impact** | Must **not** gate product CLI or end-user install |
| **Harness** | [Invoke-Certification.ps1](./Invoke-Certification.ps1) — always runs the **full** suite |
| **Gate definitions** | [checks.json](./checks.json) — operational source of truth for commands |

This is **not** a third-party audit, SOC 2, or ISO seal.

**Not package diagnostics:** toolkit machine-readiness certificates stay under `kpi-analytics/diagnostics/` and `excel-toolkit/diagnostics/`. Do not merge those into this folder.

---

## Contents

1. [Summary](#summary)
2. [When to regenerate (renewal)](#when-to-regenerate-renewal)
3. [Developer tools](#developer-tools)
4. [Declared surfaces](#declared-surfaces)
5. [How to run](#how-to-run)
6. [Outputs](#outputs)
7. [Disclaimer](#disclaimer)
8. [Document history](#document-history)

---

## When to regenerate (renewal)

Policy authority: [RULES — Certification renewal enforcement](../RULES.md#certification-renewal-enforcement-required).

After any change set that touches **product code**, **gate definitions** (`checks.json`, harness, `.pylintrc`), or **language surface inventory**:

1. Run the **full** package: `Invoke-Certification.ps1` (all Domain B **and** Domain A checks, including **pylint** and **Gitleaks**).  
2. Confirm `OverallPass` is **true** when shipping or marking work complete.  
3. Leave regenerable outputs **untracked** (gitignored).

**Rules:**

- **No partial renewal** — do not re-run only Bandit, only pylint, or only Gitleaks and rewrite the cert.  
- **Code verification always included** — pylint, PowerShell parse/BOM, and `validate-score` run every renewal.  
- **Security always included** — Bandit, PSScriptAnalyzer Error, and Gitleaks run every renewal.  
- Missing required tools ⇒ failed check ⇒ `OverallPass = false` (never a silent skip).  
- Narrow exception: pure docs edits that cannot affect gate results may skip renewal (see RULES).

Do not mark the task complete if a **required** check was skipped or failed.

---

## Developer tools

Install on **developer** machines only (not product runtime for end users).

| Tool | Role | Install hint (Windows) |
|------|------|------------------------|
| Python 3.13 + **pylint** | Domain B style | `py -3.13 -m pip install pylint` (user/dev env) |
| **Bandit** | Domain A Python SAST | `py -3.13 -m pip install bandit` |
| **PSScriptAnalyzer** | Domain A PowerShell | `Install-Module PSScriptAnalyzer -Scope CurrentUser` |
| **Gitleaks** | Domain A Secrets | `winget install Gitleaks.Gitleaks` (restart shell if needed) |

The harness probes PATH and common WinGet package locations for `gitleaks.exe`.

---

## Declared surfaces

Commands and pass criteria for this repository (also encoded in [checks.json](./checks.json)):

| Surface | Domain B command | Domain A command | Pass criteria |
|---------|------------------|------------------|---------------|
| Python (`kpi_modules`) | From `kpi-analytics\`: `py -3.13 -m pylint kpi_modules` | From `kpi-analytics\`: `py -3.13 -m bandit -r kpi_modules` | Exit 0; pylint **10.00/10**; Bandit clean |
| PowerShell (`excel-toolkit`) | PS 5.1 parse + UTF-8 BOM (or pure ASCII) on product `*.ps1`/`*.psm1` (sample-test excluded) | `Invoke-ScriptAnalyzer -Path excel-toolkit -Severity Error -Recurse` | Zero Error findings; scripts load |
| Secrets (whole repo) | — | `gitleaks detect` (via harness) | Exit 0; no leaks |
| Python contract | `kpi-analytics.cmd validate-score` | — | Exit 0; fixtures green |

**Required surfaces:** Python, PowerShell, Secrets. All required checks run on **every** certification renewal.

---

## How to run

From the **repository root** (Windows PowerShell 5.1):

```powershell
.\certification\Invoke-Certification.ps1
```

Exit code **0** means `OverallPass` is true; **1** means one or more required checks failed.

The harness always executes the full matrix in `checks.json`. There is no `-Domain` or partial-skip mode for production renewals.

---

## Outputs

| File | Role | Tracked? |
|------|------|----------|
| [README.md](./README.md) | This operator guide | Yes |
| [checks.json](./checks.json) | Declarative check list | Yes |
| [Invoke-Certification.ps1](./Invoke-Certification.ps1) | Full-suite harness | Yes |
| `last_certification.json` | Machine-readable certificate | **No** (gitignored) |
| `last_certification.txt` | Human-readable certificate | **No** (gitignored) |
| `logs/` | Optional tool reports (e.g. gitleaks JSON) | **No** (gitignored) |

JSON fields include: `CertificateType`, `OverallPass`, timestamps, `RepoRoot`, `GitCommit` / `GitBranch` / `GitDirty`, `LanguageSurfaces`, `ToolVersions`, `PassCriteria`, `Domains.Security`, `Domains.CodeValidation`, `Checks[]`, `Disclaimer`.

---

## Disclaimer

Self-attestation of automated checks only. Not a third-party audit. Not runtime package diagnostics. No claim rows, passwords, or secret values in certificate outputs (report counts / rule ids on failure).

**Suggested IT one-liner:**

> Automated security static analysis and code validation for declared language surfaces produced a pass certificate for commit \<sha\> at \<timestamp\>. Self-attestation only; not a third-party audit.

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial certification package: full-suite harness, checks.json, Secrets/Gitleaks required, renewal enforcement pointer to RULES |
