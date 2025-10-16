#!/usr/bin/env bash
set -euxo pipefail

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env

# Create workspace
mkdir -p ~/vllm-runtime
cd ~/vllm-runtime

# Set up Python 3.12
uv python install 3.12
uv venv --python 3.12 --seed
source .venv/bin/activate

# Install dependencies
uv pip install -U vllm \
    --torch-backend=auto \
    --extra-index-url https://wheels.vllm.ai/nightly

# Check NVIDIA drivers
if command -v nvidia-smi &>/dev/null; then
  echo "Detected NVIDIA GPU:"
  nvidia-smi || true
else
  echo "⚠️  No NVIDIA GPU detected or drivers not installed."
fi

# Verify installation
python -m vllm.entrypoints.api_server --help || true
echo "✅ vllm environment ready in $(pwd)"
