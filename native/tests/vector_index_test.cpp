#include <gtest/gtest.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <limits>
#include <numeric>
#include <random>
#include <string>
#include <vector>

#include "jackdaw.h"

namespace {

struct Index {
  explicit Index(int32_t dims) { EXPECT_EQ(jackdaw_index_create(dims, &value), JACKDAW_OK); }
  explicit Index(jackdaw_index* loaded) : value(loaded) {}
  ~Index() { jackdaw_index_free(value); }
  Index(const Index&) = delete;
  Index& operator=(const Index&) = delete;
  jackdaw_index* value = nullptr;
};

std::vector<float> random_vectors(std::size_t count, int32_t dims, uint32_t seed) {
  std::mt19937 engine(seed);
  std::normal_distribution<float> normal;
  std::vector<float> values(count * static_cast<std::size_t>(dims));
  for (auto& value : values) value = normal(engine);
  return values;
}

std::vector<uint64_t> search(const Index& index, const float* query, int32_t k) {
  std::vector<uint64_t> keys(static_cast<std::size_t>(k));
  std::vector<float> scores(static_cast<std::size_t>(k));
  int32_t count = 0;
  EXPECT_EQ(jackdaw_index_search(index.value, query, k, keys.data(), scores.data(), &count),
            JACKDAW_OK);
  for (int32_t i = 1; i < count; ++i) EXPECT_GE(scores[i - 1], scores[i]);
  keys.resize(static_cast<std::size_t>(count));
  return keys;
}

std::filesystem::path temp_file(const char* name) {
  return std::filesystem::temp_directory_path() / name;
}

}

TEST(VectorIndex, MatchesExactSearchWithHighRecall) {
  constexpr int32_t dims = 64;
  constexpr std::size_t count = 3000;
  const auto vectors = random_vectors(count, dims, 7);
  std::vector<uint64_t> keys(count);
  std::iota(keys.begin(), keys.end(), uint64_t{100});
  Index index(dims);
  ASSERT_EQ(jackdaw_index_add(index.value, keys.data(), vectors.data(), static_cast<int32_t>(count)),
            JACKDAW_OK);
  EXPECT_EQ(jackdaw_index_size(index.value), static_cast<int64_t>(count));
  const auto queries = random_vectors(50, dims, 11);
  std::size_t found = 0;
  for (std::size_t q = 0; q < 50; ++q) {
    const float* query = queries.data() + q * dims;
    std::vector<std::pair<double, uint64_t>> exact;
    for (std::size_t row = 0; row < count; ++row) {
      double dot = 0, norm = 0;
      for (int32_t d = 0; d < dims; ++d) {
        dot += static_cast<double>(vectors[row * dims + static_cast<std::size_t>(d)]) * query[d];
        norm += static_cast<double>(vectors[row * dims + static_cast<std::size_t>(d)]) *
                vectors[row * dims + static_cast<std::size_t>(d)];
      }
      exact.emplace_back(-dot / std::sqrt(norm), keys[row]);
    }
    std::partial_sort(exact.begin(), exact.begin() + 10, exact.end());
    const auto hits = search(index, query, 10);
    for (int32_t i = 0; i < 10; ++i) {
      found += static_cast<std::size_t>(std::count(hits.begin(), hits.end(), exact[static_cast<std::size_t>(i)].second));
    }
  }
  EXPECT_GE(static_cast<double>(found) / 500.0, 0.95);
}

TEST(VectorIndex, ReplacesAndRemovesByKey) {
  Index index(2);
  const uint64_t keys[] = {1, 2, 3};
  const float vectors[] = {1, 0, 0, 1, -1, 0};
  ASSERT_EQ(jackdaw_index_add(index.value, keys, vectors, 3), JACKDAW_OK);
  const float east[] = {1, 0.05F};
  EXPECT_EQ(search(index, east, 1), std::vector<uint64_t>{1});
  const uint64_t replace[] = {3};
  const float now_east[] = {4, 0};
  ASSERT_EQ(jackdaw_index_add(index.value, replace, now_east, 1), JACKDAW_OK);
  EXPECT_EQ(jackdaw_index_size(index.value), 3);
  int32_t removed = 0;
  ASSERT_EQ(jackdaw_index_remove(index.value, 1, &removed), JACKDAW_OK);
  EXPECT_EQ(removed, 1);
  ASSERT_EQ(jackdaw_index_remove(index.value, 1, &removed), JACKDAW_OK);
  EXPECT_EQ(removed, 0);
  EXPECT_EQ(search(index, east, 5), (std::vector<uint64_t>{3, 2}));
  EXPECT_TRUE(search(index, east, 0).empty());
  const float zero[] = {0, 0};
  const uint64_t zero_key[] = {9};
  ASSERT_EQ(jackdaw_index_add(index.value, zero_key, zero, 1), JACKDAW_OK);
  EXPECT_EQ(jackdaw_index_dimensions(index.value), 2);
}

