"""Fetch coconut / copra market rates from public government sources.

Sources
  - Coconut Development Board price portal (coconutboard.in/priceweb/Reports.aspx)
  - Agmarknet 2.0 public dashboard (api.agmarknet.gov.in)

Writes
  data/history.json  every observation, keyed by series id, with first_seen time
  data/latest.json   latest value + change per series, for the website

Stdlib only so it runs anywhere (GitHub Actions, a laptop, a cron box).
Be polite: this is meant to run every ~30 minutes, not in a tight loop.
"""
from __future__ import annotations

import html
import http.cookiejar
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

IST = timezone(timedelta(hours=5, minutes=30))
ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
UA = "Mozilla/5.0 (thengai-vilai free farmer price app)"

CDB_URL = "https://coconutboard.in/priceweb/Reports.aspx"

# CDB product id -> (slug, English, Tamil, unit_of_raw_value)
# unit_of_raw_value is what the number on the CDB page actually means.
# CDB labels everything "Rs/Ql", but green/black coconut are per tonne
# (the CDB summary page shows the same figure /1000 as Rs/kg).
CDB_PRODUCTS = {
    "2": ("milling_copra", "Milling copra", "அரவை கொப்பரை", "quintal"),
    "7": ("ball_copra", "Ball copra", "பந்து கொப்பரை", "quintal"),
    "19": ("coconut_black", "Coconut (black)", "தேங்காய் (கருப்பு)", "tonne"),
    "18": ("coconut_green", "Coconut (green)", "தேங்காய் (பச்சை)", "tonne"),
    "1": ("coconut_oil", "Coconut oil", "தேங்காய் எண்ணெய்", "quintal"),
}

# CDB market id -> (slug, English, Tamil)
CDB_MARKETS = {
    "4": ("kangayam", "Kangayam", "காங்கேயம்"),
    "21": ("kangayam_mkt", "Kangayam (market)", "காங்கேயம் (சந்தை)"),
    "20": ("pollachi", "Pollachi", "பொள்ளாச்சி"),
    "25": ("pollachi_mkt", "Pollachi (market)", "பொள்ளாச்சி (சந்தை)"),
    "26": ("udumalpet", "Udumalpet", "உடுமலைப்பேட்டை"),
    "28": ("coimbatore", "Coimbatore", "கோயம்புத்தூர்"),
    "1": ("kochi", "Kochi", "கொச்சி"),
    "3": ("kozhikode", "Kozhikode", "கோழிக்கோடு"),
    "11": ("tiptur", "Tiptur", "திப்தூர்"),
    "27": ("arisikere", "Arisikere", "அரசிகெரே"),
}

AGM_URL = "https://api.agmarknet.gov.in/v1/dashboard-data/"
# (commodity id, commodity group id, slug, English, Tamil)
AGM_COMMODITIES = [
    (116, 7, "coconut", "Coconut", "தேங்காய்"),
    (111, 3, "copra", "Copra", "கொப்பரை"),
    (161, 5, "tender_coconut", "Tender coconut", "இளநீர்"),
]
AGM_STATES = [
    (31, "tamil_nadu", "Tamil Nadu", "தமிழ்நாடு"),
    (17, "kerala", "Kerala", "கேரளா"),
    # Karnataka is left out on purpose: its coconut entries are per 1000 nuts,
    # not per quintal, so converting them to Rs/kg gives nonsense (~Rs 220/kg).
]

TO_PER_KG = {"quintal": 100.0, "tonne": 1000.0, "kg": 1.0}


def now_ist() -> datetime:
    return datetime.now(IST)


# --------------------------------------------------------------------------
# Coconut Development Board
# --------------------------------------------------------------------------
class CdbClient:
    def __init__(self) -> None:
        jar = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
        self.opener.addheaders = [("User-Agent", UA)]

    def _open(self, data: dict | None = None) -> str:
        body = urllib.parse.urlencode(data, doseq=True).encode() if data else None
        with self.opener.open(CDB_URL, body, timeout=90) as r:
            return r.read().decode("utf-8", "ignore")

    @staticmethod
    def _hidden(page: str) -> dict:
        return dict(re.findall(r'<input type="hidden" name="([^"]+)" id="[^"]*" value="([^"]*)"', page))

    def report(self, start: datetime, end: datetime) -> str:
        page = self._open()
        # Selecting "Daily" posts back and reveals the date boxes.
        form = self._hidden(page)
        form.update({"__EVENTTARGET": "ctl00$contentBody$ddlSelectTime", "ctl00$contentBody$ddlSelectTime": "1"})
        page = self._open(form)
        form = self._hidden(page)
        form.update({
            "__EVENTTARGET": "",
            "ctl00$contentBody$ddlSelectTime": "1",
            "ctl00$contentBody$ddlProduct": list(CDB_PRODUCTS),
            "ctl00$contentBody$ddlMarket": list(CDB_MARKETS),
            "ctl00$contentBody$txtStartDate": start.strftime("%d/%m/%Y"),
            "ctl00$contentBody$txtEndDate": end.strftime("%d/%m/%Y"),
            "ctl00$contentBody$btnLoad": "Show Price",
        })
        return self._open(form)


