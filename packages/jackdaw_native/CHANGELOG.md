## 1.0.0

First stable release.

- GGUF inference through a C++ core on llama.cpp, with prebuilt libraries
  for Android, iOS, macOS, Linux and Windows.
- Structured output and tool calls enforced while decoding, cancellation
  within milliseconds, and prompt prefix reuse across turns.
- Saving and loading a session's processed prompt, and downloading
  models with a hash check.
- On-device embeddings, and an exact int8 vector index in the C++ core.
