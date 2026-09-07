<p align="center">
  <img src="docs/assets/icon.png" width="120" alt="Karobar Saathi app icon" />
</p>

<h1 align="center">Karobar Saathi</h1>

<p align="center">
  <strong>Spoken transactions → confirmed ledger → explainable financial evidence</strong><br/>
  For Pakistani informal micro-businesses.
</p>

<p align="center">
  <a href="https://github.com/ahsankhizar5/karobar-saathi/actions/workflows/ci.yml">
    <img src="https://github.com/ahsankhizar5/karobar-saathi/actions/workflows/ci.yml/badge.svg" alt="CI" />
  </a>
  <a href="https://github.com/ahsankhizar5/karobar-saathi/releases/latest">
    <img src="https://img.shields.io/github/v/release/ahsankhizar5/karobar-saathi?include_prereleases" alt="Latest release" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/ahsankhizar5/karobar-saathi" alt="License" />
  </a>
  <a href="https://ahsankhizar5.github.io/karobar-saathi">
    <img src="https://img.shields.io/badge/API-homepage-0d6f69" alt="API homepage" />
  </a>
</p>

<p align="center">
  <a href="https://github.com/ahsankhizar5/karobar-saathi/releases/latest">
    <img src="https://img.shields.io/badge/Download%20APK-1.4.0-0d6f69?style=for-the-badge" alt="Download APK" />
  </a>
</p>

<p align="center">
  <img src="docs/demo.gif" width="280" alt="Short demo of adding a transaction by voice" />
</p>

