import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/schema/ui_schemas.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/surface/ui_surfaces.dart';
import 'package:jackdaw/src/ui/target/ui_forward_target.dart';
import 'package:jackdaw/src/ui/target/ui_protocol.dart';

/// Where the screens a model builds go: jackdaw's own surfaces, another
/// A2UI renderer, or any UI library an app plugs in by implementing this.
///
/// `uiTool`, `generateUi` and `uiReplay` take a target, so the choice of
/// renderer does not change how the agent works.
abstract interface class UiTarget {
  /// jackdaw's own surfaces for [catalog], drawn by jackdaw_flutter.
  factory surfaces(UiCatalog catalog) => UiSurfaces(catalog);

  /// A renderer that takes A2UI messages in [protocol], such as one built
  /// on a2ui_core, which [send] hands them to.
  factory forward(
    UiCatalog catalog, {
    required void Function(List<Map<String, Object?>> messages) send,
    UiProtocol protocol,
  }) = UiForwardTarget;

  /// Flutter's genui 0.10, which renders A2UI v0.9: [send] hands each
  /// batch of lowered messages to it, for example to a `SurfaceController`.
  factory genui(
    UiCatalog catalog, {
    required void Function(List<Map<String, Object?>> messages) send,
  }) => UiForwardTarget(catalog, send: send, protocol: UiProtocol.v0_9);

  /// The schemas of the catalog the target draws with.
  UiSchemas get schemas;

  /// Shows the A2UI v1.0 [messages] and returns every problem, warnings
  /// included. Creating a surface that exists replaces it. A batch with an
  /// error shows nothing, unless [partial] asks to show what it can.
  List<UiProblem> show(List<Object?> messages, {bool partial = false});
}
