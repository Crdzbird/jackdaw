/// Which side may call a catalog function.
enum UiCaller {
  /// Only the renderer, from bindings, checks and actions.
  rendererOnly,

  /// Only the agent, with a `callRendererFunction` message.
  agentOnly,

  /// Either side.
  rendererOrAgent,
}
