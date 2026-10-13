#ifndef JACKDAW_H
#define JACKDAW_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define JACKDAW_API __declspec(dllexport)
#else
#define JACKDAW_API __attribute__((visibility("default")))
#endif

/// Version of this ABI. Bumped on every incompatible change.
#define JACKDAW_ABI_VERSION 2

/// Status codes returned by every fallible function.
typedef enum jackdaw_status {
  JACKDAW_OK = 0,
  JACKDAW_ERR_INVALID_ARGUMENT = 1,
  JACKDAW_ERR_IO = 2,
  JACKDAW_ERR_MODEL = 3,
  JACKDAW_ERR_GRAMMAR = 4,
  JACKDAW_ERR_BUSY = 5,
  JACKDAW_ERR_CONTEXT_FULL = 6,
  JACKDAW_ERR_BUFFER_TOO_SMALL = 7,
  JACKDAW_ERR_NOT_FOUND = 8,
  JACKDAW_ERR_INTERNAL = 9
} jackdaw_status;

/// Kinds of events delivered to a jackdaw_event_callback.
typedef enum jackdaw_event_kind {
  /// A text piece is ready; value is the slot to pass to jackdaw_session_read.
  JACKDAW_EVENT_PIECE = 0,
  /// Generation ended; value is a jackdaw_finish_reason.
  JACKDAW_EVENT_DONE = 1,
  /// Generation failed; value is a jackdaw_status.
  JACKDAW_EVENT_ERROR = 2
} jackdaw_event_kind;

/// Why a generation ended.
typedef enum jackdaw_finish_reason {
  JACKDAW_FINISH_STOP = 0,
  JACKDAW_FINISH_LENGTH = 1,
  JACKDAW_FINISH_CANCELLED = 2
} jackdaw_finish_reason;

typedef struct jackdaw_model jackdaw_model;
typedef struct jackdaw_session jackdaw_session;

/// Options for jackdaw_model_load. Zero-initialise, then set fields.
typedef struct jackdaw_model_params {
  /// Layers to offload to the GPU; negative offloads all, 0 keeps the CPU.
  int32_t gpu_layers;
  /// Non-zero to memory-map the file instead of reading it.
  int32_t use_mmap;
} jackdaw_model_params;

/// Facts about a loaded model.
typedef struct jackdaw_model_info {
  uint64_t parameters;
  uint64_t size_bytes;
  int32_t context_train;
} jackdaw_model_info;

/// One chat message for jackdaw_model_apply_template.
typedef struct jackdaw_chat_message {
  const char* role;
  const char* content;
} jackdaw_chat_message;

/// Options for jackdaw_session_create. Zero values pick defaults.
typedef struct jackdaw_session_params {
  /// Context window in tokens; 0 uses 4096.
  int32_t context_tokens;
  /// Worker threads; 0 picks a value for the device.
  int32_t threads;
  /// Prompt batch size in tokens; 0 uses 512.
  int32_t batch_tokens;
} jackdaw_session_params;

/// Options for one jackdaw_session_generate call.
typedef struct jackdaw_generate_params {
  /// Sampling temperature; 0 or less selects greedy decoding.
  float temperature;
  /// Top-k cut-off; 0 disables it.
  int32_t top_k;
  /// Nucleus cut-off; 0 or 1 disables it.
  float top_p;
  /// Seed for sampling.
  uint32_t seed;
  /// Maximum generated tokens; 0 means until the context is full.
  int32_t max_tokens;
  /// Optional GBNF grammar with a root rule named "root"; NULL for none.
  const char* grammar;
} jackdaw_generate_params;

/// Timings and counts for the last finished generation.
typedef struct jackdaw_session_stats {
  int32_t prompt_tokens;
  int32_t reused_tokens;
  int32_t generated_tokens;
  double prompt_ms;
  double first_token_ms;
  double generate_ms;
} jackdaw_session_stats;

/// Receives generation events. Called from the session's worker thread.
typedef void (*jackdaw_event_callback)(int64_t request_id, int32_t kind,
                                       int32_t value);

