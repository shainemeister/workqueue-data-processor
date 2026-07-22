---
title: Work Queue Priority Matrix Concept
description: Progressive multi-version design for explainable Work Queue priority scoring (V1 foundation through V3 decision support).
version: "1.0.0"
status: current
audience:
  - developers
  - analysts
doc_type: concept
related:
  - kpi-analytics/SCORE-METHODOLOGY.md
  - kpi-analytics/README.md
  - wq_schema.json
last_updated: "2026-07-22"
---

# Work Queue Priority Matrix – Concept Documentation

This document describes a progressive, multi-version approach to prioritization scoring for Work Queue (WQ) denial and follow-up claims.

**Document version:** 1.0.0  
**Current implementation target:** Version 1 (implemented in `kpi-analytics`)  

**Related:** [kpi-analytics/SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md) · [kpi-analytics/README.md](./kpi-analytics/README.md)

---

## Summary

The system produces a single explainable priority score between **0.0 and 1.0** for each claim. All intermediate calculations are retained as separate columns so the score can be audited and understood.

The design grows in sophistication across three versions while remaining practical to implement:

| Version | Focus |
|---------|--------|
| **V1 – Foundation** | Simple, calculable metrics; healthy vs chaos weights; full audit columns |
| **V2 – Operational intelligence** | Denial volume, velocity, and category exposure |
| **V3 – Advanced decision support** | Recovery probability, difficulty, capacity-aware recommendations |

**Implemented today:** Version 1 formulas and columns in `kpi-analytics` (see SCORE-METHODOLOGY). V2/V3 remain design targets.

---

## Contents

