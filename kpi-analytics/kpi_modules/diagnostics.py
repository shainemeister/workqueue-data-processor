"""
Enterprise dry-run diagnostics for kpi-analytics (stdlib only).

Runtime and import checks plus a durable pass/fail report under
kpi-analytics/diagnostics/. Operational CLI commands gate on a valid
pass certificate (see ensure_diagnostics_pass).
"""

from __future__ import annotations

import importlib
import json
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from . import __version__
from .config import DEFAULT_CONFIG_PATH, load_config

REPORT_VERSION = 1

# Stdlib modules referenced by production kpi_modules code.
STDLIB_MODULES: tuple[str, ...] = (
    "argparse",
    "copy",
    "csv",
    "datetime",
    "json",
    "pathlib",
    "random",
    "sys",
    "tempfile",
    "traceback",
    "typing",
)

# Package modules that operational paths import.
PACKAGE_MODULES: tuple[str, ...] = (
    "kpi_modules",
    "kpi_modules.cli",
    "kpi_modules.config",
    "kpi_modules.diagnostics",
    "kpi_modules.io_csv",
    "kpi_modules.kpi_quantifiers",
    "kpi_modules.metrics",
    "kpi_modules.normalize",
    "kpi_modules.probe",
    "kpi_modules.score_v1",
    "kpi_modules.summary_report",
    "kpi_modules.synthesize",
    "kpi_modules.validate_score",
    "kpi_modules.__main__",
)

GATED_COMMANDS = frozenset({"score", "generate", "validate-score"})


def toolkit_root() -> Path:
    """Return the kpi-analytics toolkit root directory."""
    # kpi-analytics/kpi_modules/diagnostics.py → parents[1] = kpi-analytics
    return Path(__file__).resolve().parents[1]


def diagnostics_dir() -> Path:
    """Return the diagnostics report directory under the toolkit root."""
    return toolkit_root() / "diagnostics"


def report_json_path() -> Path:
    """Path to the machine-readable diagnostics certificate JSON."""
    return diagnostics_dir() / "last_diagnostics.json"


def report_text_path() -> Path:
    """Path to the human-readable diagnostics PASS/FAIL text report."""
    return diagnostics_dir() / "last_diagnostics.txt"


def _check(
    name: str,
    passed: bool,
    detail: str,
    *,
    severity: str = "critical",
) -> dict[str, Any]:
    """Build one diagnostics check result dict."""
    return {
        "Name": name,
        "Passed": bool(passed),
        "Severity": severity,
        "Detail": detail,
    }


def _python_version_string() -> str:
    ver = sys.version_info
    return f"{ver.major}.{ver.minor}.{ver.micro}"


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _run_checks() -> list[dict[str, Any]]:
    checks: list[dict[str, Any]] = []

    # --- Runtime ---
    ver = sys.version_info
    py_ok = ver.major == 3 and ver.minor >= 13
    checks.append(
        _check(
            "PythonVersion",
            py_ok,
            f"{_python_version_string()} (target: 3.13+ stdlib)",
        )
    )

    exe = sys.executable or ""
    exe_path = Path(exe) if exe else None
    exe_ok = bool(exe_path and exe_path.is_file())
    checks.append(
        _check(
            "PythonExecutable",
            exe_ok,
            str(exe_path.resolve()) if exe_ok and exe_path else (exe or "empty"),
        )
    )

    checks.append(
        _check(
            "Platform",
            True,
            f"{sys.platform} ({platform.platform()})",
            severity="advisory",
        )
    )
    checks.append(
        _check(
            "PythonImplementation",
            True,
            platform.python_implementation(),
            severity="advisory",
        )
    )
    checks.append(
        _check(
            "WorkingDirectory",
            True,
            str(Path.cwd().resolve()),
            severity="advisory",
        )
    )
    root = toolkit_root()
    checks.append(
        _check(
            "ToolkitRoot",
            root.is_dir(),
            str(root),
            severity="critical" if not root.is_dir() else "advisory",
        )
    )

    # --- Stdlib imports ---
    for mod_name in STDLIB_MODULES:
        try:
            importlib.import_module(mod_name)
            checks.append(_check(f"Stdlib.{mod_name}", True, "import ok"))
        except Exception as exc:
            checks.append(_check(f"Stdlib.{mod_name}", False, str(exc)))

    # --- Package modules ---
    for mod_name in PACKAGE_MODULES:
        short = mod_name.removeprefix("kpi_modules.").removeprefix("kpi_modules")
        label = "kpi_modules" if mod_name == "kpi_modules" else short or "kpi_modules"
        try:
            importlib.import_module(mod_name)
            if mod_name == "kpi_modules":
                detail = f"import ok (toolkit {__version__})"
            else:
                detail = "import ok"
            checks.append(_check(f"PackageImport.{label}", True, detail))
        except Exception as exc:
            checks.append(_check(f"PackageImport.{label}", False, str(exc)))

    # --- Default config (required by operational paths) ---
    try:
        load_config(None)
        checks.append(
            _check(
                "DefaultConfigLoad",
                True,
                str(DEFAULT_CONFIG_PATH.resolve()),
            )
        )
    except Exception as exc:
        checks.append(_check("DefaultConfigLoad", False, str(exc)))

    # --- Diagnostics directory writable (required for certificate) ---
    ddir = diagnostics_dir()
    probe_name = "_write_probe.tmp"
    probe_path = ddir / probe_name
    try:
        ddir.mkdir(parents=True, exist_ok=True)
        probe_path.write_text("ok\n", encoding="utf-8")
        content = probe_path.read_text(encoding="utf-8")
        probe_path.unlink(missing_ok=True)
        ok = content.strip() == "ok"
        checks.append(
            _check(
                "DiagnosticsDirWritable",
                ok,
                str(ddir.resolve()) if ok else "write/read mismatch",
            )
        )
    except Exception as exc:
        try:
            probe_path.unlink(missing_ok=True)
        except OSError:
            pass
        checks.append(_check("DiagnosticsDirWritable", False, str(exc)))

    return checks


