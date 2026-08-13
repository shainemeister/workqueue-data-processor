#requires Python 3.13 stdlib only
"""Post-score detail-row sort (Cluster 3.2). Does not change V1 or kpi_q math."""

from __future__ import annotations

from typing import Any

SORT_PRESETS: dict[str, str] = {
    "priority": "v1_priority_score:desc,out_ins_amt:desc",
    "deadline": "days_until_appeal_deadline:asc,v1_priority_score:desc",
    "cash": "out_ins_amt:desc,v1_priority_score:desc",
}


def parse_sort_spec(spec: str) -> list[tuple[str, bool]]:
    """Parse ``col[:asc|:desc],...`` into ``(column, descending)`` pairs."""
    text = (spec or "").strip()
    if not text:
        raise ValueError("sort spec is empty")
    parsed: list[tuple[str, bool]] = []
    for raw in text.split(","):
        piece = raw.strip()
        if not piece:
            raise ValueError("sort spec has an empty key")
        if ":" in piece:
            name, direc = piece.rsplit(":", 1)
            name = name.strip()
            direc = direc.strip().lower()
            if not name:
                raise ValueError("sort spec has an empty column name")
            if direc not in ("asc", "desc"):
                raise ValueError(
                    f"sort direction must be asc or desc, got {direc!r}"
                )
            parsed.append((name, direc == "desc"))
        else:
            parsed.append((piece, False))
    return parsed


def resolve_sort_spec(
    *,
    sort_spec: str | None = None,
    sort_preset: str | None = None,
) -> tuple[str | None, str | None, list[tuple[str, bool]]]:
    """Resolve CLI sort inputs. Empty inputs mean keep input order."""
    spec_raw = (sort_spec or "").strip() or None
    preset_raw = (sort_preset or "").strip() or None
    if spec_raw and preset_raw:
        raise ValueError("--sort and --sort-preset are mutually exclusive")
    if preset_raw:
        key = preset_raw.lower()
        if key not in SORT_PRESETS:
            known = ", ".join(sorted(SORT_PRESETS))
            raise ValueError(
                f"unknown sort preset {preset_raw!r}; expected one of: {known}"
            )
        spec_raw = SORT_PRESETS[key]
        return spec_raw, key, parse_sort_spec(spec_raw)
    if spec_raw:
        return spec_raw, None, parse_sort_spec(spec_raw)
    return None, None, []


def _cell_key(value: Any, *, descending: bool) -> tuple[int, float, tuple[int, ...]]:
    text = "" if value is None else str(value).strip()
    if not text:
        return (1, 0.0, ())
    try:
        number = float(text)
        return (0, -number if descending else number, ())
    except ValueError:
        folded = text.casefold()
        ords = tuple(ord(ch) for ch in folded)
        if descending:
            ords = tuple(-code for code in ords)
        return (0, 0.0, ords)


def apply_output_sort(
    rows: list[dict[str, Any]],
    specs: list[tuple[str, bool]],
    fieldnames: list[str],
) -> list[dict[str, Any]]:
    """Return a new list sorted by specs; original input index is the last key."""
    if not specs:
        return list(rows)
    missing = [name for name, _desc in specs if name not in fieldnames]
    if missing:
        raise ValueError(
            "sort column(s) not in scored output: " + ", ".join(missing)
        )

    def row_key(item: tuple[int, dict[str, Any]]) -> tuple[Any, ...]:
        index, row = item
        parts: list[Any] = [
            _cell_key(row.get(name), descending=desc) for name, desc in specs
        ]
        parts.append((0, float(index), ()))
        return tuple(parts)

    indexed = list(enumerate(rows))
    indexed.sort(key=row_key)
    return [row for _index, row in indexed]


def sort_applied_payload(
    specs: list[tuple[str, bool]],
) -> list[dict[str, str]]:
    """JSON-friendly list of applied keys."""
    return [
        {"Column": name, "Direction": "desc" if desc else "asc"}
        for name, desc in specs
    ]
