"""Synthetic Work Queue CSV generator — Professional Billing style (stdlib only)."""

from __future__ import annotations

import json
import random
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any

from .io_csv import read_csv_rows, write_csv_rows

# Excel serial day 0 on Windows Excel is 1899-12-30
_EXCEL_EPOCH = date(1899, 12, 30)

# ---------------------------------------------------------------------------
# Professional Billing–oriented catalogs (synthetic / non-PHI)
# ---------------------------------------------------------------------------

WQ_STATUSES = ("R", "R", "R", "D", "T", "W")  # workqueue often dominated by Ready
DENIAL_STATUSES = (
    "Created",
    "Created",
    "In Progress",
    "Denied",
    "Appealed",
    "Pending Payer",
    "Closed",
)

# Common professional denial / follow-up categories
CODE_CATEGORIES = (
    "Non-Covered",
    "Authorization",
    "Coding",
    "Timely Filing",
    "Medical Necessity",
    "Duplicate",
    "Eligibility",
    "COB / Other Payer",
    "Modifier",
    "Bundling / NCCI",
    "Frequency Limit",
    "Provider Enrollment",
)

PAYERS = (
    "CIGNA",
    "AETNA",
    "UHC",
    "BCBS",
    "MEDICARE",
    "MEDICAID",
    "HUMANA",
    "TRICARE",
    "WORKERS COMP",
)

# Professional plan product labels (paired loosely with payer)
PLAN_PRODUCTS = (
    "OPEN ACCESS PPO",
    "HMO STANDARD",
    "POS PLUS",
    "EPO BASIC",
    "MEDICARE ADVANTAGE PPO",
    "MEDICARE TRADITIONAL",
    "MEDICAID MCO",
    "EXCHANGE SILVER PPO",
    "SELF-FUNDED PPO",
)

LOCATIONS = (
    "MAIN PHYSICIAN GROUP",
    "NORTH CLINIC",
    "SOUTH CAMPUS SPECIALTY",
    "OUTPATIENT CENTER",
    "URGENT CARE WEST",
    "CARDIOLOGY ASSOC",
    "ORTHO SPECIALISTS",
    "PRIMARY CARE EAST",
    "TELEHEALTH VIRTUAL",
)

# Professional / specialty departments (not facility bed units)
DEPARTMENTS = (
    "PRIMARY CARE",
    "FAMILY MEDICINE",
    "INTERNAL MEDICINE",
    "CARDIOLOGY",
    "ORTHOPEDICS",
    "GASTROENTEROLOGY",
    "DERMATOLOGY",
    "NEUROLOGY",
    "ONCOLOGY",
    "RADIOLOGY PRO FEE",
    "EMERGENCY PRO FEE",
    "ANESTHESIA",
    "SURGERY",
    "OB/GYN",
    "PULMONOLOGY",
    "ENDOCRINOLOGY",
    "RHEUMATOLOGY",
    "UROLOGY",
    "OPHTHALMOLOGY",
    "PHYSICAL MEDICINE",
)

# Professional CPT mix: office E&M heavy, hospital pro-fee, procedures, imaging pro
# Weights applied separately in _pick_cpt
CPT_OFFICE_EM = (
    "99202", "99203", "99204", "99205",
    "99211", "99212", "99213", "99214", "99215",
)
CPT_HOSP_EM = (
    "99221", "99222", "99223",
    "99231", "99232", "99233",
    "99238", "99239",
    "99281", "99282", "99283", "99284", "99285",
)
CPT_PREVENTIVE = ("99385", "99386", "99395", "99396", "G0439")
CPT_PROCEDURES = (
    "20610",  # joint injection
    "17000",  # destruction lesion
    "11102",  # biopsy
    "43239",  # EGD biopsy
    "45378",  # colonoscopy
    "45380",
    "27447",  # TKA (surgeon)
    "27130",  # THA
    "66984",  # cataract
    "19301",  # breast partial mastectomy
    "93000",  # ECG
    "93306",  # echo
    "71046",  # chest x-ray pro
    "70450",  # CT head pro
    "70553",  # MRI brain pro
    "36415",  # venipuncture
    "90471",  # immunization admin
    "J1100",  # injection drug (pro claim line sometimes)
)
CPT_TELEHEALTH = ("99213", "99214", "99441", "99442", "99443")

