---
title: "Work Queue Data Processor — Security and code-validation certification"
description: "Operator guide for the formal regenerable self-attestation certificate (Domain A security + Domain B code validation, including dual-mode Gitleaks)."
version: "1.2.0"
status: current
audience:
  - developers
  - security
  - it
doc_type: other
related:
  - ../kit/RULES.md
  - ../kit/rules/security.md
  - ../CHANGELOG.md
  - checks.json
  - Invoke-Certification.ps1
  - schema/checks.schema.json
  - policies/banned-patterns.json
last_updated: "2026-07-30"
---

# Work Queue Data Processor — Certification

Operator guide for the **formal, regenerable** security and code-validation certificate for this repository. One package covers **Domain A (security / SAST + secrets + dynamic invariants)** and **Domain B (code validation)** in a single certificate pair.

**Document version:** 1.2.0  
**Status:** current  

**Related:** [Security and code-validation certification](../kit/rules/security.md#security-and-code-validation-certification) · [Language surface inventory](../kit/rules/security.md#language-surface-inventory) · [checks.json](./checks.json) · [Invoke-Certification.ps1](./Invoke-Certification.ps1) · [schema/checks.schema.json](./schema/checks.schema.json)

---

## Summary

| Item | Decision |
|------|----------|
| **What** | Developer **self-attestation** certificate (JSON + TXT) for Domain A **and** Domain B |
| **Where** | This folder only: `certification/` |
| **Who runs it** | Developers / release reviewers — **not** end-user product launchers |
| **Product impact** | Must **not** gate product CLI or end-user install |
| **Harness** | [Invoke-Certification.ps1](./Invoke-Certification.ps1) — always runs the **full** suite for the selected mode |
| **Gate definitions** | [checks.json](./checks.json) — operational source of truth for commands |
| **Modes** | `Standard` (default, day-to-day renewal) · `Ship` (adds clean-git gate) |
| **Engine policy** | Executable allowlist for `Kind=process`; structural schema validation; harness self-check (parse/BOM + PSSA) |

This is **not** a third-party audit, SOC 2, or ISO seal.

**Not package diagnostics:** toolkit machine-readiness certificates stay under `kpi-analytics/diagnostics/` and `excel-toolkit/diagnostics/`. Do not merge those into this folder.

---

## Contents

1. [Summary](#summary)
2. [When to regenerate (renewal)](#when-to-regenerate-renewal)
3. [Developer tools](#developer-tools)
4. [Declared surfaces](#declared-surfaces)
5. [How to run](#how-to-run)
6. [Modes](#modes)
7. [Engine hardening](#engine-hardening)
8. [Outputs](#outputs)
9. [Advisory notes](#advisory-notes)
10. [Disclaimer](#disclaimer)
11. [Document history](#document-history)

---

## When to regenerate (renewal)

Policy authority: [Certification renewal enforcement](../kit/rules/security.md#certification-renewal-enforcement-required).

After any change set that touches **product code**, **gate definitions** (`checks.json`, harness, `.pylintrc`), or **language surface inventory**:

1. Run the **full** package: `Invoke-Certification.ps1` (all Domain B **and** Domain A checks, including **pylint** and **Gitleaks**).  
2. Confirm `OverallPass` is **true** when shipping or marking work complete.  
3. Leave regenerable outputs **untracked** (gitignored).

**Rules:**

- **No partial renewal** — do not re-run only Bandit, only pylint, or only Gitleaks and rewrite the cert.  
- **Code verification always included** — pylint (declarative **10.00/10** via `RequirePylintScore`), PowerShell parse/BOM, and `validate-score` run every renewal.  
- **Security always included** — Bandit, PSScriptAnalyzer Error (product scripts only), and **dual-mode Gitleaks** run every renewal.  
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
| Meta (manifest) | Structural `checks.json` validation (`schema-validate`) | — | Required fields, known Kinds, process executables on allowlist |
| Python (`kpi_modules`) | From `kpi-analytics\`: `py -3.13 -m pylint kpi_modules` | Bandit on `kpi_modules` with JSON evidence under `logs/bandit.json` | Exit 0; pylint **10.00/10** (`RequirePylintScore`); Bandit clean |
| PowerShell (`excel-toolkit` product scripts) | PS 5.1 parse + UTF-8 BOM (or pure ASCII) on product `*.ps1`/`*.psm1` (**`sample-test` excluded**) | PSScriptAnalyzer **Error** on the **same** product file set (**`sample-test` excluded**) | Zero Error findings; scripts load |
| PowerShell (`certification` harness) | PS 5.1 parse + UTF-8 BOM on `certification\*.ps1` | PSScriptAnalyzer **Error** on the same set | Zero Error findings; harness loads |
| Secrets (whole repo) | — | **Gitleaks dual mode:** working tree (`--no-git`) **and** git history | Exit 0 on **both** modes; no leaks |
| Python contract | `kpi-analytics.cmd validate-score` (handcalc defaults) | — | Exit 0; handcalc fixtures green |
| Python contract (RCM) | `kpi-analytics.cmd validate-score` with `fixtures/rcm_impact_*` | — | Exit 0; RCM dual-attribution golden green |
| Meta (Ship mode only) | Clean git working tree (`git-clean`) | — | No porcelain when `-Mode Ship` |
| **Dynamic — privacy** | — | `python-assert` `invariant_privacy_score.py` | Privacy on: DOB blank; patient mask pattern; no raw fixture PHI in output |
| **Dynamic — profiles** | — | `invariant_profile_denylist.py` | Rejects `rows`/`claims`/`data`/`records` in profile envelopes |
| **Dynamic — diagnostics** | — | `invariant_diagnostics_keys.py` | Diagnostics key tree has no PHI/claim dump shapes |
| **Dynamic — Excel macros** | — | `invariant_automation_security.py` | `ExcelCom.psm1` sets `AutomationSecurity = 3` (non-comment) |
| **Dynamic — password JSON** | — | `invariant_password_json_contract.py` | CLI/module JSON exposes `PasswordUsed` boolean only |
| **Policy** | — | `policy-scan` + [policies/banned-patterns.json](./policies/banned-patterns.json) | Zero critical banned patterns in product trees |

**Required surfaces:** Python, PowerShell, Secrets. All required checks for the selected **mode** run on **every** certification renewal (full suite; no partial recert). Standard mode currently runs **17** required checks (static + dynamic + policy).

**Gitleaks modes (both required):**

| Mode | Flag | Purpose |
|------|------|---------|
| `workdir` | `--no-git` | Catch secrets in the current working tree (including uncommitted files) |
| `git` | default git scan | Catch secrets still present in repository history |

Reports: `certification/logs/gitleaks-workdir.json` and `certification/logs/gitleaks-git.json` (gitignored; counts/rule ids only in the certificate—never secret values).

---

## How to run

From the **repository root** (Windows PowerShell 5.1):

```powershell
.\certification\Invoke-Certification.ps1
# Release / ship renewal (also requires clean git tree):
.\certification\Invoke-Certification.ps1 -Mode Ship
# CI-style: run suite without rewriting cert files
.\certification\Invoke-Certification.ps1 -SkipWrite
```

Exit code **0** means `OverallPass` is true; **1** means one or more required checks failed.

The harness always executes the full matrix applicable to the mode. There is no `-Domain` or partial-skip mode for production renewals.

---

## Modes

| Mode | When to use | Extra gates |
|------|-------------|-------------|
| **Standard** (default) | Day-to-day renewal after product/gate changes | All required non-`ShipOnly` checks |
| **Ship** | Pre-release / completion when claiming a clean ship packet | Standard suite **plus** `ship-clean-git` (`GitDirty` must be false) |

`ShipOnly` checks are **skipped** in Standard (not failed). They are **required** in Ship.

---

## Engine hardening

| Control | Behavior |
|---------|----------|
| **Schema validation** | `Kind=schema-validate` checks required fields, domains, severities, known Kinds, and process allowlist membership |
| **Executable allowlist** | `Policy.ExecutableAllowlist` in `checks.json` (default: `py`, `python`, `kpi-analytics.cmd`, `gitleaks`). Rooted arbitrary paths for `Kind=process` are rejected |
| **Harness self-check** | `certification\*.ps1` included in parse/BOM + PSSA Error |
| **Evidence logs** | Bandit JSON → `logs/bandit.json`; Gitleaks → `logs/gitleaks-*.json`; policy-scan → `logs/policy-scan.json` (gitignored; counts/rule ids only in certificate) |
| **Illustrative schema** | [schema/checks.schema.json](./schema/checks.schema.json) documents the shape; runtime validation is in the harness (no external JSON Schema dependency) |
| **Dynamic asserts** | `Kind=python-assert` / `powershell-assert` run scripts under `certification/scripts/` only (path confined) |
| **Policy scan** | `Kind=policy-scan` loads [policies/banned-patterns.json](./policies/banned-patterns.json); comment lines ignored |

### Dynamic / policy checks (required Security)

| Id | Script / policy | Proves |
|----|-----------------|--------|
| `invariant-privacy-score` | [scripts/invariant_privacy_score.py](./scripts/invariant_privacy_score.py) + [fixtures/privacy_score_input.csv](./fixtures/privacy_score_input.csv) | Score-path PHI masking |
| `invariant-profile-denylist` | [scripts/invariant_profile_denylist.py](./scripts/invariant_profile_denylist.py) | Profiles cannot embed claim dumps |
| `invariant-diagnostics-keys` | [scripts/invariant_diagnostics_keys.py](./scripts/invariant_diagnostics_keys.py) | Diagnostics cert shape is environment-only |
| `invariant-automation-security` | [scripts/invariant_automation_security.py](./scripts/invariant_automation_security.py) | Macro force-disable still present |
| `invariant-password-json-contract` | [scripts/invariant_password_json_contract.py](./scripts/invariant_password_json_contract.py) | No password values in JSON payloads |
| `policy-banned-patterns` | [policies/banned-patterns.json](./policies/banned-patterns.json) | No Stop-Process/IEX/Unblock-File/download/pip/eval patterns in product code |

**Not yet gated (roadmap):** KPI menu `cmd /c` quoting (after product spawn hardening); Excel live password canary (needs Excel); PSSA Warning as critical (after secure CLI password path).

Privacy invariants are **operational masking proofs**, not HIPAA Safe Harbor claims.

---

## Outputs

| File | Role | Tracked? |
|------|------|----------|
| [README.md](./README.md) | This operator guide | Yes |
| [checks.json](./checks.json) | Declarative check list | Yes |
| [Invoke-Certification.ps1](./Invoke-Certification.ps1) | Full-suite harness | Yes |
| [schema/checks.schema.json](./schema/checks.schema.json) | Documented JSON Schema for the manifest | Yes |
| [policies/banned-patterns.json](./policies/banned-patterns.json) | Policy-scan rule pack | Yes |
| [scripts/](./scripts/) | Dynamic invariant helpers (`python-assert`) | Yes |
| [fixtures/](./fixtures/) | Synthetic cert fixtures (no real PHI) | Yes |
| `last_certification.json` | Machine-readable certificate | **No** (gitignored) |
| `last_certification.txt` | Human-readable certificate | **No** (gitignored) |
| `logs/` | Tool reports (bandit, dual gitleaks JSON, …) | **No** (gitignored) |

JSON fields include: `CertificateType`, `SchemaVersion` (**1.1**), `Mode`, `OverallPass`, `Message`, timestamps, `RepoRoot`, `GitCommit` / `GitBranch` / `GitDirty`, `LanguageSurfaces`, `PackageVersions`, `ToolVersions`, `Policy`, `Coverage`, `PassCriteria`, `Domains.Security`, `Domains.CodeValidation`, `Checks[]` (including `Category`, `DurationMs`), `Disclaimer`.

---

## Advisory notes

### PSScriptAnalyzer Warning (not a certification gate)

PSScriptAnalyzer may report **Warning**-severity `PSAvoidUsingPlainTextForPassword` on automation bridges such as CLI `-Password` (string) and related COM helpers. Per [SAST gates](../kit/rules/security.md#security--sast-gates-required-when-declared), **Warning** findings stay **advisory** unless the project promotes them to critical.

- Certification Domain A for PowerShell requires **zero Error** findings only.  
- Interactive menu paths already prefer **SecureString** for workbook open passwords where practical.  
- String `-Password` remains available for Task Scheduler / non-interactive automation (password is not logged or written to JSON payloads as a secret value).  
- Further SecureString hardening is a **follow-up** product change (CLI contract awareness)—not part of the certification Error gate.

---

## Disclaimer

Self-attestation of automated checks only. Not a third-party audit. Not runtime package diagnostics. No claim rows, passwords, or secret values in certificate outputs (report counts / rule ids on failure).

**Suggested IT one-liner:**

> Automated security static analysis and code validation for declared language surfaces produced a pass certificate for commit \<sha\> at \<timestamp\>. Self-attestation only; not a third-party audit.

---

## Document history

| Version | Notes |
|---------|--------|
| 1.2.0 | Phase 2 dynamic Security invariants + policy-scan required in full suite (privacy, profile denylist, diagnostics keys, AutomationSecurity, password JSON, banned patterns); 16 Standard checks |
| 1.1.0 | Engine hardening: SchemaVersion 1.1, schema-validate, process allowlist, harness self-check (parse/BOM + PSSA), Bandit evidence log, `-Mode Ship` clean-git, Coverage/Policy/Category fields |
| 1.0.2 | Links updated for repo-kit 2.x (`kit/rules/security.md`); harness root detection uses `kit/RULES.md` |
| 1.0.1 | PSSA product-only scope (align with parse/BOM); dual-mode Gitleaks; declarative pylint score; cert schema polish (`PackageVersions`, `DurationMs`, `Message`); password Warning advisory note |
| 1.0.0 | Initial certification package: full-suite harness, checks.json, Secrets/Gitleaks required, renewal enforcement pointer to RULES |
