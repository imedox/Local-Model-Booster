# LM Studio & Bionic Hardware Tuning: Qwen3.8-27B on RTX 3090 24 GB, i5-13600K, 32 GB RAM, NVMe

Verified and benchmarked in production on: 2026-10-15.
Server: Bionic runtime (llama.cpp CUDA 12) exposing OpenAI API at `http://localhost:1235/v1`.
Context Manager: Billion-Context Proxy Daemon running at `http://127.0.0.1:8787` (`BiliProxyService`).

---

## 1. Verified Hardware & Model Specifications

| Component | Verified Specification | Notes |
| :--- | :--- | :--- |
| **GPU** | NVIDIA GeForce RTX 3090 24 GB GDDR6X | 24,576 MiB total VRAM. Idle baseline: ~500 MiB used. |
| **System RAM** | 32 GB DDR5 | 32,766,904 KB physical. Comfortably holds OS and memory buffers. |
| **CPU** | Intel Core i5-13600K | 14 cores (6 P-cores + 8 E-cores), 20 threads. |
| **Model** | `HauhauCS/Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF` | GGUF arch `qwen35`, 64 layers (48 Gated DeltaNet + 16 Gated Attention). |
| **Quantization** | `Q4_K_P` ("Perfect" custom quant by HauhauCS) | 17.92 GB file (16.69 GiB), 5.25 bpw, embedded FastMTP head. |
| **Vision Projector** | `mmproj-Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-BF16.gguf` | 909 MB (888 MiB), BF16 multimodal vision encoder. |
| **Context Window** | **131,072 tokens (128K)** | Verified stable with `q8_0` KV cache and Flash Attention. |
| **KV Cache** | `q8_0` for K and V cache | Flash Attention enabled. Consumes ~4.25 GiB VRAM at 128K. |
| **VRAM Footprint** | ~22.6 GiB loaded (Weights 16.7 + KV 4.25 + mmproj 0.9 + buffers 0.8) | Fits cleanly within 24 GB VRAM with ~1.4 GB headroom. |
| **Inference Speed** | **27 - 31 tokens/sec** (eval), **54 - 58 tokens/sec** with FastMTP | 100% GPU offload (65/65 layers). |

---

## 2. Six Production-Tuned Profiles

Configurations are stored in `scratch/target_tuning/configs/` and can be switched via `C:\tools\switch_profile.ps1`:

| Profile | ID | Context | Reasoning Budget | Temp / Top_P | KV Cache | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Coding (Default)** | `01_coding` | 131,072 | 16,384 | 0.6 / 0.95 | `q8_0` | High-precision coding, bug fixing, refactoring, and general chat. |
| **General Operation** | `02_general_operation` | 98,304 | 8,192 | 0.7 / 0.80 | `q8_0` | Fast interactive assistant, balanced reasoning. |
| **Tool Use** | `03_tool_use` | 98,304 | 4,096 | 0.3 / 0.90 | `q8_0` | Strict JSON schema adherence, deterministic tool arguments. |
| **Long Tasks** | `04_long_tasks` | 131,072 | 8,192 | 0.5 / 0.90 | `q4_0` | Massive codebases (>50K tokens); maximizes VRAM safety. |
| **Max Intelligence** | `05_max_intelligence` | 131,072 | 24,576 | 0.7 / 0.95 | `q8_0` | Complex algorithm design, difficult proofs, deep reasoning. |
| **Max Speed** | `06_max_speed` | 65,536 | 0 (Off) | 0.7 / 0.80 | `q8_0` | Maximum throughput (~68-75 t/s), direct instruct generation. |

---

## 3. Recommended Runtime Parameters (`01_coding` Active)

```json
{
  "context_length": 131072,
  "flash_attention": true,
  "gpu_offload_layers": 65,
  "k_cache_quantization": "q8_0",
  "v_cache_quantization": "q8_0",
  "num_parallel_sessions": 1,
  "temperature": 0.6,
  "top_p": 0.95,
  "top_k": 20,
  "min_p": 0.0,
  "repeat_penalty": 1.0,
  "presence_penalty": 0.0,
  "max_output_tokens": 16384,
  "reasoning_budget": 16384
}
```

---

## 4. Billion-Context Daemon & MCP Integration

- **Daemon Address**: `http://127.0.0.1:8787`
- **Persistence**: Managed via Windows Scheduled Task `BiliProxyService` (auto-starts on boot).
- **Available MCP Tools**:
  - `compress`: Compresses large conversation contexts using hierarchical summarization.
  - `decompress`: Retrieves expanded historical details.
  - `search_context`: Fast semantic retrieval across conversation history.
  - `acp_status`: Checks context health and cache metrics.
- **Workflow**: When conversation context usage passes 60%, the agent leverages `compress` and `search_context` to retain complete architectural memory without filling physical VRAM.

---

## 5. Critical Model-Booster Operational Adjustments for Qwen 3.8

1. **In-Memory Decision Discipline (NO Recursive Tool Loops)**:
   - Do NOT prompt the model to call PowerShell commands (like `bt loop-check` or `bt estimate-tokens`) on every step.
   - External process spawning on Windows induces 20-40 second thinking loops in Qwen 3.8 thinking mode.
   - Cognitive checks must be evaluated **in-memory**. The model stops itself if the same failure occurs twice.
2. **Reasoning Ceilings**:
   - `preserve_thinking: true` is active by default in Qwen 3.8.
   - For routine coding tasks, keep thinking focused: 500 - 1,500 tokens for simple edits; 1,500 - 4,000 tokens for multi-file features.
3. **Bionic Native Tools**:
   - Bionic provides native file read/write, terminal execution, and browser tools. Prefer these directly over improvised CLI pipelines.
