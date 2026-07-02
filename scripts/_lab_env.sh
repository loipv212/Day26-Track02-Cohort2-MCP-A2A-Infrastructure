#!/usr/bin/env bash
# Chọn Python/uvicorn/adk có google-adk (conda pii-env) — source từ các script khác.

load_dotenv_file() {
  local root="$1"
  local env_file="$root/.env"
  if [[ ! -f "$env_file" ]]; then
    echo "⚠ Không tìm thấy $env_file — GOOGLE_API_KEY có thể thiếu"
    return 0
  fi
  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
  export GOOGLE_GENAI_USE_VERTEXAI="${GOOGLE_GENAI_USE_VERTEXAI:-FALSE}"
  export LAB_MODEL_PROVIDER="${LAB_MODEL_PROVIDER:-google}"

  if [[ "$LAB_MODEL_PROVIDER" == "openai" ]]; then
    if [[ -z "${OPENAI_API_KEY:-}" || "${OPENAI_API_KEY:-}" == "your_openai_api_key_here" ]]; then
      echo "⚠ .env loaded (provider=openai, OPENAI_API_KEY thiếu hoặc đang là placeholder)"
    else
      echo "→ .env loaded (provider=openai, model=${OPENAI_MODEL:-openai/gpt-4o-mini})"
    fi
  elif [[ -z "${GOOGLE_API_KEY:-}" ]]; then
    echo "⚠ .env loaded (provider=google, GOOGLE_API_KEY trống)"
  else
    echo "→ .env loaded (provider=google, model=${GOOGLE_MODEL:-gemini-2.5-flash})"
  fi
}

resolve_lab_python() {
  local root="${1:-.}"
  local c candidates=()

  # Ưu tiên conda (pii-env) — lab không dùng .venv
  if [[ -n "${CONDA_PREFIX:-}" && -x "${CONDA_PREFIX}/bin/python" ]]; then
    candidates+=("${CONDA_PREFIX}/bin/python")
  fi
  if command -v python >/dev/null 2>&1; then
    candidates+=("$(command -v python)")
  fi
  if command -v python3 >/dev/null 2>&1; then
    candidates+=("$(command -v python3)")
  fi

  for c in "${candidates[@]}"; do
    [[ -n "$c" && -x "$c" ]] || continue
    if "$c" -c "import google.adk" >/dev/null 2>&1; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

setup_lab_env() {
  local root="${1:?root required}"
  load_dotenv_file "$root"
  LAB_PYTHON="$(resolve_lab_python "$root")" || {
    echo "✗ Không tìm thấy Python có google-adk."
    echo "  Chạy: conda activate pii-env"
    echo "  Rồi: pip install -r requirements.txt"
    exit 1
  }
  export PYTHONPATH="${PYTHONPATH:-}:$root"
  LAB_BIN="$(dirname "$LAB_PYTHON")"
  # python -m uvicorn — cùng env với google-adk (tránh Homebrew uvicorn)
  LAB_UVICORN=("$LAB_PYTHON" -m uvicorn)
  if [[ -x "$LAB_BIN/adk" ]]; then
    LAB_ADK="$LAB_BIN/adk"
  elif command -v adk >/dev/null 2>&1; then
    LAB_ADK="$(command -v adk)"
  else
    echo "✗ Không tìm thấy lệnh adk trong $LAB_BIN"
    exit 1
  fi
  echo "→ Python: $LAB_PYTHON"
  echo "→ ADK:    $LAB_ADK"
}
