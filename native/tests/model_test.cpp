#include <gtest/gtest.h>

#include <chrono>
#include <condition_variable>
#include <cstdlib>
#include <mutex>
#include <string>
#include <vector>

#include "jackdaw.h"

namespace {

using Clock = std::chrono::steady_clock;

struct Events {
  std::mutex mutex;
  std::condition_variable changed;
  std::vector<int32_t> slots;
  int32_t kind = -1;
  int32_t value = -1;
  Clock::time_point finished;
};

Events events;

void record(int64_t, int32_t kind, int32_t value) {
  std::lock_guard lock(events.mutex);
  if (kind == JACKDAW_EVENT_PIECE) {
    events.slots.push_back(value);
  }
  if (kind != JACKDAW_EVENT_PIECE) {
    events.kind = kind;
    events.value = value;
    events.finished = Clock::now();
  }
  events.changed.notify_all();
}

class ModelTest : public testing::Test {
 protected:
  static void SetUpTestSuite() {
    const char* path = std::getenv("JACKDAW_TEST_MODEL");
    if (path == nullptr) return;
    jackdaw_model_params params{};
    params.use_mmap = 1;
    params.gpu_layers = 0;
    ASSERT_EQ(jackdaw_model_load(path, &params, &model_), JACKDAW_OK) << jackdaw_last_error();
  }

  static void TearDownTestSuite() { jackdaw_model_free(model_); }

  void SetUp() override {
    if (model_ == nullptr) GTEST_SKIP() << "set JACKDAW_TEST_MODEL to a GGUF file";
    jackdaw_session_params params{};
    params.context_tokens = 2048;
    ASSERT_EQ(jackdaw_session_create(model_, &params, record, &session_), JACKDAW_OK);
    std::lock_guard lock(events.mutex);
    events.slots.clear();
    events.kind = -1;
  }

  void TearDown() override { jackdaw_session_free(session_); }

  std::string prompt(const std::string& user) {
    jackdaw_chat_message messages[] = {{"system", "You are terse."}, {"user", user.c_str()}};
    int32_t length = 0;
    jackdaw_model_apply_template(model_, messages, 2, 1, nullptr, 0, &length);
    std::string out(static_cast<std::size_t>(length), '\0');
    EXPECT_EQ(jackdaw_model_apply_template(model_, messages, 2, 1, out.data(), length, &length),
              JACKDAW_OK);
    return out;
  }

  int32_t start(const std::string& text, jackdaw_generate_params params, int64_t id = 1) {
    {
      std::lock_guard lock(events.mutex);
      events.slots.clear();
      events.kind = -1;
    }
    return jackdaw_session_generate(session_, id, text.data(), static_cast<int32_t>(text.size()),
                                    &params);
  }

  std::string wait() {
    std::unique_lock lock(events.mutex);
    events.changed.wait(lock, [] { return events.kind != -1; });
    std::string text;
    for (const auto slot : events.slots) {
      char buffer[256];
      int32_t length = 0;
      if (jackdaw_session_read(session_, slot, buffer, sizeof buffer, &length) == JACKDAW_OK) {
        text.append(buffer, static_cast<std::size_t>(length));
      }
    }
    return text;
  }