DX_PRIMARY = (
    "I10", "E11.9", "E78.5", "J06.9", "J18.9", "M54.5", "M25.561",
    "R07.9", "R10.9", "N39.0", "N17.9", "K21.9", "F41.9", "G43.909",
    "H25.9", "L30.9", "Z00.00", "Z23", "Z51.11", "I25.10", "I48.91",
    "J44.9", "N18.3", "M17.11", "S83.511A",
)
DX_SECONDARY = (
    "Z79.4", "Z87.891", "E66.9", "I25.2", "F17.210", "Z68.30", "N40.0",
)

# CARC-style / payer remark patterns common on professional remits
REASON_CODES = (
    "CO-4", "CO-11", "CO-16", "CO-18", "CO-29", "CO-45", "CO-50", "CO-97",
    "CO-109", "CO-151", "CO-197", "CO-204", "CO-B7",
    "PR-1", "PR-2", "PR-3", "PR-96",
    "OA-18", "OA-23",
    "N130", "N362", "N479", "M15", "MA130", "119",
)

REMIT_PHRASES = (
    "THIS SERVICE IS NOT COVERED BY THE PLAN",
    "PRIOR AUTHORIZATION ABSENT OR INVALID",
    "PROCEDURE CODE INCONSISTENT WITH MODIFIER USED",
    "DUPLICATE PROFESSIONAL CLAIM / SERVICE",
    "CLAIM TIMELY FILING LIMIT EXCEEDED",
    "MISSING OR INVALID MODIFIER",
    "MEDICAL NECESSITY NOT ESTABLISHED FOR LEVEL BILLED",
    "BENEFIT MAXIMUM FOR THIS SERVICE HAS BEEN REACHED",
    "PROVIDER NOT ELIGIBLE TO BILL THIS SERVICE",
    "NCCI BUNDLING - SERVICE INCLUDED IN PRIMARY PROC",
    "FREQUENCY LIMIT EXCEEDED FOR THIS CPT",
    "DIAGNOSIS INCONSISTENT WITH PROCEDURE",
    "COB INFORMATION REQUIRED - OTHER PAYER PRIMARY",
    "NUM DAYS/UNITS SRV EXCEEDS ACCEPT MAX",
    "ASSISTANT SURGEON NOT PAYABLE FOR THIS PROCEDURE",
    "PLACE OF SERVICE INCONSISTENT WITH PROCEDURE",
)

DEFERRAL_REASONS = (
    "",
    "",
    "",
    "Awaiting medical records",
    "Awaiting op report",
    "Patient contact for COB",
    "Payer portal downtime",
    "Auth reconsideration",
    "Coding review pending",
    "Appeal packet prep",
)

MODIFIERS_PRO = (
    "",
    "",
    "",
    "25",   # significant E&M
    "59",   # distinct procedural
    "XS",
    "XE",
    "GT",   # telehealth legacy
    "95",   # telehealth
    "26",   # professional component
    "TC",   # technical (less common pure pro)
    "AS",   # assistant at surgery PA/NP
    "80",   # assistant surgeon
    "RT",
    "LT",
    "50",   # bilateral
    "76",   # repeat
    "GW",   # hospice unrelated
)

PROVIDER_SPECIALTIES = (
    "FAMILY MED", "IM", "CARDIO", "ORTHO", "GI", "DERM", "NEURO",
    "ONC", "EM", "ANES", "GSURG", "OBGYN", "PULM", "ENDO", "RHEUM",
    "URO", "OPHTH", "PMR", "RAD PRO",
)

# Professional charge anchors (approximate allowed-ish billed before write-off)
# Office E&M often $75–$350; procedures/surgery much higher
BILLED_BY_FAMILY = {
    "office_em": (85, 120, 160, 220, 280, 350, 425),
    "hosp_em": (150, 220, 310, 420, 550, 700),
    "preventive": (140, 180, 220, 260),
    "procedure": (250, 450, 800, 1500, 3200, 5500, 12000, 28000),
    "telehealth": (90, 130, 175, 220),
    "ancillary": (25, 45, 75, 120, 200, 400),
}


def date_to_excel_serial(d: date) -> int:
    """Convert a calendar date to a Windows Excel serial day number."""
    return (d - _EXCEL_EPOCH).days


def excel_serial_to_date(serial: int) -> date:
    """Convert a Windows Excel serial day number to a calendar date."""
    return _EXCEL_EPOCH + timedelta(days=int(serial))


