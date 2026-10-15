#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <random>
#include <string>
#include <vector>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size);

namespace {

std::string read(const std::filesystem::path& path) {
  std::ifstream file(path, std::ios::binary);
  return {std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
}

void run(const std::string& input) {
  if (const char* keep = std::getenv("JACKDAW_FUZZ_CURRENT")) {
    std::ofstream file(keep, std::ios::binary | std::ios::trunc);
    file.write(input.data(), static_cast<std::streamsize>(input.size()));
  }
  LLVMFuzzerTestOneInput(reinterpret_cast<const uint8_t*>(input.data()), input.size());
}

}

/// Stands in for libFuzzer where it is missing, such as Apple clang:
/// replays every corpus file given, then runs random mutations of them.
/// With JACKDAW_FUZZ_CURRENT set, each input is written to that path first,
/// so an input that hangs can be recovered.
/// Usage: <fuzzer> <corpus dir> [mutations]
int main(int argc, char** argv) {
  if (argc < 2) {
    std::cerr << "usage: " << argv[0] << " <corpus dir> [mutations]\n";
    return 2;
  }
  std::vector<std::string> corpus;
  for (const auto& entry : std::filesystem::directory_iterator(argv[1])) {
    if (entry.is_regular_file()) corpus.push_back(read(entry.path()));
  }
  for (const auto& input : corpus) run(input);
  const long mutations = argc > 2 ? std::strtol(argv[2], nullptr, 10) : 10000;
  std::mt19937 random(1234);
  for (long i = 0; i < mutations && !corpus.empty(); ++i) {
    auto input = corpus[random() % corpus.size()];
    const auto edits = 1 + random() % 8;
    for (unsigned e = 0; e < edits; ++e) {
      const auto at = input.empty() ? 0 : random() % input.size();
      switch (random() % 4) {
        case 0:
          if (!input.empty()) input[at] = static_cast<char>(random());
          break;
        case 1:
          input.insert(at, 1, static_cast<char>(random()));
          break;
        case 2:
          if (!input.empty()) input.erase(at, 1 + random() % 4);
          break;
        default:
          input += corpus[random() % corpus.size()].substr(0, random() % 64);
      }
    }
    run(input);
  }
  std::cout << "replayed " << corpus.size() << " inputs and " << mutations << " mutations\n";
  return 0;
}
