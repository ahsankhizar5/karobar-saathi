"""
LLM-based transaction parsing with Pakistani bazaar vernacular glossary.
Converts transcribed text (Roman Urdu / Urdu / English mix) into structured ledger entries.
"""
import json
import os
import httpx
from typing import Optional
from app.models.schemas import ParsedEntry, EntryType
from app.config import settings


PARSING_SYSTEM_PROMPT = """You are a financial transaction parser for Pakistani micro-businesses.
Your job is to extract structured ledger entries from spoken or written daily business notes.

## VERnACULAR GLOSSARY (Pakistani Bazaar Terms)

### Sales/Income:
- "Sale", "Bikri", "Kamai", "Kamaya", "Aamdani", "Becha" → type: "sale"
- "Ki sale hui", "Ki bikri hui", "Ki kamai" → indicates sale amount

### Purchases/Stock:
- "Maal", "Stock", "Khareeda", "Khareedari", "Samaan", "Liya" → type: "purchase"
- "Ka maal khareeda", "Ka stock liya" → indicates purchase amount

### Expenses:
- "Kharcha", "Bill", "Kiraya", "Bijli ka bill", "Dukaan ka kiraya" → type: "expense"
- "Committee" (rotating savings fund contribution) → type: "expense" unless context clarifies
- "Gas bill", "Phone bill", "Pani ka bill" → type: "expense"

### Withdrawals:
- "Ghar bheje", "Ghar ke liye", "Nikaal liye", "Udhaar diya", "De diye" → type: "withdrawal"
- "Ghar kharch", "Personal use" → type: "withdrawal"

### Number Formats:
- "4500", "4,500", "45 sau", "saadhe 4 hazar" → 4500
- "2 hazar", "2000", "do hazar" → 2000
- "3.5 hazar", "saadhe 3 hazar", "3500" → 3500
- "1 lakh", "ek lakh" → 100000
- "50 hazaar", "50k" → 50000
- "Sau" = 100, "Hazaar/Hazar" = 1000, "Lakh" = 100000

## STRICT RULES:
1. ONLY extract transactions that are EXPLICITLY stated in the input.
2. NEVER invent, assume, or infer transactions not mentioned.
3. If a transaction is ambiguous (e.g., "3 hazar diye" without specifying to whom or what for),
   set entry_type to "unclear" and provide a clarification_question.
4. Each distinct transaction in the input should be a separate entry.
5. Amounts must be numeric (float). Convert Urdu number words to numbers.
6. Include a brief note in Urdu/Roman Urdu describing what the transaction was for.
7. Add a category when inferable: "food", "utilities", "stock", "rent", "household", "transport", "other".

## OUTPUT FORMAT (strict JSON object):
```json
{
  "entries": [
    {
      "entry_type": "sale",
      "amount": 4500.0,
      "note": "Aaj ki sale",
      "category": "other",
      "needs_clarification": false,
      "clarification_question": null
    }
  ]
}
```

If ANY entry is ambiguous, include it in `entries` with `entry_type` set to `unclear`.
Return ONLY the JSON object. No explanation or markdown outside the JSON."""


PARSED_ENTRIES_SCHEMA = {
    "name": "parsed_ledger_entries",
    "strict": True,
    "schema": {
        "type": "object",
        "properties": {
            "entries": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "entry_type": {
                            "type": "string",
                            "enum": ["sale", "purchase", "expense", "withdrawal", "unclear"],
                        },
                        "amount": {"type": "number"},
                        "note": {"type": ["string", "null"]},
                        "category": {"type": ["string", "null"]},
                        "needs_clarification": {"type": "boolean"},
                        "clarification_question": {"type": ["string", "null"]},
                    },
                    "required": [
                        "entry_type",
                        "amount",
                        "note",
                        "category",
                        "needs_clarification",
                        "clarification_question",
                    ],
                    "additionalProperties": False,
                },
            },
        },
        "required": ["entries"],
        "additionalProperties": False,
    },
}


async def parse_with_llm(transcript: str) -> list[ParsedEntry]:
    """Parse a transcript string into structured ledger entries using LLM."""
    if not settings.LLM_API_KEY:
        return _parse_with_rules(transcript)

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                settings.LLM_API_URL,
                headers={
                    "Authorization": f"Bearer {settings.LLM_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": settings.LLM_MODEL,
                    "messages": [
                        {"role": "system", "content": PARSING_SYSTEM_PROMPT},
                        {"role": "user", "content": f"Parse these transactions:\n{transcript}"},
                    ],
                    "temperature": 0.1,
                    "max_tokens": 1000,
                    "response_format": {
                        "type": "json_schema",
                        "json_schema": PARSED_ENTRIES_SCHEMA,
                    },
                },
            )
            response.raise_for_status()
            result = response.json()
            content = result["choices"][0]["message"]["content"]
            parsed = json.loads(content)
            entries = []
            for item in parsed["entries"]:
                entries.append(ParsedEntry(
                    entry_type=EntryType(item.get("entry_type", "unclear")),
                    amount=float(item.get("amount", 0)),
                    note=item.get("note"),
                    category=item.get("category"),
                    needs_clarification=item.get("needs_clarification", False),
                    clarification_question=item.get("clarification_question"),
                ))
            return entries
    except Exception as e:
        print(f"[LLM Parse Error] {e}, falling back to rule-based parsing")
        return _parse_with_rules(transcript)


