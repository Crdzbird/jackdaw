# Dart/Flutter LLM and Agent Ecosystem Survey (as of 2026-10-12)

Scope: competitive landscape for a new independent Dart/Flutter agent framework
with a C++ core (on-device inference, constrained decoding, exact tokenization
and context budgeting, native vector index, security layer, Flutter web with
pure-Dart fallbacks).

## Method and data provenance

- pub.dev numbers come from `https://pub.dev/api/packages/<name>` and
  `https://pub.dev/api/packages/<name>/score`, fetched 2026-10-12. "Points" is
  grantedPoints/maxPoints, "dl/30d" is downloadCount30Days.
- Platforms are pub.dev analysis tags (A=Android, I=iOS, M=macOS, W=Windows,
  L=Linux, Web). A pub tag means the package compiles for that target, not that
  every feature works there; where the README says otherwise it is noted.
- GitHub data comes from the `gh` CLI (read-only): repo stats, full issue title
  dumps (`gh issue list --state all`) and GitHub search sorted by reactions and
  comments. Reaction counts across these repos are very low (almost all 0 to 5),
  so comment count and recurrence were used as the signal.
- Anything not directly verified is marked **(unverified)**.
- Two naming traps found during the survey:
  - `flutter_gemma` is now **discontinued on pub.dev, replaced by
    `flutter_edge_ai`**; the GitHub repo was renamed
    `DenisovAV/flutter_gemma` to `DenisovAV/flutter_edge_ai`.
  - The pub.dev package named `fllama` (0.0.1, xuegao-tzx) is **not**
    Telosnex fllama. Telosnex/fllama is git-only (`publish_to: 'none'`) and
    GPL-2.0 with a commercial dual license.
  - `dartantic_ai` lives at `csells/dartantic` (the `dartantic_ai` repo URL
    redirects).
  - `llama_cpp_dart` on pub (0.2.2, Jan 2026) is far behind GitHub
    (`0.9.0-dev.12`, a mobile-only rewrite with CI-built prebuilt binaries).

## Headline context

- **Genkit Dart 1.0.0 shipped 2026-10-07** (publisher genkit.dev, Apache-2.0,
  33,338 dl/30d) with Google AI, OpenAI, Anthropic, MCP and Shelf plugins.
  On-device is not first-party yet: genkit-dart issue
  https://github.com/genkit-ai/genkit-dart/issues/383 "On-device Genkit
  (Flutter)" is open, while third parties already ship `genkit_llamadart` and
  `genkit_flutter_edge_ai`.
- The most aggressive on-device competitor is **llamadart** (leehack): 59
  versions since 2026-01-28, llama.cpp plus LiteRT-LM, build-hook prebuilt
  binaries, an experimental WebGPU web path, grammars, tool loops, and adapters
  for both Genkit and Dartantic. The same author maintains `mcp_dart`.
- **flutter_edge_ai** (ex flutter_gemma) is the incumbent by adoption
  (flutter_gemma: 436 likes, 65,791 dl/30d) and now has a modular engine
  architecture (LiteRT-LM, MediaPipe, ONNX, OS built-in models) plus RAG,
  speech, agent skills and Genkit integration.

## A. Agent and LLM frameworks / provider SDKs