def _format_text_report(result: dict[str, Any]) -> str:
    overall = "PASS" if result.get("OverallPass") else "FAIL"
    lines = [
        "KPI Analytics — Enterprise Diagnostics",
        f"ToolkitVersion: {result.get('ToolkitVersion')}",
        f"PythonVersion: {result.get('PythonVersion')}",
        f"PythonExecutable: {result.get('PythonExecutable')}",
        f"Platform: {result.get('Platform')}",
        f"OverallPass: {overall}",
        f"StartedAt: {result.get('StartedAt')}",
        f"FinishedAt: {result.get('FinishedAt')}",
        f"ToolkitRoot: {result.get('ToolkitRoot')}",
        "",
        "Checks:",
    ]
    for c in result.get("Checks") or []:
        flag = "PASS" if c.get("Passed") else "FAIL"
        sev = c.get("Severity", "critical")
        lines.append(f"  [{flag}] ({sev}) {c.get('Name')}: {c.get('Detail')}")
    failed = result.get("CriticalFailed") or []
    if failed:
        lines.append("")
        lines.append("Critical failures: " + ", ".join(failed))
    lines.append("")
    lines.append(str(result.get("Message") or ""))
    lines.append("")
    lines.append(
        "Privacy: this report records environment and import results only; "
        "it does not include claim rows or PHI."
    )
    lines.append("")
    return "\n".join(lines)


def write_reports(result: dict[str, Any]) -> dict[str, str]:
    """Write JSON + text reports; return resolved paths."""
    ddir = diagnostics_dir()
    ddir.mkdir(parents=True, exist_ok=True)
    json_path = report_json_path()
    text_path = report_text_path()

    # Stable JSON for gate readers (indent for IT readability)
    with json_path.open("w", encoding="utf-8", newline="\n") as fh:
        json.dump(result, fh, indent=2, default=str)
        fh.write("\n")

    text_path.write_text(_format_text_report(result), encoding="utf-8", newline="\n")
    return {
        "JsonPath": str(json_path.resolve()),
        "TextPath": str(text_path.resolve()),
    }


