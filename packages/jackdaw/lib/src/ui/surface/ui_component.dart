/// One component on a surface: its id, its catalog name and its props.
final class UiComponent {
  /// Creates the component [id] of the catalog component [type].
  const factory(String id, String type, Map<String, Object?> props) =
      UiComponent._;

  const new _(this.id, this.type, this.props);

  /// Reads a component as A2UI sends it, with `id` and `component`
  /// beside the props.
  factory fromJson(Map<String, Object?> json) =>
      UiComponent(json['id']! as String, json['component']! as String, {
        for (final MapEntry(:key, :value) in json.entries)
          if (key != 'id' && key != 'component') key: value,
      });

  /// The component id, unique on its surface.
  final String id;

  /// The name of the component in the catalog.
  final String type;

  /// Every other property, including `accessibility`.
  final Map<String, Object?> props;

  /// The component as A2UI sends it.
  Map<String, Object?> toJson() => {'id': id, 'component': type, ...props};
}
