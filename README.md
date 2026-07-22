# Work Queue Data Files

This directory contains a simple two-file format for Work Queue (WQ) denial / follow-up records, plus two local toolkits for Excel export and KPI scoring.

## Documentation standard

For consistent, professional markdown across this repository (any toolkit or design doc), use:

| Path | Purpose |
|------|---------|
| [`MARKDOWN-STANDARD.md`](./MARKDOWN-STANDARD.md) | Canonical formatting standard, content order, frontmatter, checklist |
| [`RULES.md`](./RULES.md) | Repository maintenance rules (docs, git, boundaries, verification) |
| [`FILE-CATALOG.md`](./FILE-CATALOG.md) | Concise purpose inventory of every intentional source file |
| [`templates/`](./templates/) | Copy-paste skeletons (README, CLI, methodology, security, concept, generic) |

## Toolkits

| Path | Purpose | Runtime |
|------|---------|---------|
| **`excel-toolkit\`** | CSV → formatted Excel (menu, module, CLI) | Windows PowerShell 5.1 + Excel COM |
| **`kpi-analytics\`** | CSV → scored / KPI CSV (Priority Matrix V1) | Python **3.13** stdlib only |

| Path | Purpose |
|------|---------|
| `excel-toolkit\README.md` | Excel toolkit overview |
| `excel-toolkit\CLI-GUIDE.md` | Excel CLI syntax and examples |
| `excel-toolkit\ENTERPRISE-SECURITY.md` | Excel toolkit enterprise / execution notes |
| `excel-toolkit\Start-ExcelMenu.cmd` | Interactive Excel menu |
| `excel-toolkit\excel-toolkit.cmd` | Excel CLI shim |
| `kpi-analytics\README.md` | KPI analytics overview |
| `kpi-analytics\CLI-GUIDE.md` | KPI CLI syntax and examples |
| `kpi-analytics\ENTERPRISE-SECURITY.md` | KPI analytics enterprise / execution notes |
| `kpi-analytics\SCORE-METHODOLOGY.md` | Priority + KPI Q implementation methodology |
| `kpi-analytics\RCM_KPI_Claim_Impact_Methodology.md` | RCM dual-attribution theory |
| `kpi-analytics\kpi-analytics.cmd` | KPI CLI shim |
| `kpi-analytics\kpi_modules\` | Python package (`score`, `generate`, …) |
| `MARKDOWN-STANDARD.md` | Repo-wide markdown documentation standard |
| `templates\` | Markdown document templates |
| `excel-toolkit\sample-test\` | Tiny check: can `.cmd` / `.ps1` / `.psm1` execute on this PC? |

Root launcher: `Start-ExcelMenu.cmd` → `excel-toolkit\Start-ExcelMenu.cmd`.

Typical synthetic → score → workbook flow:

```bat
cd kpi-analytics
kpi-analytics.cmd generate --rows 100 --output ..\output\wq_data_synthetic.csv
kpi-analytics.cmd score --csv ..\output\wq_data_synthetic.csv --output ..\output\wq_scored.csv
cd ..\excel-toolkit
excel-toolkit.cmd export-csv -CsvPath ..\output\wq_scored.csv -OutputPath ..\output\wq_scored.xlsx
```

## Files

| File | Purpose | Format |
|------|---------|--------|
| `wq_schema.json` | Field definitions, data types, and original display names | JSON |
| `wq_schema.csv` | Same schema as CSV (display names) | CSV |
| `wq_data.csv` | Actual record data (one row per WQ item) | CSV |
| `WQ_Priority_Matrix_Concept.md` | Priority scoring design (V1–V3 concept) | Markdown |

## How the files work together

- **`wq_schema.json`** describes every column: the clean database-style name (`field_name`), the original label from the source system (`wq_field_name`), the expected data type, and whether the field can be empty.
- **`wq_data.csv`** holds the bulk data. The first row contains the `field_name` values as column headers. Each subsequent row is one WQ record.

This separation keeps the schema easy to read and version while allowing the data file to stay compact and efficient for large volumes (tens of thousands of rows).

## Data types used in the schema

- `str` – text values
- `int` – whole numbers
- `float` – decimal numbers
- Empty cells in the CSV are treated as null / missing values

## Notes

- The CSV is designed to be streamed row-by-row with Python’s built-in `csv` module.
- The JSON schema is intended to be loaded once and used for type conversion, validation, or display mapping.
- **kpi-analytics** requires only the Python 3.13 standard library (`csv`, `json`, `argparse`, etc.)—no pip packages.
- **excel-toolkit** requires Windows PowerShell 5.1 and desktop Excel for COM export.
