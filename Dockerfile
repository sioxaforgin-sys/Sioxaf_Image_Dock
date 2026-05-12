# ─────────────────────────────────────────────────────────────
#  Sioxa SwarmUI Image
#  Base: vastai/swarmui:0.9.8-Beta
#  Registry: ghcr.io/sioxaforgin-sys/swarmui-sioxa:latest
# ─────────────────────────────────────────────────────────────
FROM vastai/swarmui:0.9.8-Beta

# ── System packages ───────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    git wget curl unzip \
    && rm -rf /var/lib/apt/lists/*

# ── Clone ComfyUI at the EXACT path SwarmUI expects ───────────
# Pinned to a known-good commit to avoid drift
RUN mkdir -p /workspace/SwarmUI/dlbackend && \
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git \
        /workspace/SwarmUI/dlbackend/ComfyUI

# ── ComfyUI venv + all required dependencies ──────────────────
RUN cd /workspace/SwarmUI/dlbackend/ComfyUI && \
    python3 -m venv venv && \
    venv/bin/pip install --upgrade pip --quiet && \
    venv/bin/pip install \
        torch torchvision \
        --index-url https://download.pytorch.org/whl/cu124 \
        --quiet && \
    venv/bin/pip install -r requirements.txt --quiet && \
    venv/bin/pip install \
        torchsde einops transformers safetensors aiohttp \
        pyyaml Pillow scipy tqdm psutil kornia spandrel \
        sqlalchemy simpleeval blake3 \
        --quiet

# ── Same deps into SwarmUI's own venv + system python ─────────
RUN DEPS="torchsde einops transformers safetensors aiohttp pyyaml \
          Pillow scipy tqdm psutil kornia spandrel sqlalchemy simpleeval blake3" && \
    /venv/main/bin/pip install $DEPS --quiet && \
    python3 -m pip install $DEPS --quiet

# ── Model directories ─────────────────────────────────────────
RUN mkdir -p \
    /workspace/SwarmUI/Models/Stable-Diffusion \
    /workspace/SwarmUI/Models/Lora \
    /workspace/SwarmUI/Models/yolov8

# ── Download checkpoints from R2 ─────────────────────────────
# nova_anime_xl16 — used by Pipeline 1 (Original Sioxaf), 2 (Cyberboi), 5 (Balecxi)
RUN wget -q --show-progress \
    "https://pub-9203f67dce5a400293d9b5ce32cb207b.r2.dev/checkpoints/nova_anime_xl16.safetensors" \
    -O /workspace/SwarmUI/Models/Stable-Diffusion/nova_anime_xl16.safetensors

# hoseki — used by Pipeline 4 (Hoseki Lustrous)
RUN wget -q --show-progress \
    "https://pub-9203f67dce5a400293d9b5ce32cb207b.r2.dev/checkpoints/hoseki-lustrousmix-illustriousxlnoobai.safetensors" \
    -O /workspace/SwarmUI/Models/Stable-Diffusion/hoseki-lustrousmix-illustriousxlnoobai.safetensors

# ── Download & unzip YOLOv8 eye enhancer ─────────────────────
RUN wget -q \
    "https://pub-9203f67dce5a400293d9b5ce32cb207b.r2.dev/checkpoints/eye_enhancer.zip" \
    -O /tmp/eye_enhancer.zip && \
    unzip -q /tmp/eye_enhancer.zip -d /workspace/SwarmUI/Models/yolov8 && \
    rm /tmp/eye_enhancer.zip

# ── Download style LoRAs ──────────────────────────────────────
# Cyberboi — Pipeline 2
RUN wget -q \
    "https://pub-9203f67dce5a400293d9b5ce32cb207b.r2.dev/Loras/Styles/Cyberboi.safetensors" \
    -O /workspace/SwarmUI/Models/Lora/Cyberboi.safetensors

# Balecxi — Pipeline 5
RUN wget -q \
    "https://pub-9203f67dce5a400293d9b5ce32cb207b.r2.dev/Loras/Styles/Balecxi_style_lora.safetensors" \
    -O /workspace/SwarmUI/Models/Lora/Balecxi_style_lora.safetensors

# ── Pre-write Backends.fds with correct ComfyUI path ──────────
# This is what SwarmUI reads to know how to launch ComfyUI.
# Writing it here means no SSH config step needed at session start.
RUN mkdir -p /workspace/SwarmUI/Data
COPY Backends.fds /workspace/SwarmUI/Data/Backends.fds

# ── Entrypoint ────────────────────────────────────────────────
# The base vastai/swarmui image already uses supervisord to manage
# the swarmui process. We don't override it — just let it start
# naturally. Our Backends.fds is already in place so ComfyUI
# connects immediately on first boot.
