"""Command-line interface for kpi-analytics."""

from __future__ import annotations

import argparse
import json
import sys
import traceback
from pathlib import Path
from typing import Any

from . import __version__
from .diagnostics import (
    GATED_COMMANDS,
    attach_gate_fields,
    ensure_diagnostics_pass,
    run_diagnostics,
)
from .probe import run_probe
from .score_v1 import score_csv
from .synthesize import generate_csv  # professional billing synthetic WQ
from .validate_score import validate_score


EXIT_OK = 0
EXIT_VALIDATION = 1
EXIT_RUNTIME = 2


def _repo_root() -> Path:
    # kpi-analytics/kpi_modules/cli.py → parents[2] = repo root
    return Path(__file__).resolve().parents[2]


def _default_score_output() -> Path:
    return _repo_root() / "output" / "wq_scored.csv"


def _default_generate_output() -> Path:
    return _repo_root() / "output" / "wq_data_synthetic.csv"


def _default_schema() -> Path:
    return _repo_root() / "wq_schema.json"


def _default_template_csv() -> Path:
    return _repo_root() / "wq_data.csv"


def _toolkit_root() -> Path:
    # kpi-analytics/kpi_modules/cli.py → parents[1] = kpi-analytics
    return Path(__file__).resolve().parents[1]


def _default_fixture_csv() -> Path:
    return _toolkit_root() / "fixtures" / "v1_handcalc_input.csv"


def _default_fixture_config() -> Path:
    return _toolkit_root() / "fixtures" / "v1_handcalc_config.json"


def _default_fixture_expected() -> Path:
    return _toolkit_root() / "fixtures" / "v1_handcalc_expected.json"


def _emit(obj: Any, *, as_json: bool, quiet: bool) -> None:
    if as_json:
        print(json.dumps(obj, separators=(",", ":"), default=str))
    elif not quiet:
        if isinstance(obj, dict):
            for key, val in obj.items():
                if key == "Checks" and isinstance(val, list):
                    print("Checks:")
                    for c in val:
                        flag = "PASS" if c.get("Passed") else "FAIL"
                        sev = c.get("Severity")
                        sev_s = f" ({sev})" if sev else ""
                        print(f"  [{flag}]{sev_s} {c.get('Name')}: {c.get('Detail')}")
                elif key in ("Weights", "Chaos") and isinstance(val, dict):
                    print(f"{key}:")
                    for k2, v2 in val.items():
                        print(f"  {k2}: {v2}")
                else:
                    print(f"{key}: {val}")
        else:
            print(obj)


def _add_gate_flags(p: argparse.ArgumentParser) -> None:
    p.add_argument(
        "--force-diagnostics",
        action="store_true",
        help="Re-run enterprise diagnostics before this command (refresh pass certificate)",
    )
    p.add_argument(
        "--skip-diagnostics-gate",
        action="store_true",
        help="Skip diagnostics gate (emergency/support only)",
    )


