# [GCP] Deploying VLLM on a GPU-Accelerated VM

0. Rent a GPU-Accelerated machine. [a2-highgpu-1g](https://gcloud-compute.com/a2-highgpu-1g.html) is a solid choice
1. Start off a basic Ubuntu LTS Minimal
2. Install CUDA drivers

```bash
curl -fSsL -O https://storage.googleapis.com/compute-gpu-installation-us/installer/latest/cuda_installer.pyz
sudo python3 cuda_installer.pyz install_cuda
```

3. Install UV

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
```

4. Create a runtime for VLLM

```bash
# Create shared runtime folder
sudo mkdir -p /opt/vllm-runtime
sudo chown root:google-sudoers /opt/vllm-runtime
sudo chmod 2775 /opt/vllm-runtime
cd /opt/vllm-runtime

# Set up Python
uv python install 3.12
uv venv --python 3.12 --seed
source .venv/bin/activate

# Install dependencies
uv pip install -U vllm \
  --torch-backend=auto \
  --extra-index-url https://wheels.vllm.ai/nightly \
  --prerelease=allow
```

5. Install Caddy

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
chmod o+r /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

6. Define Caddyfile to serve VLLM

```bash
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
YOUR_DOMAIN_NAME {
    reverse_proxy localhost:8000
}
EOF

```

7. Start VLLM

```jsx
vllm serve rednote-hilab/dots.ocr \
    --trust-remote-code \
    --api-key YOUR_API_KEY \
    --chat-template-content-format string
```