def _cells(row_html: str) -> list[str]:
    cells = re.findall(r"(?is)<t[dh][^>]*>(.*?)</t[dh]>", row_html)
    return [re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", c))).strip() for c in cells]


def parse_cdb(page: str) -> list[dict]:
    """Turn the CDB report tables into observations."""
    # Names exactly as the CDB tables print them.
    cdb_names = {"milling copra": "2", "ball copra": "7", "coconut black": "19",
                 "coconut green": "18", "coconut oil": "1"}
    cdb_market_names = {"kochi": "1", "kozhikode": "3", "kangayam": "4", "tiptur": "11",
                        "pollachi": "20", "kangeyam(mkt)": "21", "pollachi(mkt)": "25",
                        "udumalpet": "26", "arisikere": "27", "coimbatore": "28"}
    out: list[dict] = []
    header: list[str | None] = []
    for row in re.findall(r"(?is)<tr.*?</tr>", page):
        cells = _cells(row)
        if len(cells) >= 3 and cells[0] == "Product" and cells[1] == "Date":
            header = []
            for h in cells[2:]:
                m = re.match(r"(.+?)-Price", h)
                header.append(cdb_market_names.get(m.group(1).strip().lower()) if m else None)
            continue
        if not header or len(cells) < 3:
            continue
        pid = cdb_names.get(cells[0].strip().lower())
        if pid is None or not re.match(r"\d{2}-\d{2}-\d{4}$", cells[1]):
            continue
        day = datetime.strptime(cells[1], "%d-%m-%Y").date().isoformat()
        slug, en, ta, unit = CDB_PRODUCTS[pid]
        for mid, raw in zip(header, cells[2:]):
            if mid is None:
                continue
            raw = raw.replace(",", "").strip()
            if not re.match(r"^\d+(\.\d+)?$", raw):
                continue
            value = float(raw)
            if value <= 0:
                continue
            mslug = CDB_MARKETS[mid][0]
            out.append({
                "series": f"cdb.{slug}.{mslug}",
                "date": day,
                "per_kg": round(value / TO_PER_KG[unit], 2),
                "raw": value,
                "raw_unit": unit,
            })
    return out


def series_meta_cdb() -> dict:
    meta = {}
    for pid, (slug, en, ta, unit) in CDB_PRODUCTS.items():
        for mid, (mslug, men, mta) in CDB_MARKETS.items():
            meta[f"cdb.{slug}.{mslug}"] = {
                "source": "cdb", "product": slug, "product_en": en, "product_ta": ta,
                "market": mslug, "market_en": men, "market_ta": mta,
            }
    return meta


# --------------------------------------------------------------------------
# Agmarknet 2.0 (state level, latest 3 days per call)
# --------------------------------------------------------------------------
def fetch_agmarknet(day: datetime) -> list[dict]:
    out: list[dict] = []
    for cid, gid, slug, _en, _ta in AGM_COMMODITIES:
        for sid, sslug, _sen, _sta in AGM_STATES:
            body = json.dumps({
                "dashboard": "marketwise_price_arrival", "date": day.strftime("%Y-%m-%d"),
                "group": [gid], "commodity": [cid], "state": sid,
                "format": "json", "limit": 10, "page": 1,
            }).encode()
            req = urllib.request.Request(AGM_URL, body, {"Content-Type": "application/json", "User-Agent": UA})
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    payload = json.load(r)
            except Exception as e:  # noqa: BLE001 - one bad call must not kill the run
                print(f"agmarknet {slug}/{sslug}: {e}", file=sys.stderr)
                time.sleep(4)
                continue
            data = payload.get("data") or {}
            recs = data.get("records") if isinstance(data, dict) else None
            cols = data.get("columns") if isinstance(data, dict) else None
            if recs:
                rec = recs[0]
                # Column titles carry the actual dates for as_on / 1 day ago / 2 days ago.
                titles = {}
                for grp in cols or []:
                    for c in grp.get("columns", []):
                        titles[c.get("key")] = c.get("title")
                for key in ("as_on_price", "one_day_ago_price", "two_day_ago_price"):
                    v, t = rec.get(key), titles.get(key)
                    if not v or not t:
                        continue
                    try:
                        d = datetime.strptime(t, "%d %b, %Y").date().isoformat()
                        value = float(v)
                    except ValueError:
                        continue
                    if value <= 0:
                        continue
                    out.append({
                        "series": f"agm.{slug}.{sslug}",
                        "date": d,
                        "per_kg": round(value / 100.0, 2),
                        "raw": value,
                        "raw_unit": "quintal",
                    })
            time.sleep(4)  # Agmarknet throttles bursts
    return out


def series_meta_agm() -> dict:
    meta = {}
    for _cid, _gid, slug, en, ta in AGM_COMMODITIES:
        for _sid, sslug, sen, sta in AGM_STATES:
            meta[f"agm.{slug}.{sslug}"] = {
                "source": "agmarknet", "product": slug, "product_en": en, "product_ta": ta,
                "market": sslug, "market_en": f"{sen} (state avg)", "market_ta": f"{sta} (சராசரி)",
            }
    return meta


# --------------------------------------------------------------------------
# Merge + publish
# --------------------------------------------------------------------------
def load_json(path: Path, default):
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def merge(history: dict, obs: list[dict], seen_at: str) -> int:
    """history = {series: {date: {per_kg, raw, raw_unit, first_seen, updated}}}"""
    changed = 0
    for o in obs:
        days = history.setdefault(o["series"], {})
        cur = days.get(o["date"])
        rec = {"per_kg": o["per_kg"], "raw": o["raw"], "raw_unit": o["raw_unit"]}
        if cur is None:
            days[o["date"]] = {**rec, "first_seen": seen_at, "updated": seen_at}
            changed += 1
        elif cur["per_kg"] != o["per_kg"]:
            # Source revised a past figure: keep first_seen, record the revision time.
            cur.update(rec)
            cur["updated"] = seen_at
            changed += 1
    return changed


def build_latest(history: dict, meta: dict, generated: str) -> dict:
    items = []
    for sid, days in history.items():
        if not days or sid not in meta:
            continue
        dates = sorted(days)
        last = days[dates[-1]]
        prev = days[dates[-2]] if len(dates) > 1 else None
        items.append({
            "id": sid, **meta[sid],
            "date": dates[-1],
            "per_kg": last["per_kg"],
            "first_seen": last["first_seen"],
            "change_per_kg": round(last["per_kg"] - prev["per_kg"], 2) if prev else None,
            "prev_date": dates[-2] if prev else None,
        })
    return {"generated": generated, "items": items}


def main() -> int:
    DATA.mkdir(exist_ok=True)
    seen = now_ist()
    seen_at = seen.isoformat(timespec="minutes")
    history = load_json(DATA / "history.json", {})
    first_run = not history

    obs: list[dict] = []
    try:
        # First run backfills ~1 year; later runs only re-read the last 10 days
        # (CDB sometimes posts or revises a day late).
        start = seen - timedelta(days=365 if first_run else 10)
        page = CdbClient().report(start, seen)
        cdb_obs = parse_cdb(page)
        print(f"cdb: {len(cdb_obs)} observations")
        obs += cdb_obs
    except Exception as e:  # noqa: BLE001
        print(f"cdb failed: {e}", file=sys.stderr)

    try:
        agm_obs = fetch_agmarknet(seen)
        print(f"agmarknet: {len(agm_obs)} observations")
        obs += agm_obs
    except Exception as e:  # noqa: BLE001
        print(f"agmarknet failed: {e}", file=sys.stderr)

    if not obs:
        print("no data fetched; leaving files untouched", file=sys.stderr)
        return 1

    changed = merge(history, obs, seen_at)
    meta = {**series_meta_cdb(), **series_meta_agm()}
    (DATA / "history.json").write_text(json.dumps(history, ensure_ascii=False, sort_keys=True, indent=1))
    (DATA / "latest.json").write_text(json.dumps(build_latest(history, meta, seen_at), ensure_ascii=False, indent=1))
    # Small per-series files so a phone only downloads the chart it opens.
    series_dir = DATA / "series"
    series_dir.mkdir(exist_ok=True)
    for sid, days in history.items():
        rows = [[d, days[d]["per_kg"]] for d in sorted(days)]
        (series_dir / f"{sid}.json").write_text(json.dumps(rows, separators=(",", ":")))
    print(f"{changed} new/changed values at {seen_at}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
