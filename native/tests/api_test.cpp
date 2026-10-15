#include <gtest/gtest.h>

#include <string>

#include "jackdaw.h"

namespace {

void ignore(int64_t, int32_t, int32_t) {}

TEST(Api, ReportsAbiVersion) { EXPECT_EQ(jackdaw_abi_version(), JACKDAW_ABI_VERSION); }

TEST(Api, ReportsCpuRequirements) {
  EXPECT_STREQ(jackdaw_cpu_requirements(), JACKDAW_CPU_REQUIREMENTS);
}

TEST(Api, RejectsMissingArguments) {
  jackdaw_model* model = nullptr;
  EXPECT_EQ(jackdaw_model_load(nullptr, nullptr, &model), JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_STREQ(jackdaw_last_error(), "path and out are required");
  EXPECT_EQ(jackdaw_model_get_info(nullptr, nullptr), JACKDAW_ERR_INVALID_ARGUMENT);
  jackdaw_session* session = nullptr;
  EXPECT_EQ(jackdaw_session_create(nullptr, nullptr, ignore, &session),
            JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_session_cancel(nullptr, 1), JACKDAW_ERR_INVALID_ARGUMENT);
  int32_t length = 0;
  EXPECT_EQ(jackdaw_session_read(nullptr, 0, nullptr, 0, &length), JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_session_get_stats(nullptr, nullptr), JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_session_save(nullptr, "x"), JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_session_load(nullptr, "x", &length), JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_session_error(nullptr, nullptr, 0, &length), JACKDAW_ERR_INVALID_ARGUMENT);
  int32_t count = 0;
  EXPECT_EQ(jackdaw_model_tokenize(nullptr, "a", 1, 0, nullptr, 0, &count),
            JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_model_apply_template(nullptr, nullptr, 0, 1, nullptr, 0, &length),
            JACKDAW_ERR_INVALID_ARGUMENT);
}

TEST(Api, FailsToLoadMissingFiles) {
  jackdaw_model* model = nullptr;
  jackdaw_model_params params{};
  EXPECT_EQ(jackdaw_model_load("/nonexistent/model.gguf", &params, &model), JACKDAW_ERR_IO);
  EXPECT_EQ(model, nullptr);
  EXPECT_NE(std::string(jackdaw_last_error()).find("cannot load"), std::string::npos);
}

TEST(Api, FreeingNullIsSafe) {
  jackdaw_model_free(nullptr);
  jackdaw_session_free(nullptr);
}

}
