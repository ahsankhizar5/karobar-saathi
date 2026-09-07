"""
Karobar Saathi — AI-powered financial evidence platform for Pakistani micro-businesses.
FastAPI backend serving both the mobile app and the public Partner/Government API.
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

from app.config import settings
from app.database import init_db
from app.seed_data import seed_database
from app.routers import voice, ledger, dashboard, evidence, users


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    init_db()
    seed_database()
    yield


app = FastAPI(
    title="Karobar Saathi API",
    description=(
        "AI-powered financial evidence platform for informal micro-businesses in Pakistan. "
        "Turns spoken daily transactions into a structured, explainable financial record."
    ),
    version="1.4.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router)
app.include_router(voice.router)
app.include_router(ledger.router)
app.include_router(dashboard.router)
app.include_router(evidence.router)


_API_HOME_URL = "https://ahsankhizar5.github.io/karobar-saathi"

_root_json = {
    "app": "Karobar Saathi",
    "version": "1.4.0",
    "status": "running",
    "docs": "/docs",
    "api_base": "/api/v1",
}


@app.get("/")
async def root(request: Request):
    """Return JSON for API clients and a friendly HTML page for browsers."""
    accept = request.headers.get("accept", "")
    if "application/json" in accept:
        return _root_json

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Karobar Saathi API</title>
  <style>
    :root {{
      --bg: #f6f7f9;
      --surface: #ffffff;
      --text: #1f2328;
      --muted: #57606a;
      --accent: #0d6f69;
      --border: #d0d7de;
      --shadow: 0 8px 24px rgba(66,74,83,0.08);
    }}
    @media (prefers-color-scheme: dark) {{
      :root {{ --bg: #0d1117; --surface: #161b22; --text: #c9d1d9; --muted: #8b949e; --accent: #4ecdc4; --border: #30363d; --shadow: 0 8px 24px rgba(0,0,0,0.4); }}
    }}
    body {{ margin: 0; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: var(--bg); color: var(--text); line-height: 1.6; }}
    .container {{ max-width: 640px; margin: 0 auto; padding: 48px 20px; text-align: center; }}
    .card {{ background: var(--surface); border: 1px solid var(--border); border-radius: 16px; padding: 32px; box-shadow: var(--shadow); }}
    h1 {{ margin: 0 0 8px; font-size: 1.75rem; }}
    p {{ color: var(--muted); margin: 0 0 20px; }}
    a {{ color: var(--accent); text-decoration: none; font-weight: 600; }}
    a:hover {{ text-decoration: underline; }}
    .links {{ display: flex; flex-wrap: wrap; gap: 12px; justify-content: center; }}
    .btn {{ padding: 10px 16px; border-radius: 10px; border: 1px solid var(--border); background: var(--bg); color: var(--text); }}
    .btn-primary {{ background: var(--accent); border-color: var(--accent); color: #fff; }}
    code {{ font-family: ui-monospace, monospace; background: var(--bg); padding: 2px 6px; border-radius: 6px; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="card">
      <h1>Karobar Saathi API</h1>
      <p>AI-powered financial evidence for informal micro-businesses in Pakistan.</p>
      <div class="links">
        <a class="btn btn-primary" href="{_API_HOME_URL}">API homepage</a>
        <a class="btn" href="/docs">Swagger UI</a>
        <a class="btn" href="/redoc">ReDoc</a>
      </div>
      <p style="margin-top: 20px; font-size: 0.9rem;">
        <code>GET /health</code> · <code>/api/v1/voice/transcribe</code> · <code>/api/v1/evidence-profile/&lt;user_id&gt;</code>
      </p>
    </div>
    <p style="margin-top: 24px; font-size: 0.85rem;">
      Looking for the JSON response? Send <code>Accept: application/json</code>.
    </p>
  </div>
</body>
</html>"""
    return HTMLResponse(content=html, media_type="text/html")


@app.get("/health")
async def health():
    return {"status": "healthy"}
