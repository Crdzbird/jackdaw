/// Measures the jackdaw core on a device: prompt processing, generation
/// and grammar parsing, through the same C API the Dart package uses.
///
/// Usage: jackdaw_speed <model.gguf> <prompt file> <max tokens>
///        [threads] [grammar file] [runs]
/// The prompt file holds the text exactly as the model reads it. Each run
/// starts with a different first character, so no prompt prefix is reused.

#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <fstream>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

#include "jackdaw.h"
#include "llama.h"

namespace {

std::mutex done_mutex;
std::condition_variable done_signal;
bool finished = false;
jackdaw_session* active = nullptr;
std::string output;

void on_event(int64_t, int32_t kind, int32_t value) {
  if (kind == JACKDAW_EVENT_PIECE) {
    char buffer[256];
    int32_t length = 0;
    jackdaw_session_read(active, value, buffer, sizeof buffer, &length);
    output.append(buffer, static_cast<std::size_t>(length));
    return;
  }
  std::lock_guard lock(done_mutex);
  finished = true;
  done_signal.notify_one();
}

std::string read_file(const char* path) {
  std::ifstream file(path, std::ios::binary);
  std::stringstream text;
  text << file.rdbuf();
  return text.str();
}

double grammar_parse_ms(const char* model_path, const std::string& grammar) {
  auto params = llama_model_default_params();
  auto* model = llama_model_load_from_file(model_path, params);
  const auto* vocab = llama_model_get_vocab(model);
  const auto start = std::chrono::steady_clock::now();
  auto* sampler = llama_sampler_init_grammar(vocab, grammar.c_str(), "root");
  const auto ms = std::chrono::duration<double, std::milli>(
                      std::chrono::steady_clock::now() - start)
                      .count();
  llama_sampler_free(sampler);
  llama_model_free(model);
  return ms;
}

}

int main(int argc, char** argv) {
  if (argc < 4) {
    std::fprintf(stderr, "usage: %s model prompt max_tokens [threads] [grammar] [runs]\n",
                 argv[0]);
    return 2;
  }
  const std::string prompt = read_file(argv[2]);
  const int32_t max_tokens = std::stoi(argv[3]);
  const int32_t threads = argc > 4 ? std::stoi(argv[4]) : 4;
  const std::string grammar = argc > 5 && std::string(argv[5]) != "-" ? read_file(argv[5]) : "";
  const int runs = argc > 6 ? std::stoi(argv[6]) : 3;
  llama_backend_init();
  if (!grammar.empty()) {
    std::printf("grammar %zu bytes, parse %.1f ms\n", grammar.size(),
                grammar_parse_ms(argv[1], grammar));
  }
  jackdaw_model_params model_params{0, 1};
  jackdaw_model* model = nullptr;
  if (jackdaw_model_load(argv[1], &model_params, &model) != 0) {
    std::fprintf(stderr, "load failed: %s\n", jackdaw_last_error());
    return 1;
  }
  jackdaw_session_params session_params{4096, threads, 512};
  if (jackdaw_session_create(model, &session_params, on_event, &active) != 0) {
    std::fprintf(stderr, "session failed: %s\n", jackdaw_last_error());
    return 1;
  }
  for (int run = 0; run <= runs; ++run) {
    const std::string text = std::string(1, static_cast<char>('A' + run)) + prompt;
    jackdaw_generate_params params{0.0F, 0, 0.0F, 1, max_tokens,
                                   grammar.empty() ? nullptr : grammar.c_str()};
    {
      std::lock_guard lock(done_mutex);
      finished = false;
      output.clear();
    }
    jackdaw_session_generate(active, run, text.data(), static_cast<int32_t>(text.size()),
                             &params);
    std::unique_lock lock(done_mutex);
    done_signal.wait(lock, [] { return finished; });
    jackdaw_session_stats stats{};
    jackdaw_session_get_stats(active, &stats);
    const double decode_ms = stats.generate_ms - stats.prompt_ms;
    std::printf("%s prompt %d tok %.1f ms (%.1f tok/s) first %.1f ms, gen %d tok %.1f tok/s\n",
                run == 0 ? "warm-up" : "run", stats.prompt_tokens, stats.prompt_ms,
                stats.prompt_tokens * 1000.0 / stats.prompt_ms, stats.first_token_ms,
                stats.generated_tokens,
                stats.generated_tokens > 1 ? (stats.generated_tokens - 1) * 1000.0 /
                    (decode_ms - (stats.first_token_ms - stats.prompt_ms)) : 0.0);
  }
  std::printf("output %s\n", output.c_str());
  jackdaw_session_free(active);
  jackdaw_model_free(model);
  return 0;
}
