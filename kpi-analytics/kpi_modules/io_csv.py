"""CSV read/write helpers (stdlib csv only)."""

from __future__ import annotations

import csv
from pathlib import Path
from typing import Any


def read_csv_rows(path: str | Path) -> tuple[list[str], list[dict[str, str]]]:
    """Return (fieldnames, rows) from a CSV with a header row."""
    p = Path(path)
    if not p.is_file():
        raise FileNotFoundError(f"CSV not found: {p}")

    with p.open("r", encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh)
        if reader.fieldnames is None:
            raise ValueError(f"CSV has no header row: {p}")
        fieldnames = list(reader.fieldnames)
        rows: list[dict[str, str]] = []
        for row in reader:
            # Normalize None values from DictReader to empty string
            cleaned = {
                k: ("" if v is None else str(v)) for k, v in row.items() if k is not None
            }
            rows.append(cleaned)
    return fieldnames, rows


def write_csv_rows(
    path: str | Path,
    fieldnames: list[str],
    rows: list[dict[str, Any]],
) -> int:
    """Write rows to CSV; create parent directories as needed. Returns row count."""
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    with p.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            out = {}
            for key in fieldnames:
                val = row.get(key, "")
                if val is None:
                    out[key] = ""
                else:
                    out[key] = val
            writer.writerow(out)
    return len(rows)
