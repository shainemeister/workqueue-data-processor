"""Dynamic invariant: Excel COM bootstrap force-disables macros."""

from __future__ import annotations

import sys
from pathlib import Path

# Allow `from _common import ...` when launched as py path/to/script.py
sys.path.insert(0, str(Path(__file__).resolve().parent))
import re

from _common import fail_exit, pass_exit, repo_root

_ASSIGN_RE = re.compile(r"AutomationSecurity\s*=\s*3\b")


def main() -> None:
    path = repo_root() / "excel-toolkit" / "ExcelCom.psm1"
    if not path.is_file():
        fail_exit("ExcelCom.psm1 missing")

    text = path.read_text(encoding="utf-8", errors="replace")
    found = False
    for line in text.splitlines():
        stripped = line.strip()
        # Skip comment-only lines (PowerShell # and block comment interiors best-effort)
        if stripped.startswith("#"):
            continue
        if _ASSIGN_RE.search(line):
            found = True
            break

    if not found:
        fail_exit("AutomationSecurity = 3 not found on non-comment line")

    pass_exit("automation_security ok; AutomationSecurity=3 present")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        fail_exit(f"invariant_automation_security error: {type(exc).__name__}")