| package | version | last published | points / likes / dl30 | platforms | license | notes |
|---|---|---|---|---|---|---|
| dartantic_ai | 3.4.2 | 2026-07-02 | 150/160, 60 likes, 4,056 | A I W L M Web | BSD-3 | Agent with multi-step tools, typed output (json_schema_builder), 10+ providers, MCP, thinking, server-side tools, media gen. Repo csells/dartantic: 94 stars, 29 open / 82 total issues. No release since July. |
| dartantic_interface | 4.0.1 | 2026-07-02 | 160/160, 1, 3,904 | A I W L M Web | BSD-3 | Provider interface for custom providers. |
| dartantic_llamadart | 0.7.1 | 2026-10-04 | 160/160, 1, 480 | A I W L M Web | BSD-3 | Third-party local GGUF/LiteRT-LM provider for Dartantic via llamadart. |
| langchain | 0.9.0 | 2026-08-27 | 160/160, 303, 2,301 | A I W L M Web | MIT | LCEL, chains, agents, memory, MemoryVectorStore. Repo: 689 stars, 9 open / 243 total issues. |
| langchain_core / _openai / _google / _anthropic / _ollama / _community / _chroma | 0.4.0 to 0.9.0 | 2026-08-27 | 150 to 160 pts, 3 to 29 likes, 109 to 2,318 | A I W L M Web | MIT | langchain_community has an ObjectBox vector store; no sqlite-vec store. |
| openai_dart | 11.0.1 | 2026-10-11 | 160/160, 137, 43,853 | A I W L M Web | MIT | davidmigloz/ai_clients_dart; includes realtime WebSocket/WebRTC. |
| anthropic_sdk_dart | 9.0.0 | 2026-09-16 | 160/160, 17, 24,435 | A I W L M Web | MIT | ai_clients_dart. |
| googleai_dart | 13.0.0 | 2026-09-16 | 160/160, 31, 9,999 | A I W L M Web | MIT | Unofficial Gemini + Vertex client. |
| ollama_dart | 4.0.0 | 2026-09-30 | 160/160, 92, 5,825 | A I W L M Web | MIT | ai_clients_dart. |
| mistralai_dart | 8.1.0 | 2026-10-04 | 160/160, 9, 3,982 | A I W L M Web | MIT | ai_clients_dart. |
| dart_openai | 8.0.0 | 2026-08-25 | 160/160, 576, 15,495 | A I W L M Web | MIT | anasfik/openai; older popular OpenAI SDK. |
| genkit | 1.0.0 | 2026-10-07 | 160/160, 81, 33,338 | A I W L M Web | Apache-2.0 | Google-backed: flows, tools, structured output, streaming, embed, dotprompt, dev UI and tracing. genkit-dart: 166 stars, 104 open / 177 total issues. |
| genkit_google_genai / _openai / _anthropic | 1.0.0 | 2026-10-07 | 150 to 160 pts, 1 to 2 likes, 5,065 to 26,959 | A I W L M Web | Apache-2.0 | First-party Genkit model plugins. |
| genkit_mcp / genkit_shelf | 1.0.0 | 2026-10-07 | 140 to 150 pts | A I W L M (no Web) | Apache-2.0 | MCP and server integration. |
| genkit_llamadart | 3.2.1 | 2026-10-11 | 160/160, 7, 611 | A I W L M Web | MIT | Local GGUF/LiteRT-LM chat, tools, JSON, embeddings for Genkit. |
| genkit_flutter_edge_ai | 0.9.0 | 2026-10-12 | 150/160, 1, 636 | A I W L M Web | MIT | Replaces genkit_flutter_gemma 0.6.3 (final). |
| agents | 2.0.0 | 2026-07-31 | 60/160, 1, 81 | none tagged | MIT | jamiewest: Dart port of Microsoft Agents framework. Low score. |
| agents_genkit | 0.1.0 | 2026-05-24 | 140/160, 0, 33 | A I W L M | MIT | **Discontinued** on pub.dev. |
| firebase_ai | 4.0.0 | 2026-08-24 | 140/160, 126, 89,664 | A I M Web | Apache-2.0 | Official Firebase AI Logic (Gemini/Imagen, incl. hybrid on-device on some targets (unverified)). No Windows/Linux. Replaces firebase_vertexai (discontinued). |
| google_generative_ai | 0.4.7 | 2025-04-17 | 150/160, 912, 84,130 | A I W L M Web | Apache-2.0 | **Deprecated**: README titled "[Deprecated]", repo google-gemini/generative-ai-dart archived; points users to Firebase SDK. Not flagged discontinued on pub, still heavily downloaded. |
| mcp_dart | 2.4.2 | 2026-09-03 | 160/160, 79, 210,245 | A I W L M Web | MIT | leehack; servers, clients, hosts. 116 stars. |
| dart_mcp | 0.5.2 | 2026-06-29 | 150/160, 83, 513,242 | A I W L M Web | BSD-3 | Official dart-lang/ai (labs.dart.dev). |
| flutter_ai_toolkit | 1.0.0 | 2025-12-15 | 140/160, 246, 8,060 | A I M Web | BSD-3 | Official chat UI widgets (flutter/ai). |
| genui | 0.10.4 | 2026-09-29 | 130/160, 198, 44,491 | A I M Web | BSD-3 | Official generative UI (replaces flutter_genui). |
| ag_ui | 0.3.0 | 2026-06-24 | 140/160, 6, 15,939 | A I W L M Web | MIT | AG-UI protocol Dart SDK. |
| dart_agent_core | 2.1.7 | 2026-10-09 | 160/160, 11, 972 | A I W L M Web | MIT | memex-lab, 46 stars: agent loop, skills (SKILL.md), MCP, context compression, evals with pass@k, state persistence. Notable newcomer. |
| adk_dart | 2026.10.7 | 2026-10-07 | 140/160, 6, 575 | A I W L M | Apache-2.0 | Community Dart port of Google ADK runtime. |
| agentic_core / agentic_llm / agentic_vector | 0.3.1 | 2026-09-30 | 160/160, 2, 506 to 598 | A I W L M Web | MIT | New (Aug 2026) provider-independent stack with JSON Schema, cancellation, vector port. |
| ai_sdk_openai_compatible / ai_sdk_anthropic | 3.0.0 | 2026-10-04 | 140 to 160 pts, 0 | A I W L M Web | MIT | codenameakshay/ai_sdk_dart (Vercel AI SDK style). |
| llm_dart | 0.10.7 | 2026-03-26 | 90/160, 22, 740 | none tagged | MIT | Multi-provider; low score. |
| agenix | 4.1.2 | 2026-07-02 | 160/160, 18, 83 | A I W L M Web | MIT | Multi-agent orchestration. |
| vantura | 1.2.0 | 2026-08-23 | 160/160, 9, 101 | A I W L M | BSD-3 | ReAct agent for on-device LLMs. |
| flutter_local_agent_kit | 1.1.6 | 2026-08-20 | 160/160, 12, 126 | A I W M | MIT | Offline agent + local RAG + UI. |
| llm_tool | 1.0.1 | 2026-10-08 | 160/160, 6, 496 | A I W L M Web | MIT | Annotation-generated tools for many providers. |
| instructor_dart | 1.4.1 | 2026-08-29 | 160/160, 0, 196 | A I W L M Web | MIT | Typed validated structured output (post-hoc validate/retry). |

