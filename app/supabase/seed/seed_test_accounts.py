"""Creates the three test accounts with the Supabase Admin API.

Run from app/: python3 -I supabase/seed/seed_test_accounts.py
The service role key is read from the Supabase CLI at run time and kept in
memory only. Passwords are generated here, saved to the macOS keychain
(service `money-navigation-test-<slug>`) and to test_accounts.local.md
(gitignored). Nothing secret is printed. Re-running keeps existing accounts
and their passwords, and refreshes profiles and sample records.
"""

import json
import secrets
import string
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

REF = "ufoyezpfxwqfonfyrgcy"
URL = f"https://{REF}.supabase.co"
HERE = Path(__file__).resolve().parent

# Sample records use the app's TripSave shape and the verdict numbers the
# unit tests prove for the printed demo props (CLAUDE.md "Demo data").
MANGO_SOURCE = "market_prices.json, usual 80-110 THB per kilo (October)"
MANGO_COUNTER = {
    "source": MANGO_SOURCE,
    "verdict": "high",
    "counterOfferThb": 110,
    "sentenceTh": "ลดเหลือ 110 บาทได้ไหม",
}
CHATUCHAK = {"place_name": "Chatuchak Weekend Market", "place_lat": 13.7999, "place_lng": 100.5503}
HAGGLE_AI = "speech_to_text+item_matcher+places"

ACCOUNTS = [
    {
        "slug": "visitor",
        "email": "test.visitor@example.com",
        "about": "US visitor in Bangkok: card in USD, English",
        "name": "Test Visitor",
        "profile": {
            "traveler_type": "visitor_in_thailand",
            "home_currency": "USD",
            "card_currency": "USD",
            "language": "en",
            # Sample fee facts, as a traveler would state them for their card.
            "card_fee_percent": 3.0,
            "atm_fee_policy": "charges_fixed",
            "atm_fee_value": 5.0,
        },
        "polite_ending": "male",
        "records": [
            {
                "client_id": "seed-atm-1",
                "kind": "atmConversion",
                "kept_thb": 245.75,
                "saved_at": "2026-10-15T03:12:00Z",
                "place_name": "ATM, Sukhumvit Soi 11",
                "place_lat": 13.7426,
                "place_lng": 100.5560,
                "verdict": "declineConversion",
                "ai_path": "mlkit_ocr",
                "detail": {
                    "source": "ATM prop: withdrawal 4,000 THB, fee 220 THB, "
                    "1 USD = 30.86 THB, mark-up 5.50 %",
                    "recommended": "declineConversion",
                    "chargedThb": 4220,
                    "chargedUsd": 144.71,
                    "extraCostUsd": 7.96,
                    "extraCostThb": 245.75,
                },
            },
            {
                "client_id": "seed-haggle-1",
                "kind": "haggle",
                "kept_thb": 40,
                "saved_at": "2026-10-15T05:40:00Z",
                "item_key": "mango",
                "asked_thb": 150,
                "paid_thb": 110,
                **CHATUCHAK,
                "verdict": "high",
                "ai_path": HAGGLE_AI,
                "detail": MANGO_COUNTER,
                "rounds": [
                    {"round_no": 1, "seller_said": "มะม่วงกิโลละร้อยห้าสิบ",
                     "seller_price_thb": 150, "our_offer_thb": 110,
                     "our_sentence": "ลดเหลือ 110 บาทได้ไหม", "outcome": "accepted"},
                ],
            },
            {
                # Two days earlier at the same market: asked 130, settled at 90.
                "client_id": "seed-haggle-0",
                "kind": "haggle",
                "kept_thb": 40,
                "saved_at": "2026-10-13T08:20:00Z",
                "item_key": "mango",
                "asked_thb": 130,
                "paid_thb": 90,
                **CHATUCHAK,
                "verdict": "high",
                "ai_path": HAGGLE_AI,
                "detail": MANGO_COUNTER,
                "rounds": [
                    {"round_no": 1, "seller_said": "มะม่วงกิโลละร้อยสามสิบ",
                     "seller_price_thb": 130, "our_offer_thb": 110,
                     "our_sentence": "ลดเหลือ 110 บาทได้ไหม", "outcome": "countered"},
                    {"round_no": 2, "seller_said": "เอาไปเก้าสิบ",
                     "seller_price_thb": 90, "outcome": "accepted"},
                ],
            },
        ],
    },
    {
        "slug": "thai",
        "email": "test.thai@example.com",
        "about": "Thai traveller in Tokyo: card in THB, Thai",
        "name": "ทดสอบ เดินทาง",
        "profile": {
            "traveler_type": "thai_abroad",
            "home_currency": "THB",
            "card_currency": "THB",
            "language": "th",
            "card_fee_percent": 2.5,
            "atm_fee_policy": "unknown",
        },
        "polite_ending": "female",
        "records": [
            {
                "client_id": "seed-terminal-1",
                "kind": "terminalDcc",
                "kept_thb": 494.30,
                "saved_at": "2026-10-15T06:05:00Z",
                "place_name": "Don Quijote Shibuya",
                "place_lat": 35.6604,
                "place_lng": 139.6989,
                "verdict": "payLocal",
                "ai_path": "mlkit_ocr",
                "detail": {
                    "source": "Japanese terminal prop: F1 THB 12,851.82, "
                    "F2 JPY 58,000, demo rate 1 THB = 4.6935 JPY",
                    "payLocal": True,
                    "homeAmount": 12851.82,
                    "localAmountJpy": 58000,
                    "fairHomeAmount": 12357.52,
                    "extraHome": 494.30,
                },
            },
            {
                # Same rule as the demo terminal: 10,000 / 4.6935 = 2,130.61
                # fair, so the THB option (2,215.80) costs 85.19 more.
                "client_id": "seed-terminal-0",
                "kind": "terminalDcc",
                "kept_thb": 85.19,
                "saved_at": "2026-10-14T01:30:00Z",
                "place_name": "Narita Airport Terminal 1",
                "place_lat": 35.7720,
                "place_lng": 140.3929,
                "verdict": "payLocal",
                "ai_path": "mlkit_ocr",
                "detail": {
                    "source": "Sample terminal: F1 THB 2,215.80, F2 JPY 10,000, "
                    "demo rate 1 THB = 4.6935 JPY",
                    "payLocal": True,
                    "homeAmount": 2215.80,
                    "localAmountJpy": 10000,
                    "fairHomeAmount": 2130.61,
                    "extraHome": 85.19,
                },
            },
        ],
    },
    {
        "slug": "new",
        "email": "test.new@example.com",
        "about": "New user: nothing filled in, shows the first-run questions",
        "name": None,
        "profile": None,
        "polite_ending": None,
        "records": [],
    },
]


