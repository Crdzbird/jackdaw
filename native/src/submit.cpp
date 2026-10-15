#include "submit.hpp"

#include <utility>

#include "error.hpp"
#include "grammar_guard.hpp"

namespace jackdaw {

int32_t submit_generation(jackdaw_session& session, Job job,
                          const jackdaw_generate_params& params) {
  job.params = params;
  if (params.grammar != nullptr) {
    if (auto problem = grammar_problem(params.grammar)) {
      return fail(JACKDAW_ERR_GRAMMAR, *problem);
    }
    job.grammar = std::string(params.grammar);
  }
  job.params.grammar = nullptr;
  const auto status = session.submit(std::move(job));
  if (status != JACKDAW_OK) return fail(status, "a generation is already running");
  return static_cast<int32_t>(JACKDAW_OK);
}

}