1. [Summary](#summary)
2. [Overview](#overview)
3. [Shared principles](#shared-principles)
4. [Version 1 – Foundation](#version-1--foundation)
5. [Version 2 – Operational intelligence](#version-2--operational-intelligence)
6. [Version 3 – Advanced decision support](#version-3--advanced-decision-support)
7. [Implementation notes](#implementation-notes)
8. [Document control](#document-control)

---

## Overview

This document describes a progressive, multi-version approach to prioritization scoring for Work Queue (WQ) denial and follow-up claims.

The system produces a single explainable priority score between **0.0 and 1.0** for each claim. All intermediate calculations are retained as separate columns so the score can be audited and understood.

The design grows in sophistication across three versions while remaining practical to implement.

---

## Shared principles

| Principle | Description |
|---------|-------------|
| Ratio / Rank based | Metrics are converted to a 0.0 – 1.0 scale before weighting |
| Full explainability | Every raw value, ratio, weight, and flag is written to the output |
| Dual-mode awareness | Behavior changes when the Work Queue is healthy vs unhealthy (chaos) |
| Configurable focus | Base weights can be adjusted by multipliers according to Point of Interest |
| Progressive complexity | Each version builds on the previous one |

---

## Version 1 – Foundation

**Goal:** Deliver a transparent, mathematically simple prioritization score using only easy-to-calculate fields.

### Core metrics

| Metric | Description | Basic Calculation | Notes |
|--------|-------------|-------------------|-------|
| AR Days | Age of the claim from Date of Service | `Today - service_date` | Foundational aging measure |
| AR Disparity | Distance from the AR Days target | `AR Days - AR_Day_Target` | Positive = past target |
| Outstanding Balance | Remaining insurance responsibility | `out_ins_amt` | Primary financial exposure |
| Billed Amount | Original charged amount | `billed_amount` | Supporting financial signal |
| Appeal Urgency | Days remaining before appeal rights are lost | `days_until_appeal_deadline` | Critical permanent-loss risk |
| WQ Age | Days the item has been in the current Work Queue | `days_on_wq_tab` | Secondary signal |

### Healthy vs chaos detection

A Work Queue is flagged as **unhealthy / chaos** when:

- AR Days significantly exceed the organizational target, **or**
- The AR aging curve is unfavorable (elevated share in 60 / 90 / 120+ buckets), **or**
- Average claims cleared per day falls below a defined viability threshold

In chaos mode, greater weight is automatically applied to AR Disparity and Appeal Urgency.

### Normalization and weighting

- Metrics are normalized to 0.0 – 1.0 using percentile ranking or min-max style scaling (chosen per metric).
- A single base set of weights is used.
- Weights are adjusted by multipliers when the queue is in chaos mode or when leadership changes the Point of Interest.

### Output

- Final Priority Score (0.0 – 1.0)
- All raw metrics, normalized ratios, applied weights/multipliers, and mode flag as separate columns

---

## Version 2 – Operational intelligence

**Goal:** Add volume, velocity, and category awareness so the matrix can react to denial patterns and workload pressure more intelligently.

### New metrics added

| Metric | Description | Purpose |
|--------|-------------|---------|
| Denial Category Volume | Count of claims sharing the same denial category / reason code | Identifies high-frequency problems |
| Denial Velocity (DOS-based) | Rate of new denials by Date of Service period | Early pattern detection |
| Denial Velocity (WQ-based) | Rate of denials accumulating inside the Work Queue | Measures current backlog pressure |
| Category Financial Exposure | Total or average outstanding balance by denial category | Combines volume with dollars |
| Repeat Denial Flag | Whether the claim has been denied more than once (`denial_count > 1`) | Signals harder or recurring issues |

### Enhanced chaos detection

In addition to Version 1 signals, Version 2 also considers:

- Rising denial velocity
- Concentration of volume in a small number of denial categories
- Clearing capacity versus incoming denial volume

### Weighting improvements

- Base weights remain.
- Stronger automatic multipliers are applied in chaos mode to permanent-loss metrics.
- Leadership Point of Interest can now emphasize volume/velocity suppression in addition to aging or dollars.

### Output additions

- Category-level summary statistics
- Velocity trend indicators
- Clear flags showing which Version 2 metrics most influenced the final score

---

## Version 3 – Advanced decision support

**Goal:** Incorporate recovery potential, resolution difficulty, and richer operational context so the matrix can make more nuanced trade-offs.

### New concepts introduced

| Concept | Description | Benefit |
|---------|-------------|---------|
| Difficulty-of-Resolution Score | Interpretation layer that rates how hard a denial type is to overturn (e.g., missing authorization requiring appeal) | Avoids spending effort on low-probability work when better opportunities exist |
| Historical Recovery / Overturn Rate | Past success rate by denial category or reason code | Moves from “what is big” to “what is worth working” |
| Dynamic Daily Clearing Capacity | Rolling calculation of actual claims cleared per day | Replaces static thresholds with real throughput |
| Multiple Point-of-Interest Profiles | Named weight sets (e.g., “Protect Write-offs”, “Maximize Cash”, “Suppress Emerging Trends”) | Faster response to leadership direction |
| Expected Value Proxy | Combination of outstanding balance × estimated recovery probability | Better ranking of true financial opportunity |

### Advanced chaos / health logic

- Continuously updated WQ Health Index (0.0 – 1.0) rather than simple binary flags
- Capacity-aware recommendations (surface only as many claims as the team can realistically clear)

### Output additions

- Recommended action context (e.g., “High dollar + high recovery probability”, “Approaching timely filing”, “High velocity emerging category”)
- Contribution breakdown showing how much each major factor influenced the final score
- Optional daily work-list size recommendation based on clearing capacity

---

## Implementation notes

- **Version 1** should be fully implementable with the fields already available in the current data model (and is the live path in `kpi-analytics`).
- Each later version reuses and extends the columns produced by the previous version.
- All versions maintain the core requirement that the final score is a single float between 0.0 and 1.0 and that supporting calculations are written out for transparency.

---

## Document control

- This document is updated as formulas, thresholds, and weight sets are refined.
- Current implementation target: **Version 1**.

| Version | Notes |
|---------|--------|
| 1.0.0 | Concept restructured to repository markdown standard; single H1; YAML frontmatter; V1–V3 design retained |
