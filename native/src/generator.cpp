#include "generator.hpp"

#include <algorithm>
#include <chrono>
#include <climits>
#include <exception>

#include "model.hpp"
#include "sampler.hpp"
#include "text.hpp"

namespace jackdaw {

namespace {

using Clock = std::chrono::steady_clock;

double elapsed_ms(Clock::time_point start) {
  return std::chrono::duration<double, std::milli>(Clock::now() - start).count();
}

/// Outcome of one generation step.
enum class Step { next, stop, length, cancelled, failed };

class Run {
 public:
  Run(jackdaw_session& session, const Job& job)
      : s_(session), job_(job), vocab_(session.model.vocab) {}

  void execute() {
    stats_ = {};
    const auto tokens = tokenize(vocab_, job_.prompt);
    if (tokens.empty()) return fail(JACKDAW_ERR_INVALID_ARGUMENT, "prompt is empty");
    if (tokens.size() >= llama_n_ctx(s_.context)) {
      return fail(JACKDAW_ERR_CONTEXT_FULL, "prompt does not fit the context");
    }
    auto samplers = make_samplers(vocab_, job_);
    if (!samplers) return fail(JACKDAW_ERR_GRAMMAR, "grammar does not parse");
    stats_.prompt_tokens = static_cast<int32_t>(tokens.size());
    if (const auto step = ingest(tokens); step != Step::next) return end(step);
    stats_.prompt_ms = elapsed_ms(start_);
    end(generate_tokens(*samplers));
  }

 private:
  Step ingest(const std::vector<llama_token>& tokens) {
    auto& cached = s_.cached;
    std::size_t prefix = 0;
    while (prefix < cached.size() && prefix < tokens.size() &&
           cached[prefix] == tokens[prefix]) {
      ++prefix;
    }
    prefix = std::min(prefix, tokens.size() - 1);
    auto* memory = llama_get_memory(s_.context);
    if (!llama_memory_seq_rm(memory, 0, static_cast<llama_pos>(prefix), -1)) {
      llama_memory_clear(memory, true);
      prefix = 0;
    }
    cached.resize(prefix);
    stats_.reused_tokens = static_cast<int32_t>(prefix);
    const auto batch = static_cast<std::size_t>(s_.batch_tokens);
    for (auto i = prefix; i < tokens.size(); i += batch) {
      const auto n = std::min(batch, tokens.size() - i);
      auto* chunk = const_cast<llama_token*>(tokens.data() + i);
      if (const auto step = decode(chunk, static_cast<int32_t>(n)); step != Step::next) {
        return step;
      }
      cached.insert(cached.end(), tokens.begin() + static_cast<std::ptrdiff_t>(i),
                    tokens.begin() + static_cast<std::ptrdiff_t>(i + n));
    }
    return Step::next;
  }

  Step generate_tokens(Samplers& samplers) {
    const auto limit = job_.params.max_tokens > 0 ? job_.params.max_tokens : INT32_MAX;
    const auto context = llama_n_ctx(s_.context);
    for (;;) {
      if (s_.cancelled.load()) return Step::cancelled;
      if (stats_.generated_tokens >= limit || s_.cached.size() >= context) {
        return Step::length;
      }
      auto token = sample(samplers, s_.context, vocab_);
      if (llama_vocab_is_eog(vocab_, token)) return Step::stop;
      if (const auto step = emit(piece(vocab_, token)); step != Step::next) return step;
      ++stats_.generated_tokens;
      if (const auto step = decode(&token, 1); step != Step::next) return step;
      s_.cached.push_back(token);
    }
  }

  Step emit(const std::string& text) {
    if (stats_.generated_tokens == 0) stats_.first_token_ms = elapsed_ms(start_);
    if (text.empty()) return Step::next;
    const auto slot = s_.ring.push(text, s_.cancelled);
    if (slot < 0) return Step::cancelled;
    s_.callback(job_.id, JACKDAW_EVENT_PIECE, slot);
    return Step::next;
  }

  Step decode(llama_token* tokens, int32_t count) {
    const auto status = llama_decode(s_.context, llama_batch_get_one(tokens, count));
    if (status == 0) return Step::next;
    llama_memory_clear(llama_get_memory(s_.context), true);
    s_.cached.clear();
    if (status == 2 || s_.cancelled.load()) return Step::cancelled;
    error_ = "decode failed with status " + std::to_string(status);
    return Step::failed;
  }

  void end(Step step) {
    stats_.generate_ms = elapsed_ms(start_);
    publish_stats();
    switch (step) {
      case Step::stop:
        return s_.finish(job_.id, JACKDAW_EVENT_DONE, JACKDAW_FINISH_STOP);
      case Step::length:
        return s_.finish(job_.id, JACKDAW_EVENT_DONE, JACKDAW_FINISH_LENGTH);
      case Step::cancelled:
      case Step::next:
        return s_.finish(job_.id, JACKDAW_EVENT_DONE, JACKDAW_FINISH_CANCELLED);
      case Step::failed:
        return fail(JACKDAW_ERR_MODEL, error_);
    }
  }

  void fail(int32_t status, const std::string& message) {
    {
      std::lock_guard lock(s_.state_mutex);
      s_.error = message;
    }
    s_.finish(job_.id, JACKDAW_EVENT_ERROR, status);
  }

  void publish_stats() {
    std::lock_guard lock(s_.state_mutex);
    s_.stats = stats_;
  }

  jackdaw_session& s_;
  const Job& job_;
  const llama_vocab* vocab_;
  Clock::time_point start_ = Clock::now();
  jackdaw_session_stats stats_{};
  std::string error_;
};

}

void generate(jackdaw_session& session, const Job& job) {
  session.ring.clear();
  try {
    Run(session, job).execute();
  } catch (const std::exception& error) {
    {
      std::lock_guard lock(session.state_mutex);
      session.error = error.what();
    }
    session.finish(job.id, JACKDAW_EVENT_ERROR, JACKDAW_ERR_INTERNAL);
  }
}

}
