#pragma once

#include <optional>
#include <string>
#include <string_view>

namespace jackdaw {

/// Returns why grammar must not reach llama.cpp, or nothing when it may.
///
/// llama.cpp 0.6.0 loops without bound, allocating as it goes, on a
/// repetition whose minimum is larger than its maximum, such as "a"{2,1}:
/// it subtracts the counts as unsigned numbers. Such ranges are refused
/// here. String literals, character classes and comments are skipped, so
/// braces inside them are not mistaken for repetitions.
std::optional<std::string> grammar_problem(std::string_view grammar);

}
