---
title: KPI Analytics
description: Python 3.13 stdlib toolkit for Work Queue priority scoring, RCM claim-level KPI impacts, synthetic data, and validation.
version: "1.8.0"
status: current
audience:
  - users
  - developers
  - analysts
related:
  - CLI-GUIDE.md
  - SCORE-METHODOLOGY.md
  - RCM_KPI_Claim_Impact_Methodology.md
  - ENTERPRISE-SECURITY.md
last_updated: "2026-07-22"
---

# KPI Analytics (`kpi-analytics`)

Windows-oriented **Python 3.13** toolkit (standard library only) for professional billing Work Queue (WQ) analytics:

1. **Priority Matrix V1** — explainable 0–1 work-queue ranking (`v1_*` columns).  
2. **RCM KPI claim impact** — portfolio KPIs plus per-claim static share and exact resolution impact (`kpi_q_*`).  
3. **Vertical summary CSV** — run metrics, KPIs, and plain-language explanations as rows.  
4. **Synthetic data** — de-identified professional billing test CSVs.  
5. **Validation** — integrity checks and golden fixtures.  
6. **Enterprise diagnostics** — first-run runtime/import dry-run with a durable pass/fail report and a gate on operational commands.  
7. **PHI field masking** — optional score-output masking of patient name and DOB (config-driven; default on).

**Toolkit version:** 1.8.0  
**Product folder:** `kpi-analytics\`  
**Python package:** `kpi_modules\` (implementation; name differs from the product folder on purpose)

| Document | Audience |
|----------|----------|
| [CLI-GUIDE.md](./CLI-GUIDE.md) | Commands, exit codes, automation |
| [SCORE-METHODOLOGY.md](./SCORE-METHODOLOGY.md) | Priority formulas + `kpi_q_*` implementation |
| [RCM_KPI_Claim_Impact_Methodology.md](./RCM_KPI_Claim_Impact_Methodology.md) | RCM dual-attribution theory (proof of concept) |
| [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md) | Trust boundary for controlled PCs |

Column **order** always comes from your data CSV. Scoring appends fields; it does not invent missing business columns. Metric field names are configurable (defaults match the repo WQ schema).

---

## Summary

KPI Analytics is a local, offline Python toolkit for professional billing Work Queue files. It scores each claim for **work priority** (`v1_priority_score` and audit columns), attaches **RCM claim-impact measures** (`kpi_q_*` static share and exact resolution deltas), and writes a **vertical summary CSV** that explains portfolio KPIs (Total AR, Days in AR, aging %) in plain language. Optional commands generate de-identified synthetic data and validate results against fixtures. On first operational use (or when the certificate is missing/stale), **enterprise diagnostics** auto-runs a runtime/import dry-run and writes a pass/fail report under `diagnostics\`. The runtime is **Python 3.13 standard library only**—no pip packages, no network, no Excel automation (use sibling `excel-toolkit` for `.xlsx` export).

| You want… | Start here |
|-----------|------------|
| First-run on a locked-down PC | `kpi-analytics.cmd diagnostics` · [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md) |
| Run scoring end-to-end | [Recommended workflow](#recommended-workflow) |
| CLI syntax & automation | [CLI-GUIDE.md](./CLI-GUIDE.md) |
| Formulas & validation | [SCORE-METHODOLOGY.md](./SCORE-METHODOLOGY.md) |
| RCM dual-attribution theory | [RCM_KPI_Claim_Impact_Methodology.md](./RCM_KPI_Claim_Impact_Methodology.md) |
| Security / controlled PCs | [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md) |

---

## Contents

1. [Summary](#summary)
2. [Who should use what](#who-should-use-what)
3. [Recommended workflow](#recommended-workflow)
4. [What a score run produces](#what-a-score-run-produces)
5. [Prerequisites](#prerequisites)
6. [Data and configuration](#data-and-configuration)
7. [Synthetic data (`generate`)](#synthetic-data-generate)
8. [Layout and architecture](#layout-and-architecture)
9. [Using from Python](#using-from-python)
10. [CLI quick reference](#cli-quick-reference)
11. [Configuration highlights](#configuration-highlights)
12. [Validation and fixtures](#validation-and-fixtures)
13. [Enterprise notes (summary)](#enterprise-notes-summary)
14. [Troubleshooting](#troubleshooting)
15. [Out of scope](#out-of-scope)

---

## Who should use what

| Audience | Entry point |
|----------|-------------|
| Command Prompt / batch | `kpi-analytics.cmd` |
| Same process (Python) | `from kpi_modules.score_v1 import score_csv` |
| Synthetic test volume | `kpi-analytics.cmd generate` |
| Formulas & validation | [SCORE-METHODOLOGY.md](./SCORE-METHODOLOGY.md) · `validate-score` |
| RCM theory (Days in AR, aging %, Δ) | [RCM_KPI_Claim_Impact_Methodology.md](./RCM_KPI_Claim_Impact_Methodology.md) |
| Excel workbook | Score first, then sibling **`excel-toolkit\`** |

---

## Recommended workflow

```bat
cd /d C:\path\to\workqueue-data-processor\kpi-analytics

