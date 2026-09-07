"""
Generate Karobar Saathi Jaw-Dropping PowerPoint Presentation (.pptx).
Creates a 16:9 widescreen, custom dark-fintech styled presentation deck.
"""
import os
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

# -------------------------------------------------------------
# DESIGN SYSTEM CONSTANTS
# -------------------------------------------------------------
BG_DARK = RGBColor(7, 10, 18)       # #070A12
BG_CARD = RGBColor(18, 26, 42)      # #121A2A
BORDER_CARD = RGBColor(30, 41, 65)  # #1E2941
EMERALD_DARK = RGBColor(13, 111, 105) # #0D6F69
EMERALD_LIGHT = RGBColor(45, 212, 191) # #2DD4BF
MINT_ACCENT = RGBColor(16, 185, 129)  # #10B981
AMBER_ACCENT = RGBColor(245, 158, 11) # #F59E0B
ROSE_ACCENT = RGBColor(244, 63, 94)   # #F43F5E
INDIGO_ACCENT = RGBColor(99, 102, 241) # #6366F1
TEXT_WHITE = RGBColor(248, 250, 252)  # #F8FAFC
TEXT_MUTED = RGBColor(148, 163, 184)  # #94A3B8
TEXT_DIM = RGBColor(100, 116, 139)    # #64748B

FONT_TITLE = 'Arial'
FONT_BODY = 'Arial'