def load_schema_fields(schema_path: str | Path) -> list[dict[str, Any]]:
    """Load field definitions from wq_schema-style JSON."""
    path = Path(schema_path)
    if not path.is_file():
        raise FileNotFoundError(f"Schema not found: {path}")
    with path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if isinstance(data, dict) and "fields" in data:
        fields = list(data["fields"])
    elif isinstance(data, list):
        fields = list(data)
    else:
        raise ValueError("Schema must be a JSON object with 'fields' or a field array")
    if not fields:
        raise ValueError("Schema has no fields")
    return fields


def resolve_fieldnames(
    *,
    schema_path: str | Path | None,
    template_csv: str | Path | None,
) -> tuple[list[str], dict[str, dict[str, Any]]]:
    """
    Return (fieldnames in output order, meta by field_name).

    Prefer template CSV header order when provided; fall back to schema order.
    """
    meta: dict[str, dict[str, Any]] = {}
    schema_order: list[str] = []

    if schema_path:
        for f in load_schema_fields(schema_path):
            name = str(f.get("field_name") or "").strip()
            if not name:
                continue
            schema_order.append(name)
            meta[name] = {
                "data_type": str(f.get("data_type") or "str").lower(),
                "nullable": bool(f.get("nullable", True)),
            }

    if template_csv and Path(template_csv).is_file():
        headers, _ = read_csv_rows(template_csv)
        fieldnames = list(headers)
        for h in fieldnames:
            meta.setdefault(h, {"data_type": "str", "nullable": True})
        return fieldnames, meta

    if schema_order:
        return schema_order, meta

    raise ValueError("Provide a readable --schema and/or --template-csv")


def _fmt_money(value: float) -> str:
    return f"{value:.2f}"


def _patient_name(index: int, rng: random.Random) -> str:
    first = "John" if (index % 2 == 1) else "Jane"
    if rng.random() < 0.08:
        first = "Jane" if first == "John" else "John"
    return f"Doe,{first}{index}"


def _dob_excel_serial(rng: random.Random, as_of: date) -> int:
    """Random DOB with day-of-month fixed at 01; returned as Excel serial int."""
    age_years = rng.randint(18, 90)
    month = rng.randint(1, 12)
    year = as_of.year - age_years
    if year < 1925:
        year = 1925
    dob = date(year, month, 1)
    return date_to_excel_serial(dob)


def _service_date_and_bucket(rng: random.Random, as_of: date) -> tuple[date, str, int]:
    """
    Professional AR aging distribution including 365+ day balances.

    Buckets approximate a denial/follow-up WQ (skewed older than pure production AR).
    """
    # weights: 0-30, 31-60, 61-90, 91-120, 121-180, 181-270, 271-365, 366-450, 451-540, 541-730
    bucket = rng.choices(
        population=(
            "0_30",
            "31_60",
            "61_90",
            "91_120",
            "121_180",
            "181_270",
            "271_365",
            "366_450",
            "451_540",
            "541_730",
        ),
        weights=(12, 14, 14, 12, 12, 10, 8, 8, 6, 4),
        k=1,
    )[0]
    ranges = {
        "0_30": (0, 30),
        "31_60": (31, 60),
        "61_90": (61, 90),
        "91_120": (91, 120),
        "121_180": (121, 180),
        "181_270": (181, 270),
        "271_365": (271, 365),
        "366_450": (366, 450),
        "451_540": (451, 540),
        "541_730": (541, 730),
    }
    lo, hi = ranges[bucket]
    days_ago = rng.randint(lo, hi)
    return as_of - timedelta(days=days_ago), bucket, days_ago


def _mmddyyyy(d: date) -> str:
    return d.strftime("%m/%d/%Y")


def _pick_cpt_family(rng: random.Random) -> tuple[str, str]:
    """Return (family_key, cpt_code)."""
    family = rng.choices(
        population=("office_em", "hosp_em", "preventive", "procedure", "telehealth", "ancillary"),
        weights=(42, 14, 6, 22, 8, 8),
        k=1,
    )[0]
    if family == "office_em":
        # 99213/99214 dominate professional primary care
        code = rng.choices(
            CPT_OFFICE_EM,
            weights=(3, 8, 18, 10, 2, 6, 22, 20, 8),
            k=1,
        )[0]
    elif family == "hosp_em":
        code = rng.choice(CPT_HOSP_EM)
    elif family == "preventive":
        code = rng.choice(CPT_PREVENTIVE)
    elif family == "procedure":
        code = rng.choice(CPT_PROCEDURES)
    elif family == "telehealth":
        code = rng.choice(CPT_TELEHEALTH)
    else:
        code = rng.choice(("36415", "90471", "93000", "J1100", "71046"))
    return family, code


