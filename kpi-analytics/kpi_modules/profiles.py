"""Scoring configuration profiles (POI presets and operator-saved JSON).

Stdlib only. Profiles are envelopes that deep-merge optional config overlays onto
package defaults and may embed or reference a column-mapping roles object.
"""

from __future__ import annotations

import json
import re
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from . import __version__
from .column_map import ROLE_KEYS, load_mapping_profile
from .config import (
    DEFAULT_CONFIG_PATH,
    effective_weights,
    load_config,
    validate_config,
)

PROFILE_SCHEMA_VERSION = "1.0"
SUPPORTED_PROFILE_SCHEMA_VERSIONS = frozenset({PROFILE_SCHEMA_VERSION})

# Strict allow-list of top-level profile keys.
ALLOWED_TOP_LEVEL_KEYS = frozenset(
    {
        "profile_schema_version",
        "name",
        "description",
        "min_toolkit_version",
        "wq_label",
        "created_at",
        "config",
        "mapping",
        "mapping_path",
    }
)

# Reject accidental claim dumps.
DENYLIST_KEYS = frozenset({"rows", "data", "claims", "records"})

_SLUG_RE = re.compile(r"^[a-z][a-z0-9_]*$")
_SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)(?:[-+].*)?$")


def toolkit_root() -> Path:
    """Return the kpi-analytics toolkit root directory."""
    return Path(__file__).resolve().parents[1]


def profiles_dir() -> Path:
    """Return the profiles directory under the toolkit root."""
    return toolkit_root() / "profiles"


def deep_merge(base: dict[str, Any], overlay: dict[str, Any]) -> dict[str, Any]:
    """
    Deep-merge *overlay* onto a deep copy of *base*.

    - Nested dicts merge recursively.
    - Lists and scalars in *overlay* replace base values.
    - Overlay keys with value None are skipped (partial profiles stay clean).
    """
    out = deepcopy(base)
    for key, value in overlay.items():
        if value is None:
            continue
        if (
            key in out
            and isinstance(out[key], dict)
            and isinstance(value, dict)
        ):
            out[key] = deep_merge(out[key], value)
        else:
            out[key] = deepcopy(value)
    return out


def _parse_semver(text: str) -> tuple[int, int, int]:
    match = _SEMVER_RE.match(str(text).strip())
    if not match:
        raise ValueError(
            f"Invalid semver string: {text!r} "
            "(expected major.minor.patch)"
        )
    return int(match.group(1)), int(match.group(2)), int(match.group(3))


def _version_less(a: str, b: str) -> bool:
    """True if semver *a* is strictly older than *b*."""
    return _parse_semver(a) < _parse_semver(b)


def _check_denylist(obj: Any, path: str = "") -> None:
    """Raise ValueError if deny-listed keys appear anywhere in a dict tree."""
    if isinstance(obj, dict):
        for key, value in obj.items():
            key_s = str(key)
            here = f"{path}.{key_s}" if path else key_s
            if key_s in DENYLIST_KEYS:
                raise ValueError(
                    f"Profile must not contain claim/data key {key_s!r} "
                    f"at {here}; profiles must not embed extracts"
                )
            _check_denylist(value, here)
    elif isinstance(obj, list):
        for idx, item in enumerate(obj):
            _check_denylist(item, f"{path}[{idx}]")


def validate_profile_envelope(data: dict[str, Any]) -> dict[str, Any]:
    """
    Validate a profile document (envelope only; does not merge config).

    Returns a shallow-validated deep copy.
    """
    if not isinstance(data, dict):
        raise ValueError("Profile root must be a JSON object")

    unknown = sorted(set(data.keys()) - ALLOWED_TOP_LEVEL_KEYS)
    if unknown:
        raise ValueError(
            "Profile has unknown top-level key(s): "
            + ", ".join(unknown)
            + f"; allowed: {', '.join(sorted(ALLOWED_TOP_LEVEL_KEYS))}"
        )

    _check_denylist(data)

    schema_ver = data.get("profile_schema_version")
    if schema_ver is None or not str(schema_ver).strip():
        raise ValueError("Profile missing required key: profile_schema_version")
    schema_ver_s = str(schema_ver).strip()
    if schema_ver_s not in SUPPORTED_PROFILE_SCHEMA_VERSIONS:
        raise ValueError(
            f"Unsupported profile_schema_version {schema_ver_s!r}; "
            f"supported: {', '.join(sorted(SUPPORTED_PROFILE_SCHEMA_VERSIONS))}"
        )

    name = data.get("name")
    if name is None or not str(name).strip():
        raise ValueError("Profile missing required key: name")
    name_s = str(name).strip()

    description = data.get("description")
    if description is None or not str(description).strip():
        raise ValueError(
            "Profile missing required non-empty key: description"
        )
    description_s = str(description).strip()

    out = deepcopy(data)
    out["profile_schema_version"] = schema_ver_s
    out["name"] = name_s
    out["description"] = description_s

    if "min_toolkit_version" in out and out["min_toolkit_version"] is not None:
        min_v = str(out["min_toolkit_version"]).strip()
        out["min_toolkit_version"] = min_v
        # Fail if package is older than required.
        if _version_less(__version__, min_v):
            raise ValueError(
                f"Profile requires kpi-analytics {min_v} or newer; "
                f"this package is {__version__}"
            )

    if "config" in out and out["config"] is not None:
        if not isinstance(out["config"], dict):
            raise ValueError("Profile 'config' must be a JSON object")
        _check_denylist(out["config"], "config")

    if "mapping" in out and out["mapping"] is not None:
        if not isinstance(out["mapping"], dict):
            raise ValueError("Profile 'mapping' must be a JSON object")
        roles = out["mapping"].get("roles")
        if not isinstance(roles, dict):
            raise ValueError(
                "Profile 'mapping' must contain a 'roles' object"
            )
        for role, col in roles.items():
            role_s = str(role).strip()
            if role_s not in ROLE_KEYS:
                raise ValueError(
                    f"Unknown mapping role {role_s!r} in profile; "
                    f"expected one of {', '.join(ROLE_KEYS)}"
                )
            col_s = str(col).strip() if col is not None else ""
            if not col_s:
                raise ValueError(
                    f"Profile mapping role {role_s!r} has an empty column name"
                )

    if "mapping_path" in out and out["mapping_path"] is not None:
        if not isinstance(out["mapping_path"], (str, Path)):
            raise ValueError("Profile 'mapping_path' must be a string path")
        out["mapping_path"] = str(out["mapping_path"]).strip() or None

    if "wq_label" in out and out["wq_label"] is not None:
        out["wq_label"] = str(out["wq_label"])

    if "created_at" in out and out["created_at"] is not None:
        out["created_at"] = str(out["created_at"]).strip()

    return out


