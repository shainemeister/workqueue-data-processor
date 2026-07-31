"""Dynamic invariant: Excel toolkit JSON exposes PasswordUsed boolean only.

Source-level contract (no Excel, no password values).
"""

from __future__ import annotations

import sys
from pathlib import Path

# Allow `from _common import ...` when launched as py path/to/script.py
sys.path.insert(0, str(Path(__file__).resolve().parent))
import re

from _common import fail_exit, pass_exit, repo_root

# Property that serializes a secret into JSON payloads (forbidden).
_BAD_PASSWORD_PROP = re.compile(
    r"""Password\s*=\s*\$?(Password|PlainPassword|plainPassword|securePassword)\b""",
    re.IGNORECASE,
)

# Must appear for import JSON path
_PASSWORD_USED_BOOL = re.compile(
    r"PasswordUsed\s*=\s*\[bool\]",
    re.IGNORECASE,
)


def _scan_file(path_label: str, text: str, issues: list[str]) -> None:
    for i, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        # Allow SecureString parameter declarations and PasswordUsed boolean
        if re.search(r"\[SecureString\]\s*\$Password\b", line):
            continue
        if re.search(r"PasswordUsed\s*=", line, re.IGNORECASE):
            continue
        if re.search(r"\.PARAMETER\s+Password\b", line, re.IGNORECASE):
            continue
        if re.search(r"param\s*\(.*Password", line, re.IGNORECASE):
            continue
        # Hashtable / object property assigning the secret value
        if re.search(
            r"""['\"]Password['\"]\s*=\s*\$?(Password|PlainPassword|plainPassword)\b""",
            line,
            re.IGNORECASE,
        ):
            issues.append(f"{path_label}:{i}:secret_prop")
            continue
        # pscustomobject Password = $Password (not PasswordUsed)
        if re.search(
            r"(?<![A-Za-z])Password\s*=\s*\$Password\b",
            line,
        ) and "PasswordUsed" not in line:
            # Allow openParams['Password'] = $securePwd style COM open (not JSON)
            if "openParams" in line or "saveParams" in line or "exportParams" in line or "importParams" in line:
                continue
            if "ConvertTo-Json" in line:
                issues.append(f"{path_label}:{i}:password_in_json_line")
                continue
            # Result object assignment Password = is forbidden
            if "$result" in line or "payload" in line.lower():
                issues.append(f"{path_label}:{i}:password_on_result")


def main() -> None:
    root = repo_root()
    cli = root / "excel-toolkit" / "ExcelToolkit.ps1"
    mod = root / "excel-toolkit" / "ExcelToolkit.psm1"
    issues: list[str] = []

    if not cli.is_file() or not mod.is_file():
        fail_exit("ExcelToolkit.ps1 or ExcelToolkit.psm1 missing")

    cli_text = cli.read_text(encoding="utf-8", errors="replace")
    mod_text = mod.read_text(encoding="utf-8", errors="replace")

    if not _PASSWORD_USED_BOOL.search(cli_text):
        fail_exit("CLI missing PasswordUsed = [bool] pattern")

    if "PasswordUsed" not in mod_text:
        fail_exit("module missing PasswordUsed field")

    _scan_file("ExcelToolkit.ps1", cli_text, issues)
    _scan_file("ExcelToolkit.psm1", mod_text, issues)

    # Explicit: JSON payload in CLI should not list bare Password property
    if re.search(
        r"\$payloadHt\s*=\s*@\{[^}]*\bPassword\s*=",
        cli_text,
        re.IGNORECASE | re.DOTALL,
    ):
        # Allow only PasswordUsed inside payloadHt
        block = re.search(
            r"\$payloadHt\s*=\s*@\{(.*?)\n\s*\}",
            cli_text,
            re.DOTALL,
        )
        if block:
            body = block.group(1)
            for line in body.splitlines():
                if re.search(r"^\s*Password\s*=", line) and "PasswordUsed" not in line:
                    issues.append("ExcelToolkit.ps1:payloadHt:Password_prop")

    if issues:
        fail_exit(f"password json contract hits: {','.join(issues[:8])}")

    pass_exit("password_json_contract ok; PasswordUsed boolean only")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        fail_exit(f"invariant_password_json_contract error: {type(exc).__name__}")
