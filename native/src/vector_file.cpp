#include <bit>
#include <cmath>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <limits>
#include <mutex>
#include <string>
#include <system_error>

#include "error.hpp"
#include "jackdaw.h"
#include "vector_index.hpp"

namespace jackdaw {

namespace {

constexpr uint32_t magic = 0x584e444a;
constexpr uint32_t version = 1;
constexpr std::size_t header_size = 24;
constexpr uint32_t max_dimensions = 65536;

struct Header {
  uint32_t magic;
  uint32_t version;
  uint32_t dimensions;
  uint32_t reserved;
  uint64_t count;
};

static_assert(sizeof(Header) == header_size);
static_assert(std::endian::native == std::endian::little, "index files are little-endian");

template <typename T>
void write_all(std::ofstream& file, const std::vector<T>& values) {
  file.write(reinterpret_cast<const char*>(values.data()),
             static_cast<std::streamsize>(values.size() * sizeof(T)));
}

bool read_into(std::ifstream& file, void* target, std::size_t bytes) {
  file.read(static_cast<char*>(target), static_cast<std::streamsize>(bytes));
  return file.gcount() == static_cast<std::streamsize>(bytes);
}

}

int32_t save_index(const jackdaw_index& index, const char* path) {
  std::shared_lock lock(index.mutex);
  const std::filesystem::path target(path);
  auto temporary = target;
  temporary += ".tmp";
  {
    std::ofstream file(temporary, std::ios::binary | std::ios::trunc);
    const Header header{magic, version, static_cast<uint32_t>(index.dimensions), 0,
                        index.keys.size()};
    file.write(reinterpret_cast<const char*>(&header), sizeof header);
    write_all(file, index.keys);
    write_all(file, index.scales);
    write_all(file, index.codes);
    file.flush();
    if (!file) return fail(JACKDAW_ERR_IO, "cannot write " + temporary.string());
  }
  std::error_code error;
  std::filesystem::rename(temporary, target, error);
  if (error) return fail(JACKDAW_ERR_IO, "cannot replace " + target.string());
  return JACKDAW_OK;
}

int32_t load_index(const char* path, std::unique_ptr<jackdaw_index>& out) {
  std::error_code error;
  const auto size = std::filesystem::file_size(path, error);
  std::ifstream file(path, std::ios::binary);
  if (error || !file) return fail(JACKDAW_ERR_IO, std::string("cannot open ") + path);
  Header header{};
  if (size < header_size || !read_into(file, &header, header_size)) {
    return fail(JACKDAW_ERR_IO, "index file is truncated");
  }
  if (header.magic != magic || header.version != version || header.dimensions == 0 ||
      header.dimensions > max_dimensions) {
    return fail(JACKDAW_ERR_IO, "not a jackdaw index file");
  }
  const uint64_t row_bytes = sizeof(uint64_t) + sizeof(float) + header.dimensions;
  const uint64_t body = size - header_size;
  if (header.count > body / row_bytes || header.count * row_bytes != body) {
    return fail(JACKDAW_ERR_IO, "index file size does not match its header");
  }
  auto index = std::make_unique<jackdaw_index>(static_cast<int32_t>(header.dimensions));
  const auto count = static_cast<std::size_t>(header.count);
  index->keys.resize(count);
  index->scales.resize(count);
  index->codes.resize(count * header.dimensions);
  if (!read_into(file, index->keys.data(), count * sizeof(uint64_t)) ||
      !read_into(file, index->scales.data(), count * sizeof(float)) ||
      !read_into(file, index->codes.data(), index->codes.size())) {
    return fail(JACKDAW_ERR_IO, "cannot read index file");
  }
  index->rows.reserve(count);
  for (std::size_t row = 0; row < count; ++row) {
    if (!std::isfinite(index->scales[row]) || index->scales[row] < 0 ||
        !index->rows.try_emplace(index->keys[row], row).second) {
      return fail(JACKDAW_ERR_IO, "index file holds invalid rows");
    }
  }
  out = std::move(index);
  return JACKDAW_OK;
}

}
