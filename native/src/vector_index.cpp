#include "vector_index.hpp"

#include <algorithm>
#include <cmath>
#include <functional>
#include <mutex>
#include <utility>

jackdaw_index::jackdaw_index(int32_t dims) : dimensions(dims) {}

namespace jackdaw {

float quantize(const float* vector, int32_t dims, int8_t* codes) {
  double sum = 0;
  float largest = 0;
  for (int32_t i = 0; i < dims; ++i) {
    sum += static_cast<double>(vector[i]) * vector[i];
    largest = std::max(largest, std::fabs(vector[i]));
  }
  if (sum == 0 || largest == 0) {
    std::fill(codes, codes + dims, int8_t{0});
    return 0;
  }
  const auto norm = static_cast<float>(std::sqrt(sum));
  const float scale = largest / norm / 127.0F;
  for (int32_t i = 0; i < dims; ++i) {
    const float code = std::round(vector[i] / norm / scale);
    codes[i] = static_cast<int8_t>(std::clamp(code, -127.0F, 127.0F));
  }
  return scale;
}

int32_t dot(const int8_t* a, const int8_t* b, int32_t dims) {
  int32_t sum = 0;
  for (int32_t i = 0; i < dims; ++i) {
    sum += static_cast<int32_t>(a[i]) * static_cast<int32_t>(b[i]);
  }
  return sum;
}

}

void jackdaw_index::add(uint64_t key, const float* vector) {
  std::vector<int8_t> code(static_cast<std::size_t>(dimensions));
  const float scale = jackdaw::quantize(vector, dimensions, code.data());
  std::unique_lock lock(mutex);
  auto [found, inserted] = rows.try_emplace(key, keys.size());
  const std::size_t row = found->second;
  if (inserted) {
    keys.push_back(key);
    scales.push_back(scale);
    codes.insert(codes.end(), code.begin(), code.end());
    return;
  }
  scales[row] = scale;
  std::copy(code.begin(), code.end(),
            codes.begin() + static_cast<std::ptrdiff_t>(row * code.size()));
}

bool jackdaw_index::remove(uint64_t key) {
  std::unique_lock lock(mutex);
  const auto found = rows.find(key);
  if (found == rows.end()) return false;
  const std::size_t row = found->second;
  const std::size_t last = keys.size() - 1;
  const auto width = static_cast<std::size_t>(dimensions);
  rows.erase(found);
  if (row != last) {
    keys[row] = keys[last];
    scales[row] = scales[last];
    std::copy_n(codes.begin() + static_cast<std::ptrdiff_t>(last * width), width,
                codes.begin() + static_cast<std::ptrdiff_t>(row * width));
    rows[keys[row]] = row;
  }
  keys.pop_back();
  scales.pop_back();
  codes.resize(last * width);
  return true;
}

std::size_t jackdaw_index::search(const float* query, int32_t k, uint64_t* out_keys,
                                  float* out_scores) const {
  std::vector<int8_t> code(static_cast<std::size_t>(dimensions));
  const float scale = jackdaw::quantize(query, dimensions, code.data());
  using Hit = std::pair<float, std::size_t>;
  std::vector<Hit> heap;
  const auto limit = static_cast<std::size_t>(std::max(k, 0));
  heap.reserve(limit + 1);
  std::shared_lock lock(mutex);
  for (std::size_t row = 0; row < keys.size() && limit > 0; ++row) {
    const int8_t* stored = codes.data() + row * code.size();
    const auto score = static_cast<float>(jackdaw::dot(stored, code.data(), dimensions)) *
                       scales[row] * scale;
    if (heap.size() == limit && score <= heap.front().first) continue;
    heap.emplace_back(score, row);
    std::push_heap(heap.begin(), heap.end(), std::greater<>());
    if (heap.size() > limit) {
      std::pop_heap(heap.begin(), heap.end(), std::greater<>());
      heap.pop_back();
    }
  }
  std::sort_heap(heap.begin(), heap.end(), std::greater<>());
  for (std::size_t i = 0; i < heap.size(); ++i) {
    out_keys[i] = keys[heap[i].second];
    out_scores[i] = heap[i].first;
  }
  return heap.size();
}
