"""Shared helpers for certification python-assert scripts (stdlib only)."""

from __future__ import annotations

import sys
from pathlib import Path


def repo_root() -> Path:
    """certification/scripts/<this> -> repository root."""
    return Path(__file__).resolve().parents[2]


def ensure_kpi_on_path() -> Path:
    """Insert kpi-analytics on sys.path; return that directory."""
    root = repo_root()
    kpi = root / "kpi-analytics"
    kpi_s = str(kpi)
    if kpi_s not in sys.path:
        sys.path.insert(0, kpi_s)
    return kpi


def pass_exit(message: str) -> None:
    print(message)
    raise SystemExit(0)


def fail_exit(message: str) -> None:
    """Fail without embedding PHI or secrets in the message."""
    print(f"FAIL: {message}")
    raise SystemExit(1)
