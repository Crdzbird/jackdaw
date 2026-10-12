#include "error.hpp"

#include <utility>

namespace jackdaw {

namespace {
thread_local std::string last_message;
}

int32_t fail(int32_t status, std::string message) noexcept {
  try {
    last_message = std::move(message);
  } catch (...) {
    last_message.clear();
  }
  return status;
}

const char* last_error() noexcept { return last_message.c_str(); }

}
