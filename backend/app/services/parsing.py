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

## OUTPUT FORMAT (strict JSON array):
```json
[
  {
    "entry_type": "sale",
    "amount": 4500.0,
    "note": "Aaj ki sale",
    "category": "other",
    "needs_clarification": false,
    "clarification_question": null
  }
]
```

If ANY entry is ambiguous:
```json
[
  {
    "entry_type": "unclear",
    "amount": 3000.0,
    "note": "3 hazar diye",
    "category": null,
    "needs_clarification": true,
    "clarification_question": "3000 rupay kis ko diye? Kya yeh udhaar tha, kharcha tha, ya ghar bheje?"
  }
]
```

Return ONLY the JSON array. No explanation, no markdown outside the JSON."""


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
                },
            )
            response.raise_for_status()
            result = response.json()
            content = result["choices"][0]["message"]["content"]
            content = content.strip()
            if content.startswith("```"):
                content = content.split("\n", 1)[1] if "\n" in content else content[3:]
                if content.endswith("```"):
                    content = content[:-3]
                content = content.strip()

            parsed = json.loads(content)
            entries = []
            for item in parsed:
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


def _parse_with_rules(transcript: str) -> list[ParsedEntry]:
    """Rule-based fallback parser for when LLM is unavailable."""
    import re
    entries = []
    text = transcript.lower().strip()

    sale_patterns = [
        r"(\d+(?:[,.]?\d+)*)\s*(?:(?:rs|rups?|rupay)\s*)?(?:ki\s*)?(?:sale|bikri|kamai|kamaya|becha)",
        r"(?:sale|bikri|kamai)\s*(?:hui|hoi)?\s*(?:thi)?\s*(\d+(?:[,.]?\d+)*)",
    ]
    purchase_patterns = [
        r"(\d+(?:[,.]?\d+)*)\s*(?:(?:rs|rups?|rupay)\s*)?(?:ka\s*)?(?:maal|stock|khareeda|samaan)",
        r"(?:maal|stock|khareedari)\s*(\d+(?:[,.]?\d+)*)",
    ]
    withdrawal_patterns = [
        r"(\d+(?:[,.]?\d+)*)\s*(?:(?:rs|rups?|rupay)\s*)?(?:ghar\s*bheje|ghar\s*ke\s*liye|ghar\s*kharch|nikaal|udhaar\s*diya)",
        r"(?:ghar\s*bheje|ghar\s*kharch)\s*(\d+(?:[,.]?\d+)*)",
    ]
    expense_patterns = [
        r"(\d+(?:[,.]?\d+)*)\s*(?:(?:rs|rups?|rupay)\s*)?(?:ka\s*)?(?:bill|kiraya|kharcha|committee)",
        r"(?:bill|kiraya|kharcha)\s*(\d+(?:[,.]?\d+)*)",
    ]

    def extract_amount(match_str: str) -> float:
        cleaned = match_str.replace(",", "").replace(" ", "")
        try:
            return float(cleaned)
        except ValueError:
            return 0.0

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
        number_matches = re.findall(r"(\d+(?:[,.]?\d+)*)\s*(?:rs|rups?|rupay|hazaar|sau)?", text)
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