/// Returns JACKDAW_ABI_VERSION of the loaded library.
JACKDAW_API int32_t jackdaw_abi_version(void);

/// Returns the CPU features this build requires, such as "dotprod", or an
/// empty string. The string is static and owned by the library.
JACKDAW_API const char* jackdaw_cpu_requirements(void);

/// Returns the message for the last failure on the calling thread.
/// The string is owned by the library and valid until the next call on
/// that thread.
JACKDAW_API const char* jackdaw_last_error(void);

/// Loads a GGUF model from path. Blocks; call off the UI thread.
/// On success *out owns the model; release it with jackdaw_model_free.
JACKDAW_API int32_t jackdaw_model_load(const char* path,
                                       const jackdaw_model_params* params,
                                       jackdaw_model** out);

/// Frees a model. Every session created from it must be freed first.
JACKDAW_API void jackdaw_model_free(jackdaw_model* model);

/// Fills *out with facts about model. Thread-safe.
JACKDAW_API int32_t jackdaw_model_get_info(const jackdaw_model* model,
                                           jackdaw_model_info* out);

/// Tokenizes text_len bytes of text with the model vocabulary.
/// Writes at most capacity tokens and sets *out_count to the total. When
/// capacity is too small returns JACKDAW_ERR_BUFFER_TOO_SMALL with
/// *out_count set to the required size. Thread-safe.
JACKDAW_API int32_t jackdaw_model_tokenize(const jackdaw_model* model,
                                           const char* text, int32_t text_len,
                                           int32_t add_special,
                                           int32_t* tokens, int32_t capacity,
                                           int32_t* out_count);

/// Renders messages with the chat template stored in the model.
/// Writes at most capacity bytes, without a terminator, and sets *out_len to
/// the full length. When capacity is too small returns
/// JACKDAW_ERR_BUFFER_TOO_SMALL with *out_len set to the required size.
JACKDAW_API int32_t jackdaw_model_apply_template(
    const jackdaw_model* model, const jackdaw_chat_message* messages,
    int32_t count, int32_t add_assistant, char* buffer, int32_t capacity,
    int32_t* out_len);

/// Creates a session with its own context and worker thread.
/// callback receives every event of every generation on this session.
JACKDAW_API int32_t jackdaw_session_create(jackdaw_model* model,
                                           const jackdaw_session_params* params,
                                           jackdaw_event_callback callback,
                                           jackdaw_session** out);

/// Cancels any running generation, joins the worker thread and frees the
/// session. No callback runs after this returns.
JACKDAW_API void jackdaw_session_free(jackdaw_session* session);

/// Starts generating from prompt and returns at once. Events arrive on the
/// callback tagged with request_id. Returns JACKDAW_ERR_BUSY when a
/// generation is already running. The prompt and grammar are copied.
JACKDAW_API int32_t jackdaw_session_generate(
    jackdaw_session* session, int64_t request_id, const char* prompt,
    int32_t prompt_len, const jackdaw_generate_params* params);

/// Requests cancellation of request_id. Safe from any thread. The
/// generation ends with JACKDAW_EVENT_DONE and JACKDAW_FINISH_CANCELLED.
JACKDAW_API int32_t jackdaw_session_cancel(jackdaw_session* session,
                                           int64_t request_id);

/// Copies the piece in slot into buffer and frees the slot. Writes at most
/// capacity bytes and sets *out_len to the piece length.
JACKDAW_API int32_t jackdaw_session_read(jackdaw_session* session,
                                         int32_t slot, char* buffer,
                                         int32_t capacity, int32_t* out_len);

/// Fills *out with statistics of the last finished generation.
JACKDAW_API int32_t jackdaw_session_get_stats(const jackdaw_session* session,
                                              jackdaw_session_stats* out);

/// Copies the message of the last JACKDAW_EVENT_ERROR into buffer.
JACKDAW_API int32_t jackdaw_session_error(const jackdaw_session* session,
                                          char* buffer, int32_t capacity,
                                          int32_t* out_len);

#ifdef __cplusplus
}
#endif

#endif
