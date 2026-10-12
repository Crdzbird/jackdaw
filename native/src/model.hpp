#pragma once

#include <string>

#include "llama.h"

/// A loaded GGUF model and its vocabulary.
struct jackdaw_model {
  explicit jackdaw_model(llama_model* loaded);
  ~jackdaw_model();
  jackdaw_model(const jackdaw_model&) = delete;
  jackdaw_model& operator=(const jackdaw_model&) = delete;

  llama_model* model;
  const llama_vocab* vocab;
  std::string chat_template;
};