  static jackdaw_model* model_;
  jackdaw_session* session_ = nullptr;
};

jackdaw_model* ModelTest::model_ = nullptr;

TEST_F(ModelTest, TokenizesAndReportsInfo) {
  int32_t count = 0;
  EXPECT_EQ(jackdaw_model_tokenize(model_, "Hello world", 11, 0, nullptr, 0, &count),
            JACKDAW_ERR_BUFFER_TOO_SMALL);
  std::vector<int32_t> tokens(static_cast<std::size_t>(count));
  EXPECT_EQ(jackdaw_model_tokenize(model_, "Hello world", 11, 0, tokens.data(), count, &count),
            JACKDAW_OK);
  EXPECT_GT(count, 0);
  jackdaw_model_info info{};
  EXPECT_EQ(jackdaw_model_get_info(model_, &info), JACKDAW_OK);
  EXPECT_GT(info.parameters, 0U);
}

TEST_F(ModelTest, GeneratesGreedyText) {
  jackdaw_generate_params params{};
  params.max_tokens = 8;
  ASSERT_EQ(start(prompt("Count from one to five."), params), JACKDAW_OK);
  const auto text = wait();
  EXPECT_EQ(events.kind, JACKDAW_EVENT_DONE);
  EXPECT_FALSE(text.empty());
  jackdaw_session_stats stats{};
  jackdaw_session_get_stats(session_, &stats);
  EXPECT_LE(stats.generated_tokens, 8);
  EXPECT_GT(stats.prompt_tokens, 0);
}


TEST_F(ModelTest, GrammarConstrainsOutput) {
  jackdaw_generate_params params{};
  params.max_tokens = 16;
  params.grammar = "root ::= \"yes\" | \"no\"";
  ASSERT_EQ(start(prompt("Is water wet? Answer yes or no."), params), JACKDAW_OK);
  const auto text = wait();
  EXPECT_EQ(events.kind, JACKDAW_EVENT_DONE);
  EXPECT_EQ(events.value, JACKDAW_FINISH_STOP);
  EXPECT_TRUE(text == "yes" || text == "no") << text;
}

TEST_F(ModelTest, ReportsBadGrammar) {
  jackdaw_generate_params params{};
  params.grammar = "root ::= (";
  ASSERT_EQ(start(prompt("hi"), params), JACKDAW_OK);
  wait();
  EXPECT_EQ(events.kind, JACKDAW_EVENT_ERROR);
  EXPECT_EQ(events.value, JACKDAW_ERR_GRAMMAR);
  char buffer[64];
  int32_t length = 0;
  EXPECT_EQ(jackdaw_session_error(session_, buffer, sizeof buffer, &length), JACKDAW_OK);
  EXPECT_EQ(std::string(buffer, static_cast<std::size_t>(length)), "grammar does not parse");
}

TEST_F(ModelTest, CancelStopsDecodingQuickly) {
  jackdaw_generate_params params{};
  params.temperature = 0.8F;
  params.seed = 7;
  ASSERT_EQ(start(prompt("Write a very long story about a jackdaw."), params, 5), JACKDAW_OK);
  {
    std::unique_lock lock(events.mutex);
    events.changed.wait(lock, [] { return events.slots.size() >= 4; });
  }
  EXPECT_EQ(start(prompt("busy?"), params, 6), JACKDAW_ERR_BUSY);
  const auto requested = Clock::now();
  ASSERT_EQ(jackdaw_session_cancel(session_, 5), JACKDAW_OK);
  wait();
  const auto latency = std::chrono::duration_cast<std::chrono::milliseconds>(
      events.finished - requested);
  EXPECT_EQ(events.value, JACKDAW_FINISH_CANCELLED);
  EXPECT_LT(latency.count(), 100);
}

TEST_F(ModelTest, ReusesThePromptPrefix) {
  jackdaw_generate_params params{};
  params.max_tokens = 4;
  const auto first = prompt("Name a bird.");
  ASSERT_EQ(start(first, params), JACKDAW_OK);
  wait();
  ASSERT_EQ(start(first + "A jackdaw.", params, 2), JACKDAW_OK);
  wait();
  jackdaw_session_stats stats{};
  jackdaw_session_get_stats(session_, &stats);
  EXPECT_GT(stats.reused_tokens, 10);
}

TEST_F(ModelTest, SavedStateSkipsTheSavedPrompt) {
  jackdaw_generate_params params{};
  params.max_tokens = 4;
  const auto first = prompt("Name a bird.");
  ASSERT_EQ(start(first, params), JACKDAW_OK);
  wait();
  const auto path = testing::TempDir() + "jackdaw_state.bin";
  ASSERT_EQ(jackdaw_session_save(session_, path.c_str()), JACKDAW_OK) << jackdaw_last_error();
  jackdaw_session* fresh = nullptr;
  jackdaw_session_params session_params{};
  session_params.context_tokens = 2048;
  ASSERT_EQ(jackdaw_session_create(model_, &session_params, record, &fresh), JACKDAW_OK);
  int32_t restored = 0;
  ASSERT_EQ(jackdaw_session_load(fresh, path.c_str(), &restored), JACKDAW_OK)
      << jackdaw_last_error();
  EXPECT_GT(restored, 10);
  jackdaw_session_free(session_);
  session_ = fresh;
  ASSERT_EQ(start(first + "A jackdaw.", params, 2), JACKDAW_OK);
  wait();
  jackdaw_session_stats stats{};
  jackdaw_session_get_stats(session_, &stats);
  EXPECT_GT(stats.reused_tokens, 10);
  EXPECT_EQ(jackdaw_session_load(session_, "/nonexistent/state.bin", &restored), JACKDAW_ERR_IO);
}

}

TEST_F(ModelTest, RefusesGrammarsThatWouldHangTheParser) {
  jackdaw_generate_params params{};
  params.max_tokens = 4;
  params.grammar = R"(root ::= "a"{2,1})";
  const std::string text = "hi";
  EXPECT_EQ(jackdaw_session_generate(session_, 1, text.c_str(), static_cast<int32_t>(text.size()), &params),
            JACKDAW_ERR_GRAMMAR);
  EXPECT_NE(std::string(jackdaw_last_error()).find("minimum above its maximum"), std::string::npos);
}
