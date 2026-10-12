#include "model.hpp"

jackdaw_model::jackdaw_model(llama_model* loaded)
    : model(loaded), vocab(llama_model_get_vocab(loaded)) {
  if (const char* tmpl = llama_model_chat_template(loaded, nullptr)) {
    chat_template = tmpl;
  }
}

jackdaw_model::~jackdaw_model() { llama_model_free(model); }
