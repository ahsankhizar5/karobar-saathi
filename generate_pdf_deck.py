"""
Generate Karobar Saathi Presentation as a stunning, high-res PDF slide deck.
Uses ReportLab with custom 16:9 widescreen canvas, dark fintech aesthetics,
glassmorphism cards, colored badges, and metric scoreboards.
"""
import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import landscape
from reportlab.pdfgen import canvas

# 16:9 Widescreen dimensions (11 inches x 6.1875 inches) in points (72 pt / inch)
PAGE_WIDTH = 11.0 * 72
PAGE_HEIGHT = 6.1875 * 72

# Design System Colors
BG_DARK = colors.HexColor("#070A12")
BG_CARD = colors.HexColor("#101828")
BORDER_CARD = colors.HexColor("#1E2941")
EMERALD_DARK = colors.HexColor("#0D6F69")
EMERALD_LIGHT = colors.HexColor("#2DD4BF")
MINT_ACCENT = colors.HexColor("#10B981")
AMBER_ACCENT = colors.HexColor("#F59E0B")
ROSE_ACCENT = colors.HexColor("#F43F5E")
INDIGO_ACCENT = colors.HexColor("#6366F1")
TEXT_WHITE = colors.HexColor("#F8FAFC")
TEXT_MUTED = colors.HexColor("#94A3B8")
TEXT_DIM = colors.HexColor("#64748B")

def draw_background(c):
    c.setFillColor(BG_DARK)
    c.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, fill=1, stroke=0)
    
    # Subtle ambient glow in corners
    c.setFillColor(colors.HexColor("#0A1926"))
    c.circle(0, PAGE_HEIGHT, 180, fill=1, stroke=0)
    c.setFillColor(colors.HexColor("#141026"))
    c.circle(PAGE_WIDTH, 0, 160, fill=1, stroke=0)

def draw_badge(c, text, x, y, badge_color=EMERALD_LIGHT, bg_color=colors.HexColor("#082827")):
    c.setFont("Helvetica-Bold", 8)
    text_width = c.stringWidth(text.upper(), "Helvetica-Bold", 8)
    badge_w = text_width + 16
    badge_h = 16
    
    c.setFillColor(bg_color)
    c.setStrokeColor(badge_color)
    c.setLineWidth(0.8)
    c.roundRect(x, y - 3, badge_w, badge_h, 8, fill=1, stroke=1)
    
    c.setFillColor(badge_color)
    c.drawString(x + 8, y + 1.5, text.upper())
    return badge_w

