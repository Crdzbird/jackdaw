#pragma once

#include "session.hpp"

namespace jackdaw {

/// Runs job on session's context and reports every event through the
/// session callback, ending with exactly one DONE or ERROR event.
void generate(jackdaw_session& session, const Job& job);

}
