#include "model.hpp"

jackdaw_model::jackdaw_model(llama_model* loaded)
    : model(loaded), vocab(llama_model_get_vocab(loaded)) {
  if (const char* tmpl = llama_model_chat_template(loaded, nullptr)) {
    chat_template = tmpl;
  }
}

jackdaw_model::~jackdaw_model() { llama_model_free(model); }

namespace jackdaw {

std::optional<std::string> render_chat(const jackdaw_model& model, const Chat& chat,
                                       bool add_assistant) {
  if (model.chat_template.empty()) return std::nullopt;
  std::vector<llama_chat_message> messages;
  std::size_t total = 0;
  for (const auto& [role, content] : chat) {
    messages.push_back({role.c_str(), content.c_str()});
    total += role.size() + content.size();
  }
  std::string rendered(total * 2 + 256, '\0');
  auto n = llama_chat_apply_template(model.chat_template.c_str(), messages.data(),
                                     messages.size(), add_assistant, rendered.data(),
                                     static_cast<int32_t>(rendered.size()));
  if (n > static_cast<int32_t>(rendered.size())) {
    rendered.resize(static_cast<std::size_t>(n));
    n = llama_chat_apply_template(model.chat_template.c_str(), messages.data(), messages.size(),
                                  add_assistant, rendered.data(), n);
  }
  if (n < 0) return std::nullopt;
  rendered.resize(static_cast<std::size_t>(n));
  return rendered;
}

}