## B. On-device inference

| package | version | last published | points / likes / dl30 | platforms | license | build approach | notes |
|---|---|---|---|---|---|---|---|
| flutter_edge_ai (ex flutter_gemma) | 2.2.1 | 2026-10-12 | 150/160, 11, 1,971 | A I W L M Web | MIT | Build hooks + federated plugin; engines as separate packages | Engines: LiteRT-LM, MediaPipe (.task), ONNX Runtime, OS built-in (Gemini Nano, Apple FM, Windows AI Foundry, Chrome Prompt API). Web via WebGPU; web .litertlm is text-only preview. Qualcomm/Intel NPU. RAG via Qdrant Edge or sqlite-vec. 638 stars, 13 open / 241 total issues. macOS needs manual Podfile post_install block and SPM disabled. |
| flutter_gemma | 1.11.4 | 2026-10-05 | 130/160, 436, 65,791 | A I W L M Web | MIT | hooks + plugin | **Discontinued, replaced by flutter_edge_ai.** Still the most-downloaded on-device LLM package. |
| llamadart | 0.11.1 | 2026-10-08 | 160/160, 49, 12,089 | A I W L M Web | MIT | Build hook downloads prebuilt native archives (no local C++ toolchain); Apple via SwiftPM companion | llama.cpp (Metal, Vulkan, CPU) + LiteRT-LM; web "experimental" via WebGPU bridge; grammars, structured output, tool loop, thinking budgets, embeddings, STT/TTS, image gen (stable-diffusion.cpp). 78 stars, 129 open / 425 total issues (mostly maintainer-filed tracking issues). |
| llama_cpp_dart | 0.2.2 (pub); 0.9.0-dev.12 (GitHub) | 2026-01-02 | 130/160, 82, 3,666 | A I W L M (pub tag) | MIT | pub 0.2.2: user compiles llama.cpp. GitHub 0.9.x: CI-built xcframework + Android AAR (CPU and Hexagon NPU), hook for Android | 0.9.x narrows scope to iOS/Android (macOS dev only); web request closed (#87). 307 stars, 2 open / 83 total issues. |
| fllama (Telosnex, git-only) | 0.0.1 in pubspec, not on pub | n/a (repo pushed 2026-10-06) | n/a; 209 stars | A I W L M Web | GPL-2.0 + commercial dual license | Build hooks + native_toolchain_cmake + git-pinned native_prebuilt | Web via bundled wllama WASM/WebGPU, needs cross-origin isolation for threads. OpenAI-compatible API, tool calling, JSON-schema constrained output, cached tokenizer for context accounting. 17 open / 24 total issues. |
| fllama (pub, xuegao-tzx) | 0.0.1 | 2024-11-12 | 130/160, 4, 781 | A I | MIT | plugin | Unrelated single-release package. |
| nobodywho | 5.1.0 | 2026-10-09 | 160/160, 27, 1,015 | A I W L M | EUPL-1.2 | Rust core (llama.cpp underneath, (unverified) via Rust bindings) with plugin per platform | 1,555 stars; also Godot, Python, Swift, Kotlin, React Native. Has its own GBNF grammar crate, function calling, embeddings, RAG, STT/TTS/VAD. No web. |
| mediapipe_genai | 0.0.1 | 2024-05-14 | 150/160, 17, 40 | A I M | BSD-3 | Early native-assets experiment (master channel) | Effectively abandoned as a package; google/flutter-mediapipe repo last pushed 2026-07-01. |
| llama_flutter_android | 0.2.6 | 2026-07-21 | 150/160, 9, 2,885 | A I | MIT | plugin | Android-focused llama.cpp. |
| aub_ai | 1.0.3 | 2023-12-06 | 130/160, 35, 58 | A I W L M | AGPL-3.0 | plugin | Stale (repo pushed 2024-04). |
| maid (Mobile-Artificial-Intelligence) | n/a | n/a | 2,721 stars | n/a | MIT (repo) | n/a | The Maid app repo now contains package.json, metro.config.js, app.config.ts: it appears to have moved to React Native (unverified beyond file layout). The pub `maid` package is unrelated (2022). Its former Dart lib `llama_sdk` 0.0.5 was last published 2025-05-28. |
| flutter_llama | 1.2.1 | 2026-10-11 | 130/160, 14, 438 | A I W L M | unknown | plugin | GitLab-hosted. |
| llm_llamacpp | 0.7.0 | 2026-09-22 | 150/160, 1, 838 | A I W L M | MIT | build hooks | brynjen/dart-llm. |
| local_ai_llama_cpp | 0.0.3 | 2026-09-04 | 140/160, 0, 120 | A I W L M | Apache-2.0 | n/a | GBNF-constrained adapter for LocalAI Kit. |
| cactus | 1.3.0 | 2025-12-19 | 110/160, 24, 521 | A I M | unknown on pub; repo LICENSE is MIT-like text with "All Rights Reserved" header (unverified terms) | plugin | cactus-flutter repo **archived**; Flutter binding now in cactus-compute/cactus `bindings/flutter` (6,118 stars). Telemetry on by default; NPU requires "Pro key". |
| executorch_flutter | 0.8.0 | 2026-09-19 | 160/160, 12, 655 | A I W L M Web | MIT | hooks + plugin | Mostly vision; experimental LLM. executorch_dart is the pure-Dart FFI sibling. |
| flutter_onnxruntime | 1.9.0 | 2026-10-06 | 150/160, 51, 26,468 | A I W L M Web | MIT | plugin (native wrappers; web via onnxruntime-web (unverified)) | Most active ORT binding. |
| onnxruntime | 1.4.1 | 2024-03-27 | 150/160, 73, 13,668 | A I W L M | MIT | plugin | Stale but still downloaded. Forks: onnxruntime_v2 (2026-01), onnxruntime_plus (2026-07, SPM). |
| flutter_litert | 3.9.4 | 2026-10-12 | 160/160, 30, 13,059 | A I W L M Web | Apache-2.0 | plugin | General LiteRT (TFLite) successor; tflite_flutter 0.12.1 (911 likes) last published 2025-10-28. |
| flutter_litert_lm | 0.3.0 | 2026-04-11 | 150/160, 11, 554 | A I | Apache-2.0 | plugin | LiteRT-LM LLMs. litertlm_dart 0.1.1 (DenisovAV, hooks) is a pure-Dart FFI variant. |
| flutter_local_ai | 0.2.1 | 2026-09-27 | 160/160, 50, 4,439 | A I W M Web | MIT | plugin | OS-provided models (Apple FM, Gemini Nano, etc.). |
| apple_foundation_models | 0.5.0 | 2026-10-08 | 160/160, 1, 817 | I M | MIT | plugin | Includes schema-constrained structured output from Apple FM. |
| onde_inference | 1.3.2 | 2026-10-09 | 160/160, 8, 645 | A I W L M | MIT | plugin | Qwen 2.5 focused. |
| xybrid_flutter / edge_veda / llamafu / flutter_gpt_engine / onenm_local_llm / flutter_local_llm | various | 2026 | 0 to 19 likes | mostly A I | MIT / Apache-2.0 | plugin | Long tail of small 2026 entrants. |
| whisper_ggml / sherpa_onnx | 2.8.0 / 1.13.8 | 2026-10-12 / 2026-09-11 | 41 / 121 likes | sherpa_onnx has Web | MIT / Apache-2.0 | plugin | Speech; relevant for ggml symbol collisions (see gaps). |
| gguf | 0.1.1 | 2025-10-16 | 160/160, 0, 35 | A I W L M | BSD-3 | pure Dart | GGUF metadata parser. |

No pub.dev package for MLC LLM was found (`mlc_llm` returns 404; search for
"mlc" returned only unrelated HTML packages).

## C. Vector / RAG

| package | version | last published | points / likes / dl30 | platforms | license | notes |
|---|---|---|---|---|---|---|
| objectbox (+ objectbox_flutter_libs) | 5.3.2 | 2026-05-20 | 160/160, 1,580, 187,547 | A I W L M (no Web) | Apache-2.0 (Dart binding); native core licensing per objectbox.io FAQ (unverified) | Mature on-device HNSW vector search with persistence and queries. No web. Used by langchain_community ObjectBoxVectorStore. |
| sqlite3 | 3.7.0 | 2026-09-30 | 150/160, 465, 2,839,441 | A I W L M Web | MIT | Build hooks; web via WASM. Base for sqlite-vec extensions. |
| sqlite3_vec | 0.1.2 | 2026-09-16 | 150/160, 0, 468 | A I W L M (no Web) | MIT | sqlite-vec v0.1.9 compiled from bundled C as a native asset (hooks). |
| sqlite_vec | 0.1.7-alpha.3 | 2026-01-18 | 160/160, 0, 415 | A I W L M | MIT | Plugin; alpha. |
| sqlite_vector | 1.1.2 | 2026-09-11 | 115/160, 2, 4,401 | A I W L M | Apache-2.0 (pub tag); upstream sqliteai licensing may differ (unverified) | sqlite.ai extension via hooks. |
| flutter_edge_ai_sqlite | 2.0.1 | 2026-10-10 | 160/160, 0, 511 | A I W L M Web | MIT | sqlite-vec for flutter_edge_ai on all six platforms including web. |
| local_hnsw | 1.0.0 | 2025-03-28 | 130/160, 8, 7,249 | A I W L M Web | MIT | Pure-Dart in-memory HNSW, JSON save/load, single release. |
| dart_vector_index | 1.0.1 | 2026-10-06 | 160/160, 2, 395 | A I W L M Web | Apache-2.0 | Pure-Dart HNSW + flat + SQ8 quantization + metadata filters; 2 versions old. |
| dart_hnsw | 0.3.0 | 2026-07-13 | 150/160, 1, 53 | A I W L M | Apache-2.0 | hnswlib bindings via hooks, multi-isolate shared index. |
| mobile_rag_engine (+ rag_engine_flutter) | 0.20.1 | 2026-10-08 | 160/160, 15, 542 | A I W L M | MIT | Rust core via Cargokit, HNSW + BM25 hybrid; requires Rust toolchain at build (no prebuilt yet). |
| flutter_hybrid_search | 1.2.0 | 2026-04-13 | 160/160, 4, 52 | A I M | MIT | HNSW + FTS5 hybrid. |
| tostore | 3.5.1 | 2026-09-01 | 160/160, 141, 939,018 | A I W L M Web | Apache-2.0 | KV/table store with vector and hybrid retrieval. The 30-day download figure looks anomalous relative to likes (possibly CI-driven) (unverified). |
| agentic_vector | 0.3.1 | 2026-09-30 | 160/160, 2, 506 | A I W L M Web | MIT | Exact in-process search + Qdrant adapter. |
| langchain (MemoryVectorStore) / langchain_community (ObjectBoxVectorStore) / langchain_chroma / langchain_supabase / langchain_pinecone | see A | 2026-08-27 (pinecone 2025-08-10) | | | MIT | Only local options are in-memory and ObjectBox. sqlite-vec store request open since 2024 (#516). |
| chromadb / pinecone | 2.0.0 / 0.7.2 | 2026-09-16 / 2023-11-20 | 20 / 8 likes | all incl. Web | MIT / BSD-3 | Remote clients. |
| isar | 3.1.0+1 | 2023 (latest stable) | 130/160, 2,448, 3,758 | A I W L M Web | Apache-2.0 | No vector search; stale stable line. |
| dvdb | 1.0.7 | 2024-03-11 | 140/160, 16, 41 | A I W L M | Apache-2.0 | Stale. |

## D. Tokenizers

| package | version | last published | points / likes / dl30 | platforms | license | notes |
|---|---|---|---|---|---|---|
| tiktoken | 1.0.3 | 2023-04-06 | 160/160, 22, 863 | all incl. Web | MIT | Stale; cl100k era. |
| langchain_tiktoken | 1.0.1 | 2024-01-09 | 140/160, 3, 2,696 | all incl. Web | MIT | Stale fork. |
| tiktoken_tokenizer_gpt4o_o1 | 1.2.1 | 2025-04-05 | 140/160, 3, 689 | all incl. Web | BSD-2 | Adds o200k (GPT-4o/o1); pure Dart. |
| flutter_tiktoken / mishamosher_tiktoken / flutter_gpt_tokenizer | 0.0.1 / 1.0.1 / 0.1.1 | 2023 to 2024 | 1 to 11 likes | | MIT | Stale. |
| dart_sentencepiece_tokenizer | 1.4.1 | 2026-09-06 | 160/160, 7, 36,970 | A I W L M (no Web tag despite README claiming web) | MIT | Pure Dart BPE (Gemma) + Unigram (Llama), HF tokenizer.json for SentencePiece pipelines; DenisovAV is a contributor. |
| hf_tokenizers | 1.2.2 | 2026-09-22 | 160/160, 1, 708 | W L M only | MIT | HF tokenizers over FFI via hooks, claims byte-exact BPE/WordPiece/Unigram; no mobile or web tag. |
| dart_bert_tokenizer / bert_tokenizer / dart_wordpiece | 1.2 to 1.3 | 2026 | 2 to 4 likes | | MIT | WordPiece for embedding models. |
| token_counter | 1.0.0 | 2026-04-25 | 160/160, 0, 17 | all incl. Web | MIT | Heuristic estimator with optional exact tiktoken/SentencePiece loading, context helpers, cost tables. |
| flutter_edge_ai_embeddings | 2.2.3 | 2026-10-12 | 160/160, 0, 594 | all incl. Web | MIT | Embedding tokenizers for flutter_edge_ai. |
| (engine-bundled) | | | | | | llamadart, fllama, llama_cpp_dart and nobodywho expose the model's own tokenizer through llama.cpp; fllama advertises cached tokenization for context accounting. |

No exact tokenizer exists for Claude or Gemini cloud models in Dart (those
vocabularies are not public; providers expose count-tokens endpoints instead).

## E. Security / guardrails (supplementary)

| package | version | last published | likes / dl30 | platforms | notes |
|---|---|---|---|---|---|
| ai_guardrails | 1.4.2 | 2026-09-10 | 2 / 396 | all incl. Web | Input/output safety checks, provider-agnostic. |
| redact | 0.1.0 | 2026-07-06 | 1 / 1,359 | all incl. Web | PII redaction. |
| llm_prompt_guard | 1.0.0 | 2026-08-23 | 1 / 71 | all incl. Web | Prompt-injection pattern scanning. |
| ironclad_guardrails | 0.0.1 | 2026-10-12 | 0 / n/a | all incl. Web | Published today; injection firewall, tool-call gating. |

None of the major frameworks ships a built-in security layer (tool permission
policy, injection detection, secret handling).

## Competitor issue mining

Reaction counts are near zero everywhere; most-commented and recurring themes
are listed. Full title dumps were analysed for: web, streaming, tools, build,
size, structured output, tokens, RAG, crashes/memory, isolates, performance,
security.

### dartantic (csells/dartantic) - 29 open / 82 total
- Most discussed: Gemini thinking levels (#100, 17 comments), faking typed
  output when tools are present on Gemini (#32, 14), tool onCall not invoked
  (#56, 14), Ollama apiKey/baseUrl (#52, 12), web runtime error (#36, 6).
- Open asks: llama.cpp support (#22), secure client-side API key access (#12),
  deterministic testing framework (#19), progressive tool discovery (#114),
  forced tool choice for all providers (#75), Anthropic prompt caching (#64),
  JSON parsing fails with Anthropic on long prompt plus complex schema (#71).
- Theme: provider-feature parity and structured-output-with-tools edge cases;
  no local inference in core.

### langchain_dart (davidmigloz/langchain_dart) - 9 open / 243 total
- Mostly closed; open long-tail integration asks: HuggingFace Hub (#19),
  sqlite-vec vector store (#516, open since 2024-08), callbacks (#518),
  flutter_gemma support (#931).
- Recurring bug classes (closed): streaming plus tool-call parsing
  (#913, #741, #746, #778, #811), multi-tool-call on Gemini (#753), thought
  signature loss in tool round-trips (#942), web incompatibility (#207 int64
  literal on web, #251, #567 WASM, #812 webdev).

### flutter_edge_ai / flutter_gemma (DenisovAV) - 13 open / 241 total
- Most commented (all closed): iOS crashes with Gemma 4 (#218, 22), Android
  crash after 3 to 4 turns (#37, 21), iOS build failure (#5, 20), NPU failure
  (#293, 20), 16 KB pages (#137, 15), TensorFlowLiteSelectTfOps not found
  (#143, 13), garbage output on GPU (#214, 13), Windows load failure (#212, 12),
  App Store upload rejected for framework min OS (#286, 12).
- Recurring: native packaging (32 build-related titles), crashes and memory
  (26: native leak about 65 MB per inference #402, close() not releasing GPU
  memory #348), main-isolate blocking (#364, #299), stream cancel not
  cancelling native generation (#373), tool-call format parsing per model
  family (#228, #367), web gaps (#244 dart:ffi on web, #251, #352, #131).
- Open: constrained decoding (#195), memory diagnostics (#517), Windows ARM64
  (#326), Genkit plugin returns no usage (#570), maxTokens semantics (#571).

### llama_cpp_dart (netdur) - 2 open / 83 total
- Most commented: LateInitializationError on context (#51, 15, 5 reactions),
  garbled Chinese output (#55), iOS model load (#44), libllama.so load
  (#38), build help (#2), prebuilt binaries request (#50, 4 reactions).
- Recurring: build/link failures (19 titles: dlsym symbol lookup #104, #27,
  #93; 16 KB page size #107; hard-coded paths #97), isolate callback errors
  (#88), cancellation not stopping decode (#105), GBNF grammar SIGABRT
  (#112), prompt larger than batch (#89), tokenizer token loss on mixed
  CJK/Latin (#86), slowdown on each turn (#79), web support (#87, closed).

### fllama (Telosnex) - 17 open / 24 total
- Open: dynamic library load failure (#10), model reloaded on every request
  (#15), low Android speed (#16), Windows crash (#14), multimodal crashes (#5),
  web demo request (#8), iOS header conflicts with other ggml-based pods (#25).
- Low maintainer responsiveness on issues relative to repo activity.

### llamadart (leehack) - 129 open / 425 total
- Mostly maintainer-filed engineering issues. Open themes: WebGPU behaviour
  (43 titles), structured output validation (#584, #174 strict structured
  output for LiteRT-LM), tool schema fidelity (#1007), per-model chat
  template and thinking parsing (#741, #742, #901), memory growth (#634, #552),
  worker isolate supervision (#629), GPU wrong output under grammar (#948).

## What they do better than we could (at least for v1)

1. **Provider breadth and churn tracking.** dartantic (10+ providers,
   server-side tools, media generation) and davidmigloz/ai_clients_dart
   (openai_dart 43,853 dl/30d, anthropic_sdk_dart 24,435, googleai_dart,
   mistralai_dart, ollama_dart, all web-capable) keep pace with provider API
   churn. Competing on cloud provider coverage is a losing race; reuse these
   clients.
2. **Genkit Dart 1.0 is official and Google-backed**: flows, dotprompt, dev UI,
   tracing, MCP, Shelf hosting, and an emerging plugin ecosystem. Being a Genkit
   plugin (model, embedder, retriever, middleware) is likely more valuable than
   being a parallel framework.
3. **Engine breadth on-device.** flutter_edge_ai covers LiteRT-LM, MediaPipe,
   ONNX and OS built-in models (Gemini Nano, Apple FM, Windows AI Foundry,
   Chrome Prompt API), NPU paths (Qualcomm, Intel), speech, model download
   management and LoRA. Google model formats (.litertlm, .task) and Gemma
   first-day support are its moat.
4. **llamadart's velocity and packaging.** Hook-delivered prebuilt binaries
   (no local toolchain), WebGPU web path, llama.cpp plus LiteRT-LM, grammars,
   tool loops, STT/TTS and image generation, already wired into Genkit and
   Dartantic. Matching its llama.cpp feature surface is expensive.
5. **nobodywho's multi-runtime reach** (Rust core reused across Flutter,
   Godot, Python, Swift, Kotlin, React Native; 1,555 stars) and
   commercial-friendly EUPL licensing.
6. **ObjectBox's mature persistent HNSW** (1,580 likes, 187k dl/30d) and the
   sqlite3 package's hooks plus WASM story (2.8M dl/30d) for storage.
7. **Official MCP and UI**: dart_mcp (dart-lang) and mcp_dart are mature;
   flutter_ai_toolkit and genui are official Flutter labs UI layers.

## Unmet needs / gaps (with evidence)

1. **Engine-level constrained decoding that is reliable and portable.**
   - No constrained decoding in the LiteRT/MediaPipe stack:
     https://github.com/DenisovAV/flutter_edge_ai/issues/195 (open),
     https://github.com/leehack/llamadart/issues/174 (open, strict structured
     output for LiteRT-LM), https://github.com/leehack/llamadart/issues/584.
   - Grammar paths crash: https://github.com/netdur/llama_cpp_dart/issues/112
     (GBNF SIGABRT on any grammar), https://github.com/leehack/llamadart/issues/948.
   - Cloud structured output with tools is fragile:
     https://github.com/csells/dartantic/issues/32,
     https://github.com/csells/dartantic/issues/71,
     https://github.com/csells/dartantic/issues/96,
     https://github.com/genkit-ai/genkit-dart/issues/426 (structured output
     comes back as prose on models without native constrained decoding),
     https://github.com/genkit-ai/genkit-dart/issues/560.
   - Opportunity: one JSON-Schema-to-grammar compiler in the C++ core used by
     every local engine, plus a pure-Dart incremental JSON validator/repairer
     for web and cloud models.
2. **Exact tokenization and context budgeting.**
   - Missing usage and confused token limits:
     https://github.com/DenisovAV/flutter_edge_ai/issues/570,
     https://github.com/DenisovAV/flutter_edge_ai/issues/571,
     https://github.com/DenisovAV/flutter_edge_ai/issues/62,
     https://github.com/netdur/llama_cpp_dart/issues/89.
   - Tokenizer correctness bugs:
     https://github.com/netdur/llama_cpp_dart/issues/86,
     https://github.com/leehack/llamadart/issues/554.
   - Ecosystem: tiktoken ports are stale (2023 to 2025), hf_tokenizers is
     desktop-only, dart_sentencepiece_tokenizer lacks a web tag, no unified
     "count, truncate, pack history to budget" API across cloud and local.
     langchain_dart's early asks (#3, #26) were never generalised.
3. **Flutter web parity.** Native-first designs break or degrade on web:
   https://github.com/csells/dartantic/issues/36,
   https://github.com/davidmigloz/langchain_dart/issues/207,
   https://github.com/davidmigloz/langchain_dart/issues/567,
   https://github.com/DenisovAV/flutter_edge_ai/issues/244,
   https://github.com/DenisovAV/flutter_edge_ai/issues/251,
   https://github.com/DenisovAV/flutter_edge_ai/issues/131,
   https://github.com/netdur/llama_cpp_dart/issues/87,
   https://github.com/Telosnex/fllama/issues/8. llamadart labels web
   experimental with best-effort tool calls; fllama web needs cross-origin
   isolation. ObjectBox and sqlite3_vec have no web build.
4. **Native packaging pain is the number one complaint class.**
   https://github.com/netdur/llama_cpp_dart/issues/50 (prebuilt request),
   https://github.com/netdur/llama_cpp_dart/issues/104,
   https://github.com/netdur/llama_cpp_dart/issues/107 (16 KB pages),
   https://github.com/DenisovAV/flutter_edge_ai/issues/5,
   https://github.com/DenisovAV/flutter_edge_ai/issues/143,
   https://github.com/DenisovAV/flutter_edge_ai/issues/286 (App Store
   rejection), https://github.com/DenisovAV/flutter_edge_ai/issues/316
   (checksum mismatch), https://github.com/DenisovAV/flutter_edge_ai/issues/457
   (macOS dylib bundling), https://github.com/Telosnex/fllama/issues/10.
   **ggml symbol collisions** when an app links two ggml-based libraries
   (llama plus whisper): https://github.com/Telosnex/fllama/issues/25,
   https://github.com/netdur/llama_cpp_dart/issues/61. A C++ core should
   namespace or statically hide ggml symbols.
5. **Isolate, cancellation and lifecycle correctness.**
   https://github.com/netdur/llama_cpp_dart/issues/88,
   https://github.com/netdur/llama_cpp_dart/issues/105,
   https://github.com/DenisovAV/flutter_edge_ai/issues/364,
   https://github.com/DenisovAV/flutter_edge_ai/issues/299,
   https://github.com/DenisovAV/flutter_edge_ai/issues/373,
   https://github.com/DenisovAV/flutter_edge_ai/issues/379,
   https://github.com/leehack/llamadart/issues/629.
6. **Memory accounting and leaks.**
   https://github.com/DenisovAV/flutter_edge_ai/issues/402,
   https://github.com/DenisovAV/flutter_edge_ai/issues/348,
   https://github.com/DenisovAV/flutter_edge_ai/issues/517,
   https://github.com/leehack/llamadart/issues/634,
   https://github.com/leehack/llamadart/issues/552,
   https://github.com/netdur/llama_cpp_dart/issues/79,
   https://github.com/Telosnex/fllama/issues/15 (model reloaded per request).
7. **Local tool calling is per-model-family glue that keeps breaking.**
   https://github.com/DenisovAV/flutter_edge_ai/issues/228,
   https://github.com/DenisovAV/flutter_edge_ai/issues/367,
   https://github.com/DenisovAV/flutter_edge_ai/issues/551,
   https://github.com/leehack/llamadart/issues/741,
   https://github.com/leehack/llamadart/issues/1007; cloud side
   https://github.com/davidmigloz/langchain_dart/issues/913,
   https://github.com/davidmigloz/langchain_dart/issues/753,
   https://github.com/csells/dartantic/issues/56. Grammar-constrained tool
   calls derived from the model's own chat template would address this.
8. **Local vector store/RAG that is persistent, cross-platform and web-capable.**
   https://github.com/davidmigloz/langchain_dart/issues/516 (sqlite-vec open
   since 2024), https://github.com/DenisovAV/flutter_edge_ai/issues/131,
   https://github.com/DenisovAV/flutter_edge_ai/issues/232,
   https://github.com/DenisovAV/flutter_edge_ai/issues/492 (Qdrant Edge index
   not flushed), https://github.com/DenisovAV/flutter_edge_ai/issues/264
   (embeddings diverge between iOS and Android). Pure-Dart HNSW packages are
   young (local_hnsw: one 2025 release; dart_vector_index: 2 versions);
   mobile_rag_engine needs a Rust toolchain; ObjectBox has no web.
9. **Security layer.** https://github.com/csells/dartantic/issues/12 (secure
   client-side API key access, open since 2025-06). No framework offers tool
   permission policies, prompt-injection screening on tool results, or secret
   redaction; standalone guardrail packages have 0 to 2 likes.
10. **Local models inside agent frameworks remain bolt-ons.**
    https://github.com/csells/dartantic/issues/22,
    https://github.com/davidmigloz/langchain_dart/issues/931,
    https://github.com/genkit-ai/genkit-dart/issues/383. Third-party adapters
    exist (dartantic_llamadart, genkit_llamadart, genkit_flutter_edge_ai) but
    budgeting, constrained decoding and memory are not unified across cloud and
    local.

## Licensing notes relevant to a new C++ core

- Permissive: llamadart, llama_cpp_dart, flutter_edge_ai, langchain_dart,
  ai_clients_dart (MIT); genkit, firebase_ai (Apache-2.0); dartantic (BSD-3).
- Copyleft or restricted: Telosnex fllama (GPL-2.0 or commercial), aub_ai
  (AGPL-3.0), nobodywho (EUPL-1.2, weak copyleft), cactus (custom; telemetry
  default on, Pro key for NPU) (unverified terms).
- A permissive (MIT/Apache/BSD) C++ core with prebuilt hook-delivered binaries
  would be competitive with llamadart on licensing, and better than fllama,
  aub_ai and cactus.