def load_profile(path: str | Path) -> dict[str, Any]:
    """Load and validate a profile JSON file."""
    p = Path(path)
    if not p.is_file():
        raise FileNotFoundError(f"Scoring profile not found: {p}")
    with p.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"Profile root must be a JSON object: {p}")
    return validate_profile_envelope(data)


def resolve_profile_path(name_or_path: str | Path) -> Path:
    """
    Resolve a profile name or path to an existing file.

    - Tokens containing path separators or ending with ``.json`` are filesystem paths.
    - Bare names try ``profiles/<name>.json`` then ``profiles/poi_<name>.json``.
    """
    token = str(name_or_path).strip()
    if not token:
        raise ValueError("Profile name or path is empty")

    looks_like_path = (
        ("\\" in token)
        or ("/" in token)
        or token.lower().endswith(".json")
    )
    if looks_like_path:
        p = Path(token)
        if not p.is_file():
            raise FileNotFoundError(f"Scoring profile not found: {p}")
        return p.resolve()

    root = profiles_dir()
    candidates = [
        root / f"{token}.json",
        root / f"poi_{token}.json",
    ]
    # If token already starts with poi_, avoid poi_poi_*.
    if token.startswith("poi_"):
        candidates = [root / f"{token}.json"]

    for cand in candidates:
        if cand.is_file():
            return cand.resolve()

    tried = ", ".join(str(c) for c in candidates)
    raise FileNotFoundError(
        f"Scoring profile {token!r} not found under {root}. "
        f"Tried: {tried}"
    )


def config_from_profile(profile: dict[str, Any]) -> dict[str, Any]:
    """Deep-merge profile config overlay onto package default and validate."""
    base = load_config(DEFAULT_CONFIG_PATH)
    overlay = profile.get("config")
    if overlay is None:
        overlay = {}
    if not isinstance(overlay, dict):
        raise ValueError("Profile 'config' must be a JSON object")
    merged = deep_merge(base, overlay)
    return validate_config(merged)


def mapping_roles_from_profile(
    profile: dict[str, Any],
    profile_path: str | Path | None = None,
) -> tuple[dict[str, str] | None, str | None]:
    """
    Extract role→column mapping from a profile.

    Returns ``(roles_or_none, source)`` where *source* is
    ``profile_inline``, ``profile_path``, or ``None``.
    """
    mapping = profile.get("mapping")
    if isinstance(mapping, dict) and isinstance(mapping.get("roles"), dict):
        roles: dict[str, str] = {}
        for role, col in mapping["roles"].items():
            roles[str(role).strip()] = str(col).strip()
        return roles, "profile_inline"

    mapping_path = profile.get("mapping_path")
    if mapping_path:
        mp = Path(str(mapping_path))
        if not mp.is_absolute() and profile_path is not None:
            mp = (Path(profile_path).resolve().parent / mp).resolve()
        roles_loaded = load_mapping_profile(mp)
        return roles_loaded, "profile_path"

    return None, None


