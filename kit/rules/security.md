---
title: Security Baseline
description: Trust baseline, security doc modularity, language surface inventory, SAST gates, and certification schema.
version: "1.0.3"
status: current
audience:
  - developers
  - security
doc_type: other
related:
  - ../RULES.md
  - ./contracts.md
  - ./authoring-and-style.md
  - ./verification-and-ops.md
  - ../../certification/README.md
  - ../../excel-toolkit/ENTERPRISE-SECURITY.md
  - ../../kpi-analytics/ENTERPRISE-SECURITY.md
  - ../templates/TEMPLATE-CERTIFICATION-README.md
  - ../templates/TEMPLATE-SECURITY.md
last_updated: "2026-07-30"
---

# Security Baseline

Hard rules for product code and launchers, inventory-driven SAST, and formal certification for this repository.

**Document version:** 1.0.3  

**Related:** [RULES.md](../RULES.md) · [contracts.md](./contracts.md) · [authoring-and-style.md](./authoring-and-style.md) · [verification-and-ops.md](./verification-and-ops.md) · [certification/README.md](../../certification/README.md) · [TEMPLATE-SECURITY](../templates/TEMPLATE-SECURITY.md) · [TEMPLATE-CERTIFICATION-README](../templates/TEMPLATE-CERTIFICATION-README.md)

---

## Summary

| Must | Must not |
|------|----------|
| Fill language surface inventory for shipped surfaces | Paste the full multi-language SAST table without inventory evidence |
| Run **declared** Domain A (SAST) gates before complete | Treat SAST tools as product runtime dependencies |
| Omit empty SECURITY docs when modularity allows | Commit `last_certification.*` or treat certification as a product launcher gate |

---

## Contents