TEST(VectorIndex, RejectsInvalidArguments) {
  jackdaw_index* out = nullptr;
  EXPECT_EQ(jackdaw_index_create(0, &out), JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_index_create(4, nullptr), JACKDAW_ERR_INVALID_ARGUMENT);
  Index index(2);
  const uint64_t key[] = {1};
  const float bad[] = {std::numeric_limits<float>::quiet_NaN(), 0};
  EXPECT_EQ(jackdaw_index_add(index.value, key, bad, 1), JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_index_add(index.value, nullptr, bad, 1), JACKDAW_ERR_INVALID_ARGUMENT);
  int32_t count = 0;
  EXPECT_EQ(jackdaw_index_search(index.value, bad, 1, nullptr, nullptr, &count),
            JACKDAW_ERR_INVALID_ARGUMENT);
  const float inf[] = {std::numeric_limits<float>::infinity(), 0};
  uint64_t keys[1];
  float scores[1];
  EXPECT_EQ(jackdaw_index_search(index.value, inf, 1, keys, scores, &count),
            JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_index_remove(index.value, 1, nullptr), JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_index_size(nullptr), 0);
  EXPECT_EQ(jackdaw_index_save(nullptr, "x"), JACKDAW_ERR_INVALID_ARGUMENT);
  EXPECT_EQ(jackdaw_index_load(nullptr, &out), JACKDAW_ERR_INVALID_ARGUMENT);
}

TEST(VectorIndex, SavesAndLoadsAtomically) {
  const auto path = temp_file("jackdaw_index_test.bin");
  const auto vectors = random_vectors(200, 16, 3);
  std::vector<uint64_t> keys(200);
  std::iota(keys.begin(), keys.end(), uint64_t{1});
  Index index(16);
  ASSERT_EQ(jackdaw_index_add(index.value, keys.data(), vectors.data(), 200), JACKDAW_OK);
  ASSERT_EQ(jackdaw_index_save(index.value, path.string().c_str()), JACKDAW_OK);
  EXPECT_FALSE(std::filesystem::exists(path.string() + ".tmp"));
  jackdaw_index* raw = nullptr;
  ASSERT_EQ(jackdaw_index_load(path.string().c_str(), &raw), JACKDAW_OK);
  Index loaded(raw);
  EXPECT_EQ(jackdaw_index_size(loaded.value), 200);
  EXPECT_EQ(search(loaded, vectors.data() + 16 * 42, 3), search(index, vectors.data() + 16 * 42, 3));
  std::filesystem::remove(path);
}

TEST(VectorIndex, RejectsDamagedFiles) {
  const auto path = temp_file("jackdaw_index_bad.bin");
  Index index(4);
  const uint64_t keys[] = {1, 2};
  const float vectors[] = {1, 0, 0, 0, 0, 1, 0, 0};
  ASSERT_EQ(jackdaw_index_add(index.value, keys, vectors, 2), JACKDAW_OK);
  ASSERT_EQ(jackdaw_index_save(index.value, path.string().c_str()), JACKDAW_OK);
  std::string bytes;
  {
    std::ifstream in(path, std::ios::binary);
    bytes.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
  }
  const auto load_variant = [&](const std::string& data) {
    {
      std::ofstream out(path, std::ios::binary | std::ios::trunc);
      out.write(data.data(), static_cast<std::streamsize>(data.size()));
    }
    jackdaw_index* raw = nullptr;
    const auto status = jackdaw_index_load(path.string().c_str(), &raw);
    jackdaw_index_free(raw);
    return status;
  };
  auto wrong_magic = bytes;
  wrong_magic[0] = 'X';
  EXPECT_EQ(load_variant(wrong_magic), JACKDAW_ERR_IO);
  EXPECT_EQ(load_variant(bytes.substr(0, 10)), JACKDAW_ERR_IO);
  EXPECT_EQ(load_variant(bytes.substr(0, bytes.size() - 1)), JACKDAW_ERR_IO);
  auto huge = bytes;
  huge[16] = '\xff';
  huge[23] = '\x7f';
  EXPECT_EQ(load_variant(huge), JACKDAW_ERR_IO);
  auto duplicate = bytes;
  duplicate.replace(32, 8, duplicate.substr(24, 8));
  EXPECT_EQ(load_variant(duplicate), JACKDAW_ERR_IO);
  EXPECT_EQ(load_variant(bytes), JACKDAW_OK);
  std::filesystem::remove(path);
  jackdaw_index* raw = nullptr;
  EXPECT_EQ(jackdaw_index_load(path.string().c_str(), &raw), JACKDAW_ERR_IO);
}
