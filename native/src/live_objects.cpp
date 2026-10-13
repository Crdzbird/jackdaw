#include "live_objects.hpp"

#include <cstdlib>
#include <mutex>
#include <unordered_set>

#include "embedder.hpp"
#include "model.hpp"
#include "session.hpp"

namespace jackdaw {

namespace {

struct Live {
  std::mutex mutex;
  std::unordered_set<jackdaw_model*> models;
  std::unordered_set<jackdaw_session*> sessions;
  std::unordered_set<jackdaw_embedder*> embedders;
};

Live& live() {
  static auto* objects = new Live();
  return *objects;
}

void free_at_exit() { free_all_live(); }

template <typename T>
bool take(std::unordered_set<T*>& set, T* object) {
  std::lock_guard lock(live().mutex);
  return set.erase(object) == 1;
}

template <typename T>
std::unordered_set<T*> take_all(std::unordered_set<T*>& set) {
  std::lock_guard lock(live().mutex);
  std::unordered_set<T*> all;
  all.swap(set);
  return all;
}

}

void track(jackdaw_model* model) {
  static std::once_flag once;
  std::call_once(once, [] { std::atexit(free_at_exit); });
  std::lock_guard lock(live().mutex);
  live().models.insert(model);
}

void track(jackdaw_session* session) {
  std::lock_guard lock(live().mutex);
  live().sessions.insert(session);
}

void track(jackdaw_embedder* embedder) {
  std::lock_guard lock(live().mutex);
  live().embedders.insert(embedder);
}

bool untrack(jackdaw_model* model) { return take(live().models, model); }

bool untrack(jackdaw_session* session) { return take(live().sessions, session); }

bool untrack(jackdaw_embedder* embedder) { return take(live().embedders, embedder); }

void free_all_live() noexcept {
  try {
    for (auto* session : take_all(live().sessions)) delete session;
    for (auto* embedder : take_all(live().embedders)) delete embedder;
    for (auto* model : take_all(live().models)) delete model;
  } catch (...) {
    return;
  }
}

}
