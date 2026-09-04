# Pre-recorded Voice Samples

Six sample voice notes covering the daily-book patterns of a Pakistani
micro-business. Use them to demo the voice-to-ledger pipeline without recording
live audio.

| File | Says (Roman Urdu) | Expected ledger entries |
| --- | --- | --- |
| `sample_01_daily_sale.wav` | "Aaj 4500 ki sale hui." | sale 4,500 |
| `sample_02_stock_purchase.wav` | "2000 ka maal khareeda." | purchase 2,000 |
| `sample_03_bijli_bill.wav` | "800 ka bijli ka bill diya." | expense 800 (utilities) |
| `sample_04_ghar_withdrawal.wav` | "1500 ghar bheje." | withdrawal 1,500 |
| `sample_05_multi_transaction.wav` | "Aaj 6000 ki bikri hui. 2500 ka stock liya. 500 kiraya diya." | sale 6,000; purchase 2,500; expense 500 |
| `sample_06_unclear_amount.wav` | "3000 diye." | unclear 3,000 (asks a clarification question) |

## Test against the live API

```bash
curl -X POST https://karobar-saathi.onrender.com/api/v1/voice/transcribe \
  -F "user_id=shop_001" \
  -F "audio=@sample_01_daily_sale.wav;type=audio/wav"
```

The audio is transcribed with Groq's hosted Whisper (`whisper-large-v3`), parsed
into structured ledger entries by the LLM parser, and returned as JSON. Swap
`karobar-saathi.onrender.com` for `http://localhost:8000` to test a local
backend.