def build_parser() -> argparse.ArgumentParser:
    """Build the kpi-analytics argparse CLI."""
    parser = argparse.ArgumentParser(
        prog="kpi-analytics",
        description=(
            "KPI Analytics — Work Queue KPI scoring and synthetic data "
            "(Python 3.13 stdlib only)."
        ),
    )
    parser.add_argument(
        "--version",
        action="store_true",
        help="Print version and exit",
    )

    sub = parser.add_subparsers(dest="command")

    p_ver = sub.add_parser("version", help="Print toolkit version")
    p_ver.add_argument("--json", action="store_true", help="JSON result on stdout")
    p_ver.add_argument("--quiet", action="store_true", help="Minimal host text")

    p_probe = sub.add_parser("probe", help="Run environment / path preflight")
    p_probe.add_argument("--csv", dest="csv_path", default=None, help="Data CSV to check")
    p_probe.add_argument(
        "--config", dest="config_path", default=None, help="Config JSON to check"
    )
    p_probe.add_argument(
        "--schema", dest="schema_path", default=None, help="Optional schema path check"
    )
    p_probe.add_argument("--json", action="store_true")
    p_probe.add_argument("--quiet", action="store_true")

    p_diag = sub.add_parser(
        "diagnostics",
        help="Enterprise dry-run diagnostics (runtime/import; writes pass/fail report)",
    )
    p_diag.add_argument(
        "--force",
        action="store_true",
        help="Re-run and overwrite report even if a valid pass certificate exists",
    )
    p_diag.add_argument("--json", action="store_true")
    p_diag.add_argument("--quiet", action="store_true")

    p_score = sub.add_parser("score", help="Score a WQ data CSV (Priority Matrix V1)")
    p_score.add_argument(
        "--csv",
        dest="csv_path",
        required=True,
        help="Input data CSV",
    )
    p_score.add_argument(
        "--output",
        dest="output_path",
        default=None,
        help="Output scored CSV (default: <repo>/output/wq_scored.csv)",
    )
    p_score.add_argument(
        "--config",
        dest="config_path",
        default=None,
        help="Optional weights/thresholds JSON (default: package config)",
    )
    p_score.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate and compute summary only; do not write output",
    )
    p_score.add_argument(
        "--summary",
        dest="summary_path",
        default=None,
        help="Vertical summary CSV path (default: <output_stem>_summary.csv)",
    )
    p_score.add_argument(
        "--no-summary",
        action="store_true",
        help="Do not write the vertical summary CSV",
    )
    privacy_group = p_score.add_mutually_exclusive_group()
    privacy_group.add_argument(
        "--privacy",
        dest="privacy_override",
        action="store_const",
        const=True,
        default=None,
        help="Force PHI field masking on scored output (overrides config)",
    )
    privacy_group.add_argument(
        "--no-privacy",
        dest="privacy_override",
        action="store_const",
        const=False,
        help="Disable PHI field masking on scored output (overrides config)",
    )
    _add_gate_flags(p_score)
    p_score.add_argument("--json", action="store_true")
    p_score.add_argument("--quiet", action="store_true")

    p_gen = sub.add_parser(
        "generate",
        help="Generate synthetic WQ CSV (de-identified Doe,John/Jane + DOB day=01)",
    )
    p_gen.add_argument(
        "--rows",
        type=int,
        default=100,
        help="Number of synthetic data rows (default: 100)",
    )
    p_gen.add_argument(
        "--output",
        dest="output_path",
        default=None,
        help="Output CSV (default: <repo>/output/wq_data_synthetic.csv)",
    )
    p_gen.add_argument(
        "--schema",
        dest="schema_path",
        default=None,
        help="Schema JSON for field list/types (default: <repo>/wq_schema.json)",
    )
    p_gen.add_argument(
        "--template-csv",
        dest="template_csv",
        default=None,
        help="Template CSV for column order only (default: <repo>/wq_data.csv)",
    )
    p_gen.add_argument(
        "--seed",
        type=int,
        default=42,
        help="RNG seed for reproducible output (default: 42)",
    )
    p_gen.add_argument(
        "--append",
        action="store_true",
        help="Append new rows to an existing output CSV (continues Doe name index)",
    )
    p_gen.add_argument(
        "--start-index",
        type=int,
        default=1,
        help=(
            "Starting patient index for Doe,John/Jane{N} "
            "(default: 1; ignored if --append finds existing)"
        ),
    )
    p_gen.add_argument(
        "--dry-run",
        action="store_true",
        help="Build summary only; do not write output",
    )
    _add_gate_flags(p_gen)
    p_gen.add_argument("--json", action="store_true")
    p_gen.add_argument("--quiet", action="store_true")

    p_val = sub.add_parser(
        "validate-score",
        help="Validate V1 scores (contrib integrity + optional golden fixture)",
    )
    p_val.add_argument(
        "--csv",
        dest="csv_path",
        default=None,
        help="Input data CSV to score (default: fixtures/v1_handcalc_input.csv)",
    )
    p_val.add_argument(
        "--config",
        dest="config_path",
        default=None,
        help="Config JSON (default: fixtures/v1_handcalc_config.json when using fixtures)",
    )
    p_val.add_argument(
        "--expected",
        dest="expected_path",
        default=None,
        help="Golden expected JSON (default: fixtures/v1_handcalc_expected.json if present)",
    )
    p_val.add_argument(
        "--scored-csv",
        dest="scored_csv_path",
        default=None,
        help="Already-scored CSV to validate (skips recompute; still checks sum(contrib))",
    )
    p_val.add_argument(
        "--epsilon",
        type=float,
        default=1e-5,
        help="Numeric tolerance (default: 1e-5)",
    )
    p_val.add_argument(
        "--no-expected",
        action="store_true",
        help="Integrity checks only (do not load golden expected file)",
    )
    _add_gate_flags(p_val)
    p_val.add_argument("--json", action="store_true")
    p_val.add_argument("--quiet", action="store_true")

    p_help = sub.add_parser("help", help="Show help")
    p_help.add_argument("--json", action="store_true")
    p_help.add_argument("--quiet", action="store_true")

    return parser


