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
| Score and open Excel in one step | Double-click `Start-ExcelMenu.cmd` → **Process my data** → Full pipeline |
| Rank WQ work by priority only | [kpi-analytics](./kpi-analytics/README.md) · `score` |
| Put an existing CSV into Excel | [excel-toolkit](./excel-toolkit/README.md) |
| See what a claim row looks like | [wq_data.csv](./wq_schema/wq_data.csv) · [wq_schema.json](./wq_schema/wq_schema.json) |

**Privacy:** samples and synthetic files in this repo are for demo and testing. Do **not** commit real patient or production extracts.

---

## Use cases

| Use case | What you get | Start here |
|----------|--------------|------------|
| **Prioritize denial / follow-up work** | Scored CSV with `v1_priority_score` and clear audit columns | [kpi-analytics](./kpi-analytics/README.md) · `score` |
| **Emphasize a focus (cash / write-offs / stall)** | Same score path with POI focus preset (`--profile`), also selectable from the Excel menu | [KPI CLI — profiles](./kpi-analytics/CLI-GUIDE.md#scoring-profiles-260) · [Excel menu](./excel-toolkit/README.md#for-most-users-recommended) |
| **Measure RCM claim impact** | Portfolio KPIs plus per-claim static share and resolution impact (`kpi_q_*`) | `score` · [methodology](./kpi-analytics/SCORE-METHODOLOGY.md) |
| **Demo or test without real PHI** | Synthetic professional-billing WQ CSV (de-identified names) | `generate` · [KPI CLI guide](./kpi-analytics/CLI-GUIDE.md) |
| **Share results with leadership** | Formatted `.xlsx` from a scored or summary CSV | [excel-toolkit](./excel-toolkit/README.md) |
| **Score and Excel in one menu step** | Scored + summary workbooks under `output\` | `Start-ExcelMenu.cmd` → **Process my data** → Full pipeline |
| **Score only (no Excel)** | Scored + summary CSV under `output\` | `Start-ExcelMenu.cmd` → **Process my data** → Score only |
| **Grouped follow-up worklist** | Scored workbook with Groups + two-level Worklist sheets | `Start-ExcelMenu.cmd` → **Process my data** → Build worklist |
| **Several files, named Excel** | Per-file preview (2+ files); Excel named `[WQ]_MM-DD-YYYY.xlsx` plus Totals sheet | `Start-ExcelMenu.cmd` → **Process my data** |
| **First run on a locked-down PC** | Pass/fail environment certificates for IT | KPI or Excel `diagnostics` · [KPI security](./kpi-analytics/ENTERPRISE-SECURITY.md) · [Excel security](./excel-toolkit/ENTERPRISE-SECURITY.md) |
| **Understand the data layout** | Field definitions and sample fact rows | [wq_schema.json](./wq_schema/wq_schema.json) · [wq_data.csv](./wq_schema/wq_data.csv) |

---

## What’s included

| Area | Path | Role |
|------|------|------|
| KPI / priority scoring | `kpi-analytics\` | Score, generate, validate, first-run diagnostics |
| Excel export / import | `excel-toolkit\` | Menu, CLI, and Excel COM automation |
| Data contract | `wq_schema/wq_schema.json`, `wq_schema/wq_schema.csv` | Column names, types, display labels |
| Sample data | `wq_schema/wq_data.csv` | Example WQ rows (headers match schema `field_name`) |
| Demo inputs | `import\` | Tracked synthetic (or other non-PHI) inputs you choose to keep |
| Run outputs | `output\` | Scored CSVs and Excel files (regenerable; not versioned) |
| Design (optional) | `docs\WQ_Priority_Matrix_Concept.md` | Priority matrix roadmap (V1–V3); **V1 is implemented** |

---

## Prerequisites

| For | Requirement |
|-----|-------------|
| **kpi-analytics** | Python **3.13.x** on PATH (`py -3.13` or `python`). **No pip packages.** |
| **excel-toolkit** | Windows PowerShell **5.1** and desktop **Microsoft Excel**. |
| **Your data** | A CSV with a header row. Prefer schema `field_name` headers; otherwise use aliases, `score --mapping`, or `score --interactive-mapping` (kpi-analytics 2.1.0+). |

IT / controlled-PC notes: [kpi-analytics security](./kpi-analytics/ENTERPRISE-SECURITY.md) · [excel-toolkit security](./excel-toolkit/ENTERPRISE-SECURITY.md)

---

## Quick start

### Easiest path (score + Excel)

1. Put a WQ CSV (or Excel extract) under `import\` (or use the included synthetic file).  
2. Double-click **`Start-ExcelMenu.cmd`**.  
3. Choose **1) Process my data**, pick the file(s) (`1`, `1-3`, or `1,3-5`), then **Full pipeline**.

You get scored and summary CSVs plus both workbooks under `output\`. If a file name already exists, a free `name_N` suffix is used. You can optionally protect Excel output with a workbook open password. Needs **Python 3.13** and **Excel**. On first use, each toolkit may run a one-time **diagnostics** check and write a local pass report for IT.

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
| [wq_schema.json](./wq_schema/wq_schema.json) | Canonical field list: `field_name`, original WQ label, type, nullability |
| [wq_schema.csv](./wq_schema/wq_schema.csv) | Same schema in CSV form |
| [wq_data.csv](./wq_schema/wq_data.csv) | Sample records—one row per WQ item; first row is `field_name` headers |

The **schema** describes columns; the **data file** holds rows. Types are `str`, `int`, and `float`; empty cells mean missing values. Prefer headers aligned with `field_name`. For extracts with different labels, scoring can auto-detect common synonyms, use an optional mapping profile (`score --mapping path.json`), or walk through guided mapping on a TTY (`score --interactive-mapping`).

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
| [kit/RULES.md](./kit/RULES.md) | Maintenance policy hub; **kit baseline** (adopted repo-kit version lives only there); Operator enforcement; domain modules under `kit/rules/` |
| [kit/UPGRADE.md](./kit/UPGRADE.md) | Durable repo-kit upgrade / 1.x→2.x migration guide |
| [PLAN.md](./PLAN.md) | Project control surface: mission, stages, **Agent models** (Agent Instruct) |
| [docs/WORKBOARD.md](./docs/WORKBOARD.md) | Live multi-phase execution (open / next / SHA) |
| [kit/agents/](./kit/agents/) | Agent Instruct (OPS, BUILD, generated packs) — views over L4 law |
| [CHANGELOG.md](./CHANGELOG.md) | Project history (Keep a Changelog); kit upgrades get a short note only—not kit release history |
| [docs/PLAN.md](./docs/PLAN.md) | Post-V1 product enhancement backlog (Clusters 1–3) |
| [docs/plan/](./docs/plan/) | Execution / design-freeze plans (Cluster 2–3, B1.1, kit upgrade) |
| [docs/README.md](./docs/README.md) | AI docs workspace index (`research/`, `plan/`, `project_build/`, `resources/`, workboard) |
| [LICENSE](./LICENSE) | MIT license |
| [docs/FILE-CATALOG.md](./docs/FILE-CATALOG.md) | Purpose of every intentional source file |
| [kit/MARKDOWN-STANDARD.md](./kit/MARKDOWN-STANDARD.md) | How we structure documentation |
| [certification/](./certification/) | Formal security + code-validation self-attestation (full harness after code changes; developer-only; not product diagnostics) |
| [kit/templates/](./kit/templates/) | Skeletons for toolkit README, CLI, methodology, security, certification README |
| [repo-kit](https://github.com/shainemeister/repo-kit) | Upstream standards kit — compare latest to [Kit baseline](./kit/RULES.md#kit-baseline) before upgrading |
