#pragma once

#include <optional>
#include <string>
#include <utility>
#include <vector>

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

namespace jackdaw {

/// A chat as role and content pairs.
using Chat = std::vector<std::pair<std::string, std::string>>;

/// chat rendered with the model's chat template, ending with the opening of
/// an assistant turn when add_assistant is set, or nothing when the model
/// has no template or llama.cpp does not support it.
std::optional<std::string> render_chat(const jackdaw_model& model, const Chat& chat,
                                       bool add_assistant);

}
