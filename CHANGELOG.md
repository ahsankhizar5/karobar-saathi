# Changelog

All notable changes to Karobar Saathi are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.2] - 2026-09-07

### Fixed
- Voice recording failing on second attempt in the same app session ("Could not start recording"):
  - Fixed `package:record` single-subscription stream bug where reusing the same recorder instance threw `Bad state: Stream has already been listened to`.
  - Treated `AudioRecorder` as an ephemeral per-session resource, cleanly releasing the microphone hardware and disposing instances on `stop()`, `cancel()`, and error rollback.
  - Dynamically attach state and amplitude stream listeners per session in `TransactionSheet`.
  - Added regression test for consecutive recordings in the same sheet session.

## [1.4.1] - 2026-09-07

### Fixed
- Android 14 Bluetooth SCO crash on startRecording by configuring `manageBluetooth: false` and `audioSource: mic`.

## [1.4.0] - 2026-09-07

### Fixed
- Voice recording on Android devices by migrating from the direct
  `record_platform_interface` + `record_android` usage to the umbrella
  `record: ^5.2.1` package.
- Recorder lifecycle so platform exceptions no longer escape as unhandled
  async errors and the mic button responds immediately.

### Added
- WhatsApp/ChatGPT-style voice-recording UI: haptic feedback, elapsed timer,
  animated waveform bars, cancel/send controls, and a 60-second auto-stop.
- Optimistic recording state and a catch-all recorder error banner.
- `_HeardTranscriptCard` fallback that shows the raw transcript and a
  "Use this text" button when voice parsing returns no transactions.
- New localization keys for recording states and encoder feedback (EN + Urdu).
- Widget regression tests for synchronous mic feedback, error rollback,
  waveform rendering, empty-parse transcript fallback, and Urdu RTL layout.

### Changed
- Bumped app version to `1.4.0+5`.
- Backend API version reported on `/` updated to `1.4.0`.

### Deprecated
- The v1.3.0 release was not published as a GitHub Release because voice
  recording was non-functional on real Android hardware. v1.4.0 supersedes it.

## [1.3.0] - 2026-09-05

### Added
- "Choose your shop" login screen with persistent session and sign-out flow.
- Dashboard redesign: greeting, profit hero card, stat cards, 7-day trend
  chart, insight card, shimmer skeletons, and staggered entrance animation.
- Keep-warm ping every 10 minutes and on app resume to reduce Render cold-start
  latency.
- Stage-by-stage feedback in the transaction sheet while voice/text is being
  processed.

### Fixed
- Unbounded cross-axis layout bug in the dashboard stat-card row that silently
  dropped the trend chart and insight card in release builds.
- Refresh behavior: the AppBar icon spins while re-fetching and the previous
  data stays visible (no skeleton flash).

### Changed
- About dialog rewritten in shopkeeper-friendly language; removed backend URLs
  and technical details.
- Test suite expanded to 11 tests covering the dashboard entrance cascade and
  weekly trend chart.

## [1.2.0] - 2026-09-05

### Fixed
- Android client timeout for LLM-backed calls increased from 30 s to 150 s so
  Render free-tier cold starts no longer fail voice/typed transactions.
- Localized "server waking up" message surfaced instead of a generic error.
- Evidence endpoint 500 for unknown users changed to 404.

### Changed
- UI declutter pass: removed redundant labels and tightened spacing.
- README updated with production-readiness caveats.

## [1.1.0] - 2026-09-04

### Added
- App icon and branding assets.
- Flutter web platform scaffold for browser-based testing.

### Changed
- APK signing and release process configured.

## [1.0.0-hackathon] - 2026-09-04

### Added
- FastAPI backend with SQLite storage.
- Voice-to-ledger pipeline: audio upload → Whisper transcription → LLM/rule
  parsing → confirmed ledger.
- Typed transaction parsing with user confirmation and clarification flow.
- Dashboard, ledger, and lender views.
- Consent-gated evidence profile API (`/api/v1/evidence-profile/{user_id}`).
- Seed audio samples and three demo shop profiles.
- Bilingual English/Urdu UI with full RTL layout.

[Unreleased]: https://github.com/ahsankhizar5/karobar-saathi/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/ahsankhizar5/karobar-saathi/compare/v1.2.0...v1.4.0
[1.3.0]: https://github.com/ahsankhizar5/karobar-saathi/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/ahsankhizar5/karobar-saathi/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/ahsankhizar5/karobar-saathi/compare/v1.0.0-hackathon...v1.1.0
[1.0.0-hackathon]: https://github.com/ahsankhizar5/karobar-saathi/releases/tag/v1.0.0-hackathon
