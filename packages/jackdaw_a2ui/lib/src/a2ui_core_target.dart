import 'package:a2ui_core/a2ui_core.dart';
import 'package:jackdaw/jackdaw.dart';

/// A [UiTarget] that applies the UI a jackdaw agent builds to an a2ui_core
/// [processor], so any renderer built on a2ui_core draws it.
///
/// Messages are checked with jackdaw's rules first and then lowered to
/// A2UI v0.9, which a2ui_core 0.2 reads. What a2ui_core then rejects comes
/// back as problems too; a batch it rejects part way may stay applied up
/// to that point, since the processor is not atomic.
final class A2uiCoreTarget implements UiTarget {
  /// Creates a target that draws the UI built for [catalog] with
  /// [processor]. When the processor knows the catalog by another id than
  /// the A2UI v0.9 form of [catalog]'s, pass that id as [catalogId].
  factory(
    UiCatalog catalog,
    MessageProcessor<ComponentApi> processor, {
    String? catalogId,
  }) = A2uiCoreTarget._;

  new _(UiCatalog catalog, this.processor, {this.catalogId}) {
    _forward = UiForwardTarget(
      catalog,
      send: _process,
      protocol: UiProtocol.v0_9,
    );
  }

  /// The processor the messages go to.
  final MessageProcessor<ComponentApi> processor;

  /// The id surfaces name their catalog by, when it differs.
  final String? catalogId;

  late final UiForwardTarget _forward;
  final List<UiProblem> _found = [];

  @override
  UiSchemas get schemas => _forward.schemas;

  @override
  List<UiProblem> show(List<Object?> messages, {bool partial = false}) {
    _found.clear();
    final problems = _forward.show(messages, partial: partial);
    return [...problems, ..._found];
  }

  void _process(List<Map<String, Object?>> messages) {
    try {
      processor.processMessages(
        AgentToRendererMessagePayload.fromJson([
          for (final message in messages) _named(message),
        ], protocolVersion: A2uiProtocolVersion.v0_9),
      );
    } on A2uiError catch (error) {
      _found.add(
        UiProblem(
          UiProblemCode.values
                  .where((code) => code.wire == error.code)
                  .firstOrNull ??
              UiProblemCode.validationFailed,
          error.message,
        ),
      );
    }
  }

  Map<String, Object?> _named(Map<String, Object?> message) => switch ((
    catalogId,
    message,
  )) {
    (final String id, {'createSurface': final Map<String, Object?> body}) => {
      ...message,
      'createSurface': {...body, 'catalogId': id},
    },
    _ => message,
  };
}
