#pragma once

#include <algorithm>
#include <cstdint>
#include <thread>

namespace jackdaw {

/// Worker threads used when the caller picks none: the core count, at most
/// four, which keeps big cores busy without waking every little core.
inline int32_t default_threads() {
  const auto hardware = static_cast<int32_t>(std::thread::hardware_concurrency());
  return std::clamp(hardware, 1, 4);
}

}
