---
title: Excel Toolkit Enterprise Security
description: Security review notes, unacceptable patterns, and execution restrictions for the Excel Toolkit on controlled corporate PCs.
version: "1.4.0"
status: current
audience:
  - security
  - developers
  - it
doc_type: security
related:
  - README.md
  - CLI-GUIDE.md
last_updated: "2026-07-22"
---

# Excel Toolkit — Enterprise Security & Execution Notes

Reference for security reviews, AppLocker/WDAC discussions, and controlled corporate PCs.

**Toolkit version:** 1.3.0  
**Toolkit folder:** `excel-toolkit\`  
**Related smoke tests:** `sample-test\` (execution probes only)

**Related docs:** [README.md](./README.md) · [CLI-GUIDE.md](./CLI-GUIDE.md)

---

## Summary

The Excel Toolkit is designed for **locked-down corporate desktops**. It converts user-supplied CSV data to formatted Excel workbooks **and** can import Excel workbooks back to CSV **locally** via Microsoft Excel COM: no downloads, no credential store access, no privilege elevation, and no permanent execution-policy changes. Allowed behavior is limited to reading user-chosen CSV/schema/Excel paths, writing workbooks or CSVs under user-chosen paths, optional workbook open-password handling in process memory only, process-scoped launcher Bypass on `.cmd` entry points, local module import, and (menu option only) **subprocess** of the sibling local `kpi-analytics.cmd` for score-then-export composition. Existing destinations are not overwritten by default (unique numerical suffix); `-Force` is explicit replace only.

This document states the **trust boundary**, lists high-risk patterns the toolkit **does not** use (force-kill Office, P/Invoke, download-and-run, silent MOTW unblock, etc.), what IT still must allow (PowerShell + Excel COM + script path), and a minimal validation sequence for security review. Sibling KPI analytics risks live under `kpi-analytics\ENTERPRISE-SECURITY.md`, not here.

---

## Contents

1. [Summary](#summary)
2. [Purpose of this document](#1-purpose-of-this-document)
3. [Trust boundary](#2-trust-boundary-what-the-toolkit-is-allowed-to-do)
4. [Patterns often treated as unacceptable](#3-patterns-often-treated-as-unacceptable-and-status-here)
5. [Remaining capabilities that require allowance](#4-remaining-capabilities-that-require-enterprise-allowance)
6. [PowerShell execution restrictions](#5-powershell-execution-restrictions)
7. [Recommended enterprise validation](#6-recommended-enterprise-validation-minimal)
8. [Audit snapshot](#7-audit-snapshot-implementation-decisions)
9. [What to tell IT / security reviewers](#8-what-to-tell-it--security-reviewers)
10. [Related files](#9-related-files)
11. [Document history](#10-document-history)

---

## 1. Purpose of this document

Summarize:

1. What the toolkit **does** from a security perspective  
2. Patterns that enterprises often treat as **unacceptable** (and how this toolkit avoids them)  
3. Patterns that remain **required** for Excel automation  
4. Execution-policy / language-mode expectations  
5. Operational guidance when something is blocked  

This is not a formal penetration-test report; it is a design audit of the PowerShell Excel COM tooling in this repository.

---

## 2. Trust boundary (what the toolkit is allowed to do)

| Area | Behavior |
|------|----------|
| **Privilege** | Runs as the **current user**. No UAC elevation, no admin rights required. |
| **Policy** | Does **not** permanently change `ExecutionPolicy`, GPO, or registry policy. |
| **Network** | No downloads, no HTTP clients, no remote modules. |
| **Identity** | Does not read credentials, tokens, or browser stores. Workbook open passwords are accepted only via interactive SecureString prompt or optional CLI `-Password` for automation. |
| **Scope of files** | Reads user-supplied CSV/schema/Excel paths; writes export workbooks under chosen paths (default repo `output\`); writes **import-excel** CSVs under chosen paths (default repo `import\`); uses `%TEMP%` for tests. Does **not** clobber existing destinations by default (writes `name_N.ext` siblings). |
| **Office** | Automates **local** Microsoft Excel via COM when installed for the user. |
| **Sibling toolkit** | Menu “Score → Excel” may start **local** `kpi-analytics\kpi-analytics.cmd` (Python 3.13 stdlib scoring). No remote endpoints. |
| **Surfaces** | Interactive menu, **CLI** (`ExcelToolkit.ps1` / `excel-toolkit.cmd`), and **modules** (`ExcelToolkit.psm1`, `ExcelCom.psm1`). |
| **Passwords** | Held in process memory only for the COM open/save call; **never** written to JSON, logs, host success messages, or disk. |

---

## 3. Patterns often treated as unacceptable (and status here)

These are commonly flagged by enterprise security reviews, EDR, AppLocker/WDAC, or "script hygiene" standards—even when used for legitimate IT automation.

| Pattern | Why it is sensitive | Status in `excel-toolkit` |
|---------|---------------------|---------------------------|
| **`Stop-Process -Force` on Office** | Force-killing Excel is high-risk automation; can disrupt user work; often EDR-alerted | **Not used.** Close path never kills `EXCEL.EXE`. |
| **`Add-Type` + P/Invoke (`DllImport`)** | Dynamic compilation + native API calls; often blocked in Constrained Language Mode / code integrity rules | **Not used.** |
| **HWND → PID tracking to enable kill** | Exists only to support force-kill | **Not present.** |
| **Silent `Unblock-File` of script folders** | Clears Mark-of-the-Web; can look like bypassing a security label | **Not used.** User may unblock manually if Windows requires it. |
| **`Invoke-Expression` / encoded commands** | Arbitrary code execution vectors | **Not present.** |
| **Download-and-run** (`Invoke-WebRequest`, `WebClient`, etc.) | Supply-chain / malware delivery pattern | **Not present.** |
| **Permanent `Set-ExecutionPolicy`** | Changes host trust policy | **Not present.** Process-scoped flags only from launchers (menu + CLI `.cmd`). |
| **HKLM / machine configuration writes** | Requires admin; policy surface | **Not present.** |
| **Credential access / secret scraping** | Credential theft pattern | **Not present** for OS/browser credential stores. Optional workbook open password is user-supplied only for Excel COM open/save. |
| **Logging secrets** | Password leakage via logs/telemetry | Passwords are **never** logged or included in `-Json` output (`PasswordUsed` is boolean only). |
| **`FinalReleaseComObject` thrash + forced process hide** | Obscure COM abuse patterns | Simple `ReleaseComObject` + light GC only for RCW cleanup. |

### Excel process lifecycle (current design)

```text
Close workbooks (no save of unsaved leftovers)
    → Application.Quit()
    → wait (default ~3 seconds)
    → one reattempt Quit() + wait
    → ReleaseComObject + light GC
    → if Quit did not complete cleanly: warn user to close Excel manually
