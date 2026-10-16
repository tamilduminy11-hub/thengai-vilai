# தேங்காய் விலை · Coconut rates

Free daily coconut and copra market rates for farmers. Tamil and English, ₹ per kg / quintal / tonne, with trend charts. No login, no ads, no charges.

- **App (web):** https://thengai-vilai.web.app (Flutter, Firebase Hosting)
- **Android APK:** https://thengai-vilai.web.app/thengai-vilai.apk (redirects to the latest GitHub release; Firebase's free plan does not allow hosting APK files)
- **Lightweight page:** https://tamilduminy11-hub.github.io/thengai-vilai/ (static HTML, same data)

## Architecture

```
GitHub Actions (every 30 min) -> scraper/fetch.py -> Supabase (rates, series, meta) -> Flutter app (web + Android)
                                                  -> data/*.json in git          -> static index.html (GitHub Pages)
```

- Supabase project `thengai-vilai` (ap-south-1). Row level security: anyone can read, only the service role writes. Schema in `supabase/migrations/`.
- GitHub secrets `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` are used by the fetch job.
- Flutter app in `app/`. Reads Supabase with the public anon key (`app/lib/config.dart`).
- Android release signing: `app/android/key.properties` + keystore in `../thengai-vilai-keys/` (both outside git). **Back up the keystore**; losing it means future APKs can't update installed ones.

## Release

```bash
cd app
flutter build web --release
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk /tmp/thengai-vilai.apk
gh release create vX.Y.Z /tmp/thengai-vilai.apk --title "தேங்காய் விலை X.Y"   # bump version in pubspec.yaml first
cd .. && firebase deploy --only hosting
```

## Where the rates come from

Only public government sources:

| Source | What | Freshness |
|---|---|---|
| [Coconut Development Board](https://coconutboard.in/priceweb/Reports.aspx) | Milling and ball copra, black/green coconut, coconut oil: Kangayam, Pollachi, Kochi, Kozhikode, Tiptur, Coimbatore and more | Daily, sometimes a day late |
| [Agmarknet](https://agmarknet.gov.in) | State averages for coconut, copra, tender coconut (Tamil Nadu, Kerala) | ~2 days late |

Every rate is shown with its own date, so nobody mistakes an older rate for today's.

Unit notes:
- CDB labels every product "Rs/Quintal", but black/green coconut figures are really **per tonne**. The CDB summary page shows the same number ÷ 1000 as Rs/kg. The fetcher converts them correctly.
- Karnataka's Agmarknet coconut entries are per 1000 nuts, so Karnataka is left out of the Agmarknet feed.

## How it runs

- `scraper/fetch.py` (Python stdlib only) reads both sources and writes:
  - `data/history.json`: every rate, with the time it first appeared (`first_seen`) and any later revision
  - `data/latest.json`: latest rate and change per market, for the page
  - `data/series/<id>.json`: small per-market history files for the charts
- `.github/workflows/fetch.yml` runs the fetcher every 30 minutes, 06:00–23:30 IST, and commits any new rates.
- `index.html` is a single static page. Host it on GitHub Pages; it reads the `data/` files.

The first run backfills about a year of CDB history; later runs re-read the last 10 days, because CDB sometimes posts or revises a day late.

## Run locally

```bash
python3 -I scraper/fetch.py
python3 -m http.server 8765
```

Then open http://localhost:8765.

## Be polite to the sources

Fetching every 30 minutes is plenty. Don't lower it; these are small government servers.
