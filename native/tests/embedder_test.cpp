#include <gtest/gtest.h>

#include <cmath>
#include <cstdlib>
#include <string>
#include <vector>

#include "jackdaw.h"

namespace {

class EmbedderTest : public testing::Test {
 protected:
  static void SetUpTestSuite() {
    const char* path = std::getenv("JACKDAW_TEST_EMBED_MODEL");
    if (path == nullptr) return;
    jackdaw_model_params params{};
    params.use_mmap = 1;
    ASSERT_EQ(jackdaw_model_load(path, &params, &model_), JACKDAW_OK) << jackdaw_last_error();
    jackdaw_embedder_params settings{};
    settings.max_tokens = 128;
    ASSERT_EQ(jackdaw_embedder_create(model_, &settings, &embedder_), JACKDAW_OK)
        << jackdaw_last_error();
  }

  static void TearDownTestSuite() {
    jackdaw_embedder_free(embedder_);
    jackdaw_model_free(model_);
  }

  void SetUp() override {
    if (embedder_ == nullptr) GTEST_SKIP() << "set JACKDAW_TEST_EMBED_MODEL to a GGUF file";
  }

  static std::vector<std::vector<float>> embed(const std::vector<std::string>& texts) {
    const auto dims = jackdaw_embedder_dimensions(embedder_);
    std::vector<const char*> pointers;
    std::vector<int32_t> lengths;
    for (const auto& text : texts) {
      pointers.push_back(text.c_str());
      lengths.push_back(static_cast<int32_t>(text.size()));
    }
    std::vector<float> flat(texts.size() * static_cast<std::size_t>(dims));
    EXPECT_EQ(jackdaw_embedder_embed(embedder_, pointers.data(), lengths.data(),
                                     static_cast<int32_t>(texts.size()), flat.data(),
                                     static_cast<int64_t>(flat.size())),
              JACKDAW_OK)
        << jackdaw_last_error();
    std::vector<std::vector<float>> out;
    for (std::size_t i = 0; i < texts.size(); ++i) {
      out.emplace_back(flat.begin() + static_cast<std::ptrdiff_t>(i * static_cast<std::size_t>(dims)),
                       flat.begin() + static_cast<std::ptrdiff_t>((i + 1) * static_cast<std::size_t>(dims)));
    }
    return out;
  }

  static double cosine(const std::vector<float>& a, const std::vector<float>& b) {
    double sum = 0;
    for (std::size_t i = 0; i < a.size(); ++i) sum += static_cast<double>(a[i]) * b[i];
    return sum;
  }

  static inline jackdaw_model* model_ = nullptr;
  static inline jackdaw_embedder* embedder_ = nullptr;
};

}

TEST_F(EmbedderTest, ProducesUnitVectorsThatReflectMeaning) {
  const auto vectors = embed({"A heron wades in the river to catch fish.",
                              "The bird stood in the water hunting fish.",
                              "Quarterly revenue grew by four percent.",
                              "A heron wades in the river to catch fish."});
  EXPECT_GT(jackdaw_embedder_dimensions(embedder_), 0);
  EXPECT_NEAR(cosine(vectors[0], vectors[0]), 1.0, 1e-4);
  EXPECT_GT(cosine(vectors[0], vectors[1]), cosine(vectors[0], vectors[2]));
  EXPECT_NEAR(cosine(vectors[0], vectors[3]), 1.0, 1e-4);
}

TEST_F(EmbedderTest, CutsLongTextsAndAcceptsEmptyOnes) {
  std::string long_text;
  for (int i = 0; i < 400; ++i) long_text += "jackdaw ";
  const auto vectors = embed({long_text, ""});
  EXPECT_NEAR(cosine(vectors[0], vectors[0]), 1.0, 1e-4);
  EXPECT_TRUE(std::isfinite(vectors[1][0]));
}

TEST_F(EmbedderTest, RejectsInvalidArguments) {
  const char* text = "hi";
  const int32_t length = 2;
  float out[1];
  EXPECT_EQ(jackdaw_embedder_embed(embedder_, &text, &length, 1, out, 1),
            JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_embedder_embed(nullptr, &text, &length, 1, out, 1),
            JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_embedder_embed(embedder_, nullptr, nullptr, 0, nullptr, 0), JACKDAW_OK);
  EXPECT_EQ(jackdaw_embedder_create(nullptr, nullptr, nullptr), JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_embedder_dimensions(nullptr), 0);
}
