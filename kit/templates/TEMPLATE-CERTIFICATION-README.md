---
title: "{{PRODUCT_OR_REPO_NAME}} — Security and code-validation certification"
description: "Operator guide for regenerable self-attestation certificates (security static analysis and code validation)."
version: "{{VERSION}}"
status: draft
audience:
  - developers
  - security
  - it
doc_type: other
related:
  - ../RULES.md
  - ../rules/security.md
  - ../CHANGELOG.md
last_updated: "{{LAST_UPDATED}}"
---

# {{PRODUCT_OR_REPO_NAME}} — Certification

Operator guide for the **formal, regenerable** security and code-validation certificate for this repository. Implementation of an automated harness is optional; this folder documents schema and how to regenerate the pair.

**Document version:** {{VERSION}}  
**Status:** draft  

**Related:** [Security and code-validation certification](../rules/security.md#security-and-code-validation-certification) · [Language surface inventory](../rules/security.md#language-surface-inventory) · [RULES.md](../RULES.md)

---

## Summary

| Item | Decision |
|------|----------|
| **What** | Developer **self-attestation** certificate (JSON + TXT) for Domain A (security / SAST) **and** Domain B (code validation) |
| **Where** | This folder only: `certification/` |
| **Who runs it** | Developers / release reviewers — **not** end-user product launchers |
| **Product impact** | Must **not** gate product CLI or end-user install |
| **Harness** | Optional; may regenerate outputs manually until a project or kit runner exists |

This is **not** a third-party audit, SOC 2, or ISO seal.

---

## Contents

1. [Summary](#summary)
2. [When to regenerate](#when-to-regenerate)
3. [Declared surfaces](#declared-surfaces)
4. [Outputs](#outputs)
5. [Disclaimer](#disclaimer)
6. [Document history](#document-history)

---

## When to regenerate

After any change set that touches product code or declared gates:

1. Run Domain B and Domain A commands for surfaces in the project [language surface inventory](../rules/security.md#language-surface-inventory).  
2. Write or refresh `last_certification.json` and `last_certification.txt`.  
3. Confirm `OverallPass` is true when shipping.  
4. Leave regenerable outputs **untracked** (gitignored).

Do not mark the task complete if a **declared** gate was skipped or failed.

---

## Declared surfaces

> List **only** surfaces this repository ships. Kit catalog (do not paste unused rows): Python, Python deps, PowerShell, JavaScript/TypeScript/Node, Go, Rust, Shell, Other/mixed, Secrets, Semgrep.

| Surface | Domain B command | Domain A command | Pass criteria |
|---------|------------------|------------------|---------------|
| {{SURFACE}} | {{DOMAIN_B_COMMAND}} | {{DOMAIN_A_COMMAND}} | {{PASS_CRITERIA}} |

---

## Outputs

| File | Role |
|------|------|
| `last_certification.json` | Machine-readable certificate (gitignored) |
| `last_certification.txt` | Human-readable certificate (gitignored) |

Illustrative JSON fields: `CertificateType`, `OverallPass`, `GitCommit`, `GitDirty`, `LanguageSurfaces`, `ToolVersions`, `Domains.Security`, `Domains.CodeValidation`, `Checks[]`, `Disclaimer`. Full shape: [Certificate shape](../rules/security.md#certificate-shape-illustrative).

---

## Disclaimer

Self-attestation of automated checks only. Not a third-party audit. Not runtime package diagnostics. No claim rows, passwords, or secret values in outputs (report counts / rule ids on failure).

**Suggested IT one-liner:**

> Automated security static analysis and code validation for declared language surfaces produced a pass certificate for commit \<sha\> at \<timestamp\>. Self-attestation only; not a third-party audit.

---

## Document history

| Version | Notes |
|---------|--------|
| {{VERSION}} | Initial certification operator guide |
