"""Environment and path preflight checks (stdlib only)."""

from __future__ import annotations

import importlib
import sys
import tempfile
from pathlib import Path
from typing import Any

from . import __version__
from .config import DEFAULT_CONFIG_PATH, load_config
from .io_csv import read_csv_rows

_STDLIB_SMOKE = ("csv", "json", "argparse", "statistics")


def _check(name: str, passed: bool, detail: str) -> dict[str, Any]:
    """Build one probe check result dict."""
    return {"Name": name, "Passed": passed, "Detail": detail}


def run_probe(
    *,
    csv_path: str | Path | None = None,
    config_path: str | Path | None = None,
    schema_path: str | Path | None = None,
) -> dict[str, Any]:
    """Run readiness checks; Success is True only if all pass."""
    checks: list[dict[str, Any]] = []

    # Python version
    ver = sys.version_info
    py_ok = ver.major == 3 and ver.minor >= 13
    checks.append(
        _check(
            "PythonVersion",
            py_ok,
            f"{ver.major}.{ver.minor}.{ver.micro} (target: 3.13+ stdlib)",
        )
    )

    # Stdlib import smoke
    try:
        for mod_name in _STDLIB_SMOKE:
            importlib.import_module(mod_name)
        checks.append(
            _check("StdlibImports", True, ", ".join(_STDLIB_SMOKE))
        )
    except Exception as exc:  # pragma: no cover
        checks.append(_check("StdlibImports", False, str(exc)))

    # Temp writable
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".txt", delete=True, encoding="utf-8"
        ) as tf:
            tf.write("ok")
            checks.append(_check("TempWritable", True, tf.name))
    except Exception as exc:
        checks.append(_check("TempWritable", False, str(exc)))

    # Default config loads
    try:
        load_config(None)
        checks.append(
            _check(
                "DefaultConfig",
                True,
                str(DEFAULT_CONFIG_PATH.resolve()),
            )
        )
    except Exception as exc:
        checks.append(_check("DefaultConfig", False, str(exc)))

    # Optional config path
    if config_path:
        cp = Path(config_path)
        if not cp.is_file():
            checks.append(_check("ConfigPath", False, f"Not found: {cp}"))
        else:
            try:
                load_config(cp)
                checks.append(_check("ConfigPath", True, str(cp.resolve())))
            except Exception as exc:
                checks.append(_check("ConfigPath", False, str(exc)))

    # Optional CSV
    if csv_path:
        p = Path(csv_path)
        if not p.is_file():
            checks.append(_check("CsvPath", False, f"Not found: {p}"))
        else:
            try:
                fields, rows = read_csv_rows(p)
                checks.append(
                    _check(
                        "CsvPath",
                        True,
                        f"{p.resolve()} ({len(rows)} rows, {len(fields)} columns)",
                    )
                )
            except Exception as exc:
                checks.append(_check("CsvPath", False, str(exc)))

    # Optional schema (existence only — not required for scoring v1)
    if schema_path:
        sp = Path(schema_path)
        checks.append(
            _check(
                "SchemaPath",
                sp.is_file(),
                str(sp.resolve()) if sp.is_file() else f"Not found: {sp}",
            )
        )

    # Package importable
    try:
        importlib.import_module("kpi_modules")
        checks.append(
            _check("PackageImport", True, f"kpi_modules {__version__}")
        )
    except Exception as exc:
        checks.append(_check("PackageImport", False, str(exc)))

    all_pass = all(c["Passed"] for c in checks)
    return {
        "Success": all_pass,
        "Command": "probe",
        "Version": __version__,
        "Message": "Preflight passed." if all_pass else "Preflight failed.",
        "Checks": checks,
    }
