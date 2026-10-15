/// How a model writes UI.
enum UiFormat {
  /// A screen as a tree of components holding their children, which
  /// jackdaw turns into A2UI messages. Small models get it right far more
  /// often, since nothing refers to anything by id.
  tree,

  /// A2UI v1.0 messages as they go over the wire, with components in a
  /// flat list and children referred to by id.
  messages,
}