> **This is a working proof-of-concept, not a production product.** Anyone installing the APK should read the [production-readiness caveats](#production-readiness-caveats) below before judging it as one.

## What it does

Karobar Saathi lets a shopkeeper record daily sales, purchases, expenses, and withdrawals by **speaking in Urdu or Roman Urdu**. The app turns that voice note into a structured ledger entry, asks for confirmation when something is unclear, and builds a simple dashboard with profit, trends, and a cash-flow insight.

A separate **consent-gated evidence API** lets lenders or partners request the same financial summary — but only if the shopkeeper has explicitly allowed it.

## Live API homepage

**[ahsankhizar5.github.io/karobar-saathi](https://ahsankhizar5.github.io/karobar-saathi)**

The API homepage includes a live `/health` status check, a full endpoint reference, copy-paste `curl` examples for the consent gate, and an honest limitations block.

The bare API root (`/`) returns a friendly HTML page in browsers and the same JSON as before when called with `Accept: application/json`.

## Screenshots

| Login | Dashboard | Ledger |
|-------|-----------|--------|
| <img src="docs/screenshots/login_en.png" width="240" alt="Login screen" /> | <img src="docs/screenshots/dashboard_en.png" width="240" alt="Dashboard" /> | <img src="docs/screenshots/ledger_ur.png" width="240" alt="Ledger in Urdu" /> |

| Add transaction (English) | Add transaction (Urdu) | Lender view |
|---------------------------|------------------------|-------------|
| <img src="docs/screenshots/transaction_en.png" width="240" alt="Transaction sheet in English" /> | <img src="docs/screenshots/transaction_ur.png" width="240" alt="Transaction sheet in Urdu" /> | <img src="docs/screenshots/lender_en.png" width="240" alt="Lender view" /> |

## What's Real vs. Demo

### Fully working (live in the demo)
- Voice-to-ledger pipeline: voice note → Whisper transcription → LLM/rule parsing → confirmed ledger.
- Typed transaction parsing with user confirmation and clarification questions for ambiguous input.
- Dashboard with profit, 7-day trend, cash position, and a generated business insight.
- Consent-gated evidence endpoint `/api/v1/evidence-profile/{user_id}`.
- Auto-generated Swagger/ReDoc docs at `/docs` and `/redoc`.
- Bilingual English/Urdu UI with full RTL layout, persisted across launches.
- Login screen that remembers the chosen shop and sign-out from the About dialog.
- WhatsApp/ChatGPT-style voice recording feedback: timer, waveform, cancel/send, and auto-stop.

### Demo-simulated (concept only)
- Lender view shows three seeded demo shops, not real applicants.
- "Financial readiness" is a rule-based heuristic, not trained on real repayment outcomes.
- No actual MFB/NBFC partner is connected.

### Path to production
Turning this into a real product requires local data hosting to meet SBP/SECP data-residency expectations, a regulatory sandbox or licensed partner for capital deployment, ASR fine-tuned on Pakistani bazaar vernacular, and real repayment outcome data before any lender will trust the evidence. This release proves the core pipeline and API-readiness, not lender trust itself.

## Project layout

- `karobar_saathi/` — Flutter Android app (Riverpod, `record`)
- `backend/` — FastAPI service (voice parsing, ledger, dashboard, evidence API)
- `backend/seed_audio/` — pre-recorded voice notes for repeatable voice-pipeline demos
- `docs/` — API homepage (`index.html`) and verification logs
- `.github/workflows/` — CI and release automation
- `render.yaml` / `Dockerfile` — Render deployment configuration

## Local backend setup

1. Install Python 3.11 and FFmpeg.
2. Create a virtual environment and install dependencies:

   ```bash
   cd backend
   python -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. Copy `.env.example` to `.env` and add a Groq-compatible LLM API key. The LLM is used for strict structured transaction parsing; the app falls back to conservative parsing when no key is configured.
4. Start the API:

   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

5. Open Swagger at [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).

The first start creates SQLite data and seeds three demo profiles: Ahmad Tea Stall, Naseem General Store, and Fatima Stitching.

## Run the Flutter app

1. Install Flutter 3.24.5 or newer and an Android SDK.
2. Fetch packages:

   ```bash
   cd karobar_saathi
   flutter pub get
   ```

3. For an Android emulator using the locally running backend:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
   ```

4. For a physical phone, replace the URL with a reachable HTTPS backend address:

   ```bash
   flutter run --dart-define=API_BASE_URL=https://your-deployed-api.example
   ```

## Build the release APK

Build only after deploying the backend, so the sideloaded APK does not point to localhost. Before the first public build, generate and retain a local signing key:

```bash
keytool -genkeypair -v -keystore C:/Users/you/karobar-saathi-release.jks -alias karobar-saathi -keyalg RSA -keysize 2048 -validity 10000
```

Create `karobar_saathi/android/key.properties` locally with the matching passwords and key location:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=karobar-saathi
storeFile=C:/Users/you/karobar-saathi-release.jks
```

Both the keystore and `key.properties` are ignored by Git and must never be shared. Then build:

```bash
cd karobar_saathi
flutter build apk --release --dart-define=API_BASE_URL=https://your-deployed-api.example
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Deploy the backend

The included `render.yaml` deploys the Docker service to Render. Set `LLM_API_KEY` and `SECRET_KEY` only in Render's encrypted environment panel; do not add them to the repository. Voice transcription uses Groq's hosted Whisper API (`whisper-large-v3`) with the same `LLM_API_KEY`, so the voice pipeline works even on the free tier. Set `TRANSCRIPTION_PROVIDER=local` to run faster-whisper in-process instead (requires FFmpeg and a suitably provisioned host), or `none` for typed transactions only.

The free-tier SQLite directory is ephemeral. After a service restart, the demo data resets and the same three seeded profiles are recreated. Use persistent storage and a managed database before a production deployment.

## Production-readiness caveats

The app is polished enough to feel like a finished product — deliberately so, because the point is to demo the concept end-to-end. These are the things that would have to change before it could serve a real shopkeeper:

- **Cold starts.** The backend runs on Render's free tier and sleeps after ~15 minutes of inactivity. The first request after idle can take up to about a minute while the service wakes; the app recognizes this and shows a "server waking up" message instead of an error.
- **Ephemeral demo data.** Storage is SQLite on the service's ephemeral disk. Each deploy or restart resets everything back to the three seeded demo profiles — transactions recorded in the app are not durable, and there are no backups or data export.
- **Shared demo identity.** There are no accounts or authentication. The shopkeeper side of the app is hard-wired to a single demo user (`shop_001`), so everyone who installs the APK sees and edits the same ledger. Data is not private.
- **Free-tier limits.** Voice transcription (Groq Whisper) and LLM parsing run on a free-tier API key; sustained or heavy use can hit rate limits and temporarily fail parsing until the quota resets.
- **No real lending.** The lender view shows seeded demo shops with rule-based "readiness" heuristics. No credit decisions, loan offers, or lender integrations exist anywhere in the system.
- **Sideloading only.** The APK is distributed via GitHub Release, not Play Store, so Android will show an unknown-sources warning during install.

## Evidence API

The lender screen and external API use the same computed evidence summary.

```bash
curl -H "X-User-Consent: true" \
  https://karobar-saathi.onrender.com/api/v1/evidence-profile/shop_001
```

Revoking consent in the app (or using `PATCH /api/v1/evidence-profile/shop_001/consent`) makes the same request return HTTP `403`. The API never exposes evidence without both persisted consent and the explicit request header.

## GitHub Release checklist

1. Deploy the backend and determine its HTTPS API URL.
2. Build the APK using that URL via `API_BASE_URL`.
3. Create tag `vX.Y.Z` and attach `app-release.apk` as the release asset.
4. Verify the installed APK can call `/health` and submit a text or voice transaction against the deployed API.

## Verification, changelog, and license

- End-to-end verification logs: [`docs/VERIFICATION.md`](docs/VERIFICATION.md)
- Release history: [`CHANGELOG.md`](CHANGELOG.md)
- License: [`LICENSE`](LICENSE) (MIT)
- The app uses the [Outfit](karobar_saathi/assets/fonts/OFL.txt) font under the SIL Open Font License.