kpi-analytics.cmd version
kpi-analytics.cmd diagnostics --json
kpi-analytics.cmd probe --json

rem Optional: refresh tracked synthetic input under import\
kpi-analytics.cmd generate --rows 250 --seed 42

rem Score: default --csv is ..\import\wq_synthetic_data.csv
kpi-analytics.cmd score --output ..\output\wq_scored.csv --json

kpi-analytics.cmd validate-score --json
```

Paths (by default):

| File | Content |
|------|---------|
| `..\import\wq_synthetic_data.csv` | Tracked synthetic **input** (default for `score` / `generate`) |
| `diagnostics\last_diagnostics.json` / `.txt` | Enterprise pass/fail certificate (auto-created on first operational run) |
| `..\output\wq_scored.csv` | Scored **output**: source fields (patient/DOB masked by default) + `v1_*` + `kpi_q_*` |
| `..\output\wq_scored_summary.csv` | Vertical summary: section, metric, value, unit, formula, explanation |

`score`, `generate`, and `validate-score` require a valid diagnostics **pass** for this toolkit + Python version. If the certificate is missing, failed, or stale, diagnostics **auto-runs** and the command proceeds only when critical checks pass. Use `diagnostics --force` to re-check; `--skip-diagnostics-gate` is emergency/support only.

The launcher prefers `py -3.13`, then `python`. It does not install packages or change machine policy.

---

## What a score run produces

### A. Priority Matrix V1 (`v1_*`)

Explainable work ranking for denial / follow-up queues:

- Raw metrics (AR days, disparity vs target, balances, appeal window, WQ age)
- Batch normalization and weights (with optional chaos multipliers)
- `v1_priority_score` in **[0, 1]** plus full audit columns (`v1_raw_*`, `v1_norm_*`, `v1_weight_*`, `v1_contrib_*`)

Concept design: repository root `WQ_Priority_Matrix_Concept.md` (V1 implemented here).

### B. RCM claim impact (`kpi_q_*`) — independent of priority

Aligned with the dual-attribution model in **RCM_KPI_Claim_Impact_Methodology.md**:

| Kind | Purpose | Adds up to portfolio KPI? |
|------|---------|---------------------------|
| **Static** share / aged contrib | “How much of the problem is this claim *now*?” | **Yes** (dollar-weighted) |
| **Exact Δ** (Days in AR; aging pp) | “If balance → 0 today, how much does the KPI move?” | Days in AR **yes**; aging **% Δ no** |

Portfolio totals appear in CLI JSON as `KpiTotals` (Total AR, Days in AR, AR-over-T %, ADC).

### C. Vertical summary CSV

Transposed run report for leadership and audit: each KPI or setting is a **row**, with human-readable explanation. Sections include Run, Portfolio KPI, **Portfolio KPI Q checksum**, Claim column guide, Priority batch, and References.

---

## Prerequisites

| Need | Notes |
|------|--------|
| Python 3.13.x | Standard install only — **no pip packages** |
| Data CSV | Header row; one claim per data row |
| Optional config | `kpi_modules\config_default.json` shape |
| Optional ADC | Set `kpi_quantifiers.adc` for true Days in AR; else estimated from batch billed / 90 |

**Developers (optional):** PEP-8 style gate uses system/dev [pylint](https://pylint.readthedocs.io/) with [`.pylintrc`](./.pylintrc). From `kpi-analytics\`: `py -3.13 -m pylint kpi_modules`. Pylint is **not** required to run scoring on enterprise PCs and is not a product dependency.

---

## Data and configuration

| Input | Role |
|-------|------|
| **Data CSV** | Source of truth for column order and technical names |
| **Config JSON** | Priority weights, chaos, field map, `kpi_quantifiers` (ADC, aging breaks, credit policy) |
| **Schema** | Used by `generate` / optional `probe`; not required for score |

Default priority metric fields:

| Config key | Default CSV column | Role in priority V1 |
|------------|--------------------|---------------------|
| `service_date` | `service_date` | AR days |
| `out_ins_amt` | `out_ins_amt` | Outstanding $ (also default RCM balance) |
| `billed_amount` | `billed_amount` | Billed $ (ADC estimate input) |
| `days_until_appeal_deadline` | `days_until_appeal_deadline` | Appeal urgency |
| `days_on_wq_tab` | `days_on_wq_tab` | WQ age |

---

## Synthetic data (`generate`)

De-identified **professional billing** style rows for testing:

| Rule | Behavior |
|------|----------|
| Patients | `Doe,John{N}` / `Doe,Jane{N}` only |
| DOB | Excel serial; calendar day always **01** |
| Profile | Pro-fee CPT mix, specialty departments, denial patterns |
| Aging | Includes inventory through **365–730** days |

```bat
kpi-analytics.cmd generate --rows 250 --seed 42
kpi-analytics.cmd generate --rows 200 --append
rem one-off dump elsewhere:
kpi-analytics.cmd generate --rows 100 --output ..\output\wq_data_synthetic_tmp.csv
```

---

## Layout and architecture

```text
kpi-analytics/
  kpi-analytics.cmd          Windows CLI shim
  kpi_modules/               Python package
    cli.py                   version | probe | diagnostics | score | generate | validate-score
    diagnostics.py           Enterprise runtime/import dry-run + gate certificate
    score_v1.py              Priority orchestration + KPI attach
    kpi_quantifiers.py       RCM static + exact Δ (kpi_q_*)
    summary_report.py        Vertical summary CSV
    metrics.py / normalize.py
    synthesize.py            Synthetic WQ generator
    validate_score.py        Integrity + golden fixtures
    config_default.json
  diagnostics/               Pass/fail reports (generated; see diagnostics/README.md)
  fixtures/                  Hand-calc and RCM §6 examples
  *.md                       Documentation (this set)
