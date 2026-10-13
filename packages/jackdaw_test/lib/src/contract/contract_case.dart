/// The cases of `languageModelContract`, so a fake model can script the
/// response each one needs.
enum ContractCase {
  /// A short text reply.
  text,

  /// A reply cut by a small token limit.
  limit,

  /// JSON that must match a response schema.
  schema,

  /// A call to the `ping` tool.
  toolCall,

  /// A long reply that is cancelled after its first event.
  cancel,
}
