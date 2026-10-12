#pragma once

#include <cstdint>
#include <exception>
#include <new>
#include <string>

#include "jackdaw.h"

namespace jackdaw {

/// Records message as the calling thread's last error and returns status.
int32_t fail(int32_t status, std::string message) noexcept;

/// Returns the calling thread's last error message.
const char* last_error() noexcept;

/// Runs body and converts any escaping exception into a status code, so
/// no C++ exception crosses the C ABI.
template <typename Body>
int32_t guarded(Body&& body) noexcept {
  try {
    return body();
  } catch (const std::bad_alloc&) {
    return fail(JACKDAW_ERR_INTERNAL, "out of memory");
  } catch (const std::exception& error) {
    return fail(JACKDAW_ERR_INTERNAL, error.what());
  } catch (...) {
    return fail(JACKDAW_ERR_INTERNAL, "unknown error");
  }
}

}
