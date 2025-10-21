#!/usr/bin/env bash
set -eux

# Install NVIDIA drivers
curl -fSsL -O https://storage.googleapis.com/compute-gpu-installation-us/installer/latest/cuda_installer.pyz
sudo python3 cuda_installer.pyz install_cuda

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env

# Create shared runtime folder
RUNTIME_DIR="/opt/vllm-runtime"
sudo mkdir -p /opt/vllm-runtime
sudo chown root:google-sudoers /opt/vllm-runtime
sudo chmod 2775 /opt/vllm-runtime
cd /opt/vllm-runtime

# Set up Python 3.12
uv python install 3.12
uv venv --python 3.12 --seed
source .venv/bin/activate

# Install dependencies
uv pip install -U vllm \
  --torch-backend=auto \
  --extra-index-url https://wheels.vllm.ai/nightly \
  --prerelease=allow