def list_profiles() -> list[dict[str, Any]]:
    """
    List JSON files in the profiles directory (non-recursive).

    Each entry has Path, Valid, and either metadata fields or Message.
    """
    root = profiles_dir()
    if not root.is_dir():
        return []

    entries: list[dict[str, Any]] = []
    for path in sorted(root.glob("*.json")):
        item: dict[str, Any] = {
            "Path": str(path.resolve()),
            "FileName": path.name,
        }
        try:
            prof = load_profile(path)
            item["Valid"] = True
            item["Name"] = prof["name"]
            item["Description"] = prof["description"]
            if prof.get("wq_label") is not None:
                item["WqLabel"] = prof.get("wq_label")
            if prof.get("min_toolkit_version"):
                item["MinToolkitVersion"] = prof.get("min_toolkit_version")
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            item["Valid"] = False
            item["Message"] = str(exc)
        entries.append(item)
    return entries


def profile_show_summary(
    name_or_path: str | Path,
) -> dict[str, Any]:
    """Resolve, load, and summarize a profile (no claim data)."""
    path = resolve_profile_path(name_or_path)
    profile = load_profile(path)
    cfg = config_from_profile(profile)
    roles, map_source = mapping_roles_from_profile(profile, path)
    poi = cfg.get("point_of_interest") or {}
    poi_name = str(poi.get("name", "default"))
    poi_mult = {
        k: float(v) for k, v in (poi.get("multipliers") or {}).items()
    }
    base_weights = {k: float(v) for k, v in cfg["weights"].items()}
    eff_off = effective_weights(cfg, chaos_mode=False)
    eff_on = effective_weights(cfg, chaos_mode=True)

    return {
        "Success": True,
        "Command": "profile-show",
        "Path": str(path),
        "Name": profile["name"],
        "Description": profile["description"],
        "ProfileSchemaVersion": profile["profile_schema_version"],
        "MinToolkitVersion": profile.get("min_toolkit_version"),
        "WqLabel": profile.get("wq_label"),
        "CreatedAt": profile.get("created_at"),
        "PoiName": poi_name,
        "PoiMultipliers": poi_mult,
        "BaseWeights": base_weights,
        "EffectiveWeightsChaosOff": {
            k: round(v, 6) for k, v in eff_off.items()
        },
        "EffectiveWeightsChaosOn": {
            k: round(v, 6) for k, v in eff_on.items()
        },
        "MappingSource": map_source,
        "MappingRoles": roles,
    }


def validate_slug(slug: str) -> str:
    """Validate a profile file slug (name without .json)."""
    s = str(slug).strip()
    if not s or not _SLUG_RE.match(s):
        raise ValueError(
            f"Invalid profile slug {slug!r}; expected "
            r"^[a-z][a-z0-9_]*$ (use user_<name> for local profiles)"
        )
    if ".." in s or "/" in s or "\\" in s:
        raise ValueError(f"Invalid profile slug {slug!r}")
    return s


def save_profile(
    name: str,
    *,
    description: str | None = None,
    from_config: str | Path | None = None,
    from_mapping: str | Path | None = None,
    wq_label: str | None = None,
    force: bool = False,
) -> dict[str, Any]:
    """
    Write ``profiles/<name>.json``.

    Config body: if *from_config* is set, store that JSON object under ``config``
    (operator intent). Otherwise ``config`` is ``{}`` (package default).
    """
    slug = validate_slug(name)
    out_path = profiles_dir() / f"{slug}.json"
    if out_path.is_file() and not force:
        raise FileExistsError(
            f"Profile already exists: {out_path} (pass --force to overwrite)"
        )

    desc = (
        str(description).strip()
        if description is not None and str(description).strip()
        else f"Saved scoring profile {slug}"
    )

    config_body: dict[str, Any] = {}
    if from_config is not None:
        cfg_path = Path(from_config)
        if not cfg_path.is_file():
            raise FileNotFoundError(f"Config not found: {cfg_path}")
        with cfg_path.open("r", encoding="utf-8") as fh:
            loaded = json.load(fh)
        if not isinstance(loaded, dict):
            raise ValueError("from-config root must be a JSON object")
        # Validate it is a usable config (may be full product config).
        validate_config(deepcopy(loaded))
        config_body = loaded

    mapping_obj: dict[str, Any] | None = None
    if from_mapping is not None:
        roles = load_mapping_profile(from_mapping)
        mapping_obj = {
            "version": "1.0",
            "description": f"Embedded from {Path(from_mapping).name}",
            "roles": roles,
        }

    created = datetime.now(timezone.utc).date().isoformat()
    document: dict[str, Any] = {
        "profile_schema_version": PROFILE_SCHEMA_VERSION,
        "name": slug,
        "description": desc,
        "min_toolkit_version": __version__,
        "created_at": created,
        "config": config_body,
    }
    if wq_label is not None and str(wq_label).strip():
        document["wq_label"] = str(wq_label).strip()
    if mapping_obj is not None:
        document["mapping"] = mapping_obj

    # Final envelope + deny-list check.
    document = validate_profile_envelope(document)

    profiles_dir().mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="\n") as fh:
        json.dump(document, fh, indent=2)
        fh.write("\n")

    return {
        "Success": True,
        "Command": "profile-save",
        "Path": str(out_path.resolve()),
        "Name": slug,
        "Description": desc,
        "Forced": bool(force),
    }
