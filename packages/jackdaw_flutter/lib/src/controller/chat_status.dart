/// What a chat is doing right now.
enum ChatStatus {
  /// Waiting for the user.
  idle,

  /// The agent is working on an answer.
  responding,

  /// A tool call waits for the user's approval.
  awaitingApproval,

  /// The last turn failed; see `ChatController.error`.
  failed,
}