1. [Summary](#summary)
2. [Security baseline](#security-baseline)
3. [Security documentation modularity](#security-documentation-modularity)
4. [Language surface inventory](#language-surface-inventory)
5. [Security / SAST gates (required when declared)](#security--sast-gates-required-when-declared)
6. [Security and code-validation certification](#security-and-code-validation-certification)
7. [Document history](#document-history)

---

## Security baseline

Hard rules for product code and launchers. Full matrices live in the project security doc when one is required.

| Rule | Guidance |
|------|----------|
| Privilege | Prefer current user only; document any elevation requirement |
| Network | Document whether product code may reach the network or package indexes |
| Secrets | Never commit secrets; rotate if leaked; treat history cleanup as an incident |
| Dependencies | Match the declared dependency policy; no silent download-and-run |
| Host policy | Do not permanently weaken host security policy in product install steps without explicit, documented need |

Canonical detail (when applicable): the package `SECURITY.md` / `ENTERPRISE-SECURITY.md` (or equivalent) listed in the [authority map](../RULES.md#authority-map).

### This repository — enterprise constraints

| Rule | Excel toolkit | KPI analytics |
|------|---------------|---------------|
| Privilege | Current user only; no elevation | Current user only; no elevation |
| Network | No product downloads / remote modules | No network / package index access |
| Policy | Process-scoped Bypass on `.cmd` only; never permanent `Set-ExecutionPolicy` | No host policy mutation |
| Office | Local Excel COM when required | **No** Office automation |
| Dependencies | PowerShell + Excel COM | Python 3.13 stdlib only |
| Kill / unblock | No force-kill; no silent MOTW unblock | N/A for Office; no process kill patterns |

Canonical detail:

- [excel-toolkit/ENTERPRISE-SECURITY.md](../../excel-toolkit/ENTERPRISE-SECURITY.md)  
- [kpi-analytics/ENTERPRISE-SECURITY.md](../../kpi-analytics/ENTERPRISE-SECURITY.md)  

Policy-sensitive environments: run `excel-toolkit\sample-test\` probes before claiming the toolkit “works on locked-down PCs.”

---

## Security documentation modularity

Create or maintain a package `SECURITY.md` (or equivalent) **only when** the package has an **execution surface**, **network access**, **elevated privilege**, or **handles secrets**. Pure documentation packages and pure libraries with **no runtime side effects** may **omit** security documentation entirely—do not create empty files to satisfy a template habit.

| Situation | `SECURITY.md` |
|-----------|---------------|
| Docs-only / standards repo | **Omit** |
| Pure library, no network / privilege / secrets handling | **Omit** (optional short note in package README if helpful) |
| CLI, service, automation, or other execution surface | **Required** |
| Handles credentials, tokens, or elevated install | **Required** |
| Monorepo | Per package: required only for packages that meet the triggers above |

When omitted, remove the Security / trust boundary row from the [authority map](../RULES.md#authority-map). When present, keep trust-boundary detail in that canonical file—not duplicated into README. Trust surfaces are contracts when present—see [contracts.md](./contracts.md).

**This repository:** both `excel-toolkit` (PowerShell + Excel COM automation) and `kpi-analytics` (Python CLI / scoring execution surface) **require** their `ENTERPRISE-SECURITY.md` files.

---

## Language surface inventory

Declare **which product language and security surfaces this repository ships**. The inventory records **Status** and **tool identity**. **Executable commands and pass criteria** for formal certification live in [certification/README.md](../../certification/README.md) and [certification/checks.json](../../certification/checks.json)—do not re-paste long command tables here when only a Status or tool name changes.

| Surface | Status | Domain B — style / validation | Domain A — security / SAST | Typical pass | Notes |
|---------|--------|-------------------------------|----------------------------|--------------|--------|
| **Python** product code (`kpi_modules`) | **Declared** | **pylint** (exit 0, score **10.00/10** via `RequirePylintScore`) | **Bandit** | Style + SAST clean | Commands: [certification/README.md](../../certification/README.md) |
| **PowerShell** (`excel-toolkit` product scripts) | **Declared** | PS 5.1 parse + UTF-8 **BOM** policy | **PSScriptAnalyzer** Error | Zero Error findings; scripts load | Product `*.ps1`/`*.psm1` only; **`sample-test` excluded** from Domain A and B |
| **Secrets** (whole repo) | **Declared** | — | **Gitleaks** (workdir **and** git history) | No leaks on **both** modes | **Required** for completion and every certification renewal |
| **Python** dependencies | **Not declared** | — | pip-audit | — | Product is **stdlib-only** |
| JS/TS, Go, Rust, Shell, Semgrep | **Not present** | — | — | — | Do not invent gates for surfaces this repo does not ship |

**Declared surfaces for this repository:** **Python**, **PowerShell**, and **Secrets**. Domain A/B (and Secrets) gates are **required**. Prefer the [certification harness](../../certification/Invoke-Certification.ps1) so all declared surfaces run together.

**Rules:**

1. Inventory Status drives the [completion rule](./verification-and-ops.md#completion-rule) and [certification renewal](#certification-renewal-enforcement-required).  
2. Adding a language later updates inventory, certification `checks.json` / README, and authority map in the **same change set**.  
3. **Python product** and **Python dependencies** are separate (Bandit vs pip-audit). This repo declares product Python only.  
4. Prefer declared inventory over heuristic filesystem scans.  
5. **Secrets / Gitleaks:** **Declared and required** — skipping Gitleaks fails completion and fails certification renewal. The harness requires **two** scans: working tree (`--no-git`) and git history (default).

Domain B tool detail: [authoring-and-style.md](./authoring-and-style.md).

---

## Security / SAST gates (required when declared)

**Developer-tooling** gates for security-oriented static analysis. These are **not** style gates and are **not** product runtime dependencies.

**Posture:** When a language or security surface is **Declared** in the inventory, its Domain A tool is **required** before task completion and ship (see [Completion rule](./verification-and-ops.md#completion-rule)). Missing **required** developer tools is a **failed** gate, not a silent skip.

**Modularity rule:** Declare **only** tools for **languages and surfaces this repo ships**. Never paste unused language rows (Go, Rust, npm, etc.).

| Surface | Posture | Primary tool | Where commands live |
|---------|---------|--------------|---------------------|
| **Python** product (`kpi_modules`) | **Required** (declared) | **Bandit** (PyCQA) | [certification/checks.json](../../certification/checks.json) |
| **PowerShell** (`excel-toolkit`) | **Required** (declared) | **PSScriptAnalyzer** (Microsoft) | certification package |
| **Secrets** | **Required** (declared) | **Gitleaks** (workdir + git history) | certification package (full harness) |

**Product dependency:** **No.** Bandit, PSScriptAnalyzer, Gitleaks, and similar tools are **developer tooling** only. Do **not** add them as required installs for end users of the product.

**Rules:**

1. Operational commands and pass criteria live under `certification/`—keep this section as posture + tool identity.  
2. Install tools in the **developer** environment only.  
3. Warning-level findings (e.g. PSScriptAnalyzer **Warning**) stay advisory unless the project promotes them to critical.  
4. Package diagnostics (`kpi-analytics\diagnostics\`, `excel-toolkit\diagnostics\`) answer “can **this machine** run the product?”—they are **not** Domain A/B substitutes.  
5. **Gitleaks is required.** Skipping it fails the [Completion rule](./verification-and-ops.md#completion-rule) and [certification renewal](#certification-renewal-enforcement-required).

---

## Security and code-validation certification

This repository **maintains** a formal **developer self-attestation** package under `certification/`: for git commit *C* at time *T*, declared surfaces passed **Domain A (security / SAST + secrets)** and **Domain B (code validation)** in **one** certificate pair. This is **not** a third-party audit, SOC 2, ISO seal, or product runtime diagnostics gate.

| This **is** | This **is not** |
|-------------|-----------------|
| Self-attestation of automated checks bound to a commit | Third-party certification or compliance logo |
| Security **and** code validation in one certificate pair | A second product CLI / diagnostics gate for end users |
| Suitable for IT tickets and pre-ship review packets | Proof of regulated Safe Harbor or data claims |
| Regenerable, gitignored output under one folder | A substitute for human threat modeling |

### Single-folder rule

**All** formal certificates live under one folder:

```text
certification/
  README.md                    # operator guide + disclaimer (versioned)
  checks.json                  # declarative required checks (tracked)
  Invoke-Certification.ps1     # full-suite harness (tracked; developer-only)
  last_certification.json      # gitignored, regenerable
  last_certification.txt       # gitignored, regenerable
  logs/                        # gitignored optional tool reports
```

| Rule | Detail |
|------|--------|
| One folder | No split `security-cert/` vs `validation-cert/`; no extra root purpose directories |
| One certificate pair | Both domains appear **inside** the same JSON/TXT |
| Regenerable | Never commit `last_certification.*` or `certification/logs/` |
| Maintained | This repository **keeps** `certification/`; operator guide is [certification/README.md](../../certification/README.md) |
| Not package diagnostics | Do **not** merge `excel-toolkit\diagnostics\` or `kpi-analytics\diagnostics\` into `certification/` |

### Domains and OverallPass

```text
Domains.Security.OverallPass
Domains.CodeValidation.OverallPass
OverallPass = AND of domains that apply for declared inventory surfaces
```

**OverallPass** means: every **required critical** check that ran passed, **and** no required critical tool was missing.

| Domain | Covers (this repo) |
|--------|---------------------|
| **Security** | Bandit on `kpi_modules` (JSON evidence under `certification/logs/`); PSScriptAnalyzer Error on **product** `excel-toolkit` scripts (`sample-test` excluded) **and** `certification\*.ps1`; **Gitleaks** workdir + git history; **dynamic invariants** (privacy score mask, profile denylist, diagnostics key hygiene, `AutomationSecurity = 3`, password JSON contract); **policy-scan** banned automation patterns |
| **Code validation** | Manifest schema-validate + process executable allowlist; pylint on `kpi_modules` (**10.00/10** via `RequirePylintScore`); PS 5.1 parse/BOM on product set **and** certification harness; `validate-score` fixtures; **Ship mode:** clean git tree |

Commands: [certification/checks.json](../../certification/checks.json). Modes: `Standard` (default) · `Ship` (`-Mode Ship` adds `ship-clean-git`).

### Certificate shape (illustrative)

**Machine-readable** (`certification/last_certification.json`) should include: `CertificateType` (`SecurityAndCodeValidationCertification`), `SchemaVersion` (1.1+), `Mode`, `OverallPass`, `Message`, timestamps, `RepoRoot`, `GitCommit` / `GitBranch` / `GitDirty`, `LanguageSurfaces[]`, `PackageVersions`, `ToolVersions`, `Policy` (allowlist / clean-git), `Coverage` (static/dynamic/schema/engine counts), `PassCriteria`, `Domains.Security` / `Domains.CodeValidation`, `Checks[]` (`Name`, `Domain`, `Category`, `Passed`, `Severity`, `Detail`, `DurationMs`), `Disclaimer`.

**Human-readable** (`last_certification.txt`): same facts in sections. **Privacy:** paths, versions, rule ids, counts only—never secrets, passwords, PHI, or claim rows.

### Certification renewal enforcement (required)

When this repository maintains `certification/` (it does):

1. **Renew after code changes.** Any change set that edits product Python under `kpi-analytics\kpi_modules\`, product PowerShell under `excel-toolkit\`, certification gate definitions (`checks.json`, harness, `.pylintrc`), or [language surface inventory](#language-surface-inventory) **invalidates** the prior certificate for completion purposes.  
2. **Full package only.** Renewal **must** execute the full certification package ([Invoke-Certification.ps1](../../certification/Invoke-Certification.ps1) / **all** required rows in [checks.json](../../certification/checks.json)):  
   - **Domain B (code validation):** **pylint** (exit 0, **10.00/10**), PowerShell parse/BOM, `validate-score`, and any other required CodeValidation checks.  
   - **Domain A (security):** Bandit, PSScriptAnalyzer Error, **Gitleaks**, and any other required Security checks.  
3. **No partial renewal.** Re-running a subset of tools (only pylint, only Bandit, only Gitleaks, or only one domain) and writing a new cert pair is a **policy violation**. Both domains must be freshly executed in the **same** renewal run.  
4. **Completion rule.** Work that made certification stale is **not complete** until the harness finishes with `OverallPass = true` (or the change is reverted). Missing required tools **fail** the run; they do not exempt renewal.  
5. **Harness path.** Preferred renewal command from repo root: `.\certification\Invoke-Certification.ps1` (day-to-day **Standard** mode). For release packets with a clean tree: `.\certification\Invoke-Certification.ps1 -Mode Ship`. Manual hand-edits of a prior cert without re-running tools are **invalid**.  
6. **Narrow docs-only exception.** Pure documentation edits that cannot affect gate results may skip renewal; if unsure, renew.  
7. **Outputs.** Leave `last_certification.*` **untracked**. Never stage or commit them.  
8. **Engine integrity.** Manifest structural validation and process executable allowlist are part of the suite; do not bypass them to run unlisted tools from `checks.json`.

### Certification rule

Regenerate `last_certification.json` and `.txt` only by running the **full** suite per [Certification renewal enforcement](#certification-renewal-enforcement-required). Missing required tools yield `OverallPass = false`, not a silent skip.

**Relationship to package diagnostics:** package probes answer “can **this machine** run the product?” Certification answers “does **this source tree** meet security + validation policy?” Do not merge package diagnostics into `certification/`.

Operator guide: [certification/README.md](../../certification/README.md). Skeleton: [TEMPLATE-CERTIFICATION-README.md](../templates/TEMPLATE-CERTIFICATION-README.md).

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.3 | Certification Phase 2: required dynamic Security invariants + policy-scan in full harness |
| 1.0.2 | Certification engine hardening: schema-validate, allowlist, harness self-check, Ship mode, certificate SchemaVersion 1.1 fields |
| 1.0.1 | Project fill: inventory (Python/PowerShell/Secrets), enterprise table, certification renewal enforcement |
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0 |
