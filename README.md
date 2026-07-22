# Work Queue Data Processor

Local tools and a simple CSV data contract for **Work Queue (WQ)** denial and follow-up work: priority ranking, RCM claim-impact measures, and Excel export—all offline on your PC.

## Summary

This repository gives you two independent toolkits that work together through files (not a shared process):

| Toolkit | What it does | You need |
|---------|----------------|----------|
| **[kpi-analytics](./kpi-analytics/)** | Score claims (`v1_*` priority + `kpi_q_*` RCM impacts), generate test data, validate results | Python **3.13** standard library only |
| **[excel-toolkit](./excel-toolkit/)** | Turn a CSV into a formatted Excel workbook | Windows PowerShell **5.1** + desktop Excel |

Data is defined by a small contract: [wq_schema.json](./wq_schema.json) describes columns; [wq_data.csv](./wq_data.csv) holds sample rows. Everything runs as your user account—no cloud install, no pip packages for scoring, no elevation.

| You want to… | Start here |
|--------------|------------|
| Rank WQ work by priority | [kpi-analytics](./kpi-analytics/README.md) · `score` |
| Put results in Excel | [excel-toolkit](./excel-toolkit/README.md) |
| See what a claim row looks like | [wq_data.csv](./wq_data.csv) · [wq_schema.json](./wq_schema.json) |

## Use cases

| Use case | What you get | Start here |
|----------|--------------|------------|
| **Prioritize denial / follow-up work** | Scored CSV with explainable `v1_priority_score` and audit columns | [kpi-analytics](./kpi-analytics/README.md) · `score` |
| **Measure RCM claim impact** | Portfolio KPIs plus per-claim static share and resolution impact (`kpi_q_*`) | `score` · [SCORE-METHODOLOGY](./kpi-analytics/SCORE-METHODOLOGY.md) |
| **Demo or test without real PHI** | Synthetic professional-billing WQ CSV (de-identified names) | `generate` · [CLI guide](./kpi-analytics/CLI-GUIDE.md) |
| **Share results with leadership** | Formatted `.xlsx` from a scored or summary CSV | [excel-toolkit](./excel-toolkit/README.md) |
| **First run on a locked-down PC** | Pass/fail environment certificate for IT | `diagnostics` · [KPI security](./kpi-analytics/ENTERPRISE-SECURITY.md) |
| **Understand or extend the data layout** | Field definitions and sample fact rows | [wq_schema.json](./wq_schema.json) · [wq_data.csv](./wq_data.csv) |

## What’s included

| Area | Path | Role |
|------|------|------|
| KPI / priority scoring | `kpi-analytics\` | Score, generate, validate, enterprise diagnostics |
| Excel export | `excel-toolkit\` | Menu, module, and CLI export via Excel COM |
| Data contract | `wq_schema.json`, `wq_schema.csv` | Field names, types, display labels |
| Sample data | `wq_data.csv` | Example WQ rows (headers match schema `field_name`) |
| Design (optional reading) | `WQ_Priority_Matrix_Concept.md` | Priority matrix roadmap (V1–V3); V1 is implemented |

Outputs from runs typically go under `output\` (regenerable; not the source of truth).

## Prerequisites

| For | Requirement |
|-----|-------------|
| **kpi-analytics** | Python **3.13.x** on PATH (`py -3.13` or `python`). **No pip packages.** |
| **excel-toolkit** | Windows PowerShell **5.1** and desktop **Microsoft Excel** (COM). |
| **Data** | A CSV with a header row; column names should match the schema when using defaults. |

Enterprise / IT notes: [kpi-analytics/ENTERPRISE-SECURITY.md](./kpi-analytics/ENTERPRISE-SECURITY.md) · [excel-toolkit/ENTERPRISE-SECURITY.md](./excel-toolkit/ENTERPRISE-SECURITY.md)

## Quick start

From the repository root, a common flow is: **generate test data → score → export to Excel**.

```bat
cd kpi-analytics
kpi-analytics.cmd diagnostics
kpi-analytics.cmd generate --rows 100 --output ..\output\wq_data_synthetic.csv
kpi-analytics.cmd score --csv ..\output\wq_data_synthetic.csv --output ..\output\wq_scored.csv

cd ..\excel-toolkit
excel-toolkit.cmd export-csv -CsvPath ..\output\wq_scored.csv -OutputPath ..\output\wq_scored.xlsx
```

- Interactive Excel menu: `Start-ExcelMenu.cmd` (root) or `excel-toolkit\Start-ExcelMenu.cmd`
- Score your own extract: point `--csv` at your file (see [kpi-analytics CLI guide](./kpi-analytics/CLI-GUIDE.md))

## Your data

| File | Purpose |
|------|---------|
| [wq_schema.json](./wq_schema.json) | Canonical field list: `field_name`, original WQ label, type, nullability |
| [wq_schema.csv](./wq_schema.csv) | Same schema in CSV form |
| [wq_data.csv](./wq_data.csv) | Sample records—one row per WQ item; first row is `field_name` headers |

**How they work together:** the schema describes columns; the data file holds rows. Types are `str`, `int`, and `float`; empty cells mean missing values. Keep headers aligned with `field_name` when you bring in new extracts.

## Where to go next

| Need | Document |
|------|----------|
| KPI overview and workflow | [kpi-analytics/README.md](./kpi-analytics/README.md) |
| KPI commands and automation | [kpi-analytics/CLI-GUIDE.md](./kpi-analytics/CLI-GUIDE.md) |
| Priority and KPI Q formulas | [kpi-analytics/SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md) |
| RCM dual-attribution theory | [kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md](./kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md) |
| Excel overview | [excel-toolkit/README.md](./excel-toolkit/README.md) |
| Excel CLI | [excel-toolkit/CLI-GUIDE.md](./excel-toolkit/CLI-GUIDE.md) |

## For maintainers

| Document | Purpose |
|----------|---------|
| [RULES.md](./RULES.md) | Maintenance policy: docs, boundaries, git, verification, pylint |
| [FILE-CATALOG.md](./FILE-CATALOG.md) | Purpose of every intentional source file |
| [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) | How we structure docs (including this landing style) |
| [templates/](./templates/) | Skeletons for toolkit README, CLI, methodology, security, and more |
