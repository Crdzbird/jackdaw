#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <shared_mutex>
#include <unordered_map>
#include <vector>

/// Vectors stored as int8 codes with one scale per row and searched
/// exhaustively, so results are exact up to quantization.
struct jackdaw_index {
  explicit jackdaw_index(int32_t dims);

  /// Normalizes and stores vector under key, replacing an earlier one.
  void add(uint64_t key, const float* vector);

  /// Removes key; returns whether it was stored.
  bool remove(uint64_t key);

  /// Writes up to k best matches for query, best first; returns how many.
  std::size_t search(const float* query, int32_t k, uint64_t* out_keys,
                     float* out_scores) const;

  int32_t dimensions;
  std::vector<uint64_t> keys;
  std::vector<float> scales;
  std::vector<int8_t> codes;
  std::unordered_map<uint64_t, std::size_t> rows;
  mutable std::shared_mutex mutex;
};

namespace jackdaw {

/// Writes the int8 codes of vector after scaling it to length 1 and
/// returns the factor that turns a code back into a component.
float quantize(const float* vector, int32_t dims, int8_t* codes);

/// Integer dot product of two code rows.
int32_t dot(const int8_t* a, const int8_t* b, int32_t dims);

/// Saves index to path atomically through a temporary file.
int32_t save_index(const jackdaw_index& index, const char* path);

/// Reads an index written by save_index, validating every size.
int32_t load_index(const char* path, std::unique_ptr<jackdaw_index>& out);

}
