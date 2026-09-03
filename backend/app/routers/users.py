"""Users router — basic user management."""
from fastapi import APIRouter, HTTPException
from app.database import get_db
from app.models.schemas import UserCreate, UserResponse

router = APIRouter(prefix="/api/v1/users", tags=["users"])


@router.post("/", response_model=UserResponse)
async def create_user(user: UserCreate):
    """Register a new user."""
    with get_db() as conn:
        existing = conn.execute("SELECT id FROM users WHERE id = ?", (user.id,)).fetchone()
        if existing:
            raise HTTPException(status_code=409, detail="User already exists")

        conn.execute("""
            INSERT INTO users (id, name, business_type, business_name, phone)
            VALUES (?, ?, ?, ?, ?)
        """, (user.id, user.name, user.business_type, user.business_name, user.phone))

        conn.execute("""
            INSERT INTO evidence_summaries (user_id, has_user_consented_to_share)
            VALUES (?, 1)
            ON CONFLICT(user_id) DO NOTHING
        """, (user.id,))

        row = conn.execute("SELECT * FROM users WHERE id = ?", (user.id,)).fetchone()
        return UserResponse(
            id=row["id"],
            name=row["name"],
            business_type=row["business_type"],
            business_name=row["business_name"],
            phone=row["phone"],
            created_at=row["created_at"],
        )


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: str):
    """Get user details."""
    with get_db() as conn:
        row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        return UserResponse(
            id=row["id"],
            name=row["name"],
            business_type=row["business_type"],
            business_name=row["business_name"],
            phone=row["phone"],
            created_at=row["created_at"],
        )


@router.get("/", response_model=list[UserResponse])
async def list_users():
    """List all users."""
    with get_db() as conn:
        rows = conn.execute("SELECT * FROM users ORDER BY created_at DESC").fetchall()
        return [
            UserResponse(
                id=r["id"], name=r["name"], business_type=r["business_type"],
                business_name=r["business_name"], phone=r["phone"],
                created_at=r["created_at"],
            )
            for r in rows
        ]
