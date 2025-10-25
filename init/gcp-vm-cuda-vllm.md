# [GCP] Deploying VLLM on a GPU-Accelerated VM

## Basic setup

0. Rent a GPU-Accelerated machine. [a2-highgpu-1g](https://gcloud-compute.com/a2-highgpu-1g.html) is a solid choice
1. Start off a basic Ubuntu LTS Minimal
2. Install CUDA drivers (machine can reboot during install, just keep executing until it is finished with installation)

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
  --torch-backend=auto

# Run VLLM
vllm serve rednote-hilab/dots.ocr \
    --trust-remote-code \
    --api-key YOUR_API_KEY \
    --chat-template-content-format string

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

At this point basic setup is finished.

You can use any Open AI compatible sdk, setting `base_url` to `http://YOUR_VM_IP_ADDRESS/v1/`

Also, a quick command to start VLLM:

```bash
/opt/vllm-runtime/.venv/bin/vllm serve rednote-hilab/dots.ocr \
    --trust-remote-code \
    --api-key YOUR_API_KEY \
    --chat-template-content-format string
 ```

## Going for production

In this section, we will add custom domain, define custom script to always start vllm on reboot.

0. Make sure you've obtained a static IP and bound it to `YOUR_DOMAIN_NAME` by creating a DNS A-record.

1. Define Caddyfile to serve VLLM

```bash
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
YOUR_DOMAIN_NAME {
    reverse_proxy localhost:8000
}
EOF
```

2. Add the service configuration

```bash
sudo tee /etc/systemd/system/vllm.service > /dev/null <<'EOF'
[Unit]
Description=vLLM API Server
After=network.target

[Service]
Type=simple
User=YOUR_LINUX_USER
WorkingDirectory=/opt/vllm-runtime
ExecStart=/opt/vllm-runtime/.venv/bin/vllm serve rednote-hilab/dots.ocr \
    --trust-remote-code \
    --api-key YOUR_API_KEY \
    --chat-template-content-format string
Restart=always
RestartSec=5
Environment=PATH=/opt/vllm-runtime/.venv/bin:/usr/local/bin:/usr/bin:/bin
Environment=HOME=/home/YOUR_LINUX_USER

[Install]
WantedBy=multi-user.target
EOF
```

3. Reload and enable the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable vllm
sudo systemctl start vllm
```

4. Verify it’s running

```bash
sudo systemctl status vllm
```

5. Check logs

```
journalctl -u vllm -f
```

6. You can use any Open AI compatible sdk, setting `base_url` to `https://YOUR_DOMAIN_NAME/v1/`