def _pick_billed(rng: random.Random, family: str) -> float:
    anchors = BILLED_BY_FAMILY.get(family, BILLED_BY_FAMILY["office_em"])
    base = float(rng.choice(anchors))
    # light jitter; procedures wider
    spread = 0.22 if family == "procedure" else 0.12
    billed = round(base * rng.uniform(1.0 - spread, 1.0 + spread), 2)
    return max(15.0, billed)


def _correlated_denial(
    rng: random.Random,
    ar_days: int,
    family: str,
) -> tuple[str, str, str, int]:
    """
    Return (code_category, reason_list, remit_phrase, denial_count)
    biased by age and service family (professional denial patterns).
    """
    # Aged inventory: more timely filing / enrollment / long appeals
    if ar_days >= 365:
        cats = (
            "Timely Filing",
            "Timely Filing",
            "Provider Enrollment",
            "Medical Necessity",
            "Appeal Exhausted",
            "COB / Other Payer",
            "Non-Covered",
        )
        # map unknown category label if not in CODE_CATEGORIES list for export consistency
        cat_map = {
            "Appeal Exhausted": "Medical Necessity",
        }
        cat = rng.choice(cats)
        cat = cat_map.get(cat, cat)
        if cat not in CODE_CATEGORIES:
            cat = "Timely Filing"
        denial_count = rng.choices([1, 2, 3, 4, 5], weights=(25, 30, 25, 15, 5))[0]
    elif ar_days >= 180:
        cat = rng.choices(
            CODE_CATEGORIES,
            weights=(10, 12, 12, 14, 12, 8, 8, 8, 6, 5, 3, 2),
            k=1,
        )[0]
        denial_count = rng.choices([1, 2, 3, 4], weights=(40, 35, 18, 7))[0]
    else:
        cat = rng.choices(
            CODE_CATEGORIES,
            weights=(12, 16, 14, 6, 10, 10, 12, 6, 6, 4, 2, 2),
            k=1,
        )[0]
        denial_count = rng.choices([1, 2, 3], weights=(70, 22, 8))[0]

    # Category-linked reason codes
    cat_reasons: dict[str, tuple[str, ...]] = {
        "Timely Filing": ("CO-29", "CO-29", "N130"),
        "Authorization": ("CO-197", "CO-15", "N362"),
        "Coding": ("CO-4", "CO-11", "CO-16", "MA130"),
        "Modifier": ("CO-4", "N479", "M15"),
        "Bundling / NCCI": ("CO-97", "CO-97", "OA-23"),
        "Duplicate": ("CO-18", "OA-18"),
        "Eligibility": ("CO-27", "CO-26", "PR-96"),
        "COB / Other Payer": ("OA-23", "CO-22", "MA04"),
        "Medical Necessity": ("CO-50", "CO-50", "CO-151"),
        "Non-Covered": ("CO-96", "CO-204", "PR-96"),
        "Frequency Limit": ("CO-151", "CO-119", "119"),
        "Provider Enrollment": ("CO-B7", "CO-109", "N290"),
    }
    pool = list(cat_reasons.get(cat, REASON_CODES))
    # Ensure sample size does not exceed pool
    k = 1 if rng.random() < 0.55 else min(2, len(pool))
    reasons = rng.sample(pool, k=k) if len(pool) >= k else pool
    reason_list = ", ".join(reasons)

    # Remit phrase preference by category
    phrase_by_cat: dict[str, tuple[str, ...]] = {
        "Timely Filing": (
            "CLAIM TIMELY FILING LIMIT EXCEEDED",
            "CLAIM TIMELY FILING LIMIT EXCEEDED",
        ),
        "Authorization": (
            "PRIOR AUTHORIZATION ABSENT OR INVALID",
        ),
        "Coding": (
            "DIAGNOSIS INCONSISTENT WITH PROCEDURE",
            "PROCEDURE CODE INCONSISTENT WITH MODIFIER USED",
        ),
        "Modifier": (
            "MISSING OR INVALID MODIFIER",
            "PROCEDURE CODE INCONSISTENT WITH MODIFIER USED",
        ),
        "Bundling / NCCI": (
            "NCCI BUNDLING - SERVICE INCLUDED IN PRIMARY PROC",
        ),
        "Duplicate": (
            "DUPLICATE PROFESSIONAL CLAIM / SERVICE",
        ),
        "Medical Necessity": (
            "MEDICAL NECESSITY NOT ESTABLISHED FOR LEVEL BILLED",
        ),
        "Non-Covered": (
            "THIS SERVICE IS NOT COVERED BY THE PLAN",
        ),
        "Frequency Limit": (
            "FREQUENCY LIMIT EXCEEDED FOR THIS CPT",
            "NUM DAYS/UNITS SRV EXCEEDS ACCEPT MAX",
        ),
        "Provider Enrollment": (
            "PROVIDER NOT ELIGIBLE TO BILL THIS SERVICE",
        ),
        "COB / Other Payer": (
            "COB INFORMATION REQUIRED - OTHER PAYER PRIMARY",
        ),
    }
    phrases = phrase_by_cat.get(cat, REMIT_PHRASES)
    remit = rng.choice(phrases)

    # Office E&M + modifier 25 denials are common in pro billing
    if family == "office_em" and rng.random() < 0.12:
        cat = "Modifier"
        reason_list = "CO-4, N479"
        remit = "PROCEDURE CODE INCONSISTENT WITH MODIFIER USED"

    return cat, reason_list, remit, denial_count