def service_key() -> str:
    out = subprocess.run(
        ["supabase", "projects", "api-keys", "--project-ref", REF, "-o", "json"],
        capture_output=True, text=True, check=True,
    ).stdout
    keys = json.loads(out[out.index("["):out.rindex("]") + 1])
    for k in keys:
        if k.get("name") == "service_role" and str(k.get("api_key", "")).startswith("ey"):
            return k["api_key"]
    sys.exit("service_role key not found in the CLI output")


def call(key, method, path, body=None, prefer=None):
    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
    }
    if prefer:
        headers["Prefer"] = prefer
    req = urllib.request.Request(
        URL + path, method=method, headers=headers,
        data=None if body is None else json.dumps(body).encode(),
    )
    try:
        with urllib.request.urlopen(req) as res:
            raw = res.read()
            return res.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            detail = json.loads(raw) if raw else None
        except ValueError:
            detail = None
        return e.code, detail


def keychain_password(slug):
    r = subprocess.run(
        ["security", "find-generic-password", "-s", f"money-navigation-test-{slug}", "-w"],
        capture_output=True, text=True,
    )
    return r.stdout.strip() if r.returncode == 0 else None


def save_keychain(slug, email, password):
    subprocess.run(
        ["security", "add-generic-password", "-U", "-s", f"money-navigation-test-{slug}",
         "-a", email, "-w", password],
        check=True, capture_output=True,
    )


def find_user(key, email):
    page = 1
    while True:
        status, data = call(key, "GET", f"/auth/v1/admin/users?page={page}&per_page=200")
        if status != 200:
            sys.exit(f"listing users failed: {status}")
        users = data.get("users", [])
        for u in users:
            if u.get("email") == email:
                return u
        if len(users) < 200:
            return None
        page += 1


def check(status, ok, what):
    if status not in ok:
        sys.exit(f"{what} failed: HTTP {status}")


