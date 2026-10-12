/// One server-sent event.
final class SseEvent {
  /// Creates an event of type [event] carrying [data].
  const factory({required String data, String event, String? id}) = SseEvent._;

  const new _({required this.data, this.event = 'message', this.id});

  /// Event type; `message` when the server sent none.
  final String event;

  /// Payload, with multiple `data` lines joined by newlines.
  final String data;

  /// Last event id seen on the stream, if any.
  final String? id;
}