def _appeal_and_replace_days(rng: random.Random, ar_days: int) -> tuple[int, int]:
    """
    Days until appeal / replacement deadlines.
    Older AR more often near or past appeal windows.
    """
    if ar_days >= 365:
        # many exhausted or short window left
        appeal = rng.choices(
            [-30, -5, 0, 5, 15, 30, 45],
            weights=(15, 15, 15, 20, 15, 12, 8),
            k=1,
        )[0]
    elif ar_days >= 180:
        appeal = rng.randint(-10, 90)
    else:
        appeal = rng.randint(15, 180)
    replace = appeal + rng.randint(-15, 45)
    # export as non-negative days remaining when past? keep signed for urgency signal
    # schema is int; sample used positive. Clamp display to max(0,x) for most; allow 0.
    appeal_out = max(0, appeal)
    replace_out = max(0, replace)
    # For urgency testing keep some true zeros on old inventory
    if ar_days >= 365 and rng.random() < 0.35:
        appeal_out = 0
        replace_out = 0
    return appeal_out, replace_out


def _wq_age(rng: random.Random, ar_days: int) -> int:
    """Days on WQ tab: subset of AR life; aged claims often parked longer."""
    if ar_days <= 0:
        return 0
    if ar_days >= 365:
        # often sat on WQ a long time
        return rng.randint(max(30, ar_days // 4), ar_days)
    if ar_days >= 120:
        return rng.randint(5, ar_days)
    return rng.randint(0, max(1, min(ar_days, 45)))


def _provider_name(rng: random.Random) -> str:
    n = rng.randint(1, 85)
    spec = rng.choice(PROVIDER_SPECIALTIES)
    # Last, First style used in many practice systems
    return f"DOCTOR, SYNTH{n} {spec}"


def generate_row(
    index: int,
    fieldnames: list[str],
    meta: dict[str, dict[str, Any]],
    rng: random.Random,
    as_of: date,
) -> dict[str, str]:
    """Build one synthetic Professional Billing WQ row."""
    svc, _bucket, ar_days = _service_date_and_bucket(rng, as_of)
    family, cpt = _pick_cpt_family(rng)
    billed = _pick_billed(rng, family)

    # Outstanding insurance: full balance more common on new denials; partial on worked
    if ar_days >= 365:
        out_ratio = rng.uniform(0.55, 1.0)
    elif ar_days >= 120:
        out_ratio = rng.uniform(0.35, 1.0)
    else:
        out_ratio = rng.uniform(0.20, 1.0)
    out_ins = round(billed * out_ratio, 2)
    if out_ins > billed:
        out_ins = billed
    # small chance of very small residual (underpaid)
    if rng.random() < 0.08:
        out_ins = round(rng.uniform(5.0, min(75.0, billed)), 2)

    cat, reason_list, remit, denial_count = _correlated_denial(rng, ar_days, family)
    appeal_left, replace_left = _appeal_and_replace_days(rng, ar_days)
    wq_age = _wq_age(rng, ar_days)

    payer = rng.choice(PAYERS)
    if payer == "MEDICARE" and rng.random() < 0.55:
        plan = "MEDICARE TRADITIONAL" if rng.random() < 0.5 else "MEDICARE ADVANTAGE PPO"
    elif payer == "MEDICAID":
        plan = "MEDICAID MCO"
    else:
        plan = f"{payer} {rng.choice(PLAN_PRODUCTS)}"

    svc_provider = _provider_name(rng)
    # Group billing NPI often same as rendering for employed physicians
    if rng.random() < 0.75:
        billing_provider = svc_provider
    else:
        billing_provider = f"GROUP PRACTICE SYNTH{rng.randint(1, 12)}"

    # Diagnosis: primary + optional secondary (pro claims often 1–3)
    dx_list = [rng.choice(DX_PRIMARY)]
    if rng.random() < 0.45:
        dx_list.append(rng.choice(DX_SECONDARY))
    if rng.random() < 0.15:
        dx_list.append(rng.choice(DX_PRIMARY))
    diagnosis = ", ".join(dict.fromkeys(dx_list))  # stable unique order

    # Multi-line professional invoices occasional (related_charge_lines)
    if family == "procedure":
        related = rng.choices([1, 2, 3, 4, 5], weights=(40, 30, 15, 10, 5))[0]
    elif family == "office_em":
        related = rng.choices([1, 2, 3], weights=(75, 20, 5))[0]
    else:
        related = rng.choices([1, 2, 3, 4], weights=(60, 25, 10, 5))[0]

    # CPT list may include add-on / second line code
    cpt_field = cpt
    if related >= 2 and rng.random() < 0.4:
        extra = rng.choice(CPT_OFFICE_EM + CPT_PROCEDURES)
        if extra != cpt:
            cpt_field = f"{cpt}, {extra}"

    # Modifiers: telehealth / PC / E&M-25 patterns
    if family == "telehealth":
        mod = rng.choice(("95", "GT", "95"))
    elif family == "office_em" and related >= 2:
        mod = rng.choice(("25", "25", "59", ""))
    elif "70450" in cpt or "70553" in cpt or "71046" in cpt or "93306" in cpt:
        mod = rng.choice(("26", "26", ""))  # professional component
    else:
        mod = rng.choice(MODIFIERS_PRO)

    # Follow-up score / priority: aged + high $ tend higher
    base_score = rng.randint(5, 55)
    if ar_days >= 365:
        base_score += rng.randint(20, 40)
    elif ar_days >= 180:
        base_score += rng.randint(10, 25)
    if out_ins >= 1000:
        base_score += rng.randint(5, 20)
    if appeal_left <= 15:
        base_score += rng.randint(5, 15)
    score = max(0, min(100, base_score))
    follow_pri = score if rng.random() < 0.7 else max(0, min(100, score + rng.randint(-10, 10)))

    # Last worked: older claims more often worked recently (or stale)
    if ar_days >= 365:
        if rng.random() < 0.25:
            last_worked_s = ""  # abandoned / unworked
        else:
            last_worked_s = _mmddyyyy(as_of - timedelta(days=rng.randint(0, 90)))
    elif rng.random() < 0.12:
        last_worked_s = ""
    else:
        last_worked_s = _mmddyyyy(as_of - timedelta(days=rng.randint(0, min(60, max(1, ar_days)))))

    # Denial status by age
    if ar_days >= 365:
        denial_status = rng.choices(
            DENIAL_STATUSES,
            weights=(10, 10, 15, 25, 20, 12, 8),
            k=1,
        )[0]
    else:
        denial_status = rng.choice(DENIAL_STATUSES)

    # Deferral more common on aged complex accounts
    if ar_days >= 180 and rng.random() < 0.45:
        deferral = rng.choice([d for d in DEFERRAL_REASONS if d])
    else:
        deferral = rng.choice(DEFERRAL_REASONS)

    dept = rng.choice(DEPARTMENTS)
    # Light specialty–CPT coherence
    if cpt.startswith("992") and cpt[3] in "012" and family == "office_em":
        dept = rng.choice(
            ("PRIMARY CARE", "FAMILY MEDICINE", "INTERNAL MEDICINE", "CARDIOLOGY", "ENDOCRINOLOGY")
        )
    if family == "hosp_em":
        dept = rng.choice(("EMERGENCY PRO FEE", "INTERNAL MEDICINE", "CARDIOLOGY", "SURGERY"))

    tax_id = str(rng.randint(100000000, 999999999))
    # NPI: 10-digit synthetic
    npi = str(rng.randint(1000000000, 1999999999))

    # Account / invoice patterns resembling practice-management exports
    account = str(1000000000 + index * 37 + rng.randint(0, 16))
    invoice = f"P{200000000 + index * 3 + rng.randint(0, 2)}"

    comments_defer = ""
    comments_xfer = ""
    if deferral and rng.random() < 0.5:
        comments_defer = rng.choice(
            (
                "Synthetic: waiting records for appeal",
                "Synthetic: COB form requested",
                "Synthetic: coding query to provider",
            )
        )
    if rng.random() < 0.08:
        comments_xfer = "Synthetic: transferred to specialty follow-up team"

    # Suspended / remittance flags
    suspended = ""
    if ar_days >= 270 and rng.random() < 0.12:
        suspended = "Y"
    pending_remit = "Y" if rng.random() < 0.12 else ""

    base: dict[str, str] = {
        "wq_status": rng.choice(WQ_STATUSES),
        "related_charge_lines": str(related),
        "deferral_reason": deferral,
        "patient": _patient_name(index, rng),
        "account": account,
        "score": str(score),
        "out_ins_amt": _fmt_money(out_ins),
        "days_until_appeal_deadline": str(appeal_left),
        "days_until_replacement_deadline": str(replace_left),
        "days_on_wq_tab": str(wq_age),
        "service_date": _mmddyyyy(svc),
        "payer": payer,
        "plan": plan,
        "invoice_num": invoice,
        "last_worked_date": last_worked_s,
        "reason_code_list": reason_list,
        "remittance_code": remit,
        "location": rng.choice(LOCATIONS),
        "denial_status": denial_status,
        "code_category": cat,
        "cpt_codes": cpt_field,
        "modifiers": mod,
        "diagnosis_codes": diagnosis,
        "denial_count": str(denial_count),
        # Pro billing exports often whole dollars on billed; keep mostly int-like
        "billed_amount": str(int(round(billed))) if rng.random() < 0.9 else _fmt_money(billed),
        "svc_provider": svc_provider,
        "billing_provider": billing_provider,
        "suspended_nrp_status": suspended,
        "pending_remittance_run": pending_remit,
        "dob": str(_dob_excel_serial(rng, as_of)),
        "sub_id": f"U{400000000 + index}",
        "group_num": str(rng.randint(1000000, 9999999)),
        "department": dept,
        "billing_provider_tax_id": tax_id,
        "billing_provider_npi": npi,
        "follow_up_priority": str(follow_pri),
        "follow_up_record_id": str(60000000 + index),
        "crd_record_id": str(74000000 + index),
        "wq_defer_user_comment": comments_defer,
        "wq_transfer_user_comment": comments_xfer,
    }

    row: dict[str, str] = {}
    for name in fieldnames:
        if name in base:
            row[name] = base[name]
        else:
            info = meta.get(name, {})
            nullable = bool(info.get("nullable", True))
            dtype = str(info.get("data_type", "str")).lower()
            if nullable and rng.random() < 0.5:
                row[name] = ""
            elif dtype == "int":
                row[name] = str(rng.randint(0, 100))
            elif dtype == "float":
                row[name] = _fmt_money(rng.uniform(0, 100))
            else:
                row[name] = f"SYNTH_{name}_{index}"
    return row


def generate_rows(
    *,
    row_count: int,
    fieldnames: list[str],
    meta: dict[str, dict[str, Any]],
    seed: int,
    as_of: date | None = None,
    start_index: int = 1,
) -> list[dict[str, str]]:
    """Generate a list of synthetic WQ rows with a fixed RNG seed."""
    if row_count < 1:
        raise ValueError("--rows must be >= 1")
    if row_count > 500_000:
        raise ValueError("--rows exceeds safety cap (500000)")
    if start_index < 1:
        raise ValueError("start_index must be >= 1")
    rng = random.Random(seed)
    today = as_of or date.today()
    end = start_index + row_count - 1
    return [
        generate_row(i, fieldnames, meta, rng, today)
        for i in range(start_index, end + 1)
    ]


def _aging_summary(rows: list[dict[str, str]], as_of: date) -> dict[str, Any]:
    """Compute AR-day bucket counts from service_date for result metadata."""
    buckets = {
        "0_30": 0,
        "31_60": 0,
        "61_90": 0,
        "91_120": 0,
        "121_180": 0,
        "181_365": 0,
        "366_450": 0,
        "451_plus": 0,
        "unknown": 0,
    }
    ar_vals: list[int] = []
    for r in rows:
        raw = (r.get("service_date") or "").strip()
        if not raw:
            buckets["unknown"] += 1
            continue
        parsed = None
        for fmt in ("%m/%d/%Y", "%Y-%m-%d", "%m-%d-%Y"):
            try:
                parsed = datetime.strptime(raw, fmt).date()
                break
            except ValueError:
                continue
        if parsed is None:
            buckets["unknown"] += 1
            continue
        ar = (as_of - parsed).days
        ar_vals.append(ar)
        if ar <= 30:
            buckets["0_30"] += 1
        elif ar <= 60:
            buckets["31_60"] += 1
        elif ar <= 90:
            buckets["61_90"] += 1
        elif ar <= 120:
            buckets["91_120"] += 1
        elif ar <= 180:
            buckets["121_180"] += 1
        elif ar <= 365:
            buckets["181_365"] += 1
        elif ar <= 450:
            buckets["366_450"] += 1
        else:
            buckets["451_plus"] += 1

    return {
        "buckets": buckets,
        "ar_days_min": min(ar_vals) if ar_vals else None,
        "ar_days_max": max(ar_vals) if ar_vals else None,
        "ar_days_mean": round(sum(ar_vals) / len(ar_vals), 2) if ar_vals else None,
        "count_ge_365": sum(1 for a in ar_vals if a >= 365),
        "count_ge_450": sum(1 for a in ar_vals if a >= 450),
    }


def generate_csv(
    *,
    row_count: int = 100,
    output_path: str | Path,
    schema_path: str | Path | None = None,
    template_csv: str | Path | None = None,
    seed: int = 42,
    dry_run: bool = False,
    start_index: int = 1,
    append: bool = False,
) -> dict[str, Any]:
    """
    Generate synthetic Professional Billing WQ CSV.

    Returns a result dict suitable for CLI JSON output.
    """
    fieldnames, meta = resolve_fieldnames(
        schema_path=schema_path,
        template_csv=template_csv,
    )

    existing: list[dict[str, str]] = []
    out = Path(output_path)
    if append and out.is_file():
        prev_fields, existing = read_csv_rows(out)
        # Prefer existing header order when appending
        fieldnames = list(prev_fields)
        if existing:
            # Continue patient numbering after highest Doe,*N if possible
            max_idx = start_index - 1
            for r in existing:
                p = r.get("patient") or ""
                for prefix in ("Doe,John", "Doe,Jane"):
                    if p.startswith(prefix):
                        suffix = p[len(prefix) :]
                        if suffix.isdigit():
                            max_idx = max(max_idx, int(suffix))
            start_index = max_idx + 1

    rows = generate_rows(
        row_count=row_count,
        fieldnames=fieldnames,
        meta=meta,
        seed=seed,
        start_index=start_index,
    )

    all_rows = existing + rows if append else rows
    as_of = date.today()
    aging = _aging_summary(all_rows, as_of)

    patients = [r.get("patient", "") for r in all_rows]
    dobs_ok = True
    dob_samples: list[str] = []
    if "dob" in fieldnames:
        for r in all_rows:
            try:
                serial = int(str(r.get("dob", "")).strip())
                d = excel_serial_to_date(serial)
                if d.day != 1:
                    dobs_ok = False
                if len(dob_samples) < 3:
                    dob_samples.append(d.isoformat())
            except (TypeError, ValueError):
                dobs_ok = False

    john = sum(1 for p in patients if p.startswith("Doe,John"))
    jane = sum(1 for p in patients if p.startswith("Doe,Jane"))

    result: dict[str, Any] = {
        "Success": True,
        "Command": "generate",
        "OutputPath": str(out.resolve()),
        "RowCount": len(all_rows),
        "RowsGenerated": len(rows),
        "Append": append,
        "ColumnCount": len(fieldnames),
        "Seed": seed,
        "StartIndex": start_index,
        "DryRun": dry_run,
        "Profile": "professional_billing",
        "PatientJohnCount": john,
        "PatientJaneCount": jane,
        "DobDayAlways01": dobs_ok,
        "DobSamples": dob_samples,
        "Aging": aging,
        "HeadersSample": fieldnames[:8],
        "Message": "Dry-run only; no file written." if dry_run else "Generate complete.",
    }

    if not dry_run:
        write_csv_rows(out, fieldnames, all_rows)
        result["Message"] = "Generate complete."

    return result
