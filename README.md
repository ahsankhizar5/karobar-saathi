# Karobar Saathi

Karobar Saathi turns spoken daily business transactions into a confirmed ledger and explainable financial evidence for Pakistani informal micro-businesses.

> **This is a working proof-of-concept, not a production product.** Anyone
> installing the APK should read the
> [production-readiness caveats](#production-readiness-caveats) below before
> judging it as one.

## Project layout

- `karobar_saathi/` — Flutter Android app (Riverpod, `record`)
- `backend/` — FastAPI service (voice parsing, ledger, dashboard, evidence API)
- `backend/seed_audio/` — six pre-recorded voice notes for repeatable voice-pipeline demos
- `render.yaml` / `Dockerfile` — Render deployment configuration

## Production-readiness caveats

The app is polished enough to feel like a finished product — deliberately so,
because the point is to demo the concept end-to-end. These are the things that
would have to change before it could serve a real shopkeeper:

- **Cold starts.** The backend runs on Render's free tier and sleeps after
  ~15 minutes of inactivity. The first request after idle (opening the app,
  submitting a transaction) can take up to about a minute while the service
  wakes; the app recognizes this and shows a "server waking up" message instead
  of an error. Every request after that is fast.
- **Ephemeral demo data.** Storage is SQLite on the service's ephemeral disk.
  Each deploy or restart resets everything back to the three seeded demo
  profiles — transactions recorded in the app are not durable, and there are no
  backups or data export.
- **Shared demo identity.** There are no accounts or authentication. The
  shopkeeper side of the app is hard-wired to a single demo user
  (`shop_001`), so everyone who installs the APK sees and edits the same
  ledger. Data is not private.
- **Free-tier limits.** Voice transcription (Groq Whisper) and LLM parsing run
  on a free-tier API key; sustained or heavy use can hit rate limits and
  temporarily fail parsing until the quota resets.
- **No real lending.** The lender view shows seeded demo shops with
  rule-based "readiness" heuristics. No credit decisions, loan offers, or
  lender integrations exist anywhere in the system.
- **Sideloading only.** The APK is distributed via GitHub Release, not Play
  Store, so Android will show an unknown-sources warning during install.

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

The included `render.yaml` deploys the Docker service to Render. Set `LLM_API_KEY` and `SECRET_KEY` only in Render's encrypted environment panel; do not add them to the repository. Voice transcription uses Groq's hosted Whisper API (`whisper-large-v3`) with the same `LLM_API_KEY`, so the voice pipeline works even on the free tier. Set `TRANSCRIPTION_PROVIDER=local` to run faster-whisper in-process instead (requires FFmpeg and a suitably provisioned host), or `none` for typed transactions only.

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
✅ Voice-to-ledger pipeline: voice note → Whisper (Groq hosted `whisper-large-v3`)
   → LLM parsing → confirmed ledger
✅ Typed transaction → LLM/rule parsing → confirmed database ledger
✅ User confirmation/correction flow, including clarification questions for
   ambiguous input (no hallucinated entries)
✅ Dashboard with profit, trends, cash-flow insight
✅ REST API endpoint `/api/v1/evidence-profile/{user_id}` with consent gate
✅ Auto-generated API docs at `/docs`
✅ Installable APK (GitHub Release), works against live backend
✅ Six pre-recorded voice notes in `backend/seed_audio/` for repeatable demos
✅ In-app language switch (English ⇄ اردو) with full RTL layout, persisted
   across launches — every screen, dialog, and error message is localized

### Demo-Simulated (Concept Only)
🔶 Lender View: 3 seeded demo profiles (not real users)
🔶 "Financial Readiness" summary: rule-based heuristics, not trained on
   real repayment outcomes
🔶 Partner integrations: no actual MFB partnerships — architecture is
   API-ready, no live lender connected

### Path to Production (not built, stated for context)
This build proves the core pipeline and the API-readiness of the architecture.
Turning this into a real product requires: local data hosting to meet SBP/SECP
data-residency expectations, a regulatory sandbox application or partnership
with a licensed MFB/NBFC as the capital-deploying partner, ASR fine-tuned on
Pakistani bazaar vernacular at scale, and — most critically — real repayment
outcome data before any lender will trust this as underwriting evidence. We
are not claiming to have solved lender trust in 48 hours; we're showing the
wedge that makes solving it possible.

## End-to-end verification (2026-09-04)

The full UI was driven end-to-end against the live Render backend using a Flutter
web build of the same Dart client (the Android emulator was unavailable on the
test machine; both targets run the identical app code and API client). Every
step below was exercised against production on 2026-09-04:

- **Typed multi-transaction flow**: "Aaj subah 4500 ki chai aur biscuits ki sale
  hui, aur shaam ko 1200 ka doodh aur cheeni khareeda" → parsed into 2 entries
  (Sale Rs 4,500 / Purchase Rs 1,200) → reviewed and edited → `batch-confirm`
  saved both → dashboard updated with exact math reconciliation (profit
  Rs 3,300, sales Rs 4,500, out Rs 1,200).
- **Clarification flow**: an amountless entry produced the Roman-Urdu question
  "Bikri ki amount kya hai?" and disabled saving until a type and amount were
  provided — no entry was invented.
- **Ledger view**: saved entries listed with amount, note, original transcript,
  timestamp, and category.
- **Lender view**: explainable profile rendered (average daily sales, 30-day
  consistency, cash buffer, loan range, traceable factors).
- **Deletion**: ledger entries removed via the confirmation dialog.
- **Voice pipeline**: three seed audio samples (single sale, multi-transaction,
  unclear amount) submitted to `/api/v1/voice/transcribe` — all transcribed via
  Groq Whisper and parsed correctly, with the ambiguous "3000 die" sample
  returned as `unclear` plus a clarification question.
- **Consent gate**: revoking consent via `PATCH .../consent` made
  `GET /api/v1/evidence-profile/shop_001` return `403 consent_required` even
  with the `X-User-Consent: true` header; re-granting restored `200`.
- **Cleanup**: all test entries were deleted afterward and the dashboard was
  verified back at its pre-test baseline.

### v1.2.0 re-verification (2026-09-04, after the timeout fix + UI declutter)

- **Timeout fix**: the Android client previously timed out at 30s while the
  Render free tier was cold-starting (~24s), which made the voice and typed
  transaction buttons fail on the released APK. The client now allows 150s
  for LLM-backed calls, pings `/health` at launch to pre-warm the backend,
  and surfaces a localized "server waking up" message instead of an error.
- **Live API re-check**: `POST /api/v1/voice/parse-text` with a
  multi-transaction Roman-Urdu sentence returned 2 correct entries;
  `POST /api/v1/voice/transcribe` with the single-sale and multi-transaction
  seed audio files returned correct transcripts and 1 / 3 parsed entries
  respectively; the evidence endpoint's 404 guard for unknown users was
  confirmed (previously a 500).
- **Redesign coverage**: the redesigned ledger tile (collapsed transcript,
  tap-to-expand, single meta line) is covered by widget tests; the full UI
  was re-driven live via a web build of the same Dart client (all screens
  loaded, all API calls 200). The visual polish itself is best judged by
  installing the APK.

## GitHub Release checklist

1. Create a GitHub repository and push the source.
2. Deploy the backend and determine its HTTPS API URL.
3. Build the APK using that URL via `API_BASE_URL`.
4. Create tag `vX.Y.Z` and attach `app-release.apk` as the release asset.
5. Verify the installed APK can call `/health` and submit a text or voice transaction against the deployed API.
