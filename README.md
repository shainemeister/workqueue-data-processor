# Work Queue Data Processor

Local tools for professional-billing **Work Queue (WQ)** extracts: rank denial and follow-up items with an explainable priority score, attach RCM claim-level impact measures, and optionally export results to Excel.

Runs offline on Windows under your user account. Scoring uses Python 3.13 standard library only (no pip packages). Excel export uses PowerShell and desktop Excel. No elevation and no cloud install.

## Summary

A WQ export is typically a wide CSV of open denials and follow-ups. This repository helps process that file locally in two steps:

1. **Score** each row for work priority and for how the claim contributes to common RCM portfolio measures (for example total AR and aging buckets), with intermediate columns kept so the result can be checked.
2. **Export** the scored (or any) CSV to a formatted Excel workbook when you need a spreadsheet for review or distribution.

Implementation is a **shared column contract** (schema + sample rows) plus **two toolkits** that do not share a process; they exchange CSV (and Excel) files only:

| Toolkit | Role | Runtime |
|---------|------|---------|
| **[kpi-analytics](./kpi-analytics/)** | Priority scores (`v1_*`), RCM claim-impact columns (`kpi_q_*`), synthetic demo data, validation, first-run diagnostics | Python **3.13** stdlib only |
| **[excel-toolkit](./excel-toolkit/)** | CSV → formatted `.xlsx` (and Excel → CSV), menu and CLI, first-run diagnostics | PowerShell **5.1** + desktop Excel |

Usual path: **CSV in → score (optional summary CSV) → Excel out.** A single menu option runs that pipeline; each toolkit can also be used alone.

| You want to… | Start here |
|--------------|------------|
| Score and open Excel in one step | Double-click `Start-ExcelMenu.cmd` → option **1** |
| Rank WQ work by priority only | [kpi-analytics](./kpi-analytics/README.md) · `score` |
| Put an existing CSV into Excel | [excel-toolkit](./excel-toolkit/README.md) |
| See what a claim row looks like | [wq_data.csv](./wq_data.csv) · [wq_schema.json](./wq_schema.json) |

**Privacy:** samples and synthetic files in this repo are for demo and testing. Do **not** commit real patient or production extracts.

---

## Use cases

| Use case | What you get | Start here |
|----------|--------------|------------|
| **Prioritize denial / follow-up work** | Scored CSV with `v1_priority_score` and clear audit columns | [kpi-analytics](./kpi-analytics/README.md) · `score` |
| **Measure RCM claim impact** | Portfolio KPIs plus per-claim static share and resolution impact (`kpi_q_*`) | `score` · [methodology](./kpi-analytics/SCORE-METHODOLOGY.md) |
| **Demo or test without real PHI** | Synthetic professional-billing WQ CSV (de-identified names) | `generate` · [KPI CLI guide](./kpi-analytics/CLI-GUIDE.md) |
| **Share results with leadership** | Formatted `.xlsx` from a scored or summary CSV | [excel-toolkit](./excel-toolkit/README.md) |
| **Score and Excel in one menu step** | Scored + summary workbooks under `output\` | `Start-ExcelMenu.cmd` → option **1** |
| **First run on a locked-down PC** | Pass/fail environment certificates for IT | KPI or Excel `diagnostics` · [KPI security](./kpi-analytics/ENTERPRISE-SECURITY.md) · [Excel security](./excel-toolkit/ENTERPRISE-SECURITY.md) |
| **Understand the data layout** | Field definitions and sample fact rows | [wq_schema.json](./wq_schema.json) · [wq_data.csv](./wq_data.csv) |

---

## What’s included

| Area | Path | Role |
|------|------|------|
| KPI / priority scoring | `kpi-analytics\` | Score, generate, validate, first-run diagnostics |
| Excel export / import | `excel-toolkit\` | Menu, CLI, and Excel COM automation |
| Data contract | `wq_schema.json`, `wq_schema.csv` | Column names, types, display labels |
| Sample data | `wq_data.csv` | Example WQ rows (headers match schema `field_name`) |
| Demo inputs | `import\` | Tracked synthetic (or other non-PHI) inputs you choose to keep |
| Run outputs | `output\` | Scored CSVs and Excel files (regenerable; not versioned) |
| Design (optional) | `WQ_Priority_Matrix_Concept.md` | Priority matrix roadmap (V1–V3); **V1 is implemented** |

---

## Prerequisites

| For | Requirement |
|-----|-------------|
| **kpi-analytics** | Python **3.13.x** on PATH (`py -3.13` or `python`). **No pip packages.** |
| **excel-toolkit** | Windows PowerShell **5.1** and desktop **Microsoft Excel**. |
| **Your data** | A CSV with a header row; column names should match the schema when using defaults. |

IT / controlled-PC notes: [kpi-analytics security](./kpi-analytics/ENTERPRISE-SECURITY.md) · [excel-toolkit security](./excel-toolkit/ENTERPRISE-SECURITY.md)

---

## Quick start

### Easiest path (score + Excel)

1. Put a WQ CSV under `import\` (or use the included synthetic file).  
2. Double-click **`Start-ExcelMenu.cmd`**.  
3. Choose **1) Score CSV → Excel (KPI pipeline)** and pick the file.

You get scored and summary CSVs plus both workbooks under `output\`. If a file name already exists, a free `name_N` suffix is used. Needs **Python 3.13** and **Excel**. On first use, each toolkit may run a one-time **diagnostics** check and write a local pass report for IT.

### Manual path (command line)

From the repository root: **diagnostics → score → export**.

```bat
cd kpi-analytics
kpi-analytics.cmd diagnostics
kpi-analytics.cmd score --output ..\output\wq_scored.csv