def run_diagnostics(*, write: bool = True) -> dict[str, Any]:
    """
    Run the full runtime/import diagnostics suite.

    When write is True, always refreshes last_diagnostics.json/.txt.
    """
    started = _utc_now_iso()
    checks = _run_checks()
    critical_failed = [
        str(c["Name"])
        for c in checks
        if c.get("Severity") == "critical" and not c.get("Passed")
    ]
    overall = not critical_failed
    finished = _utc_now_iso()

    result: dict[str, Any] = {
        "ReportVersion": REPORT_VERSION,
        "Success": overall,
        "OverallPass": overall,
        "Command": "diagnostics",
        "Version": __version__,
        "ToolkitVersion": __version__,
        "PythonVersion": _python_version_string(),
        "PythonExecutable": str(Path(sys.executable).resolve())
        if sys.executable
        else "",
        "Platform": sys.platform,
        "StartedAt": started,
        "FinishedAt": finished,
        "ToolkitRoot": str(toolkit_root().resolve()),
        "CriticalFailed": critical_failed,
        "Checks": checks,
        "Message": (
            "Diagnostics passed. Operational commands may proceed."
            if overall
            else "Diagnostics failed. Fix critical failures before score/generate/validate-score."
        ),
    }

    if write:
        try:
            paths = write_reports(result)
            result["ReportJsonPath"] = paths["JsonPath"]
            result["ReportTextPath"] = paths["TextPath"]
        except Exception as exc:
            result["Success"] = False
            result["OverallPass"] = False
            result["Message"] = f"Diagnostics checks finished but report write failed: {exc}"
            if "DiagnosticsDirWritable" not in result["CriticalFailed"]:
                result["CriticalFailed"] = list(result["CriticalFailed"]) + [
                    "ReportWrite"
                ]
            result["Checks"] = list(result["Checks"]) + [
                _check("ReportWrite", False, str(exc))
            ]

    return result


def load_valid_pass_certificate() -> dict[str, Any] | None:
    """
    Return the stored diagnostics report if it is a valid pass certificate
    for this toolkit version and Python interpreter; otherwise None.
    """
    path = report_json_path()
    if not path.is_file():
        return None
    try:
        with path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, json.JSONDecodeError):
        return None

    if not isinstance(data, dict):
        return None
    if data.get("ReportVersion") != REPORT_VERSION:
        return None
    if not data.get("OverallPass"):
        return None
    if str(data.get("ToolkitVersion") or "") != __version__:
        return None
    if str(data.get("PythonVersion") or "") != _python_version_string():
        return None
    return data


def ensure_diagnostics_pass(
    *,
    force: bool = False,
    skip: bool = False,
) -> dict[str, Any]:
    """
    Ensure a valid diagnostics pass certificate exists.

    Returns a gate decision dict:
      GateOk, GateMode (cached|ran|skipped|blocked), Diagnostics (report or None),
      Message, Report paths when available.
    """
    if skip:
        return {
            "GateOk": True,
            "GateMode": "skipped",
            "DiagnosticsGateSkipped": True,
            "Diagnostics": None,
            "Message": (
                "Diagnostics gate skipped (--skip-diagnostics-gate). "
                "Emergency/support use only."
            ),
        }

    if not force:
        cached = load_valid_pass_certificate()
        if cached is not None:
            return {
                "GateOk": True,
                "GateMode": "cached",
                "DiagnosticsGateSkipped": False,
                "Diagnostics": cached,
                "ReportJsonPath": str(report_json_path().resolve()),
                "ReportTextPath": str(report_text_path().resolve())
                if report_text_path().is_file()
                else None,
                "Message": "Diagnostics certificate valid (cached pass).",
            }

    result = run_diagnostics(write=True)
    if result.get("OverallPass"):
        return {
            "GateOk": True,
            "GateMode": "ran",
            "DiagnosticsGateSkipped": False,
            "Diagnostics": result,
            "ReportJsonPath": result.get("ReportJsonPath"),
            "ReportTextPath": result.get("ReportTextPath"),
            "Message": "Diagnostics auto-ran and passed.",
        }

    text_path = result.get("ReportTextPath") or str(report_text_path())
    return {
        "GateOk": False,
        "GateMode": "blocked",
        "DiagnosticsGateSkipped": False,
        "Diagnostics": result,
        "ReportJsonPath": result.get("ReportJsonPath"),
        "ReportTextPath": text_path,
        "Message": (
            "Diagnostics gate blocked this command. "
            f"See: {text_path}. "
            "Re-run: kpi-analytics.cmd diagnostics --force"
        ),
    }


def attach_gate_fields(result: dict[str, Any], gate: dict[str, Any]) -> dict[str, Any]:
    """Merge gate metadata into an operational command result dict."""
    result["DiagnosticsGate"] = gate.get("GateMode")
    result["DiagnosticsGateSkipped"] = bool(gate.get("DiagnosticsGateSkipped"))
    if gate.get("ReportJsonPath"):
        result["DiagnosticsReportJsonPath"] = gate["ReportJsonPath"]
    if gate.get("ReportTextPath"):
        result["DiagnosticsReportTextPath"] = gate["ReportTextPath"]
    return result
