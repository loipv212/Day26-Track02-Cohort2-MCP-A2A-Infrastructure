"""Model provider selection for lab agents."""

from __future__ import annotations

import os
from typing import Any

from google.genai import types


def get_model_provider() -> str:
    """Return the configured model provider: google or openai."""
    return os.getenv("LAB_MODEL_PROVIDER", "google").strip().lower()


def get_agent_model() -> Any:
    """Build the ADK model object/string from environment settings."""
    provider = get_model_provider()
    if provider == "openai":
        from google.adk.models.lite_llm import LiteLlm

        model_name = os.getenv("OPENAI_MODEL", "openai/gpt-4o-mini")
        return LiteLlm(model=model_name)

    if provider != "google":
        raise RuntimeError(
            "LAB_MODEL_PROVIDER phải là 'google' hoặc 'openai'. "
            f"Giá trị hiện tại: {provider!r}"
        )
    return os.getenv("GOOGLE_MODEL", "gemini-2.5-flash")


def get_generate_content_config() -> types.GenerateContentConfig | None:
    """Gemini-only generation config; LiteLLM/OpenAI should not receive it."""
    if get_model_provider() != "google":
        return None
    return types.GenerateContentConfig(
        thinking_config=types.ThinkingConfig(thinking_budget=0),
    )
