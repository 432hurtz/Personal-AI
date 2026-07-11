# Hardware — your laptop, honestly, and where to go next

## Your machine

| Component | Spec | What it means here |
|---|---|---|
| CPU | AMD Athlon Silver 3050U, 2c/2t, 2.3 GHz | **The bottleneck.** Token speed lives and dies here. |
| RAM | 18 GB | Plenty. Lets you *load* 7-8B models; won't make them fast. |
| GPU | Integrated Radeon (Vega), 2 GB | **Does not accelerate Ollama.** Treat as CPU-only. |
| Storage | 1 TB NVMe, ~779 GB free | Models are 2-5 GB each; you have all the room you need. |
| OS | Windows 10 Pro 19045 | Docker Desktop (WSL2) + native Ollama. |

The takeaway most guides get wrong for a machine like this: **memory bandwidth
and core count govern token generation, not how much RAM you have.** You're not
RAM-starved; you're compute-starved. That's why the recommendation is a 3-4B
daily driver, not "the biggest model that fits in 18 GB."

## Getting the most from what you have

- Daily driver = 3-4B (`gemma3:4b`, `phi4-mini`, `qwen2.5-coder:3b`).
- Keep `num_ctx` at 4096. Long context is quadratic-ish cost on a slow CPU.
- Don't run autocomplete + big chat model simultaneously — 2 threads can't.
- Close Chrome/heavy apps while a model is generating; they steal CPU.
- Keep web-search result count at 3. RAG over raw HTML is the real stall.

## Upgrade path, best value first

Your RAM is likely soldered on this chassis (the 18 GB itself looks like a prior
upgrade — possibly one soldered stick + one SODIMM). Check before buying:
in WSL/Git Bash run `sudo dmidecode -t memory`, or on Windows use Task Manager →
Performance → Memory ("Slots used"). If there's a free SODIMM slot, matching it
for **dual-channel** is the single biggest cheap win (bandwidth ~doubles).

If the RAM is maxed/soldered, spending on this laptop hits a wall — the CPU
stays the ceiling. Better money goes to a different box:

1. **Used Apple Silicon Mac (M1/M2, 16 GB).** The standout budget buy. Unified
   memory means the GPU gets the full RAM pool, so it runs 7-14B models far
   faster than this laptop and sips power. A used M1 Mac Mini runs this whole
   stack comfortably. **This is the upgrade I'd point you at.**
2. **Used RTX 3060 12 GB** (needs a desktop). Often under $300 used; great for
   7-14B at 4-bit, 15-20+ tok/s.
3. **Mini PC with a strong iGPU** (Ryzen 7 8845HS / Radeon 780M, 32 GB
   dual-channel DDR5): ~18-25 tok/s on an 8B, $400-650.

Skip: any GPU under 8 GB VRAM (you'd fall back to CPU anyway) and anything
single-channel. Bandwidth, not clock speed, is king.

The good news: everything in this repo is portable. When you get a better
machine, you copy the folder, install Ollama + Docker, rebuild the guarded
model, and you're running — your guardrails and config come with you.
