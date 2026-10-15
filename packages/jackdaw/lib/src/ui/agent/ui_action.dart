import 'package:jackdaw/src/ui/schema/ui_message_schema.dart';

/// Something the user did on a surface that the agent should hear about,
/// such as pressing a button whose action is an event.
final class UiAction {
  /// Creates the action [name] from the component [sourceComponentId] on
  /// [surfaceId], carrying the resolved [context].
  const factory({
    required String name,
    required String surfaceId,
    required String sourceComponentId,
    required DateTime timestamp,
    Map<String, Object?> context,
    String? userMessage,
    Object? dataModel,
  }) = UiAction._;

  const new _({
    required this.name,
    required this.surfaceId,
    required this.sourceComponentId,
    required this.timestamp,
    this.context = const {},
    this.userMessage,
    this.dataModel,
  });

  /// The event name from the component's action.
  final String name;

  /// The surface the action came from.
  final String surfaceId;

  /// The component the user acted on.
  final String sourceComponentId;

  /// When the user acted.
  final DateTime timestamp;

  /// The event's context with every binding resolved.
  final Map<String, Object?> context;

  /// A sentence describing what the user did, when the action has one.
  final String? userMessage;

  /// The surface's whole data model, when the surface asked to send it.
  final Object? dataModel;

  /// The action as an A2UI v1.0 renderer-to-agent `action` message.
  Map<String, Object?> toJson() => {
    'version': uiProtocolVersion,
    'action': {
      'name': name,
      'surfaceId': surfaceId,
      'sourceComponentId': sourceComponentId,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'context': context,
      'userMessage': ?userMessage,
    },
  };
}
