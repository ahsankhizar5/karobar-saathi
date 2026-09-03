from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


_DEVELOPMENT_SECRET = "karobar-saathi-dev-key-change-in-production"


class Settings(BaseSettings):
    APP_NAME: str = "Karobar Saathi"
    ENVIRONMENT: str = "development"
    WHISPER_ENABLED: bool = False
    WHISPER_MODEL: str = "base"
    LLM_API_KEY: str = ""
    LLM_API_URL: str = "https://api.groq.com/openai/v1/chat/completions"
    LLM_MODEL: str = "llama-3.3-70b-versatile"
    CORS_ORIGINS: str = "*"
    DATA_DIR: str = "./data"
    UPLOAD_DIR: str = "./uploads"
    SECRET_KEY: str = _DEVELOPMENT_SECRET

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @property
    def cors_origins(self) -> list[str]:
        origins = [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]
        return origins or ["*"]

    @model_validator(mode="after")
    def require_hosted_secret(self) -> "Settings":
        if self.ENVIRONMENT.lower() in {"production", "staging"} and self.SECRET_KEY == _DEVELOPMENT_SECRET:
            raise ValueError("SECRET_KEY must be set for hosted environments")
        return self


settings = Settings()
