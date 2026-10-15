#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <string>

#include "jackdaw.h"

/// Feeds arbitrary bytes to the vector index loader through a file, as an
/// app would when opening an index it did not write.
extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  static const std::string path =
      (std::filesystem::temp_directory_path() / "jackdaw_index_fuzz.bin").string();
  {
    std::ofstream file(path, std::ios::binary | std::ios::trunc);
    file.write(reinterpret_cast<const char*>(data), static_cast<std::streamsize>(size));
  }
  jackdaw_index* index = nullptr;
  if (jackdaw_index_load(path.c_str(), &index) == JACKDAW_OK) {
    float query[4096] = {};
    uint64_t keys[4];
    float scores[4];
    int32_t count = 0;
    if (jackdaw_index_dimensions(index) <= 4096) {
      jackdaw_index_search(index, query, 4, keys, scores, &count);
    }
    jackdaw_index_free(index);
  }
  return 0;
}
