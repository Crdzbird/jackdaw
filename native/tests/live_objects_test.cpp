#include <gtest/gtest.h>

#include <cstdlib>

#include "jackdaw.h"
#include "live_objects.hpp"

namespace {

void ignore(int64_t, int32_t, int32_t) {}

}

TEST(LiveObjects, FreeingUnknownHandlesIsIgnored) {
  jackdaw_model_free(nullptr);
  jackdaw_session_free(nullptr);
  jackdaw_embedder_free(nullptr);
  jackdaw_model_free(reinterpret_cast<jackdaw_model*>(0x10));
  jackdaw_session_free(reinterpret_cast<jackdaw_session*>(0x10));
  jackdaw_embedder_free(reinterpret_cast<jackdaw_embedder*>(0x10));
  jackdaw::free_all_live();
}

TEST(LiveObjects, ObjectsFreedAtExitAreNotFreedAgain) {
  const char* path = std::getenv("JACKDAW_TEST_MODEL");
  if (path == nullptr) GTEST_SKIP() << "set JACKDAW_TEST_MODEL to a GGUF file";
  jackdaw_model_params params{};
  params.use_mmap = 1;
  jackdaw_model* model = nullptr;
  ASSERT_EQ(jackdaw_model_load(path, &params, &model), JACKDAW_OK);
  jackdaw_session_params session_params{};
  session_params.context_tokens = 256;
  jackdaw_session* session = nullptr;
  ASSERT_EQ(jackdaw_session_create(model, &session_params, ignore, &session), JACKDAW_OK);
  jackdaw_embedder_params embedder_params{};
  embedder_params.max_tokens = 64;
  jackdaw_embedder* embedder = nullptr;
  ASSERT_EQ(jackdaw_embedder_create(model, &embedder_params, &embedder), JACKDAW_OK);
  jackdaw::free_all_live();
  jackdaw_session_free(session);
  jackdaw_embedder_free(embedder);
  jackdaw_model_free(model);
}
