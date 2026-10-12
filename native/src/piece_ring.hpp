#pragma once

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <mutex>
#include <string>
#include <string_view>
#include <vector>

namespace jackdaw {

/// Fixed set of slots holding generated text until the caller reads them.
///
/// The producer blocks while every slot is taken, which applies
/// backpressure instead of growing memory when the reader falls behind.
class PieceRing {
 public:
  explicit PieceRing(std::size_t slots);

  /// Stores piece and returns its slot, or -1 when stop became true while
  /// waiting for a free slot.
  int32_t push(std::string_view piece, const std::atomic<bool>& stop);

  /// Copies the piece in slot into buffer, frees the slot and returns a
  /// jackdaw_status.
  int32_t read(int32_t slot, char* buffer, int32_t capacity,
               int32_t* out_len);

  /// Wakes a producer blocked in push so it can observe its stop flag.
  void wake();

  /// Frees every slot.
  void clear();

 private:
  std::mutex mutex_;
  std::condition_variable freed_;
  std::vector<std::string> pieces_;
  std::vector<bool> used_;
  std::size_t next_ = 0;
  std::size_t in_use_ = 0;
};

}