# A number token is digits (optionally with a decimal/comma) OR an Urdu/English
# word-number, optionally followed by a multiplier word (sau/hazar/lakh).
# "saadhe"/"dedh"/"dhai" express halves ("saadhe teen hazar" = 3,500).
# Bare "k" is deliberately NOT a multiplier: "12 kg cheeni" must not parse as
# 12,000 — quantities in kilograms are far more common than "2k" style in
# bazaar speech.
_NUM = r"(?:saadhe\s+)?(?:\d+(?:[,.]\d+)?|ek|do|teen|char|paanch|panch|chd|che|saat|aath|nau|das|dedh|dhai)\s*(?:sau|so|hazar|hazaar|hazaaron|lakh|lac)?"

_WORD_NUMBERS = {
    "ek": 1, "do": 2, "teen": 3, "char": 4, "paanch": 5, "panch": 5,
    "che": 6, "saat": 7, "aath": 8, "nau": 9, "das": 10,
    "dedh": 1.5, "dhai": 2.5,
}
_MULTIPLIERS = {
    "sau": 100, "so": 100, "hazar": 1000, "hazaar": 1000, "hazaaron": 1000,
    "lakh": 100000, "lac": 100000,
}


def _parse_with_rules(transcript: str) -> list[ParsedEntry]:
    """Rule-based fallback parser for when LLM is unavailable."""
    import re
    entries = []
    text = transcript.lower().strip()

    sale_patterns = [
        rf"({_NUM})\s*(?:(?:rs|rups?|rupay)\s*)?(?:ki\s*)?(?:sale|bikri|kamai|kamaya|becha)",
        rf"(?:sale|bikri|kamai)\s*(?:hui|hoi)?\s*(?:thi)?\s*({_NUM})",
    ]
    purchase_patterns = [
        rf"({_NUM})\s*(?:(?:rs|rups?|rupay)\s*)?(?:ka\s*)?(?:maal|stock|khareeda|samaan)",
        rf"(?:maal|stock|khareedari)\s*({_NUM})",
    ]
    withdrawal_patterns = [
        rf"({_NUM})\s*(?:(?:rs|rups?|rupay)\s*)?(?:ghar\s*bheje|ghar\s*ke\s*liye|ghar\s*kharch|nikaal|udhaar\s*diya)",
        rf"(?:ghar\s*bheje|ghar\s*kharch)\s*({_NUM})",
    ]
    expense_patterns = [
        # "500 ka bill" and "500 ka bijli ka bill" — the intervening noun is
        # common in phrases like "bijli ka bill" (electricity bill).
        rf"({_NUM})\s*(?:(?:rs|rups?|rupay)\s*)?(?:ka\s*)?(?:\w+\s+ka\s+)?(?:bill|kiraya|kharcha|committee)",
        rf"(?:bill|kiraya|kharcha)\s*({_NUM})",
    ]

    def extract_amount(match_str: str) -> float:
        s = match_str.lower().strip()
        half = False
        if s.startswith("saadhe"):
            half = True
            s = s[len("saadhe"):].strip()

        # Split off a trailing multiplier word if present.
        multiplier = 1
        for word, factor in _MULTIPLIERS.items():
            if s.endswith(word):
                multiplier = factor
                s = s[: -len(word)].strip()
                break

        base_str = s.replace(",", "").replace(" ", "")
        base = 0.0
        if base_str in _WORD_NUMBERS:
            base = float(_WORD_NUMBERS[base_str])
        elif base_str == "" and multiplier > 1:
            base = 1.0  # e.g. bare "hazar" → 1000
        else:
            try:
                base = float(base_str)
            except ValueError:
                return 0.0

        value = base * multiplier
        if half:
            value += multiplier / 2
        return value

    for pattern in sale_patterns:
        for match in re.finditer(pattern, text):
            amount = extract_amount(match.group(1))
            if amount > 0:
                entries.append(ParsedEntry(
                    entry_type=EntryType.SALE, amount=amount,
                    note="Sale/Bikri", category="other",
                    needs_clarification=False
                ))

    for pattern in purchase_patterns:
        for match in re.finditer(pattern, text):
            amount = extract_amount(match.group(1))
            if amount > 0:
                entries.append(ParsedEntry(
                    entry_type=EntryType.PURCHASE, amount=amount,
                    note="Maal/Stock khareeda", category="stock",
                    needs_clarification=False
                ))

    for pattern in withdrawal_patterns:
        for match in re.finditer(pattern, text):
            amount = extract_amount(match.group(1))
            if amount > 0:
                entries.append(ParsedEntry(
                    entry_type=EntryType.WITHDRAWAL, amount=amount,
                    note="Ghar bheje / Withdrawal", category="household",
                    needs_clarification=False
                ))

    for pattern in expense_patterns:
        for match in re.finditer(pattern, text):
            amount = extract_amount(match.group(1))
            if amount > 0:
                entries.append(ParsedEntry(
                    entry_type=EntryType.EXPENSE, amount=amount,
                    note="Kharcha/Bill", category="utilities",
                    needs_clarification=False
                ))

    if not entries:
        number_matches = re.findall(rf"({_NUM})", text)
        number_matches = [m for m in number_matches if m.strip()]
        if number_matches:
            entries.append(ParsedEntry(
                entry_type=EntryType.UNCLEAR,
                amount=extract_amount(number_matches[0]),
                note=transcript[:100],
                needs_clarification=True,
                clarification_question="Yeh transaction kya thi? Sale, khareed, kharcha ya ghar bheje?"
            ))

    return entries if entries else [ParsedEntry(
        entry_type=EntryType.UNCLEAR, amount=0,
        note=transcript[:100],
        needs_clarification=True,
        clarification_question="Koi wazeh transaction nahi mili. Dobara bataiye."
    )]