def _apply_gate(
    args: argparse.Namespace,
    *,
    command: str,
    as_json: bool,
    quiet: bool,
) -> tuple[bool, dict[str, Any] | None, int | None]:
    """
    Run diagnostics gate for operational commands.

    Returns (ok, gate_dict_or_none, exit_code_if_blocked).
    """
    if command not in GATED_COMMANDS:
        return True, None, None

    force = bool(getattr(args, "force_diagnostics", False))
    skip = bool(getattr(args, "skip_diagnostics_gate", False))
    gate = ensure_diagnostics_pass(force=force, skip=skip)

    if skip and not quiet and not as_json:
        print(
            "WARNING: Diagnostics gate skipped (--skip-diagnostics-gate). "
            "Emergency/support use only.",
            file=sys.stderr,
        )

    if gate.get("GateOk"):
        if gate.get("GateMode") == "ran" and not quiet and not as_json:
            print(
                f"Diagnostics auto-ran and passed. "
                f"Report: {gate.get('ReportTextPath')}",
                file=sys.stderr,
            )
        return True, gate, None

    blocked = {
        "Success": False,
        "Command": command,
        "Version": __version__,
        "DiagnosticsOverallPass": False,
        "DiagnosticsGate": gate.get("GateMode"),
        "DiagnosticsReportJsonPath": gate.get("ReportJsonPath"),
        "DiagnosticsReportTextPath": gate.get("ReportTextPath"),
        "Message": gate.get("Message"),
    }
    diag = gate.get("Diagnostics")
    if isinstance(diag, dict) and diag.get("CriticalFailed"):
        blocked["CriticalFailed"] = diag["CriticalFailed"]
    _emit(blocked, as_json=as_json, quiet=quiet)
    return False, gate, EXIT_VALIDATION


