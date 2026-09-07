# Verification log

This file collects the end-to-end checks run against the live Render backend.
It is kept separate from the README so the main project page stays readable.

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

### v1.3.0 re-verification (2026-09-05, login screen + voice latency + dashboard redesign)

- **Login screen**: new "Choose your shop" screen listing the three seeded
  demo shops; the choice persists across launches (a reload goes straight
  into the books) and About → Sign out — with a confirmation dialog —
  returns to it. Verified live in a web build against the deployed API.
- **Voice latency**: recording starts on button press (the recorder is
  created up front), the backend is pinged warm at app open, every 10
  minutes, and on app resume, and the transaction sheet shows
  stage-by-stage feedback instead of a single spinner. Cold start on the
  Render free tier was measured at ~23s; keep-warm means the first voice
  transaction usually hits an awake backend. (The audio-record plugin is
  Android-only, so this was verified by code review plus backend warm-up
  evidence rather than web E2E.)
- **Dashboard redesign**: greeting, profit hero card, stat cards, 7-day
  trend chart, and insight card with a staggered entrance animation and
  shimmer skeleton loaders. Also fixed a layout bug (an unbounded
  cross-axis on the stat-card row) that silently dropped the trend chart
  and insight card in release builds — a widget test now fails without
  the fix.
- **Refresh**: the AppBar refresh icon spins while re-fetching and the
  last data stays on screen (no skeleton flash). Verified live: dashboard
  and ledger both re-fetched 200 while the content stayed visible.
- **About dialog**: rewritten for shopkeepers — what the app does, the
  privacy promise, app version, signed-in shop, and Sign out. No backend
  URLs or technical details.
- **Test suite**: 11 tests pass, including new coverage for the dashboard
  entrance cascade and the weekly trend chart; `flutter analyze` is clean.

### v1.4.0 verification notes

To be added after the voice-recorder migration is verified on a physical Android
device.
