# ─────────────────────────────────────────────────────────────
#  Stage 1 — builder
#  Downloads models and installs deps. This layer is discarded;
#  its history (including R2 URLs) never appears in the final image.
# ─────────────────────────────────────────────────────────────
FROM vastai/swarmui:0.9.8-Beta AS builder

RUN apt-get update && apt-get install -y \
    git wget curl unzip \
    && rm -rf /var/lib/apt/lists/*

# ── Clone ComfyUI ─────────────────────────────────────────────
RUN mkdir -p /workspace/SwarmUI/dlbackend && \
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git \
        /workspace/SwarmUI/dlbackend/ComfyUI

# ── ComfyUI venv + deps ───────────────────────────────────────
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

# ── Model directories ─────────────────────────────────────────
RUN mkdir -p \
    /workspace/SwarmUI/Models/Stable-Diffusion \
    /workspace/SwarmUI/Models/Lora \
    /workspace/SwarmUI/Models/yolov8

# ── Download checkpoints ──────────────────────────────────────
RUN wget -q --show-progress \
    "https://pub-9203f67dce5a400293d9b5ce32cb207b.r2.dev/checkpoints/nova_anime_xl16.safetensors" \
    -O /workspace/SwarmUI/Models/Stable-Diffusion/nova_anime_xl16.safetensors

RUN wget -q --show-progress \
    "https://pub-9203f67dce5a400293d9b5ce32cb207b.r2.dev/checkpoints/hoseki-lustrousmix-illustriousxlnoobai.safetensors" \
    -O /workspace/SwarmUI/Models/Stable-Diffusion/hoseki-lustrousmix-illustriousxlnoobai.safetensors

# ── Download YOLOv8 eye enhancer ──────────────────────────────
RUN wget -q \
    "https://pub-9203f67dce5a400293d9b5ce32cb207b.r2.dev/checkpoints/eye_enhancer.zip" \
    -O /tmp/eye_enhancer.zip && \
    unzip -q /tmp/eye_enhancer.zip -d /workspace/SwarmUI/Models/yolov8 && \
    rm /tmp/eye_enhancer.zip

# ── Download style LoRAs ──────────────────────────────────────
RUN wget -q \
    "https://pub-9203f67dce5a400293d9b5ce32cb207b.r2.dev/Loras/Styles/Cyberboi.safetensors" \
    -O /workspace/SwarmUI/Models/Lora/Cyberboi.safetensors

RUN wget -q \
    "https://pub-9203f67dce5a400293d9b5ce32cb207b.r2.dev/Loras/Styles/Balecxi_style_lora.safetensors" \
    -O /workspace/SwarmUI/Models/Lora/Balecxi_style_lora.safetensors


# ─────────────────────────────────────────────────────────────
#  Stage 2 — final clean image
#  Fresh base: no wget, no URLs, no pip commands.
#  docker history on this image reveals nothing sensitive.
# ─────────────────────────────────────────────────────────────
FROM vastai/swarmui:0.9.8-Beta

RUN apt-get update && apt-get install -y \
    git curl \
    && rm -rf /var/lib/apt/lists/*

# ── Copy compiled assets from builder (no history of how they arrived) ──
COPY --from=builder /workspace/SwarmUI/dlbackend/ComfyUI \
                    /workspace/SwarmUI/dlbackend/ComfyUI

COPY --from=builder /workspace/SwarmUI/Models \
                    /workspace/SwarmUI/Models

# ── Same deps into SwarmUI's own venv + system python ─────────
# These are public packages — safe to show in history.
RUN DEPS="torchsde einops transformers safetensors aiohttp pyyaml \
          Pillow scipy tqdm psutil kornia spandrel sqlalchemy simpleeval blake3" && \
    /venv/main/bin/pip install $DEPS --quiet && \
    python3 -m pip install $DEPS --quiet

# ── Backends.fds ──────────────────────────────────────────────
RUN mkdir -p /workspace/SwarmUI/Data
COPY Backends.fds /workspace/SwarmUI/Data/Backends.fds