def main(argv: list[str] | None = None) -> int:
    """CLI entry point; returns process exit code 0 / 1 / 2."""
    argv = list(sys.argv[1:] if argv is None else argv)
    parser = build_parser()

    # Support top-level --version
    if argv and argv[0] in ("-V", "--version"):
        print(__version__)
        return EXIT_OK

    args = parser.parse_args(argv)

    if getattr(args, "version", False) and not args.command:
        print(__version__)
        return EXIT_OK

    command = args.command
    if command is None or command == "help":
        parser.print_help()
        return EXIT_OK

    as_json = bool(getattr(args, "json", False))
    quiet = bool(getattr(args, "quiet", False))

    try:
        if command == "version":
            if as_json:
                _emit(
                    {
                        "Success": True,
                        "Version": __version__,
                        "Command": "version",
                    },
                    as_json=True,
                    quiet=quiet,
                )
            else:
                print(__version__)
            return EXIT_OK

        if command == "probe":
            result = run_probe(
                csv_path=getattr(args, "csv_path", None),
                config_path=getattr(args, "config_path", None),
                schema_path=getattr(args, "schema_path", None),
            )
            _emit(result, as_json=as_json, quiet=quiet)
            return EXIT_OK if result.get("Success") else EXIT_VALIDATION

        if command == "diagnostics":
            # Always re-run when invoked explicitly; --force is documented alias
            result = run_diagnostics(write=True)
            _emit(result, as_json=as_json, quiet=quiet)
            return EXIT_OK if result.get("OverallPass") else EXIT_VALIDATION

        ok, gate, blocked_exit = _apply_gate(
            args, command=command, as_json=as_json, quiet=quiet
        )
        if not ok:
            return blocked_exit if blocked_exit is not None else EXIT_VALIDATION

        if command == "score":
            csv_path = args.csv_path
            if not csv_path:
                _emit(
                    {
                        "Success": False,
                        "Command": "score",
                        "Version": __version__,
                        "Message": "--csv is required",
                    },
                    as_json=as_json,
                    quiet=quiet,
                )
                return EXIT_VALIDATION

            output_path = args.output_path or str(_default_score_output())
            result = score_csv(
                csv_path,
                output_path,
                config_path=getattr(args, "config_path", None),
                dry_run=bool(getattr(args, "dry_run", False)),
                summary_path=getattr(args, "summary_path", None),
                write_summary=not bool(getattr(args, "no_summary", False)),
                privacy_enabled=getattr(args, "privacy_override", None),
            )
            result["Version"] = __version__
            if gate:
                attach_gate_fields(result, gate)
            _emit(result, as_json=as_json, quiet=quiet)
            return EXIT_OK if result.get("Success") else EXIT_VALIDATION

        if command == "generate":
            schema = getattr(args, "schema_path", None) or str(_default_schema())
            template = getattr(args, "template_csv", None)
            # Use default template only if it exists
            if template is None:
                tdef = _default_template_csv()
                template = str(tdef) if tdef.is_file() else None
            # If schema missing but template exists, still ok
            if not Path(schema).is_file() and not template:
                _emit(
                    {
                        "Success": False,
                        "Command": "generate",
                        "Version": __version__,
                        "Message": "Need a readable --schema and/or --template-csv",
                    },
                    as_json=as_json,
                    quiet=quiet,
                )
                return EXIT_VALIDATION
            if not Path(schema).is_file():
                schema = None

            output_path = args.output_path or str(_default_generate_output())
            result = generate_csv(
                row_count=int(getattr(args, "rows", 100)),
                output_path=output_path,
                schema_path=schema,
                template_csv=template,
                seed=int(getattr(args, "seed", 42)),
                dry_run=bool(getattr(args, "dry_run", False)),
                start_index=int(getattr(args, "start_index", 1)),
                append=bool(getattr(args, "append", False)),
            )
            result["Version"] = __version__
            if gate:
                attach_gate_fields(result, gate)
            _emit(result, as_json=as_json, quiet=quiet)
            return EXIT_OK if result.get("Success") else EXIT_VALIDATION

        if command == "validate-score":
            scored = getattr(args, "scored_csv_path", None)
            csv_path = getattr(args, "csv_path", None)
            config_path = getattr(args, "config_path", None)
            expected_path = getattr(args, "expected_path", None)
            no_expected = bool(getattr(args, "no_expected", False))

            # Defaults: handcalc fixtures under kpi-analytics/fixtures
            if not scored and not csv_path:
                csv_path = str(_default_fixture_csv())

            using_handcalc = bool(
                csv_path and Path(csv_path).name == "v1_handcalc_input.csv"
            )
            if config_path is None and using_handcalc and _default_fixture_config().is_file():
                config_path = str(_default_fixture_config())
            if (
                not no_expected
                and expected_path is None
                and using_handcalc
                and _default_fixture_expected().is_file()
            ):
                expected_path = str(_default_fixture_expected())
            if no_expected:
                expected_path = None

            if not scored and not csv_path:
                _emit(
                    {
                        "Success": False,
                        "Command": "validate-score",
                        "Version": __version__,
                        "Message": "Provide --csv or --scored-csv",
                    },
                    as_json=as_json,
                    quiet=quiet,
                )
                return EXIT_VALIDATION

            result = validate_score(
                csv_path=csv_path or (scored or ""),
                config_path=config_path,
                expected_path=expected_path,
                epsilon=float(getattr(args, "epsilon", 1e-5)),
                scored_csv_path=scored,
            )
            result["Version"] = __version__
            if gate:
                attach_gate_fields(result, gate)
            _emit(result, as_json=as_json, quiet=quiet)
            return EXIT_OK if result.get("Success") else EXIT_VALIDATION

        parser.print_help()
        return EXIT_VALIDATION

    except (FileNotFoundError, ValueError, OSError) as exc:
        err = {
            "Success": False,
            "Command": command,
            "Version": __version__,
            "Message": str(exc),
        }
        _emit(err, as_json=as_json, quiet=quiet)
        return EXIT_VALIDATION
    except Exception as exc:  # runtime
        err = {
            "Success": False,
            "Command": command,
            "Version": __version__,
            "Message": str(exc),
            "Detail": traceback.format_exc() if not quiet else None,
        }
        if not as_json and not quiet:
            traceback.print_exc()
        _emit(
            {k: v for k, v in err.items() if v is not None},
            as_json=as_json,
            quiet=quiet,
        )
        return EXIT_RUNTIME


if __name__ == "__main__":
    raise SystemExit(main())
