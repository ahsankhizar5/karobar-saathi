# Karobar Saathi

Karobar Saathi turns spoken daily business transactions into a confirmed ledger and explainable financial evidence for Pakistani informal micro-businesses.

## Project layout

- `karobar_saathi/` — Flutter Android app (Riverpod, `record`)
- `backend/` — FastAPI service (voice parsing, ledger, dashboard, evidence API)
- `render.yaml` / `Dockerfile` — Render deployment configuration

## Local backend setup

1. Install Python 3.11 and FFmpeg.
2. Create a virtual environment, then install dependencies:

   ```bash
   cd backend
   python -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. Copy `.env.example` to `.env` and add a Groq-compatible LLM API key. The LLM is used for strict structured transaction parsing; the application falls back to conservative parsing when no key is configured.
4. Start the API:

   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

5. Open Swagger at `http://127.0.0.1:8000/docs`.

The initial start creates SQLite data and seeds exactly three concept-demo profiles: Ahmad Tea Stall, Naseem General Store, and Fatima Stitching.

## Run the Flutter app

1. Install Flutter 3.27 or newer and an Android SDK.
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

Build only after deploying the backend, so the sideloaded APK does not point to localhost or the emulator. Before the first public build, generate and retain a local signing key:

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

The included `render.yaml` deploys the Docker service to Render. Set `LLM_API_KEY` and `SECRET_KEY` only in Render's encrypted environment panel; do not add them to the repository. The free blueprint disables Whisper to avoid model-download and memory failures, so typed transactions remain available while audio transcription requires a suitably provisioned host with `WHISPER_ENABLED=true`.

The free-tier SQLite directory is ephemeral. After a service restart, the demo data resets and the same three seeded profiles are recreated. Use persistent storage and a managed database before a production deployment.

## Evidence API

The lender screen and external API use the same computed evidence summary.

```bash
curl -H "X-User-Consent: true" \
  http://127.0.0.1:8000/api/v1/evidence-profile/shop_001
```

Revoking consent in the app (or using `PATCH /api/v1/evidence-profile/shop_001/consent`) makes the same request return HTTP `403`. This is intentional: the API never exposes evidence without both persisted consent and the explicit request header.

## What's Real vs. Demo

### Fully Working (Live in Demo)
✅ Typed transaction → LLM/rule parsing → confirmed database ledger
✅ User confirmation/correction flow (no hallucinated entries)
✅ Dashboard with profit, trends, cash-flow insight
✅ REST API endpoint `/api/v1/evidence-profile/{user_id}` with consent gate
✅ Auto-generated API docs at `/docs`
✅ Installable APK (GitHub Release), works against live backend

### Available on Suitably Provisioned Hosting
🔶 Voice-to-ledger pipeline: voice note → Whisper → LLM parsing → database
   requires FFmpeg and `WHISPER_ENABLED=true`; it is disabled on the Render
   free tier to avoid model-download and memory failures.

### Demo-Simulated (Concept Only)
🔶 Lender View: 3 seeded demo profiles (not real users)
🔶 "Financial Readiness" summary: rule-based heuristics, not trained on
   real repayment outcomes
🔶 Partner integrations: no actual MFB partnerships — architecture is
   API-ready, no live lender connected

### Path to Production (not built, stated for context)
This hackathon build proves the core pipeline and the API-readiness of the
architecture. Turning this into a real product requires: local data hosting
to meet SBP/SECP data-residency expectations, a regulatory sandbox
application or partnership with a licensed MFB/NBFC as the capital-deploying
partner, ASR fine-tuned on Pakistani bazaar vernacular at scale, and — most
critically — real repayment outcome data before any lender will trust this
as underwriting evidence. We are not claiming to have solved lender trust
in 48 hours; we're showing the wedge that makes solving it possible.

## GitHub Release checklist

1. Create a GitHub repository and push the source.
2. Deploy the backend and determine its HTTPS API URL.
3. Build the APK using that URL via `API_BASE_URL`.
4. Create tag `v1.0.0-hackathon` and attach `app-release.apk` as the release asset.
5. Verify the installed APK can call `/health` and submit a text or voice transaction against the deployed API.
