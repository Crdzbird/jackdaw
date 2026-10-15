import 'package:jackdaw/src/schema/schema.dart';

/// A component a catalog offers, such as a text, a row or a button.
final class UiComponentDefinition {
  /// Defines the component [name] with the given [props].
  ///
  /// [props] lists the component's own properties; `id`, `component` and
  /// the accessibility attributes every component has are added by the
  /// protocol. [allowedParents] and [allowedChildren] restrict where it may
  /// appear and what it may contain, by component name, with `Surface` for
  /// the top of a surface.
  const factory({
    required String name,
    required String description,
    required ObjectSchema props,
    List<String>? allowedParents,
    List<String>? allowedChildren,
  }) = UiComponentDefinition._;

  const new _({
    required this.name,
    required this.description,
    required this.props,
    this.allowedParents,
    this.allowedChildren,
  });

  /// The name used in `{"component": name}`.
  final String name;

  /// What the component shows or does, shown to the model.
  final String description;

  /// The component's own properties.
  final ObjectSchema props;

  /// Components this one may be placed in, or `null` for any.
  final List<String>? allowedParents;

  /// Components this one may contain, or `null` for any.
  final List<String>? allowedChildren;

  /// The component as an A2UI v1.0 catalog `components` entry.
  Map<String, Object?> toJson() => {
    'type': 'object',
    'description': description,
    'properties': {
      'component': {'const': name},
      for (final MapEntry(:key, :value) in props.properties.entries)
        key: value.toJson(),
    },
    'required': ['component', ...props.required],
    'allowedParents': ?allowedParents,
    'allowedChildren': ?allowedChildren,
  };
}