```

**Never:** `Stop-Process` on Excel.

If a workbook file stays locked, the user must close Excel (or the Excel task) themselves so the job can continue safely.

---

## 4. Remaining capabilities that require enterprise allowance

These are **intentional** and required for the product to work. They are not obfuscation; they should be discussed as business automation.

| Capability | Used for | Typical enterprise gate |
|------------|----------|-------------------------|
| **`New-Object -ComObject Excel.Application`** | Create/open/edit/save `.xlsx` | Excel installed; COM automation not disabled; Full Language Mode |
| **Local `Import-Module` of `.psm1`** | Load `ExcelCom.psm1` / `ExcelToolkit.psm1` | Script/module allowlisting if AppLocker/WDAC is strict |
| **Process-scoped `-ExecutionPolicy Bypass` on `.cmd` launchers** | Double-click menu and CLI without changing machine policy | GPO may override; allowlist or signing may still be required |
| **Child `powershell.exe -File ...` from the menu/CLI** | Run export/tests in an isolated process | Same script allowlisting as parent |
| **Read/write CSV and `.xlsx` under user-chosen paths** | Data export and import | Normal user file ACLs |
| **Workbook open password (COM)** | Open/save password-protected workbooks | User or operator supplies password; process memory only |
| **`AutomationSecurity` force-disable macros when opening files** | Reduce macro risk during automation | Generally **security-positive**; keep |

---

## 5. PowerShell execution restrictions

### 5.1 Execution policy scopes

| Scope | Effect |
|-------|--------|
| **Process** | Applies only to that `powershell.exe` instance (used by `Start-ExcelMenu.cmd` and `excel-toolkit.cmd`) |
| **CurrentUser / LocalMachine** | Persistent; toolkit does **not** set these |
| **MachinePolicy / UserPolicy** | Group Policy; **overrides** process Bypass if set to Restricted / AllSigned, etc. |

**Implication:** `-ExecutionPolicy Bypass` on a launcher is **not** a machine-wide disable of security. If GPO forbids script execution, the toolkit cannot and should not try to circumvent it—**IT must allowlist or sign**.

### 5.2 Language mode

| Mode | Toolkit impact |
|------|----------------|
| **FullLanguage** | Required for Excel COM automation in practice |
| **ConstrainedLanguage** | Many COM / .NET operations blocked; toolkit will fail early |

Validate with:

```powershell
$ExecutionContext.SessionState.LanguageMode
```

Expect: `FullLanguage`.

### 5.3 AppLocker / WDAC / ASR

If scripts never start:

- Allowlist path: `...\excel-toolkit\*.ps1`, `*.psm1`, `*.cmd`  
- Or code-sign scripts and allow signed publishers  
- Confirm Excel COM is not blocked by Office hardening that disables automation  

The toolkit will **not** add more aggressive flags to defeat these controls.

### 5.4 Mark of the Web (MOTW)

Files copied from zip/email may be blocked under `RemoteSigned`.

- Toolkit does **not** auto-unblock.  
- User/IT: Properties → Unblock, or enterprise content-trust tooling.

---

## 6. Recommended enterprise validation (minimal)

Use `sample-test\` first (hand-typeable probes):

| Check | Meaning |
|-------|---------|
| `Test-CanRun` / `Test-Psm1` | `.cmd`, `.ps1`, `.psm1` can run |
| `Test-Env` | LanguageMode, process policy, module import, Excel COM, temp write |

Then:

1. Double-click `excel-toolkit\Start-ExcelMenu.cmd`, or  
2. Run `excel-toolkit\excel-toolkit.cmd diagnostics` (writes `diagnostics\last_diagnostics.*` pass/fail certificate), or `probe -Json` for a quick check, then  
3. `export-csv` (dry-run then real) per [CLI-GUIDE.md](./CLI-GUIDE.md)

**First-run gate:** `export-csv` / `import-excel` auto-run readiness diagnostics when no valid pass certificate exists for the current toolkit version. Delete the certificate files to force a re-run. Reports record environment/module/COM readiness only (no claim rows or PHI).

---

## 7. Audit snapshot (implementation decisions)

| Decision | Rationale |
|----------|-----------|
| No force-kill | Unacceptable risk/noise in enterprise EDR reviews |
| No P/Invoke PID map | Unnecessary without kill; blocked under CLM / code integrity |
| No auto Unblock-File | Avoid appearing to strip MOTW automatically |
| Quit → wait → one retry → notify | Predictable, user-visible, no process destruction |
| Keep Excel COM | Product requirement; validated on controlled-PC probes |
| Keep process Bypass only on launchers | Usability for double-click; not a permanent policy change |
| Schema/CSV-driven columns | No hard-coded business field lists in engine code |
| Thin CLI over shared module | Python and Task Scheduler can call without duplicating COM logic |

---

## 8. What to tell IT / security reviewers

**Short statement you can reuse:**

> The Excel Toolkit automates the user's installed Excel via COM to convert CSV data to `.xlsx` and to import Excel workbooks to CSV. It runs as the logged-on user, does not elevate, does not change machine execution policy, does not download code, and does not force-kill Office processes. Workbook open passwords (when needed) stay in process memory only and are never logged. Scripts are plain PowerShell 5.1 under `excel-toolkit\`, with an interactive menu, a high-level module, and a thin CLI for automation. Close behavior is Quit with a single retry and a user warning if Excel remains open. Process-scoped Bypass is used only so double-click launch works where GPO allows; AppLocker/WDAC still applies.

---

## 9. Related files

| Path | Role |
|------|------|
| `excel-toolkit\README.md` | User guide + module consumer notes |
| `excel-toolkit\CLI-GUIDE.md` | CLI syntax and automation examples |
| `excel-toolkit\ExcelCom.psm1` | Low-level COM module |
| `excel-toolkit\ExcelToolkit.psm1` | High-level export/import/version API |
| `excel-toolkit\ExcelToolkit.ps1` / `excel-toolkit.cmd` | CLI entry points |
| `excel-toolkit\Start-ExcelMenu.cmd` | Interactive launcher |
| `sample-test\` | Execution-only probes for locked-down PCs |
| This file | Security / restriction reference |

Canonical toolkit location is **`excel-toolkit\` only** (legacy `scripts\` path is retired).

---

## 10. Document history

| Version | Notes |
|---------|--------|
| 1.0 | Initial findings after enterprise audit; folder renamed to `excel-toolkit`; force-kill and P/Invoke removed |
| 1.1 | CLI + `ExcelToolkit.psm1`; docs use YAML frontmatter; enterprise close path unchanged; no force-kill / auto-unblock |
| 1.2 | `import-excel` / `Import-CsvFromExcel`; optional workbook open password on open/save; password never logged or written to JSON |
| 1.2.1 | Refuse overwrite of existing output files unless `-Force` (or interactive menu confirm) |
| 1.3.0 | Default collision policy: unique numerical suffix (`name_N.ext`) instead of refuse; menu Score→Excel may subprocess local `kpi-analytics.cmd`; `-Force` still exact-path replace only |
| 1.3.0a | Product scripts saved UTF-8 **with BOM** / ASCII-safe punctuation so Windows PowerShell 5.1 `-File` parses reliably (BOM-less UTF-8 + Unicode arrows/dashes caused menu parse failures) |