```

```text
Humans / cmd     → kpi-analytics.cmd → python -m kpi_modules
Python in-process → kpi_modules.score_v1 / synthesize / config
Automation        → CLI with --json
```

---

## Using from Python

```python
import sys
from pathlib import Path

toolkit = Path(r"C:\path\to\workqueue-data-processor\kpi-analytics")
sys.path.insert(0, str(toolkit))

from kpi_modules.score_v1 import score_csv

root = toolkit.parent
result = score_csv(
    root / "wq_data.csv",
    root / "output" / "wq_scored.csv",
    # summary_path=..., write_summary=True by default
)
if not result["Success"]:
    raise RuntimeError(result["Message"])
print("Detail:", result["OutputPath"])
print("Summary:", result.get("SummaryPath"))
print("KpiTotals:", result.get("KpiTotals"))
```

### Selected `score_csv` result keys

| Property | Description |
|----------|-------------|
| `Success` | Operation succeeded |
| `OutputPath` | Claim-level scored CSV |
| `SummaryPath` | Vertical summary CSV (if written) |
| `RowCount` / `ColumnCount` | Detail file size |
| `QueueMode` | `healthy` or `chaos` (priority only) |
| `KpiTotals` | Portfolio RCM KPIs and checksums |
| `ScoreMin` / `ScoreMax` / `ScoreMean` | Priority batch stats |
| `Message` | Human status |

---

## CLI quick reference

Full detail: **[CLI-GUIDE.md](./CLI-GUIDE.md)**.

| Command | Purpose |
|---------|---------|
| `version` | Print toolkit version |
| `diagnostics` | Enterprise dry-run; writes `diagnostics\last_diagnostics.*` |
| `probe` | Optional path preflight (does **not** satisfy the gate) |
| `score` | Priority + `kpi_q_*` + summary CSV (gated) |
| `generate` | Synthetic WQ CSV (gated) |
| `validate-score` | Priority integrity, KPI Q checksums, optional golden (gated) |

| Exit code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | Validation / preflight |
| 2 | Runtime |

```bat
kpi-analytics.cmd score --csv data.csv --output ..\output\out.csv --summary ..\output\out_summary.csv
kpi-analytics.cmd score --csv data.csv --output ..\output\out.csv --no-summary
kpi-analytics.cmd score --csv data.csv --output ..\output\out.csv --privacy --json
kpi-analytics.cmd score --csv data.csv --output ..\output\out.csv --no-privacy --json
```

---

## Configuration highlights

Default: `kpi_modules\config_default.json`.

| Area | Keys (examples) |
|------|-----------------|
| Priority | `weights`, `chaos`, `point_of_interest`, `normalization`, `ar_day_target`, `as_of_date`, `fields` |
| RCM KPI Q | `kpi_quantifiers.adc`, `aged_day_breaks`, `credit_policy`, `emit_static_share`, `emit_exact_delta`, `dual_sign_columns` |
| Privacy (score output) | `privacy.enabled`, `privacy.patient.mode` (`prefix_token` / `omit` / `passthrough`), `privacy.patient.name_order`, `privacy.dob.mode` (`omit` / `passthrough`) |

**PHI masking (default on):** scored CSV writes patient as `DOE001,JOH001`-style tokens (3-letter prefixes + batch alpha-order index) and blanks DOB. This is **operational masking**, not a HIPAA Safe Harbor claim. Input files are never modified. Override per run with `score --privacy` or `score --no-privacy`. See [SCORE-METHODOLOGY.md](./SCORE-METHODOLOGY.md) · [CLI-GUIDE.md](./CLI-GUIDE.md).

---

## Validation and fixtures

| Fixture | Purpose |
|---------|---------|
| `fixtures\v1_handcalc_*` | Priority V1 + KPI Q regression |
| `fixtures\rcm_impact_*` | RCM methodology §6 numeric example (Δ AR>90, Days in AR) |

```bat
kpi-analytics.cmd validate-score --json
kpi-analytics.cmd validate-score --csv fixtures\rcm_impact_example.csv --config fixtures\rcm_impact_config.json --expected fixtures\rcm_impact_expected.json --json
```

---

## Enterprise notes (summary)

| Topic | Behavior |
|-------|----------|
| Elevation | Not required |
| Dependencies | Stdlib only — no pip |
| Network | Not used |
| Office | Not automated |
| Files | Default input under repo `import\`; default score outputs under `output\` |
| First-run gate | `diagnostics` certificate under `diagnostics\`; auto-run on operational commands |

Full write-up: **[ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md)**.

---

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| Python not found | Install CPython 3.13; ensure `py -3.13` or `python` on PATH |
| `No module named kpi_modules` | `cd` into `kpi-analytics\` or set `PYTHONPATH` |
| Diagnostics gate blocked | Open `diagnostics\last_diagnostics.txt`; fix FAIL lines; `diagnostics --force` |
| Cannot write diagnostics report | Ensure write access to `kpi-analytics\diagnostics\` (or temporary `--skip-diagnostics-gate`) |
| Days in AR looks off | Set `kpi_quantifiers.adc` to practice ADC; check `adc_source` in summary |
| All priority scores ≈ 0.5 | Single-row batch or flat metrics — norms collapse under minmax |
| File permission denied | Close the CSV in Excel and re-run |
| Want `.xlsx` | Use `excel-toolkit` on the scored or summary CSV |

---

## Out of scope

- Third-party Python packages  
- Excel COM automation (see `excel-toolkit\`)  
- Priority Matrix V2/V3  
- Network installs, elevation, or policy bypass  