def create_deck():
    prs = Presentation()
    # 16:9 Widescreen
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_layout = prs.slide_layouts[6]

    def set_slide_background(slide):
        bg = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, Inches(13.333), Inches(7.5))
        bg.fill.solid()
        bg.fill.fore_color.rgb = BG_DARK
        bg.line.fill.background() # No border
        return bg

    def add_badge(slide, text, top=Inches(0.55), left=Inches(0.8), color=EMERALD_LIGHT, bg_color=EMERALD_DARK):
        badge = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, left, top, Inches(len(text)*0.11 + 0.5), Inches(0.38))
        badge.fill.solid()
        badge.fill.fore_color.rgb = bg_color
        badge.line.color.rgb = color
        badge.line.width = Pt(1)
        tf = badge.text_frame
        tf.word_wrap = False
        tf.margin_left = Inches(0.15)
        tf.margin_right = Inches(0.15)
        tf.margin_top = Inches(0.04)
        tf.margin_bottom = Inches(0.04)
        p = tf.paragraphs[0]
        p.text = text.upper()
        p.font.size = Pt(10)
        p.font.bold = True
        p.font.color.rgb = color
        return badge

    def add_header(slide, badge_text, title_text, subtitle_text, badge_color=EMERALD_LIGHT, badge_bg=EMERALD_DARK):
        add_badge(slide, badge_text, top=Inches(0.5), left=Inches(0.8), color=badge_color, bg_color=badge_bg)
        
        # Title box
        tbox = slide.shapes.add_textbox(Inches(0.8), Inches(0.95), Inches(11.733), Inches(0.8))
        tf = tbox.text_frame
        tf.word_wrap = True
        tf.margin_left = tf.margin_top = tf.margin_right = tf.margin_bottom = 0
        p = tf.paragraphs[0]
        p.text = title_text
        p.font.name = FONT_TITLE
        p.font.size = Pt(28)
        p.font.bold = True
        p.font.color.rgb = TEXT_WHITE
        
        # Subtitle box
        sbox = slide.shapes.add_textbox(Inches(0.8), Inches(1.65), Inches(11.733), Inches(0.6))
        stf = sbox.text_frame
        stf.word_wrap = True
        stf.margin_left = stf.margin_top = stf.margin_right = stf.margin_bottom = 0
        sp = stf.paragraphs[0]
        sp.text = subtitle_text
        sp.font.name = FONT_BODY
        sp.font.size = Pt(14)
        sp.font.color.rgb = TEXT_MUTED

    def add_card(slide, left, top, width, height, bg=BG_CARD, border=BORDER_CARD):
        card = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, left, top, width, height)
        card.fill.solid()
        card.fill.fore_color.rgb = bg
        card.line.color.rgb = border
        card.line.width = Pt(1.2)
        return card

    # =========================================================
    # SLIDE 1: TITLE HERO
    # =========================================================
    s1 = prs.slides.add_slide(blank_layout)
    set_slide_background(s1)
    
    # Logo or icon placeholder box
    icon_box = s1.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.8), Inches(1.0), Inches(1.3), Inches(1.3))
    icon_box.fill.solid()
    icon_box.fill.fore_color.rgb = EMERALD_DARK
    icon_box.line.color.rgb = EMERALD_LIGHT
    icon_box.line.width = Pt(2)
    tf = icon_box.text_frame
    p = tf.paragraphs[0]
    p.text = "KS"
    p.alignment = PP_ALIGN.CENTER
    p.font.size = Pt(36)
    p.font.bold = True
    p.font.color.rgb = TEXT_WHITE

    add_badge(s1, "Production-Ready Architecture · v1.4.0", top=Inches(2.6), left=Inches(0.8))

    tbox = s1.shapes.add_textbox(Inches(0.8), Inches(3.1), Inches(11.7), Inches(2.2))
    tf = tbox.text_frame
    tf.word_wrap = True
    p1 = tf.paragraphs[0]
    p1.text = "Karobar Saathi  (کاروبار ساتھی)"
    p1.font.name = FONT_TITLE
    p1.font.size = Pt(44)
    p1.font.bold = True
    p1.font.color.rgb = TEXT_WHITE

    p2 = tf.add_paragraph()
    p2.text = "Spoken Transactions → Confirmed Ledger → Explainable Financial Evidence"
    p2.font.size = Pt(22)
    p2.font.bold = True
    p2.font.color.rgb = EMERALD_LIGHT
    p2.space_before = Pt(12)

    p3 = tf.add_paragraph()
    p3.text = "Bridging the $180B informal economy with AI voice bookkeeping and sovereign credit profiles for 5 Million+ Pakistani micro-merchants."
    p3.font.size = Pt(15)
    p3.font.color.rgb = TEXT_MUTED
    p3.space_before = Pt(12)

    # Footer metadata card
    f_card = add_card(s1, Inches(0.8), Inches(5.8), Inches(11.733), Inches(1.1), bg=BG_CARD)
    ftf = f_card.text_frame
    ftf.margin_left = Inches(0.3)
    ftf.margin_top = Inches(0.2)
    fp = ftf.paragraphs[0]
    fp.text = "CORE TECH STACK: Flutter (Riverpod) · FastAPI · Groq Whisper-large-v3 · Vernacular LLM Parser · SQLite"
    fp.font.size = Pt(13)
    fp.font.bold = True
    fp.font.color.rgb = TEXT_WHITE

    fp2 = ftf.add_paragraph()
    fp2.text = "STATUS: Live Backend & APK Release v1.4.0  |  TARGET: Chai Stalls, Kirana Stores, Home Tailors, Khokhas"
    fp2.font.size = Pt(11)
    fp2.font.color.rgb = MINT_ACCENT
    fp2.space_before = Pt(4)

    # =========================================================
    # SLIDE 2: THE PROBLEM (THE INVISIBLE 5M)
    # =========================================================
    s2 = prs.slides.add_slide(blank_layout)
    set_slide_background(s2)
    add_header(s2, "Market Reality & Pain Points", "The Invisible 5 Million & The Unbanked Trap", 
               "Micro-businesses form the economic spine of Pakistan, yet 90%+ operate completely invisible to formal finance.",
               badge_color=ROSE_ACCENT, badge_bg=RGBColor(50, 15, 25))

    col_w = Inches(3.7)
    card_h = Inches(3.4)
    top_pos = Inches(2.4)

    # Col 1
    c1 = add_card(s2, Inches(0.8), top_pos, col_w, card_h)
    tf1 = c1.text_frame
    tf1.margin_left = tf1.margin_right = tf1.margin_top = Inches(0.25)
    p = tf1.paragraphs[0]
    p.text = "5.2M+"
    p.font.size = Pt(36)
    p.font.bold = True
    p.font.color.rgb = AMBER_ACCENT
    p2 = tf1.add_paragraph()
    p2.text = "Informal Micro-Enterprises"
    p2.font.size = Pt(14)
    p2.font.bold = True
    p2.font.color.rgb = TEXT_WHITE
    p3 = tf1.add_paragraph()
    p3.text = "Roadside stalls, kirana stores, home tailors, and tea stalls handling daily cash volume without bank accounts or formal registrations."
    p3.font.size = Pt(12)
    p3.font.color.rgb = TEXT_MUTED
    p3.space_before = Pt(10)

    # Col 2
    c2 = add_card(s2, Inches(4.8), top_pos, col_w, card_h)
    tf2 = c2.text_frame
    tf2.margin_left = tf2.margin_right = tf2.margin_top = Inches(0.25)
    p = tf2.paragraphs[0]
    p.text = "93%"
    p.font.size = Pt(36)
    p.font.bold = True
    p.font.color.rgb = ROSE_ACCENT
    p2 = tf2.add_paragraph()
    p2.text = "Paper & Memory Only (Bahi Khata)"
    p2.font.size = Pt(14)
    p2.font.bold = True
    p2.font.color.rgb = TEXT_WHITE
    p3 = tf2.add_paragraph()
    p3.text = "Traditional accounting software fails. Typing on touchscreens in English or Urdu keyboards after 14 hours of shop work is slow and exhausting."
    p3.font.size = Pt(12)
    p3.font.color.rgb = TEXT_MUTED
    p3.space_before = Pt(10)

    # Col 3
    c3 = add_card(s2, Inches(8.8), top_pos, col_w, card_h)
    tf3 = c3.text_frame
    tf3.margin_left = tf3.margin_right = tf3.margin_top = Inches(0.25)
    p = tf3.paragraphs[0]
    p.text = "25-30%"
    p.font.size = Pt(36)
    p.font.bold = True
    p.font.color.rgb = INDIGO_ACCENT
    p2 = tf3.add_paragraph()
    p2.text = "Monthly Predatory Loan Rates"
    p2.font.size = Pt(14)
    p2.font.bold = True
    p2.font.color.rgb = TEXT_WHITE
    p3 = tf3.add_paragraph()
    p3.text = "Without verified financial history, commercial banks reject micro-loans. Shopkeepers are trapped borrowing from informal local moneylenders."
    p3.font.size = Pt(12)
    p3.font.color.rgb = TEXT_MUTED
    p3.space_before = Pt(10)

    # Bottleneck bar
    bot = add_card(s2, Inches(0.8), Inches(6.1), Inches(11.7), Inches(0.9), bg=RGBColor(30, 20, 10), border=AMBER_ACCENT)
    btf = bot.text_frame
    btf.margin_left = Inches(0.3)
    btf.margin_top = Inches(0.22)
    bp = btf.paragraphs[0]
    bp.text = "THE CORE BOTTLENECK: Banks don't lend without evidence. Shopkeepers can't generate evidence without unbearable bookkeeping friction."
    bp.font.size = Pt(13)
    bp.font.bold = True
    bp.font.color.rgb = AMBER_ACCENT

    # =========================================================
    # SLIDE 3: THE BREAKTHROUGH SOLUTION
    # =========================================================
    s3 = prs.slides.add_slide(blank_layout)
    set_slide_background(s3)
    add_header(s3, "The Innovation", "Zero Typing. Zero Complexity. Just Speak in Urdu.", 
               "Karobar Saathi replaces the tedious bahi khata with an AI assistant that understands Pakistani bazaar vernacular.")

    # Left 3 stacked pillars
    p_w = Inches(6.8)
    p_h = Inches(1.3)
    
    # Pillar 1
    p1 = add_card(s3, Inches(0.8), Inches(2.4), p_w, p_h)
    ptf1 = p1.text_frame
    ptf1.margin_left = ptf1.margin_top = Inches(0.18)
    pp1 = ptf1.paragraphs[0]
    pp1.text = "1. Natural Voice-to-Ledger (5 Seconds a Day)"
    pp1.font.size = Pt(14)
    pp1.font.bold = True
    pp1.font.color.rgb = EMERALD_LIGHT
    pp1_sub = ptf1.add_paragraph()
    pp1_sub.text = "Speak at closing time. Groq Whisper-v3 + LLM parse complex multi-item sales and expenses in one breath with zero typing."
    pp1_sub.font.size = Pt(11)
    pp1_sub.font.color.rgb = TEXT_MUTED

    # Pillar 2
    p2 = add_card(s3, Inches(0.8), Inches(3.9), p_w, p_h)
    ptf2 = p2.text_frame
    ptf2.margin_left = ptf2.margin_top = Inches(0.18)
    pp2 = ptf2.paragraphs[0]
    pp2.text = "2. Hallucination-Proof Roman Urdu Clarification"
    pp2.font.size = Pt(14)
    pp2.font.bold = True
    pp2.font.color.rgb = AMBER_ACCENT
    pp2_sub = ptf2.add_paragraph()
    pp2_sub.text = "Never invents numbers. If ambiguous (e.g. '3000 diye'), prompts the shopkeeper: 'Bikri ki amount kya hai ya kisko diye?' before writing to disk."
    pp2_sub.font.size = Pt(11)
    pp2_sub.font.color.rgb = TEXT_MUTED

    # Pillar 3
    p3 = add_card(s3, Inches(0.8), Inches(5.4), p_w, p_h)
    ptf3 = p3.text_frame
    ptf3.margin_left = ptf3.margin_top = Inches(0.18)
    pp3 = ptf3.paragraphs[0]
    pp3.text = "3. Sovereign, Consent-Gated Evidence Engine"
    pp3.font.size = Pt(14)
    pp3.font.bold = True
    pp3.font.color.rgb = INDIGO_ACCENT
    pp3_sub = ptf3.add_paragraph()
    pp3_sub.text = "Transforms 30 days of daily entries into underwriting evidence (sales volatility, cash runway) for microfinance banks — with instant one-tap revocation."
    pp3_sub.font.size = Pt(11)
    pp3_sub.font.color.rgb = TEXT_MUTED

    # Right card: Live Demo Callout
    rc = add_card(s3, Inches(8.0), Inches(2.4), Inches(4.5), Inches(4.3), border=EMERALD_LIGHT)
    rtf = rc.text_frame
    rtf.margin_left = rtf.margin_right = rtf.margin_top = Inches(0.3)
    rp1 = rtf.paragraphs[0]
    rp1.text = "The Shopkeeper Flow"
    rp1.font.size = Pt(18)
    rp1.font.bold = True
    rp1.font.color.rgb = TEXT_WHITE
    
    steps = [
        ("🎙️ Tap Mic", "Shopkeeper records voice note in Urdu/Roman Urdu."),
        ("⚡ 1.2s Transcription", "Hosted Whisper-large-v3 converts voice to text."),
        ("🧠 Vernacular Parser", "Pakistani bazaar terms extracted into JSON schema."),
        ("📝 One-Tap Confirm", "Visual sheet shows sale/purchase before writing to ledger."),
        ("📊 Instant Profit Card", "Net profit and 7-day sales trend update automatically.")
    ]
    for title, desc in steps:
        sp_t = rtf.add_paragraph()
        sp_t.text = title
        sp_t.font.size = Pt(12)
        sp_t.font.bold = True
        sp_t.font.color.rgb = EMERALD_LIGHT
        sp_t.space_before = Pt(8)
        sp_d = rtf.add_paragraph()
        sp_d.text = desc
        sp_d.font.size = Pt(10)
        sp_d.font.color.rgb = TEXT_MUTED

    # =========================================================
    # SLIDE 4: SYSTEM ARCHITECTURE
    # =========================================================
    s4 = prs.slides.add_slide(blank_layout)
    set_slide_background(s4)
    add_header(s4, "Full-Stack Architecture", "Engineered for Low-End Android & Slow Connections",
               "A resilient three-tier pipeline connecting shopkeeper smartphones to institutional lending APIs.",
               badge_color=INDIGO_ACCENT, badge_bg=RGBColor(25, 25, 60))

    layers = [
        ("LAYER 1: PRESENTATION & RECORDING (FLUTTER APP)", 
         "State-managed with Riverpod. WhatsApp-style live waveform recording (record: ^5.2.1), haptic feedback, bilingual EN/UR with full RTL layout, and 150s cold-start tolerance.",
         "Tech: Flutter 3.x · Riverpod · record ^5.2.1 · Urdu RTL", EMERALD_LIGHT),
        ("LAYER 2: VERNACULAR AI PIPELINE (FASTAPI SERVICE)", 
         "Groq Whisper-large-v3 speech-to-text combined with specialized Pakistani bazaar LLM parser. Enforces strict JSON Schema and flags ambiguous inputs for conversational clarification.",
         "Tech: FastAPI · Groq Whisper-v3 · Groq LLM · Bazaar Glossary", AMBER_ACCENT),
        ("LAYER 3: LEDGER STORE & EVIDENCE COMPUTER (B2B API)", 
         "ACID SQLite persistence storing confirmed entries. Computes 30-day volatility (CV), cash buffer runway, and loan ranges. Protected by X-User-Consent authorization headers.",
         "Tech: SQLite · Rule Heuristics · X-User-Consent · REST API", INDIGO_ACCENT),
    ]

    for i, (title, desc, tech, col) in enumerate(layers):
        l_top = Inches(2.4 + i * 1.5)
        lc = add_card(s4, Inches(0.8), l_top, Inches(11.733), Inches(1.3))
        ltf = lc.text_frame
        ltf.margin_left = ltf.margin_top = Inches(0.2)
        lp1 = ltf.paragraphs[0]
        lp1.text = title
        lp1.font.size = Pt(13)
        lp1.font.bold = True
        lp1.font.color.rgb = col
        lp2 = ltf.add_paragraph()
        lp2.text = desc
        lp2.font.size = Pt(11)
        lp2.font.color.rgb = TEXT_WHITE
        lp2.space_before = Pt(3)
        lp3 = ltf.add_paragraph()
        lp3.text = tech
        lp3.font.size = Pt(10)
        lp3.font.color.rgb = TEXT_MUTED
        lp3.space_before = Pt(3)

    # =========================================================
    # SLIDE 5: VERNACULAR AI & BAZAAR DICTIONARY
    # =========================================================
    s5 = prs.slides.add_slide(blank_layout)
    set_slide_background(s5)
    add_header(s5, "Proprietary AI Engineering", "Deciphering Pakistani Bazaar Vernacular",
               "Standard financial LLMs fail in street Urdu. Karobar Saathi is calibrated with a native bazaar taxonomy.")

    # Left: 4 Term categories
    c_w = Inches(5.6)
    c_h = Inches(0.95)
    terms = [
        ("Sales & Income", '"Bikri", "Kamai", "Kamaya", "Aamdani", "Becha", "Ki sale hui"', 'type: "sale"', EMERALD_LIGHT),
        ("Stock Purchases", '"Maal", "Stock liya", "Khareeda", "Samaan", "Cheeni doodh liya"', 'type: "purchase"', AMBER_ACCENT),
        ("Expenses & Bills", '"Bijli ka bill", "Dukaan ka kiraya", "Gas bill", "Committee"', 'type: "expense"', ROSE_ACCENT),
        ("Withdrawals", '"Ghar bheje", "Ghar ke liye nikaale", "Ghar kharch", "Udhaar diya"', 'type: "withdrawal"', INDIGO_ACCENT)
    ]
    for i, (cat, examples, mapping, col) in enumerate(terms):
        tc = add_card(s5, Inches(0.8), Inches(2.4 + i * 1.1), c_w, c_h)
        ttf = tc.text_frame
        ttf.margin_left = ttf.margin_top = Inches(0.15)
        tp = ttf.paragraphs[0]
        tp.text = f"{cat}  →  {mapping}"
        tp.font.size = Pt(12)
        tp.font.bold = True
        tp.font.color.rgb = col
        tp2 = ttf.add_paragraph()
        tp2.text = examples
        tp2.font.size = Pt(10)
        tp2.font.color.rgb = TEXT_MUTED

    # Right: Multi-Transaction Example
    mc = add_card(s5, Inches(6.8), Inches(2.4), Inches(5.7), Inches(4.25), border=EMERALD_LIGHT)
    mtf = mc.text_frame
    mtf.margin_left = mtf.margin_top = Inches(0.25)
    mp1 = mtf.paragraphs[0]
    mp1.text = "Multi-Transaction Extraction in One Sentence"
    mp1.font.size = Pt(16)
    mp1.font.bold = True
    mp1.font.color.rgb = TEXT_WHITE

    mp2 = mtf.add_paragraph()
    mp2.text = 'Spoken Voice Note:\n"Aaj 6000 ki bikri hui, 2500 ka stock liya, aur 500 kiraya diya."'
    mp2.font.size = Pt(12)
    mp2.font.color.rgb = AMBER_ACCENT
    mp2.space_before = Pt(8)

    mp3 = mtf.add_paragraph()
    mp3.text = "AI Automatically Deconstructs into 3 Structured Entries:"
    mp3.font.size = Pt(11)
    mp3.font.bold = True
    mp3.font.color.rgb = TEXT_WHITE
    mp3.space_before = Pt(10)

    extracted = [
        ("🟢 Sale: PKR 6,000", "Category: other | Note: Aaj bikri hui"),
        ("🟠 Purchase: PKR 2,500", "Category: stock | Note: Stock liya"),
        ("🔴 Expense: PKR 500", "Category: rent | Note: Kiraya diya")
    ]
    for ent, meta in extracted:
        ep = mtf.add_paragraph()
        ep.text = f"• {ent}  ({meta})"
        ep.font.size = Pt(11)
        ep.font.color.rgb = TEXT_MUTED
        ep.space_before = Pt(4)

    # =========================================================
    # SLIDE 6: ZERO-HALLUCINATION SAFEGUARD
    # =========================================================
    s6 = prs.slides.add_slide(blank_layout)
    set_slide_background(s6)
    add_header(s6, "Trust & Data Integrity", "The Zero-Hallucination Safeguard",
               "In financial bookkeeping, AI hallucinations corrupt balance sheets. Karobar Saathi never guesses.",
               badge_color=AMBER_ACCENT, badge_bg=RGBColor(40, 25, 10))

    # Left box: Ambiguity case
    left_c = add_card(s6, Inches(0.8), Inches(2.4), Inches(5.6), Inches(4.3), border=AMBER_ACCENT)
    ltf = left_c.text_frame
    ltf.margin_left = ltf.margin_top = Inches(0.25)
    lp = ltf.paragraphs[0]
    lp.text = 'The Ambiguous Input: "3000 diye"'
    lp.font.size = Pt(18)
    lp.font.bold = True
    lp.font.color.rgb = AMBER_ACCENT

    lp2 = ltf.add_paragraph()
    lp2.text = "A shopkeeper says: '3000 diye' (Gave 3000).\nDid they buy inventory? Pay shop rent? Give cash to family? Pay back a loan?"
    lp2.font.size = Pt(12)
    lp2.font.color.rgb = TEXT_WHITE
    lp2.space_before = Pt(8)

    lp3 = ltf.add_paragraph()
    lp3.text = "❌ Generic AI Models:\nGuesses 'Expense: PKR 3,000' (Silently corrupts the ledger)."
    lp3.font.size = Pt(11)
    lp3.font.color.rgb = ROSE_ACCENT
    lp3.space_before = Pt(10)

    lp4 = ltf.add_paragraph()
    lp4.text = "✔️ Karobar Saathi Engine:\nFlags entry_type: 'unclear' & disables saving until confirmed."
    lp4.font.size = Pt(11)
    lp4.font.color.rgb = MINT_ACCENT
    lp4.space_before = Pt(10)

    lp5 = ltf.add_paragraph()
    lp5.text = 'Conversational Clarification Prompt:\n"Bikri ki amount kya hai ya ye paise kisko diye the?"'
    lp5.font.size = Pt(12)
    lp5.font.bold = True
    lp5.font.color.rgb = EMERALD_LIGHT
    lp5.space_before = Pt(10)

    # Right: 3 Rules
    right_c = add_card(s6, Inches(6.8), Inches(2.4), Inches(5.7), Inches(4.3))
    rtf = right_c.text_frame
    rtf.margin_left = rtf.margin_top = Inches(0.25)
    rp = rtf.paragraphs[0]
    rp.text = "Three Principles of Financial Data Integrity"
    rp.font.size = Pt(18)
    rp.font.bold = True
    rp.font.color.rgb = TEXT_WHITE

    principles = [
        ("1. Strict Structural Output Enums", "Leverages JSON schema enforcement: entry_type must strictly be one of [sale, purchase, expense, withdrawal, unclear]."),
        ("2. Human-in-the-Loop Confirmation", "Every extracted transaction renders an editable visual card. The shopkeeper reviews amount and category before it touches the database."),
        ("3. Spoken Audio Audit Trail", "Original spoken audio transcripts are permanently bound to the confirmed ledger entry, preserving an immutable forensic paper trail.")
    ]
    for title, desc in principles:
        pt = rtf.add_paragraph()
        pt.text = title
        pt.font.size = Pt(13)
        pt.font.bold = True
        pt.font.color.rgb = EMERALD_LIGHT
        pt.space_before = Pt(10)
        pd = rtf.add_paragraph()
        pd.text = desc
        pd.font.size = Pt(11)
        pd.font.color.rgb = TEXT_MUTED

    # =========================================================
    # SLIDE 7: THE SHOPKEEPER EXPERIENCE (APP SHOWCASE)
    # =========================================================
    s7 = prs.slides.add_slide(blank_layout)
    set_slide_background(s7)
    add_header(s7, "User-Centric Product Design", "Crafted for Urdu Speakers & Low-Literacy Users",
               "Intuitive visual hierarchy, full bilingual localization, and WhatsApp-inspired haptic voice controls.")

    screens = [
        ("1. Profile Picker", "Choose shopkeeper profile (Ahmad Chai Wala, Bibi Naseem, Fatima Silai). Session persists across restarts.", EMERALD_LIGHT),
        ("2. Daily Dashboard", "Profit hero card, 7-day sales trend chart, cash buffer days, and actionable business insights.", AMBER_ACCENT),
        ("3. Transaction Sheet", "Urdu RTL confirmation sheet with instant category badges and confirmation buttons.", ROSE_ACCENT),
        ("4. Bahi Khata Ledger", "Categorized entries with collapsed transcript, tap-to-expand forensic detail, and date filters.", INDIGO_ACCENT)
    ]
    card_w = Inches(2.75)
    for i, (title, desc, col) in enumerate(screens):
        sc = add_card(s7, Inches(0.8 + i * 2.95), Inches(2.4), card_w, Inches(4.3))
        stf = sc.text_frame
        stf.margin_left = stf.margin_right = stf.margin_top = Inches(0.2)
        sp = stf.paragraphs[0]
        sp.text = title
        sp.font.size = Pt(14)
        sp.font.bold = True
        sp.font.color.rgb = col
        sp2 = stf.add_paragraph()
        sp2.text = desc
        sp2.font.size = Pt(11)
        sp2.font.color.rgb = TEXT_MUTED
        sp2.space_before = Pt(8)

        # Mock phone illustration box
        mock = add_card(s7, Inches(0.95 + i * 2.95), Inches(4.3), Inches(2.45), Inches(2.2), bg=RGBColor(12, 18, 30), border=col)
        mtf = mock.text_frame
        mtf.margin_left = mtf.margin_top = Inches(0.15)
        mp = mtf.paragraphs[0]
        mp.text = f"📱 Live Screenshot\n({title.split('.')[1].strip()})\nVerified in APK v1.4.0"
        mp.font.size = Pt(10)
        mp.font.color.rgb = TEXT_MUTED
        mp.alignment = PP_ALIGN.CENTER

    # =========================================================
    # SLIDE 8: THE EVIDENCE PROFILE ENGINE
    # =========================================================
    s8 = prs.slides.add_slide(blank_layout)
    set_slide_background(s8)
    add_header(s8, "Fintech Engine", "Converting Voice Notes into Underwriting Evidence",
               "Microfinance banks don't have time to read thousands of ledger lines. We distill raw records into statistical credit signals.",
               badge_color=INDIGO_ACCENT, badge_bg=RGBColor(25, 25, 60))

    # Left 3 metrics
    m_w = Inches(5.6)
    metrics = [
        ("1. Transaction Consistency Index", "Calculates recorded active days over 30 days. Proves operational stability and daily commercial discipline.", "Active Days / 30  (Target: > 80%)", EMERALD_LIGHT),
        ("2. Sales Volatility (Coefficient of Variation)", "Evaluates week-over-week revenue variation to assess whether income is stable or wildly seasonal.", "CV < 0.20 = Low Risk | CV > 0.40 = High", AMBER_ACCENT),
        ("3. Net Cash Buffer Runway", "Measures how many days of operating expenses are covered if revenue momentarily halts.", "Net Cash / Daily Expenses = Buffer Days", ROSE_ACCENT)
    ]
    for i, (title, desc, formula, col) in enumerate(metrics):
        mc = add_card(s8, Inches(0.8), Inches(2.4 + i * 1.4), m_w, Inches(1.25))
        mtf = mc.text_frame
        mtf.margin_left = mtf.margin_top = Inches(0.15)
        mp = mtf.paragraphs[0]
        mp.text = title
        mp.font.size = Pt(13)
        mp.font.bold = True
        mp.font.color.rgb = col
        mp2 = mtf.add_paragraph()
        mp2.text = desc
        mp2.font.size = Pt(10.5)
        mp2.font.color.rgb = TEXT_WHITE
        mp3 = mtf.add_paragraph()
        mp3.text = f"Formula: {formula}"
        mp3.font.size = Pt(9.5)
        mp3.font.color.rgb = TEXT_MUTED

    # Right: JSON API Profile
    rc = add_card(s8, Inches(6.8), Inches(2.4), Inches(5.7), Inches(4.3), border=INDIGO_ACCENT)
    rtf = rc.text_frame
    rtf.margin_left = rtf.margin_top = Inches(0.2)
    rp = rtf.paragraphs[0]
    rp.text = "Consent-Gated Evidence API Output"
    rp.font.size = Pt(15)
    rp.font.bold = True
    rp.font.color.rgb = TEXT_WHITE

    code = (
        'GET /api/v1/evidence-profile/shop_001\n'
        'Header: X-User-Consent: true\n\n'
        '{\n'
        '  "user_id": "shop_001",\n'
        '  "avg_daily_sales": 4250.00,\n'
        '  "sales_volatility": "low",\n'
        '  "days_with_transactions": 26,\n'
        '  "cash_buffer_days": 8,\n'
        '  "net_cash_position": 48200.00,\n'
        '  "readiness_summary": "Stable cash flow.\n'
        '    Suitable for micro-loan PKR 50,000-100,000.",\n'
        '  "explainable_factors": [\n'
        '    "Recorded transactions on 87% of days in last 30 days",\n'
        '    "Sales variance < 20% week-to-week — stable pattern",\n'
        '    "Positive cash buffer: ~8 days expenses covered"\n'
        '  ]\n'
        '}'
    )
    rp2 = rtf.add_paragraph()
    rp2.text = code
    rp2.font.name = 'Consolas'
    rp2.font.size = Pt(9.5)
    rp2.font.color.rgb = EMERALD_LIGHT
    rp2.space_before = Pt(6)

    # =========================================================
    # SLIDE 9: SHOPKEEPER SOVEREIGNTY & PRIVACY
    # =========================================================
    s9 = prs.slides.add_slide(blank_layout)
    set_slide_background(s9)
    add_header(s9, "Privacy by Design", "Shopkeeper Sovereignty: Consent-Gated Architecture",
               "We refuse predatory data harvesting. The shopkeeper retains absolute legal and technical ownership of their financial records.",
               badge_color=AMBER_ACCENT, badge_bg=RGBColor(40, 25, 10))

    priv_cards = [
        ("🔐 Cryptographic Consent Gate", "The Evidence API strictly requires an X-User-Consent: true header verified against user consent database state.", EMERALD_LIGHT),
        ("⚡ One-Tap Instant Revocation", "If the shopkeeper toggles consent off in the app, external API queries are immediately blocked with HTTP 403 Forbidden.", AMBER_ACCENT),
        ("🛡️ Zero Third-Party Ad Tracking", "No advertising SDKs, no behavioural trackers. Data is never shared or monetized with external brokers.", INDIGO_ACCENT)
    ]
    for i, (title, desc, col) in enumerate(priv_cards):
        pc = add_card(s9, Inches(0.8 + i * 4.0), Inches(2.4), Inches(3.7), Inches(3.2))
        ptf = pc.text_frame
        ptf.margin_left = ptf.margin_right = ptf.margin_top = Inches(0.25)
        pp = ptf.paragraphs[0]
        pp.text = title
        pp.font.size = Pt(15)
        pp.font.bold = True
        pp.font.color.rgb = col
        pp2 = ptf.add_paragraph()
        pp2.text = desc
        pp2.font.size = Pt(12)
        pp2.font.color.rgb = TEXT_MUTED
        pp2.space_before = Pt(10)

    # Bottom bar: Verified in verification log
    v_bar = add_card(s9, Inches(0.8), Inches(5.9), Inches(11.7), Inches(1.0), border=AMBER_ACCENT)
    vtf = v_bar.text_frame
    vtf.margin_left = Inches(0.3)
    vtf.margin_top = Inches(0.2)
    vp = vtf.paragraphs[0]
    vp.text = "LIVE PROTOCOL VERIFICATION (docs/VERIFICATION.md):"
    vp.font.size = Pt(11)
    vp.font.bold = True
    vp.font.color.rgb = AMBER_ACCENT
    vp2 = vtf.add_paragraph()
    vp2.text = "Revoking consent via PATCH .../consent immediately makes GET /api/v1/evidence-profile return 403 consent_required even with X-User-Consent: true."
    vp2.font.size = Pt(11)
    vp2.font.color.rgb = TEXT_WHITE

    # =========================================================
    # SLIDE 10: TARGET PERSONAS & VALIDATION
    # =========================================================
    s10 = prs.slides.add_slide(blank_layout)
    set_slide_background(s10)
    add_header(s10, "Target Market Personas", "Designed for Pakistan's Real Retail Ecosystem",
               "Calibrated with 30-day realistic test datasets representing the three largest segments of informal commerce.")

    personas = [
        ("☕ Ahmad Chai Wala", "Tea Stall · Urban Bazaar",
         "Daily Sales: PKR 3,000 - 5,500\nConsistency: 85% (High velocity)\nTop Costs: Milk, sugar, tea leaves, LPG\n\nUse Case: Needs PKR 25k working capital for tea stock during winter peak without paying loan sharks.", EMERALD_LIGHT),
        ("🏪 Bibi Naseem", "Kirana Store · Neighborhood",
         "Daily Sales: PKR 5,000 - 9,000\nConsistency: 93% (Very consistent)\nTop Costs: Wholesale dry goods & FMCG\n\nUse Case: Needs PKR 100k credit line to purchase wholesale rice, oil, and flour at 15% bulk discounts.", AMBER_ACCENT),
        ("🧵 Fatima Silai", "Home Tailor · Female Solo",
         "Daily Sales: PKR 1,500 - 4,000\nConsistency: 72% (Seasonal spikes)\nTop Costs: Fabric, thread, machine repair\n\nUse Case: Home-based woman entrepreneur unable to travel to bank branches; builds credit history from her living room.", INDIGO_ACCENT)
    ]
    for i, (title, sub, details, col) in enumerate(personas):
        pc = add_card(s10, Inches(0.8 + i * 4.0), Inches(2.4), Inches(3.7), Inches(4.3), border=col)
        ptf = pc.text_frame
        ptf.margin_left = ptf.margin_right = ptf.margin_top = Inches(0.25)
        pp = ptf.paragraphs[0]
        pp.text = title
        pp.font.size = Pt(16)
        pp.font.bold = True
        pp.font.color.rgb = TEXT_WHITE
        pp_sub = ptf.add_paragraph()
        pp_sub.text = sub
        pp_sub.font.size = Pt(11)
        pp_sub.font.color.rgb = col
        pp_det = ptf.add_paragraph()
        pp_det.text = details
        pp_det.font.size = Pt(11)
        pp_det.font.color.rgb = TEXT_MUTED
        pp_det.space_before = Pt(8)

    # =========================================================
    # SLIDE 11: PRODUCTION ENGINEERING & VERIFICATION
    # =========================================================
    s11 = prs.slides.add_slide(blank_layout)
    set_slide_background(s11)
    add_header(s11, "Production Verification", "Production-Grade Rigor & Battle-Tested Code",
               "Not just a prototype — backed by comprehensive test coverage, cold-start handling, and verified audio pipelines.")

    # Left: 3 engineering feats
    e_w = Inches(6.8)
    feats = [
        ("🚀 Render Cold-Start Resilience", "Extended LLM call timeouts from 30s to 150s with localized 'Server waking up' messages. Keep-warm ping every 10 mins and on app resume maintains awake state.", EMERALD_LIGHT),
        ("🎙️ Hardware Voice-Recorder Migration (v1.4.0)", "Migrated to the umbrella record: ^5.2.1 package for 100% Android hardware reliability. Added optimistic recording state, haptic feedback, and 60s auto-stop.", AMBER_ACCENT),
        ("⚙️ Automated GitHub Actions CI", "Continuous integration runs full backend pytest suites alongside Flutter analyzer and widget tests on every pull request.", INDIGO_ACCENT)
    ]
    for i, (title, desc, col) in enumerate(feats):
        fc = add_card(s11, Inches(0.8), Inches(2.4 + i * 1.4), e_w, Inches(1.25))
        ftf = fc.text_frame
        ftf.margin_left = ftf.margin_top = Inches(0.15)
        fp = ftf.paragraphs[0]
        fp.text = title
        fp.font.size = Pt(13)
        fp.font.bold = True
        fp.font.color.rgb = col
        fp2 = ftf.add_paragraph()
        fp2.text = desc
        fp2.font.size = Pt(10.5)
        fp2.font.color.rgb = TEXT_WHITE
        fp2.space_before = Pt(2)

    # Right: 4 Scoreboard stats
    sc_card = add_card(s11, Inches(8.0), Inches(2.4), Inches(4.5), Inches(4.3), border=MINT_ACCENT)
    stf = sc_card.text_frame
    stf.margin_left = stf.margin_top = Inches(0.25)
    sp = stf.paragraphs[0]
    sp.text = "Verification Scorecard"
    sp.font.size = Pt(18)
    sp.font.bold = True
    sp.font.color.rgb = TEXT_WHITE

    stats = [
        ("100%", "Flutter Analyze Clean", EMERALD_LIGHT),
        ("11 / 11", "Widget & Unit Tests Passing", AMBER_ACCENT),
        ("6 / 6", "Seed Audio Files E2E Verified", INDIGO_ACCENT),
        ("v1.4.0", "Release APK Ready for Install", MINT_ACCENT)
    ]
    for val, lbl, col in stats:
        vp = stf.add_paragraph()
        vp.text = f"{val} — {lbl}"
        vp.font.size = Pt(13)
        vp.font.bold = True
        vp.font.color.rgb = col
        vp.space_before = Pt(12)

    # =========================================================
    # SLIDE 12: BUSINESS MODEL & GTM
    # =========================================================
    s12 = prs.slides.add_slide(blank_layout)
    set_slide_background(s12)
    add_header(s12, "Sustainable Monetization", "High-Margin B2B FinTech Business Model",
               "100% free for micro-businesses. Monetization is driven by institutional lenders and wholesale distributors.",
               badge_color=INDIGO_ACCENT, badge_bg=RGBColor(25, 25, 60))

    b_models = [
        ("Shopkeeper Layer", "Always Free App", "Zero subscription fees for shopkeepers. Removes all friction to achieve viral word-of-mouth adoption across bazaar trade associations.", EMERALD_LIGHT),
        ("Lender B2B API", "Credit Origination Fees", "Microfinance Banks (Mobilink Bank, Akhuwat, Kashf) pay a query fee per Evidence Profile plus a 1.5% - 2.5% origination fee upon loan disbursement.", AMBER_ACCENT),
        ("Supply Chain Financing", "FMCG Bulk Credit", "FMCG distributors (Unilever, Nestlé, Engro) utilize stock purchase evidence to underwrite 7-day inventory credit directly inside the app.", INDIGO_ACCENT)
    ]
    for i, (tag, title, desc, col) in enumerate(b_models):
        bc = add_card(s12, Inches(0.8 + i * 4.0), Inches(2.4), Inches(3.7), Inches(3.2))
        btf = bc.text_frame
        btf.margin_left = btf.margin_right = btf.margin_top = Inches(0.25)
        bp_tag = btf.paragraphs[0]
        bp_tag.text = tag.upper()
        bp_tag.font.size = Pt(10)
        bp_tag.font.bold = True
        bp_tag.font.color.rgb = col
        bp_t = btf.add_paragraph()
        bp_t.text = title
        bp_t.font.size = Pt(16)
        bp_t.font.bold = True
        bp_t.font.color.rgb = TEXT_WHITE
        bp_t.space_before = Pt(4)
        bp_d = btf.add_paragraph()
        bp_d.text = desc
        bp_d.font.size = Pt(11)
        bp_d.font.color.rgb = TEXT_MUTED
        bp_d.space_before = Pt(8)

    # Bottom Flywheel Bar
    f_bar = add_card(s12, Inches(0.8), Inches(5.9), Inches(11.7), Inches(1.0), border=EMERALD_LIGHT)
    ftf = f_bar.text_frame
    ftf.margin_left = Inches(0.3)
    ftf.margin_top = Inches(0.2)
    fp = ftf.paragraphs[0]
    fp.text = "GO-TO-MARKET FLYWHEEL:"
    fp.font.size = Pt(11)
    fp.font.bold = True
    fp.font.color.rgb = EMERALD_LIGHT
    fp2 = ftf.add_paragraph()
    fp2.text = "Wholesale Mandi Onboarding → Voice Recording Daily Habit → First 30-Day Milestone → Instant Loan Qualification  |  $180B+ Addressable Market"
    fp2.font.size = Pt(11)
    fp2.font.color.rgb = TEXT_WHITE

    # =========================================================
    # SLIDE 13: STRATEGIC PRODUCT ROADMAP
    # =========================================================
    s13 = prs.slides.add_slide(blank_layout)
    set_slide_background(s13)
    add_header(s13, "Future Horizon", "Strategic Product & Expansion Roadmap",
               "Scaling from working proof-of-concept to national financial inclusion infrastructure.")

    phases = [
        ("PHASE 1 (Current · Q3 2026)", "Offline-First Voice Sync",
         "• Local encrypted SQLite audio queue for zero-connectivity operation.\n• Background auto-sync when cellular signal returns.\n• Production deployment on resilient auto-scaling cloud cluster.", EMERALD_LIGHT),
        ("PHASE 2 (Q4 2026)", "Multi-Dialect Expansion",
         "• Fine-tuned Whisper models for regional bazaar dialects (Pashto, Sindhi, Punjabi, Saraiki).\n• Voice-based WhatsApp bot integration for zero-install recording.\n• Automated customer ledger reminders (Udhaar recovery).", AMBER_ACCENT),
        ("PHASE 3 (Q1 2027)", "Raast Payment Rails",
         "• Direct integration with State Bank of Pakistan's Raast P2M QR rails.\n• One-click digital loan acceptance and automatic daily micropayments.\n• Formal credit bureau data ingestion (1Link / SBP ECIB).", INDIGO_ACCENT)
    ]
    for i, (phase, title, points, col) in enumerate(phases):
        pc = add_card(s13, Inches(0.8 + i * 4.0), Inches(2.4), Inches(3.7), Inches(4.3), border=col)
        ptf = pc.text_frame
        ptf.margin_left = ptf.margin_right = ptf.margin_top = Inches(0.25)
        pp_tag = ptf.paragraphs[0]
        pp_tag.text = phase
        pp_tag.font.size = Pt(10)
        pp_tag.font.bold = True
        pp_tag.font.color.rgb = col
        pp_t = ptf.add_paragraph()
        pp_t.text = title
        pp_t.font.size = Pt(16)
        pp_t.font.bold = True
        pp_t.font.color.rgb = TEXT_WHITE
        pp_t.space_before = Pt(4)
        pp_pts = ptf.add_paragraph()
        pp_pts.text = points
        pp_pts.font.size = Pt(11)
        pp_pts.font.color.rgb = TEXT_MUTED
        pp_pts.space_before = Pt(10)

    # =========================================================
    # SLIDE 14: CONCLUSION & CALL TO ACTION
    # =========================================================
    s14 = prs.slides.add_slide(blank_layout)
    set_slide_background(s14)

    add_badge(s14, "The Vision", top=Inches(1.2), left=Inches(5.6))

    c_box = s14.shapes.add_textbox(Inches(1.0), Inches(1.8), Inches(11.333), Inches(4.5))
    ctf = c_box.text_frame
    ctf.word_wrap = True
    
    cp1 = ctf.paragraphs[0]
    cp1.text = "Dukaan Aapki, Hisaab Karobar Saathi Ka."
    cp1.alignment = PP_ALIGN.CENTER
    cp1.font.name = FONT_TITLE
    cp1.font.size = Pt(40)
    cp1.font.bold = True
    cp1.font.color.rgb = TEXT_WHITE

    cp_urdu = ctf.add_paragraph()
    cp_urdu.text = "دکان آپ کی، حساب کاروبار ساتھی کا"
    cp_urdu.alignment = PP_ALIGN.CENTER
    cp_urdu.font.size = Pt(28)
    cp_urdu.font.color.rgb = EMERALD_LIGHT
    cp_urdu.space_before = Pt(10)

    cp2 = ctf.add_paragraph()
    cp2.text = "Empowering 5 million hardworking micro-entrepreneurs to be seen, verified, and funded — using nothing more than their daily voice."
    cp2.alignment = PP_ALIGN.CENTER
    cp2.font.size = Pt(16)
    cp2.font.color.rgb = TEXT_MUTED
    cp2.space_before = Pt(16)

    # Action links card
    ac = add_card(s14, Inches(2.0), Inches(4.5), Inches(9.333), Inches(1.8), bg=BG_CARD, border=EMERALD_LIGHT)
    atf = ac.text_frame
    atf.margin_top = Inches(0.25)
    atf.margin_left = Inches(0.3)
    
    ap1 = atf.paragraphs[0]
    ap1.text = "🚀 Explore the Live Project & Resources:"
    ap1.alignment = PP_ALIGN.CENTER
    ap1.font.size = Pt(14)
    ap1.font.bold = True
    ap1.font.color.rgb = TEXT_WHITE

    ap2 = atf.add_paragraph()
    ap2.text = "• Download APK v1.4.0:  github.com/ahsankhizar5/karobar-saathi/releases\n• Live API & Status Page:  ahsankhizar5.github.io/karobar-saathi\n• Live Production Backend:  karobar-saathi.onrender.com"
    ap2.alignment = PP_ALIGN.CENTER
    ap2.font.size = Pt(12)
    ap2.font.color.rgb = EMERALD_LIGHT
    ap2.space_before = Pt(8)

    # Save presentation
    output_path = "Karobar_Saathi_Presentation.pptx"
    prs.save(output_path)
    print(f"Presentation saved successfully to: {os.path.abspath(output_path)}")

if __name__ == "__main__":
    create_deck()