cd ..\excel-toolkit
excel-toolkit.cmd diagnostics
excel-toolkit.cmd export-csv -CsvPath ..\output\wq_scored.csv -OutputPath ..\output\wq_scored.xlsx
```

Optional: refresh demo input under `import\`:

```bat
cd kpi-analytics
kpi-analytics.cmd generate --rows 250 --seed 42
```

- Score your own extract: `score --csv path\to\file.csv` (see the [KPI CLI guide](./kpi-analytics/CLI-GUIDE.md)).  
- Interactive Excel only: `Start-ExcelMenu.cmd` or `excel-toolkit\Start-ExcelMenu.cmd`.

---

## Your data

| File | Purpose |
|------|---------|
| [wq_schema.json](./wq_schema.json) | Canonical field list: `field_name`, original WQ label, type, nullability |
| [wq_schema.csv](./wq_schema.csv) | Same schema in CSV form |
| [wq_data.csv](./wq_data.csv) | Sample records—one row per WQ item; first row is `field_name` headers |

The **schema** describes columns; the **data file** holds rows. Types are `str`, `int`, and `float`; empty cells mean missing values. When you bring in a new extract, keep headers aligned with `field_name`.

---

## Where to go next

| Need | Document |
|------|----------|
| KPI overview and day-to-day workflow | [kpi-analytics/README.md](./kpi-analytics/README.md) |
| KPI commands and automation | [kpi-analytics/CLI-GUIDE.md](./kpi-analytics/CLI-GUIDE.md) |
| Priority and KPI Q formulas | [kpi-analytics/SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md) |
| RCM dual-attribution theory | [kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md](./kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md) |
| Excel overview and menu | [excel-toolkit/README.md](./excel-toolkit/README.md) |
| Excel CLI and first-run diagnostics | [excel-toolkit/CLI-GUIDE.md](./excel-toolkit/CLI-GUIDE.md) |

---

## For maintainers

Policy and inventory (not required for day-to-day scoring or export):

| Document | Purpose |
|----------|---------|
| [RULES.md](./RULES.md) | How we maintain docs, boundaries, git, and verification |
| [FILE-CATALOG.md](./FILE-CATALOG.md) | Purpose of every intentional source file |
| [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) | How we structure documentation |
| [templates/](./templates/) | Skeletons for toolkit README, CLI, methodology, security |
