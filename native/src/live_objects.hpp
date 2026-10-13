#pragma once

struct jackdaw_model;
struct jackdaw_session;
struct jackdaw_embedder;

namespace jackdaw {

/// Remembers a loaded model. The first call also arranges for every live
/// object to be freed at process exit, before the GPU backends tear down:
/// ggml's Metal backend aborts when buffers are still alive at that point.
void track(jackdaw_model* model);

/// Remembers a session.
void track(jackdaw_session* session);

/// Remembers an embedder.
void track(jackdaw_embedder* embedder);

/// Forgets model and returns whether it was live, so a handle freed at
/// exit is never freed twice.
bool untrack(jackdaw_model* model);

/// Forgets session and returns whether it was live.
bool untrack(jackdaw_session* session);

/// Forgets embedder and returns whether it was live.
bool untrack(jackdaw_embedder* embedder);

/// Frees every live session and embedder, then every live model.
void free_all_live() noexcept;

}
