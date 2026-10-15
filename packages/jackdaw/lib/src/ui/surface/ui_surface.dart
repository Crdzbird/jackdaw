import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/surface/ui_component.dart';
import 'package:jackdaw/src/ui/surface/ui_data_model.dart';

/// One surface: its components by id and its data.
final class UiSurface {
  /// Creates the surface [id] drawn with [catalog].
  factory(
    String id,
    UiCatalog catalog, {
    bool sendDataModel,
    UiDataModel? data,
  }) = UiSurface._;

  new _(this.id, this.catalog, {this.sendDataModel = false, UiDataModel? data})
    : data = data ?? UiDataModel();

  /// The surface id.
  final String id;

  /// The catalog the surface's components come from.
  final UiCatalog catalog;

  /// Whether the whole data model goes with every action sent to the agent.
  final bool sendDataModel;

  /// The surface's data.
  final UiDataModel data;

  /// The components by id.
  final Map<String, UiComponent> components = {};

  /// The component with the id `root`, which the surface draws from.
  UiComponent? get root => components['root'];
}
