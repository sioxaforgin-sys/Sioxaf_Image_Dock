# SwarmUI Docker Image — Sioxa Platform

Pre-baked image for the Sioxa image generation platform.

## What's inside

| Asset | Source | Baked in? |
|---|---|---|
| SwarmUI 0.9.8-Beta | vastai base image | ✅ |
| ComfyUI (pinned) | GitHub clone | ✅ |
| All Python deps | pip | ✅ |
| Backends.fds (correct path) | this repo | ✅ |
| nova_anime_xl16 checkpoint | R2 | ✅ |
| hoseki-lustrousmix checkpoint | R2 | ✅ |
| YOLOv8 eye enhancer | R2 | ✅ |
| Cyberboi style LoRA | R2 | ✅ |
| Balecxi style LoRA | R2 | ✅ |
| Character LoRAs (50-60) | R2 | ❌ pulled at session start |

## Image path for Vast.ai

```
ghcr.io/sioxaforgin-sys/swarmui-sioxa:latest
```

## How to rebuild

1. Make your changes (new LoRA, new checkpoint, etc.)
2. Push to `main` branch → GitHub Actions triggers automatically
3. OR go to Actions tab → "Build & Push SwarmUI Image" → Run workflow
4. Wait ~30-40 min for the build to complete
5. New instances on Vast.ai will pull the updated image automatically

## Session startup (after this image)

With this image, `inject_models()` only needs to:
1. Pull the requested character LoRA(s) from R2 (~10-20s each)
2. Restart SwarmUI once to index them (~60s)
3. Wait for ComfyUI backend ready (~60s)

**Total new session time: ~3-4 min** (down from ~15-25 min)

## Adding a new pipeline / checkpoint

1. Add the checkpoint download `RUN wget ...` line to `Dockerfile`
2. Add the style LoRA download if it has one
3. Push to main → auto-rebuild
