# ─────────────────────────────────────────────────────────────
#  Sioxa SwarmUI Image
#  Base: vastai/swarmui:0.9.8-Beta
#
#  This image only adds:
#    - Pre-downloaded model checkpoints and LoRAs (no download at session start)
#    - Backends.fds so SwarmUI knows how to launch ComfyUI
#
#  ComfyUI setup (git clone + pip install) is handled by inject_models()
#  at session start, exactly as the original Telegram bot did.
# ─────────────────────────────────────────────────────────────
FROM vastai/swarmui:0.9.8-Beta

# ── Model directories ─────────────────────────────────────────
RUN mkdir -p \
    /workspace/SwarmUI/Models/Stable-Diffusion \
    /workspace/SwarmUI/Models/Lora \
    /workspace/SwarmUI/Models/yolov8

# ── Copy models from local staging folder ─────────────────────
COPY models/checkpoints/ /workspace/SwarmUI/Models/Stable-Diffusion/
COPY models/loras/       /workspace/SwarmUI/Models/Lora/
COPY models/yolov8/      /workspace/SwarmUI/Models/yolov8/

# ── Backends.fds ──────────────────────────────────────────────
RUN mkdir -p /workspace/SwarmUI/Data
COPY Backends.fds /workspace/SwarmUI/Data/Backends.fds
