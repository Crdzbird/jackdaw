#include "piece_ring.hpp"

#include <gtest/gtest.h>

#include <atomic>
#include <chrono>
#include <string>
#include <thread>

#include "jackdaw.h"

namespace {

std::string read_slot(jackdaw::PieceRing& ring, int32_t slot) {
  char buffer[32];
  int32_t length = 0;
  EXPECT_EQ(ring.read(slot, buffer, sizeof buffer, &length), JACKDAW_OK);
  return {buffer, static_cast<std::size_t>(length)};
}

TEST(PieceRing, StoresAndFreesPieces) {
  jackdaw::PieceRing ring(2);
  std::atomic<bool> stop{false};
  const auto a = ring.push("he", stop);
  const auto b = ring.push("llo", stop);
  EXPECT_NE(a, b);
  EXPECT_EQ(read_slot(ring, a), "he");
  EXPECT_EQ(read_slot(ring, b), "llo");
  char buffer[4];
  int32_t length = 0;
  EXPECT_EQ(ring.read(a, buffer, sizeof buffer, &length), JACKDAW_ERR_NOT_FOUND);
  EXPECT_EQ(ring.read(9, buffer, sizeof buffer, &length), JACKDAW_ERR_NOT_FOUND);
  EXPECT_EQ(ring.read(a, buffer, -1, &length), JACKDAW_ERR_INVALID_ARGUMENT);
}

TEST(PieceRing, ReportsSmallBuffersWithoutFreeing) {
  jackdaw::PieceRing ring(1);
  std::atomic<bool> stop{false};
  const auto slot = ring.push("abcdef", stop);
  char buffer[2];
  int32_t length = 0;
  EXPECT_EQ(ring.read(slot, buffer, sizeof buffer, &length), JACKDAW_ERR_BUFFER_TOO_SMALL);
  EXPECT_EQ(length, 6);
  EXPECT_EQ(read_slot(ring, slot), "abcdef");
}

TEST(PieceRing, BlocksWhenFullUntilRead) {
  jackdaw::PieceRing ring(1);
  std::atomic<bool> stop{false};
  const auto first = ring.push("a", stop);
  std::atomic<int32_t> second{-2};
  std::thread producer([&] { second = ring.push("b", stop); });
  std::this_thread::sleep_for(std::chrono::milliseconds(50));
  EXPECT_EQ(second.load(), -2);
  EXPECT_EQ(read_slot(ring, first), "a");
  producer.join();
  EXPECT_EQ(read_slot(ring, second.load()), "b");
}

TEST(PieceRing, StopReleasesABlockedProducer) {
  jackdaw::PieceRing ring(1);
  std::atomic<bool> stop{false};
  ring.push("a", stop);
  std::atomic<int32_t> result{-2};
  std::thread producer([&] { result = ring.push("b", stop); });
  std::this_thread::sleep_for(std::chrono::milliseconds(20));
  stop = true;
  ring.wake();
  producer.join();
  EXPECT_EQ(result.load(), -1);
  ring.clear();
  stop = false;
  EXPECT_GE(ring.push("c", stop), 0);
}

}
