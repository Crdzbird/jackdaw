#pragma once

#include <cstdint>

#include "jackdaw.h"
#include "session.hpp"

namespace jackdaw {

/// Checks the grammar in params, copies it and the other params into job
/// and queues job on session. Returns the status for the caller.
int32_t submit_generation(jackdaw_session& session, Job job,
                          const jackdaw_generate_params& params);

}
