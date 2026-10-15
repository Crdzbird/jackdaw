import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';
import 'package:jackdaw/src/ui/catalog/ui_function_definition.dart';

/// The components and functions a model may use on a surface.
///
/// A catalog is identified by [id], which surfaces name in `catalogId`,
/// and serializes as an A2UI v1.0 catalog definition with [toJson].
final class UiCatalog {
  /// Creates the catalog [id] from [components] and [functions].
  ///
  /// [instructions] tell the model how to use the catalog and go into the
  /// system prompt.
  const factory({
    required String id,
    required List<UiComponentDefinition> components,
    List<UiFunctionDefinition> functions,
    String? title,
    String? instructions,
  }) = UiCatalog._;

  const new _({
    required this.id,
    required this.components,
    this.functions = const [],
    this.title,
    this.instructions,
  });

  /// The catalog id, ideally a URL or a domain-prefixed name.
  final String id;

  /// The components, in the order they are offered to the model.
  final List<UiComponentDefinition> components;

  /// The functions, in the order they are offered to the model.
  final List<UiFunctionDefinition> functions;

  /// A short name for the catalog.
  final String? title;

  /// Guidance for the model on using the catalog.
  final String? instructions;

  /// The component named [name], or `null` when the catalog has none.
  UiComponentDefinition? component(String name) =>
      components.where((c) => c.name == name).firstOrNull;

  /// The function named [name], or `null` when the catalog has none.
  UiFunctionDefinition? function(String name) =>
      functions.where((f) => f.name == name).firstOrNull;

  /// The catalog as an A2UI v1.0 catalog definition document.
  Map<String, Object?> toJson() => {
    'catalogId': id,
    'protocolVersion': '1.0',
    'title': ?title,
    'instructions': ?instructions,
    'components': {for (final c in components) c.name: c.toJson()},
    'functions': {for (final f in functions) f.name: f.toJson()},
  };
}