def main():
    key = service_key()
    lines = [
        "# Test accounts (local only, gitignored)",
        "",
        "Made by supabase/seed/seed_test_accounts.py. Passwords are also in the",
        "macOS keychain as `money-navigation-test-<slug>`.",
        "",
    ]
    alphabet = string.ascii_letters + string.digits
    for a in ACCOUNTS:
        password = keychain_password(a["slug"])
        user = find_user(key, a["email"])
        if password is None:
            password = "".join(secrets.choice(alphabet) for _ in range(16))
            save_keychain(a["slug"], a["email"], password)
            if user is not None:
                status, _ = call(key, "PUT", f"/auth/v1/admin/users/{user['id']}",
                                 {"password": password})
                check(status, (200,), f"{a['slug']}: password reset")
        if user is None:
            meta = {"full_name": a["name"]} if a["name"] else {}
            status, user = call(key, "POST", "/auth/v1/admin/users", {
                "email": a["email"],
                "password": password,
                "email_confirm": True,
                "user_metadata": meta,
            })
            check(status, (200, 201), f"{a['slug']}: create")
        uid = user["id"]

        # The sign-up trigger already made the profile and settings rows.
        profile = {
            "display_name": a["name"],
            "traveler_type": None,
            "home_currency": None,
            "card_currency": None,
            "language": None,
            "onboarded_at": None,
            "card_fee_percent": None,
            "atm_fee_policy": None,
            "atm_fee_value": None,
        }
        if a["profile"]:
            profile.update(a["profile"])
            profile["onboarded_at"] = "2026-10-15T02:00:00Z"
        status, _ = call(key, "PATCH", f"/rest/v1/profiles?id=eq.{uid}", profile,
                         "return=minimal")
        check(status, (200, 204), f"{a['slug']}: profile")
        if a["polite_ending"]:
            status, _ = call(key, "PATCH", f"/rest/v1/settings?user_id=eq.{uid}",
                             {"polite_ending": a["polite_ending"]}, "return=minimal")
            check(status, (200, 204), f"{a['slug']}: settings")
        # Sample rows are marked is_sample; clearing them leaves real use alone.
        for table in ("haggle_rounds", "trip_records"):
            status, _ = call(key, "DELETE",
                             f"/rest/v1/{table}?user_id=eq.{uid}&is_sample=is.true")
            check(status, (200, 204), f"{a['slug']}: clear sample {table}")
        # Seed ids are reserved for samples, including rows from before is_sample.
        status, _ = call(key, "DELETE",
                         f"/rest/v1/trip_records?user_id=eq.{uid}&client_id=like.seed-*")
        check(status, (200, 204), f"{a['slug']}: clear seed ids")
        if a["records"]:
            # PostgREST bulk inserts need the same keys in every row.
            cols = ("item_key", "asked_thb", "paid_thb", "place_name", "place_lat",
                    "place_lng", "verdict", "ai_path")
            rows = [
                {**{c: None for c in cols},
                 **{k: v for k, v in r.items() if k != "rounds"},
                 "user_id": uid, "is_sample": True}
                for r in a["records"]
            ]
            status, saved = call(key, "POST", "/rest/v1/trip_records?select=id,client_id",
                                 rows, "return=representation")
            check(status, (200, 201), f"{a['slug']}: sample records")
            ids = {row["client_id"]: row["id"] for row in saved}
            round_cols = ("seller_said", "seller_price_thb", "our_offer_thb",
                          "our_sentence", "outcome")
            rounds = [
                {**{c: None for c in round_cols}, **rd,
                 "user_id": uid, "record_id": ids[r["client_id"]],
                 "haggle_id": r["client_id"], "item_key": r.get("item_key"),
                 "is_sample": True}
                for r in a["records"] for rd in r.get("rounds", [])
            ]
            if rounds:
                status, _ = call(key, "POST", "/rest/v1/haggle_rounds", rounds,
                                 "return=minimal")
                check(status, (200, 201), f"{a['slug']}: sample haggle rounds")

        lines += [
            f"## {a['slug']}: {a['about']}",
            "",
            f"- Email: `{a['email']}`",
            f"- Password: `{password}`",
            f"- Sample records: {len(a['records'])}",
            "",
        ]
        print(f"{a['slug']}: ok ({len(a['records'])} sample records)")

    out = HERE / "test_accounts.local.md"
    out.write_text("\n".join(lines))
    out.chmod(0o600)
    print(f"wrote {out.name}")


if __name__ == "__main__":
    main()
