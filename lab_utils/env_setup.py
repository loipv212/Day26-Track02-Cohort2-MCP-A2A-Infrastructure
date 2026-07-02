"""Load .env từ project root — dùng cho mọi agent (orchestrator + A2A specialists)."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parents[1]
ENV_FILE = PROJECT_ROOT / ".env"


def load_lab_env() -> None:
    """Nạp API keys và biến lab từ .env (idempotent)."""
    load_dotenv(ENV_FILE)
    os.environ.setdefault("GOOGLE_GENAI_USE_VERTEXAI", "FALSE")
    os.environ.setdefault("LAB_MODEL_PROVIDER", "google")


def require_api_key() -> None:
    """Raise sớm nếu thiếu API key cho provider đang chọn."""
    load_lab_env()
    provider = os.getenv("LAB_MODEL_PROVIDER", "google").strip().lower()
    if provider == "openai":
        key = os.getenv("OPENAI_API_KEY", "").strip()
        if not key or key == "your_openai_api_key_here":
            raise RuntimeError(
                f"Thiếu OPENAI_API_KEY thật. Đặt trong {ENV_FILE} khi "
                "LAB_MODEL_PROVIDER=openai"
            )
        return

    if not os.getenv("GOOGLE_API_KEY"):
        raise RuntimeError(
            f"Thiếu GOOGLE_API_KEY. Đặt trong {ENV_FILE} — "
            "lấy key tại https://aistudio.google.com/app/apikey"
        )
