#!/usr/bin/env bash
set -eux

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g. using sudo)."
  exit 1
fi

# Install or update uv
if command -v uv &>/dev/null; then
  echo "uv already installed. Updating..."
  uv self update || true
else
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  source "$HOME/.local/bin/env" || true
fi

# Ensure uv is on PATH
if ! command -v uv &>/dev/null; then
  echo "uv not found in PATH after installation. Please check installation."
  exit 1
fi

# Create workspace (system-wide)
RUNTIME_DIR="/opt/vllm-runtime"
mkdir -p "$RUNTIME_DIR"
chmod 777 "$RUNTIME_DIR"  # make accessible to all users
cd "$RUNTIME_DIR"

# Set up Python 3.12
uv python install 3.12
uv venv --python 3.12 --seed
source .venv/bin/activate

# Install dependencies
uv pip install -U vllm \
  --torch-backend=auto \
  --extra-index-url https://wheels.vllm.ai/nightly

# Check for NVIDIA GPU
if command -v nvidia-smi &>/dev/null; then
  echo "NVIDIA GPU detected:"
  nvidia-smi || true
else
  echo "No NVIDIA GPU detected or drivers not installed."
fi

# Verify installation
python -m vllm.entrypoints.api_server --help || true

echo "vLLM runtime environment is ready in: $RUNTIME_DIR"
echo "To activate it, run: source $RUNTIME_DIR/.venv/bin/activate"
