/// Carries JSON-RPC messages between an `McpClient` and one server.
abstract interface class McpTransport {
  /// Sends the request [message] and returns the response with its id.
  Future<Map<String, Object?>> request(Map<String, Object?> message);

  /// Sends the notification [message], which has no response.
  Future<void> notify(Map<String, Object?> message);

  /// Closes the connection.
  Future<void> close();
}
