#include "piece_ring.hpp"

#include <algorithm>
#include <cstring>

#include "jackdaw.h"

namespace jackdaw {

PieceRing::PieceRing(std::size_t slots) : pieces_(slots), used_(slots) {}

int32_t PieceRing::push(std::string_view piece, const std::atomic<bool>& stop) {
  std::unique_lock lock(mutex_);
  freed_.wait(lock, [&] { return stop.load() || in_use_ < pieces_.size(); });
  if (stop.load()) return -1;
  while (used_[next_]) next_ = (next_ + 1) % pieces_.size();
  const auto slot = next_;
  pieces_[slot].assign(piece);
  used_[slot] = true;
  ++in_use_;
  next_ = (next_ + 1) % pieces_.size();
  return static_cast<int32_t>(slot);
}

int32_t PieceRing::read(int32_t slot, char* buffer, int32_t capacity,
                        int32_t* out_len) {
  if (out_len == nullptr || capacity < 0 || (buffer == nullptr && capacity > 0)) {
    return JACKDAW_ERR_INVALID_ARGUMENT;
  }
  std::lock_guard lock(mutex_);
  const auto index = static_cast<std::size_t>(slot);
  if (slot < 0 || index >= pieces_.size() || !used_[index]) {
    return JACKDAW_ERR_NOT_FOUND;
  }
  const auto& piece = pieces_[index];
  const auto size = static_cast<int32_t>(piece.size());
  *out_len = size;
  if (size > capacity) return JACKDAW_ERR_BUFFER_TOO_SMALL;
  if (size > 0) std::memcpy(buffer, piece.data(), piece.size());
  used_[index] = false;
  --in_use_;
  freed_.notify_one();
  return JACKDAW_OK;
}

void PieceRing::wake() {
  std::lock_guard lock(mutex_);
  freed_.notify_all();
}

void PieceRing::clear() {
  std::lock_guard lock(mutex_);
  std::fill(used_.begin(), used_.end(), false);
  in_use_ = 0;
  next_ = 0;
  freed_.notify_all();
}

}
