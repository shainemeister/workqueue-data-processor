---
title: "{{DOCUMENT_TITLE}}"
description: "{{ONE_LINE_PURPOSE}}"
version: "{{VERSION}}"
status: draft
audience:
  - developers
  - analysts
doc_type: methodology
related:
  - README.md
last_updated: "{{LAST_UPDATED}}"
---

# {{DOCUMENT_TITLE}}

{{ONE_LINE_PURPOSE}}

**Document version:** {{VERSION}}  
**Related:** [README.md](./README.md)

---

## Summary

{{SUMMARY_PARAGRAPH}}

---

## Contents

1. [Summary](#summary)
2. [Purpose and scope](#1-purpose-and-scope)
3. [Pipeline overview](#2-pipeline-overview)
4. [Definitions and formulas](#3-definitions-and-formulas)
5. [Worked example](#4-worked-example)
6. [Outputs / column contracts](#5-outputs--column-contracts)
7. [Validation](#6-validation)
8. [Common false alarms](#7-common-false-alarms)
9. [Out of scope](#8-out-of-scope)
10. [Document history](#9-document-history)

---

## 1. Purpose and scope

| Item | Detail |
|------|--------|
| **Goal** | {{GOAL}} |
| **Inputs** | {{INPUTS}} |
| **Outputs** | {{OUTPUTS}} |
| **Non-goals** | {{NON_GOALS}} |

---

## 2. Pipeline overview

```text
{{PIPELINE_DIAGRAM}}
```

---

## 3. Definitions and formulas

### 3.1 {{METRIC_OR_CONCEPT}}

| Symbol / field | Meaning |
|----------------|---------|
| {{SYMBOL}} | {{MEANING}} |

```text
{{FORMULA}}
```

---

## 4. Worked example

| Case | Input | Result |
|------|-------|--------|
| {{CASE}} | {{INPUT}} | {{RESULT}} |

---

## 5. Outputs / column contracts

| Column / artifact | Description |
|-------------------|-------------|
| {{COLUMN}} | {{COLUMN_DESC}} |

---

## 6. Validation

| Check | Pass criteria |
|-------|----------------|
| {{CHECK}} | {{PASS_CRITERIA}} |

---

## 7. Common false alarms

| Observation | Explanation |
|-------------|-------------|
| {{OBSERVATION}} | {{EXPLANATION}} |

---

## 8. Out of scope

- {{OUT_OF_SCOPE_ITEM}}

---

## 9. Document history

| Version | Notes |
|---------|--------|
| {{VERSION}} | Initial draft |