def draw_header(c, badge_text, title_text, subtitle_text, badge_col=EMERALD_LIGHT, badge_bg=colors.HexColor("#082827")):
    draw_badge(c, badge_text, 40, PAGE_HEIGHT - 45, badge_col, badge_bg)
    
    c.setFont("Helvetica-Bold", 20)
    c.setFillColor(TEXT_WHITE)
    c.drawString(40, PAGE_HEIGHT - 75, title_text)
    
    c.setFont("Helvetica", 10.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(40, PAGE_HEIGHT - 95, subtitle_text)

def draw_card(c, x, y, w, h, bg=BG_CARD, border=BORDER_CARD, radius=8):
    c.setFillColor(bg)
    c.setStrokeColor(border)
    c.setLineWidth(1)
    c.roundRect(x, y, w, h, radius, fill=1, stroke=1)

def build_pdf(filename="Karobar_Saathi_Presentation.pdf"):
    c = canvas.Canvas(filename, pagesize=(PAGE_WIDTH, PAGE_HEIGHT))
    
    # =========================================================
    # SLIDE 1: TITLE HERO
    # =========================================================
    draw_background(c)
    
    # Icon box
    c.setFillColor(EMERALD_DARK)
    c.setStrokeColor(EMERALD_LIGHT)
    c.setLineWidth(1.5)
    c.roundRect(40, PAGE_HEIGHT - 110, 60, 60, 14, fill=1, stroke=1)
    c.setFont("Helvetica-Bold", 26)
    c.setFillColor(TEXT_WHITE)
    c.drawString(54, PAGE_HEIGHT - 93, "KS")
    
    draw_badge(c, "Production-Ready Architecture · v1.4.0", 40, PAGE_HEIGHT - 140)
    
    c.setFont("Helvetica-Bold", 28)
    c.setFillColor(TEXT_WHITE)
    c.drawString(40, PAGE_HEIGHT - 180, "Karobar Saathi  (کاروبار ساتھی)")
    
    c.setFont("Helvetica-Bold", 15)
    c.setFillColor(EMERALD_LIGHT)
    c.drawString(40, PAGE_HEIGHT - 208, "Spoken Transactions -> Confirmed Ledger -> Explainable Financial Evidence")
    
    c.setFont("Helvetica", 11)
    c.setFillColor(TEXT_MUTED)
    c.drawString(40, PAGE_HEIGHT - 232, "Bridging Pakistan's $180B informal economy with AI voice bookkeeping and sovereign credit profiles")
    c.drawString(40, PAGE_HEIGHT - 248, "for 5 Million+ micro-merchants.")
    
    # Footer metadata card
    draw_card(c, 40, 40, PAGE_WIDTH - 80, 70)
    c.setFont("Helvetica-Bold", 10)
    c.setFillColor(TEXT_WHITE)
    c.drawString(55, 88, "STACK: Flutter (Riverpod) · FastAPI · Groq Whisper-large-v3 · Vernacular LLM Parser · SQLite")
    c.setFont("Helvetica", 9)
    c.setFillColor(MINT_ACCENT)
    c.drawString(55, 70, "STATUS: Live Backend & APK Release v1.4.0   |   TARGET: Chai Stalls, Kirana Stores, Home Tailors, Khokhas")
    c.setFillColor(TEXT_MUTED)
    c.drawString(55, 54, "LICENSE: MIT Open Source   |   WEBSITE: ahsankhizar5.github.io/karobar-saathi")
    
    c.showPage()
    
    # =========================================================
    # SLIDE 2: THE PROBLEM
    # =========================================================
    draw_background(c)
    draw_header(c, "Market Reality & Pain Points", "The Invisible 5 Million & The Unbanked Trap",
                "Micro-businesses form the economic spine of Pakistan, yet 90%+ operate completely invisible to formal finance.",
                ROSE_ACCENT, colors.HexColor("#2B0E17"))
                
    card_w = (PAGE_WIDTH - 80 - 32) / 3
    
    # Col 1
    draw_card(c, 40, 140, card_w, 200)
    c.setFont("Helvetica-Bold", 32)
    c.setFillColor(AMBER_ACCENT)
    c.drawString(55, 295, "5.2M+")
    c.setFont("Helvetica-Bold", 12)
    c.setFillColor(TEXT_WHITE)
    c.drawString(55, 270, "Informal Micro-Enterprises")
    c.setFont("Helvetica", 9.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(55, 240, "Khokhas, dhabas, roadside carts,")
    c.drawString(55, 225, "and home workers handling daily cash")
    c.drawString(55, 210, "volume without bank accounts or")
    c.drawString(55, 195, "formal registrations.")
    
    # Col 2
    draw_card(c, 40 + card_w + 16, 140, card_w, 200)
    c.setFont("Helvetica-Bold", 32)
    c.setFillColor(ROSE_ACCENT)
    c.drawString(55 + card_w + 16, 295, "93%")
    c.setFont("Helvetica-Bold", 12)
    c.setFillColor(TEXT_WHITE)
    c.drawString(55 + card_w + 16, 270, "Paper Only (Bahi Khata)")
    c.setFont("Helvetica", 9.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(55 + card_w + 16, 240, "Traditional accounting apps fail.")
    c.drawString(55 + card_w + 16, 225, "Typing in English or Urdu after")
    c.drawString(55 + card_w + 16, 210, "14 hours of shop work is slow,")
    c.drawString(55 + card_w + 16, 195, "confusing, and exhausting.")
    
    # Col 3
    draw_card(c, 40 + (card_w + 16) * 2, 140, card_w, 200)
    c.setFont("Helvetica-Bold", 32)
    c.setFillColor(INDIGO_ACCENT)
    c.drawString(55 + (card_w + 16) * 2, 295, "25-30%")
    c.setFont("Helvetica-Bold", 12)
    c.setFillColor(TEXT_WHITE)
    c.drawString(55 + (card_w + 16) * 2, 270, "Monthly Loan Shark Rates")
    c.setFont("Helvetica", 9.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(55 + (card_w + 16) * 2, 240, "Without verified financial history,")
    c.drawString(55 + (card_w + 16) * 2, 225, "commercial banks reject micro-loans.")
    c.drawString(55 + (card_w + 16) * 2, 210, "Shopkeepers are trapped relying")
    c.drawString(55 + (card_w + 16) * 2, 195, "on informal moneylenders.")
    
    # Bottleneck banner
    draw_card(c, 40, 45, PAGE_WIDTH - 80, 65, bg=colors.HexColor("#1A1408"), border=AMBER_ACCENT)
    c.setFont("Helvetica-Bold", 10.5)
    c.setFillColor(AMBER_ACCENT)
    c.drawString(55, 85, "THE CORE BOTTLENECK:")
    c.setFont("Helvetica", 10)
    c.setFillColor(TEXT_WHITE)
    c.drawString(55, 65, "Banks don't lend without evidence. Shopkeepers can't generate evidence without unbearable bookkeeping friction.")
    
    c.showPage()
    
    # =========================================================
    # SLIDE 3: THE SOLUTION
    # =========================================================
    draw_background(c)
    draw_header(c, "The Innovation", "Zero Typing. Zero Complexity. Just Speak in Urdu.",
                "Karobar Saathi replaces the tedious bahi khata with an AI assistant that understands Pakistani bazaar vernacular.")
                
    half_w = (PAGE_WIDTH - 80 - 20) / 2
    
    # Left stacked pillars
    draw_card(c, 40, 245, half_w, 80)
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(EMERALD_LIGHT)
    c.drawString(55, 305, "1. Natural Voice-to-Ledger (5 Seconds a Day)")
    c.setFont("Helvetica", 9)
    c.setFillColor(TEXT_MUTED)
    c.drawString(55, 285, "Speak at closing time. Groq Whisper-v3 + LLM parse complex multi-item sales")
    c.drawString(55, 270, "and expenses in one breath with zero typing.")
    
    draw_card(c, 40, 150, half_w, 80)
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(AMBER_ACCENT)
    c.drawString(55, 210, "2. Hallucination-Proof Roman Urdu Clarification")
    c.setFont("Helvetica", 9)
    c.setFillColor(TEXT_MUTED)
    c.drawString(55, 190, "Never invents numbers. If ambiguous (e.g. '3000 diye'), prompts the shopkeeper:")
    c.drawString(55, 175, "'Bikri ki amount kya hai ya kisko diye?' before writing to disk.")
    
    draw_card(c, 40, 55, half_w, 80)
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(INDIGO_ACCENT)
    c.drawString(55, 115, "3. Sovereign, Consent-Gated Evidence Engine")
    c.setFont("Helvetica", 9)
    c.setFillColor(TEXT_MUTED)
    c.drawString(55, 95, "Transforms 30 days of daily entries into underwriting evidence (sales volatility,")
    c.drawString(55, 80, "cash buffer runway) for microfinance banks — with instant one-tap revocation.")
    
    # Right: Live flow
    draw_card(c, 40 + half_w + 20, 55, half_w, 270, border=EMERALD_LIGHT)
    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(TEXT_WHITE)
    c.drawString(60 + half_w + 20, 295, "The 5-Second Shopkeeper Flow")
    
    steps = [
        ("🎙️ Tap Mic", "Shopkeeper records voice note in Urdu/Roman Urdu."),
        ("⚡ 1.2s Transcription", "Hosted Whisper-large-v3 converts voice to text."),
        ("🧠 Vernacular Parser", "Pakistani bazaar terms extracted into strict JSON schema."),
        ("📝 One-Tap Confirm", "Visual sheet shows sale/purchase before writing to ledger."),
        ("📊 Instant Signals", "Net profit, 7-day sales trend, and loan readiness update.")
    ]
    y_s = 260
    for t, d in steps:
        c.setFont("Helvetica-Bold", 10)
        c.setFillColor(EMERALD_LIGHT)
        c.drawString(60 + half_w + 20, y_s, t)
        c.setFont("Helvetica", 8.5)
        c.setFillColor(TEXT_MUTED)
        c.drawString(60 + half_w + 20, y_s - 14, d)
        y_s -= 38
        
    c.showPage()
    
    # =========================================================
    # SLIDE 4: SYSTEM ARCHITECTURE
    # =========================================================
    draw_background(c)
    draw_header(c, "Full-Stack Architecture", "Engineered for Low-End Android & Slow Connections",
                "A resilient three-tier pipeline connecting shopkeeper smartphones to institutional lending APIs.",
                INDIGO_ACCENT, colors.HexColor("#1A163B"))
                
    layers = [
        ("LAYER 1: PRESENTATION & RECORDING (FLUTTER APP)",
         "State-managed with Riverpod. WhatsApp-style live waveform recording (record: ^5.2.1), haptic feedback,",
         "bilingual EN/UR with full RTL layout, and 150s cold-start tolerance.",
         "Tech: Flutter 3.x · Riverpod · record ^5.2.1 · Urdu RTL Layout", EMERALD_LIGHT),
        ("LAYER 2: VERNACULAR AI PIPELINE (FASTAPI ENGINE)",
         "Groq Whisper-large-v3 speech-to-text combined with specialized Pakistani bazaar LLM parser.",
         "Enforces strict JSON Schema and flags ambiguous inputs for conversational clarification.",
         "Tech: FastAPI · Groq Whisper-v3 · Groq LLM · Bazaar Vernacular Glossary", AMBER_ACCENT),
        ("LAYER 3: LEDGER STORE & EVIDENCE COMPUTER (B2B API)",
         "ACID SQLite persistence storing confirmed entries and original spoken audio transcripts.",
         "Computes 30-day volatility (CV), cash buffer runway, and loan ranges. Protected by X-User-Consent.",
         "Tech: SQLite · Rule Heuristic Engine · X-User-Consent · REST API", INDIGO_ACCENT)
    ]
    
    y_l = 250
    for title, d1, d2, tech, col in layers:
        draw_card(c, 40, y_l, PAGE_WIDTH - 80, 75)
        c.setFont("Helvetica-Bold", 11)
        c.setFillColor(col)
        c.drawString(55, y_l + 55, title)
        c.setFont("Helvetica", 9)
        c.setFillColor(TEXT_WHITE)
        c.drawString(55, y_l + 38, d1)
        c.drawString(55, y_l + 25, d2)
        c.setFont("Helvetica", 8)
        c.setFillColor(TEXT_MUTED)
        c.drawString(55, y_l + 10, tech)
        y_l -= 95
        
    c.showPage()
    
    # =========================================================
    # SLIDE 5: VERNACULAR GLOSSARY
    # =========================================================
    draw_background(c)
    draw_header(c, "Proprietary AI Engineering", "Deciphering Pakistani Bazaar Vernacular",
                "Standard financial LLMs fail in street Urdu. Karobar Saathi is calibrated with a native bazaar taxonomy.")
                
    # Left column terms
    terms = [
        ("Sales & Income", '"Bikri", "Kamai", "Kamaya", "Aamdani", "Becha", "Ki sale hui"', 'type: "sale"', EMERALD_LIGHT),
        ("Stock Purchases", '"Maal", "Stock liya", "Khareeda", "Samaan", "Cheeni doodh liya"', 'type: "purchase"', AMBER_ACCENT),
        ("Expenses & Bills", '"Bijli ka bill", "Dukaan ka kiraya", "Gas bill", "Committee"', 'type: "expense"', ROSE_ACCENT),
        ("Withdrawals", '"Ghar bheje", "Ghar ke liye nikaale", "Ghar kharch", "Udhaar diya"', 'type: "withdrawal"', INDIGO_ACCENT)
    ]
    y_t = 265
    for cat, ex, mapping, col in terms:
        draw_card(c, 40, y_t, half_w, 55)
        c.setFont("Helvetica-Bold", 10)
        c.setFillColor(col)
        c.drawString(52, y_t + 36, f"{cat}  ->  {mapping}")
        c.setFont("Helvetica", 8.5)
        c.setFillColor(TEXT_MUTED)
        c.drawString(52, y_t + 18, ex)
        y_t -= 68
        
    # Right: Multi-transaction
    draw_card(c, 40 + half_w + 20, 60, half_w, 260, border=EMERALD_LIGHT)
    c.setFont("Helvetica-Bold", 13)
    c.setFillColor(TEXT_WHITE)
    c.drawString(60 + half_w + 20, 290, "Multi-Transaction Extraction in One Sentence")
    
    c.setFont("Helvetica", 9.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(60 + half_w + 20, 270, "A shopkeeper speaks in a single breath:")
    
    c.setFont("Helvetica-Oblique", 10)
    c.setFillColor(AMBER_ACCENT)
    c.drawString(60 + half_w + 20, 248, '"Aaj 6000 ki bikri hui, 2500 ka stock liya, aur 500 kiraya diya."')
    
    c.setFont("Helvetica-Bold", 10)
    c.setFillColor(TEXT_WHITE)
    c.drawString(60 + half_w + 20, 215, "Deconstructed into 3 Distinct Accounting Entries:")
    
    entries = [
        ("🟢 Sale: PKR 6,000", "Category: other  |  Note: Aaj bikri hui"),
        ("🟠 Purchase: PKR 2,500", "Category: stock  |  Note: Stock liya"),
        ("🔴 Expense: PKR 500", "Category: rent   |  Note: Kiraya diya")
    ]
    y_e = 185
    for e, m in entries:
        draw_card(c, 55 + half_w + 20, y_e, half_w - 30, 30, bg=colors.HexColor("#08121E"))
        c.setFont("Helvetica-Bold", 9)
        c.setFillColor(TEXT_WHITE)
        c.drawString(65 + half_w + 20, y_e + 16, e)
        c.setFont("Helvetica", 8)
        c.setFillColor(TEXT_MUTED)
        c.drawString(65 + half_w + 20, y_e + 6, m)
        y_e -= 38
        
    c.showPage()
    
    # =========================================================
    # SLIDE 6: ZERO HALLUCINATION
    # =========================================================
    draw_background(c)
    draw_header(c, "Trust & Data Integrity", "The Zero-Hallucination Safeguard",
                "In financial bookkeeping, AI hallucinations corrupt balance sheets. Karobar Saathi never guesses.",
                AMBER_ACCENT, colors.HexColor("#2B1C0A"))
                
    draw_card(c, 40, 50, half_w, 270, border=AMBER_ACCENT)
    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(AMBER_ACCENT)
    c.drawString(55, 290, 'The Ambiguous Input: "3000 diye"')
    
    c.setFont("Helvetica", 9.5)
    c.setFillColor(TEXT_WHITE)
    c.drawString(55, 268, "A shopkeeper says: '3000 diye' (Gave 3000).")
    c.drawString(55, 254, "Did they buy inventory? Pay rent? Give cash to family?")
    
    c.setFont("Helvetica-Bold", 9.5)
    c.setFillColor(ROSE_ACCENT)
    c.drawString(55, 220, "❌ Generic AI:")
    c.setFont("Helvetica", 9)
    c.drawString(55, 206, "Guesses 'Expense: PKR 3,000' (Silently corrupts the ledger).")
    
    c.setFont("Helvetica-Bold", 9.5)
    c.setFillColor(MINT_ACCENT)
    c.drawString(55, 175, "✔️ Karobar Saathi:")
    c.setFont("Helvetica", 9)
    c.drawString(55, 161, "Flags entry_type: 'unclear' & disables saving until clarified.")
    
    draw_card(c, 50, 70, half_w - 20, 60, bg=colors.HexColor("#1A1408"), border=AMBER_ACCENT)
    c.setFont("Helvetica-Bold", 9)
    c.setFillColor(AMBER_ACCENT)
    c.drawString(60, 112, "Conversational Clarification Prompt:")
    c.setFont("Helvetica-Oblique", 9.5)
    c.setFillColor(TEXT_WHITE)
    c.drawString(60, 95, '"Bikri ki amount kya hai ya ye paise kisko diye the?"')
    
    # Right: 3 Rules
    draw_card(c, 40 + half_w + 20, 50, half_w, 270)
    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(TEXT_WHITE)
    c.drawString(60 + half_w + 20, 290, "Three Principles of Financial Integrity")
    
    rules = [
        ("1. Strict Structural Output Enums", "JSON Schema enforcement: entry_type must strictly be one of [sale, purchase, expense, withdrawal, unclear]."),
        ("2. Human-in-the-Loop Confirmation", "Every extracted transaction renders an editable visual card. The user can tweak category or amount before saving."),
        ("3. Spoken Audio Audit Trail", "Original spoken audio transcripts are permanently bound to the ledger entry, creating an immutable forensic record.")
    ]
    y_r = 245
    for t, d in rules:
        c.setFont("Helvetica-Bold", 10.5)
        c.setFillColor(EMERALD_LIGHT)
        c.drawString(60 + half_w + 20, y_r, t)
        c.setFont("Helvetica", 8.5)
        c.setFillColor(TEXT_MUTED)
        c.drawString(60 + half_w + 20, y_r - 14, d[:65])
        c.drawString(60 + half_w + 20, y_r - 26, d[65:])
        y_r -= 60
        
    c.showPage()
    
    # =========================================================
    # SLIDE 7: EVIDENCE PROFILE ENGINE
    # =========================================================
    draw_background(c)
    draw_header(c, "Fintech Engine", "Converting Voice Notes into Underwriting Evidence",
                "Microfinance banks don't have time to read thousands of ledger lines. We distill raw records into statistical signals.",
                INDIGO_ACCENT, colors.HexColor("#1A163B"))
                
    draw_card(c, 40, 230, half_w, 85)
    c.setFont("Helvetica-Bold", 10.5)
    c.setFillColor(EMERALD_LIGHT)
    c.drawString(52, 295, "1. Transaction Consistency Index")
    c.setFont("Helvetica", 8.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(52, 278, "Calculates recorded active days over 30 days. Proves operational stability.")
    c.setFont("Helvetica", 8)
    c.setFillColor(TEXT_WHITE)
    c.drawString(52, 260, "Formula: Active Days / 30  (Target: > 80% for Tier 1 micro-loan)")
    
    draw_card(c, 40, 135, half_w, 85)
    c.setFont("Helvetica-Bold", 10.5)
    c.setFillColor(AMBER_ACCENT)
    c.drawString(52, 200, "2. Sales Volatility (Coefficient of Variation)")
    c.setFont("Helvetica", 8.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(52, 183, "Evaluates week-over-week revenue variance to assess income stability.")
    c.setFont("Helvetica", 8)
    c.setFillColor(TEXT_WHITE)
    c.drawString(52, 165, "Formula: StdDev(Sales) / Mean  (CV < 0.20 = Low Risk)")
    
    draw_card(c, 40, 40, half_w, 85)
    c.setFont("Helvetica-Bold", 10.5)
    c.setFillColor(ROSE_ACCENT)
    c.drawString(52, 105, "3. Net Cash Buffer Runway")
    c.setFont("Helvetica", 8.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(52, 88, "Measures how many days of operating expenses are covered.")
    c.setFont("Helvetica", 8)
    c.setFillColor(TEXT_WHITE)
    c.drawString(52, 70, "Formula: Net Cash / Daily Expenses = Buffer Days (Safe: > 7 days)")
    
    # Right: Code Card
    draw_card(c, 40 + half_w + 20, 40, half_w, 275, border=INDIGO_ACCENT)
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(TEXT_WHITE)
    c.drawString(55 + half_w + 20, 295, "Lender Evidence Profile API Output")
    c.setFont("Helvetica", 8.5)
    c.setFillColor(MINT_ACCENT)
    c.drawString(55 + half_w + 20, 280, "GET /api/v1/evidence-profile/shop_001")
    
    json_lines = [
        '{',
        '  "user_id": "shop_001",',
        '  "avg_daily_sales": 4250.00,',
        '  "sales_volatility": "low",',
        '  "days_with_transactions": 26,',
        '  "cash_buffer_days": 8,',
        '  "net_cash_position": 48200.00,',
        '  "readiness_summary": "Stable cash flow.',
        '    Suitable for micro-loan PKR 50,000-100,000.",',
        '  "explainable_factors": [',
        '    "Recorded transactions on 87% of days in last 30 days",',
        '    "Sales variance < 20% week-to-week — stable pattern",',
        '    "Positive cash buffer: ~8 days expenses covered"',
        '  ]',
        '}'
    ]
    y_j = 255
    c.setFont("Courier", 7.5)
    c.setFillColor(TEXT_MUTED)
    for jl in json_lines:
        c.drawString(55 + half_w + 20, y_j, jl)
        y_j -= 13
        
    c.showPage()
    
    # =========================================================
    # SLIDE 8: PRIVACY & SOVEREIGNTY
    # =========================================================
    draw_background(c)
    draw_header(c, "Privacy by Design", "Shopkeeper Sovereignty: Consent-Gated Architecture",
                "We refuse predatory data harvesting. The shopkeeper retains absolute legal and technical ownership of their financial records.",
                AMBER_ACCENT, colors.HexColor("#2B1C0A"))
                
    card_w = (PAGE_WIDTH - 80 - 32) / 3
    
    draw_card(c, 40, 130, card_w, 180)
    c.setFont("Helvetica-Bold", 24)
    c.setFillColor(EMERALD_LIGHT)
    c.drawString(55, 275, "🔐")
    c.setFont("Helvetica-Bold", 11)
    c.drawString(55, 245, "Cryptographic Consent")
    c.setFont("Helvetica", 8.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(55, 220, "Evidence API strictly requires an")
    c.drawString(55, 205, "X-User-Consent: true header verified")
    c.drawString(55, 190, "against database user state.")
    
    draw_card(c, 40 + card_w + 16, 130, card_w, 180)
    c.setFont("Helvetica-Bold", 24)
    c.setFillColor(AMBER_ACCENT)
    c.drawString(55 + card_w + 16, 275, "⚡")
    c.setFont("Helvetica-Bold", 11)
    c.drawString(55 + card_w + 16, 245, "One-Tap Revocation")
    c.setFont("Helvetica", 8.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(55 + card_w + 16, 220, "If the shopkeeper toggles consent")
    c.drawString(55 + card_w + 16, 205, "off, external API queries are")
    c.drawString(55 + card_w + 16, 190, "immediately blocked with 403.")
    
    draw_card(c, 40 + (card_w + 16) * 2, 130, card_w, 180)
    c.setFont("Helvetica-Bold", 24)
    c.setFillColor(INDIGO_ACCENT)
    c.drawString(55 + (card_w + 16) * 2, 275, "🛡️")
    c.setFont("Helvetica-Bold", 11)
    c.drawString(55 + (card_w + 16) * 2, 245, "No Ad Tracking")
    c.setFont("Helvetica", 8.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(55 + (card_w + 16) * 2, 220, "No advertising SDKs, no behavioral")
    c.drawString(55 + (card_w + 16) * 2, 205, "trackers. Data is never shared or")
    c.drawString(55 + (card_w + 16) * 2, 190, "sold to external brokers.")
    
    draw_card(c, 40, 45, PAGE_WIDTH - 80, 65, border=AMBER_ACCENT)
    c.setFont("Helvetica-Bold", 9.5)
    c.setFillColor(AMBER_ACCENT)
    c.drawString(55, 85, "LIVE PROTOCOL VERIFICATION (docs/VERIFICATION.md):")
    c.setFont("Helvetica", 9)
    c.setFillColor(TEXT_WHITE)
    c.drawString(55, 65, "Revoking consent via PATCH .../consent makes GET /api/v1/evidence-profile return 403 consent_required even with X-User-Consent: true.")
    
    c.showPage()
    
    # =========================================================
    # SLIDE 9: TARGET PERSONAS
    # =========================================================
    draw_background(c)
    draw_header(c, "Target Market Personas", "Designed for Pakistan's Real Retail Ecosystem",
                "Calibrated with 30-day realistic test datasets representing the three largest segments of informal commerce.")
                
    personas = [
        ("☕ Ahmad Chai Wala", "Tea Stall · Urban Bazaar",
         "Daily Sales: PKR 3,000 - 5,500", "Consistency: 85% (High velocity)", "Top Costs: Milk, sugar, tea, LPG",
         "Needs quick 25k working capital for tea stock during winter peak.", EMERALD_LIGHT),
        ("🏪 Bibi Naseem", "Kirana Store · Neighborhood",
         "Daily Sales: PKR 5,000 - 9,000", "Consistency: 93% (Very consistent)", "Top Costs: Wholesale dry goods & FMCG",
         "Needs 100k credit line to buy wholesale dry goods at bulk discounts.", AMBER_ACCENT),
        ("🧵 Fatima Silai", "Home Tailor · Female Solo",
         "Daily Sales: PKR 1,500 - 4,000", "Consistency: 72% (Seasonal spikes)", "Top Costs: Fabric, thread, machine repair",
         "Home-based woman entrepreneur unable to travel to bank branches.", INDIGO_ACCENT)
    ]
    x_p = 40
    for title, sub, s, con, cost, quote, col in personas:
        draw_card(c, x_p, 45, card_w, 260, border=col)
        c.setFont("Helvetica-Bold", 12)
        c.setFillColor(TEXT_WHITE)
        c.drawString(x_p + 15, 275, title)
        c.setFont("Helvetica-Bold", 8.5)
        c.setFillColor(col)
        c.drawString(x_p + 15, 258, sub)
        
        c.setFont("Helvetica", 8.5)
        c.setFillColor(TEXT_MUTED)
        c.drawString(x_p + 15, 230, s)
        c.drawString(x_p + 15, 215, con)
        c.drawString(x_p + 15, 200, cost)
        
        c.setFont("Helvetica-Oblique", 8.5)
        c.setFillColor(TEXT_WHITE)
        c.drawString(x_p + 15, 160, f'"{quote}"')
        x_p += card_w + 16
        
    c.showPage()
    
    # =========================================================
    # SLIDE 10: PRODUCTION VERIFICATION
    # =========================================================
    draw_background(c)
    draw_header(c, "Production Verification", "Production-Grade Rigor & Battle-Tested Code",
                "Not just a prototype — backed by comprehensive test coverage, cold-start handling, and verified audio pipelines.")
                
    # Left feats
    draw_card(c, 40, 225, half_w, 85)
    c.setFont("Helvetica-Bold", 10.5)
    c.setFillColor(EMERALD_LIGHT)
    c.drawString(52, 290, "🚀 Render Cold-Start Resilience")
    c.setFont("Helvetica", 8.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(52, 272, "Extended LLM call timeouts from 30s to 150s with localized status messages.")
    c.drawString(52, 258, "Background keep-warm pings every 10 mins eliminate user-facing latency.")
    
    draw_card(c, 40, 130, half_w, 85)
    c.setFont("Helvetica-Bold", 10.5)
    c.setFillColor(AMBER_ACCENT)
    c.drawString(52, 195, "🎙️ Hardware Voice-Recorder Migration (v1.4.0)")
    c.setFont("Helvetica", 8.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(52, 177, "Migrated to the umbrella record: ^5.2.1 package for 100% Android hardware")
    c.drawString(52, 163, "reliability. Added optimistic state, waveform animation, and 60s auto-stop.")
    
    draw_card(c, 40, 35, half_w, 85)
    c.setFont("Helvetica-Bold", 10.5)
    c.setFillColor(INDIGO_ACCENT)
    c.drawString(52, 100, "⚙️ Automated GitHub Actions CI")
    c.setFont("Helvetica", 8.5)
    c.setFillColor(TEXT_MUTED)
    c.drawString(52, 82, "Continuous integration runs full backend pytest suites alongside Flutter")
    c.drawString(52, 68, "analyzer and widget tests on every pull request.")
    
    # Right scoreboard
    draw_card(c, 40 + half_w + 20, 35, half_w, 275, border=MINT_ACCENT)
    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(TEXT_WHITE)
    c.drawString(60 + half_w + 20, 280, "Verification Scorecard")
    
    scores = [
        ("100%", "Flutter Analyze Clean", EMERALD_LIGHT),
        ("11 / 11", "Widget & Unit Tests Passing", AMBER_ACCENT),
        ("6 / 6", "Seed Audio Files E2E Verified", INDIGO_ACCENT),
        ("v1.4.0", "Release APK Ready for Install", MINT_ACCENT)
    ]
    y_sc = 230
    for v, l, col in scores:
        c.setFont("Helvetica-Bold", 20)
        c.setFillColor(col)
        c.drawString(60 + half_w + 20, y_sc, v)
        c.setFont("Helvetica-Bold", 10)
        c.setFillColor(TEXT_WHITE)
        c.drawString(140 + half_w + 20, y_sc + 4, l)
        y_sc -= 45
        
    c.showPage()
    
    # =========================================================
    # SLIDE 11: BUSINESS MODEL & GTM
    # =========================================================
    draw_background(c)
    draw_header(c, "Sustainable Monetization", "High-Margin B2B FinTech Business Model",
                "100% free for micro-businesses. Monetization is driven by institutional lenders and wholesale distributors.",
                INDIGO_ACCENT, colors.HexColor("#1A163B"))
                
    models = [
        ("SHOPKEEPER LAYER", "Always Free App", "Zero subscription fees for shopkeepers. Removes all friction to achieve viral word-of-mouth adoption across bazaar trade associations.", EMERALD_LIGHT),
        ("LENDER B2B API", "Credit Origination Fees", "Microfinance Banks (Mobilink Bank, Akhuwat, Kashf) pay a query fee per Evidence Profile plus a 1.5% - 2.5% origination fee upon loan disbursement.", AMBER_ACCENT),
        ("SUPPLY FINANCING", "FMCG Bulk Credit", "FMCG distributors (Unilever, Nestlé, Engro) utilize stock purchase evidence to underwrite 7-day inventory credit directly inside the app.", INDIGO_ACCENT)
    ]
    x_m = 40
    for tag, t, d, col in models:
        draw_card(c, x_m, 120, card_w, 190)
        c.setFont("Helvetica-Bold", 8)
        c.setFillColor(col)
        c.drawString(x_m + 15, 290, tag)
        c.setFont("Helvetica-Bold", 12)
        c.setFillColor(TEXT_WHITE)
        c.drawString(x_m + 15, 270, t)
        c.setFont("Helvetica", 8.5)
        c.setFillColor(TEXT_MUTED)
        c.drawString(x_m + 15, 240, d[:60])
        c.drawString(x_m + 15, 226, d[60:120])
        c.drawString(x_m + 15, 212, d[120:])
        x_m += card_w + 16
        
    draw_card(c, 40, 45, PAGE_WIDTH - 80, 60, border=EMERALD_LIGHT)
    c.setFont("Helvetica-Bold", 9.5)
    c.setFillColor(EMERALD_LIGHT)
    c.drawString(55, 85, "GO-TO-MARKET FLYWHEEL:")
    c.setFont("Helvetica", 9)
    c.setFillColor(TEXT_WHITE)
    c.drawString(55, 65, "Wholesale Mandi Onboarding -> Voice Recording Daily Habit -> First 30-Day Milestone -> Instant Loan Qualification  |  $180B+ Market")
    
    c.showPage()
    
    # =========================================================
    # SLIDE 12: ROADMAP
    # =========================================================
    draw_background(c)
    draw_header(c, "Future Horizon", "Strategic Product & Expansion Roadmap",
                "Scaling from working proof-of-concept to national financial inclusion infrastructure.")
                
    phases = [
        ("PHASE 1 (Current · Q3 2026)", "Offline-First Voice Sync",
         "• Local encrypted SQLite audio queue for zero-connectivity.",
         "• Background auto-sync when cellular signal returns.",
         "• Resilient auto-scaling cloud cluster deployment.", EMERALD_LIGHT),
        ("PHASE 2 (Q4 2026)", "Multi-Dialect Expansion",
         "• Fine-tuned Whisper models for Pashto, Sindhi, Punjabi.",
         "• Voice-based WhatsApp bot integration.",
         "• Automated customer ledger reminders (Udhaar recovery).", AMBER_ACCENT),
        ("PHASE 3 (Q1 2027)", "Raast Payment Rails",
         "• State Bank of Pakistan Raast P2M QR rails integration.",
         "• One-click digital loan acceptance & micro-repayments.",
         "• Formal credit bureau data ingestion (1Link / SBP ECIB).", INDIGO_ACCENT)
    ]
    x_ph = 40
    for tag, t, p1, p2, p3, col in phases:
        draw_card(c, x_ph, 45, card_w, 260, border=col)
        c.setFont("Helvetica-Bold", 8)
        c.setFillColor(col)
        c.drawString(x_ph + 15, 285, tag)
        c.setFont("Helvetica-Bold", 12)
        c.setFillColor(TEXT_WHITE)
        c.drawString(x_ph + 15, 265, t)
        
        c.setFont("Helvetica", 8.5)
        c.setFillColor(TEXT_MUTED)
        c.drawString(x_ph + 15, 235, p1)
        c.drawString(x_ph + 15, 205, p2)
        c.drawString(x_ph + 15, 175, p3)
        x_ph += card_w + 16
        
    c.showPage()
    
    # =========================================================
    # SLIDE 13: CONCLUSION & VISION
    # =========================================================
    draw_background(c)
    
    draw_badge(c, "The Vision", PAGE_WIDTH / 2 - 40, PAGE_HEIGHT - 65)
    
    c.setFont("Helvetica-Bold", 26)
    c.setFillColor(TEXT_WHITE)
    t_str = "Dukaan Aapki, Hisaab Karobar Saathi Ka."
    tw = c.stringWidth(t_str, "Helvetica-Bold", 26)
    c.drawString((PAGE_WIDTH - tw) / 2, PAGE_HEIGHT - 110, t_str)
    
    c.setFont("Helvetica-Bold", 16)
    c.setFillColor(EMERALD_LIGHT)
    u_str = "دکان آپ کی، حساب کاروبار ساتھی کا"
    uw = c.stringWidth(u_str, "Helvetica-Bold", 16)
    c.drawString((PAGE_WIDTH - uw) / 2, PAGE_HEIGHT - 140, u_str)
    
    c.setFont("Helvetica", 11)
    c.setFillColor(TEXT_MUTED)
    sub = "Empowering 5 million hardworking micro-entrepreneurs to be seen, verified, and funded — using nothing more than their daily voice."
    sw = c.stringWidth(sub, "Helvetica", 11)
    c.drawString((PAGE_WIDTH - sw) / 2, PAGE_HEIGHT - 175, sub)
    
    # Action card
    draw_card(c, 80, 80, PAGE_WIDTH - 160, 110, border=EMERALD_LIGHT)
    c.setFont("Helvetica-Bold", 12)
    c.setFillColor(TEXT_WHITE)
    c.drawString(100, 160, "🚀 Explore the Project & Resources:")
    
    c.setFont("Helvetica-Bold", 10)
    c.setFillColor(EMERALD_LIGHT)
    c.drawString(100, 135, "• Download APK v1.4.0:")
    c.setFont("Helvetica", 10)
    c.setFillColor(TEXT_MUTED)
    c.drawString(245, 135, "github.com/ahsankhizar5/karobar-saathi/releases/latest")
    
    c.setFont("Helvetica-Bold", 10)
    c.setFillColor(EMERALD_LIGHT)
    c.drawString(100, 115, "• Live API Homepage:")
    c.setFont("Helvetica", 10)
    c.setFillColor(TEXT_MUTED)
    c.drawString(245, 115, "ahsankhizar5.github.io/karobar-saathi")
    
    c.setFont("Helvetica-Bold", 10)
    c.setFillColor(EMERALD_LIGHT)
    c.drawString(100, 95, "• Production Backend:")
    c.setFont("Helvetica", 10)
    c.setFillColor(TEXT_MUTED)
    c.drawString(245, 95, "karobar-saathi.onrender.com")
    
    c.setFont("Helvetica", 9)
    c.setFillColor(TEXT_DIM)
    c.drawString((PAGE_WIDTH - 250) / 2, 45, "MIT Licensed · Open Source on GitHub · Built for Pakistan 🇵🇰")
    
    c.showPage()
    
    c.save()
    print(f"PDF Presentation generated successfully: {os.path.abspath(filename)}")

if __name__ == "__main__":
    build_pdf()
