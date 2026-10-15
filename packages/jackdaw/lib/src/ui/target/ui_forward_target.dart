import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/schema/ui_message_schema.dart';
import 'package:jackdaw/src/ui/schema/ui_schemas.dart';
import 'package:jackdaw/src/ui/surface/ui_message_parts.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/surface/ui_surfaces.dart';
import 'package:jackdaw/src/ui/target/ui_lower_v09.dart';
import 'package:jackdaw/src/ui/target/ui_protocol.dart';
import 'package:jackdaw/src/ui/target/ui_target.dart';

/// A [UiTarget] that checks messages against its own copy of the surfaces
/// and passes the ones that show to another renderer through [send], in
/// [protocol].
///
/// A surface created again is deleted first, as strict renderers require.
final class UiForwardTarget implements UiTarget {
  /// Creates a target for [catalog] that hands messages to [send].
  factory(
    UiCatalog catalog, {
    required void Function(List<Map<String, Object?>> messages) send,
    UiProtocol protocol,
  }) = UiForwardTarget._;

  new _(
    UiCatalog catalog, {
    required this.send,
    this.protocol = UiProtocol.v1_0,
  }) : _shadow = UiSurfaces(catalog);

  /// Receives the messages to show.
  final void Function(List<Map<String, Object?>> messages) send;

  /// The A2UI version [send] receives.
  final UiProtocol protocol;

  final UiSurfaces _shadow;

  @override
  UiSchemas get schemas => _shadow.schemas;

  @override
  List<UiProblem> show(List<Object?> messages, {bool partial = false}) {
    final existing = _shadow.surfaces.keys.toSet();
    final problems = _shadow.show(messages, partial: partial);
    if (!partial && problems.any((p) => !p.warning)) return problems;
    final wire = [
      for (final message in messages.whereType<Map<String, Object?>>()) ...[
        if (uiMessageParts(message)
            case ('createSurface', {'surfaceId': final String id})
            when existing.contains(id))
          {
            'version': uiProtocolVersion,
            'deleteSurface': {'surfaceId': id},
          },
        message,
      ],
    ];
    send(switch (protocol) {
      UiProtocol.v1_0 => wire,
      UiProtocol.v0_9 => uiLowerToV09(wire, schemas.catalog),
    });
    return problems;
  }
}
