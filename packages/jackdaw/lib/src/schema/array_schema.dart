part of 'schema.dart';

/// Schema for JSON arrays.
final class ArraySchema extends Schema {
  /// Creates an array schema whose first elements match [prefixItems] in
  /// order and whose other elements match [items], with at least
  /// [minItems] and, when set, at most [maxItems] elements.
  ///
  /// Constrained decoding always emits the prefix items, so [minItems]
  /// should cover them.
  const factory({
    required Schema items,
    List<Schema> prefixItems,
    int minItems,
    int? maxItems,
    String? description,
  }) = ArraySchema._;

  const new _({
    required this.items,
    this.prefixItems = const [],
    this.minItems = 0,
    this.maxItems,
    super.description,
  }) : super._();

  /// Schema of every element after the prefix.
  final Schema items;

  /// Schemas of the first elements, in order.
  final List<Schema> prefixItems;

  /// The fewest elements allowed.
  final int minItems;

  /// The most elements allowed, or `null` for no limit.
  final int? maxItems;

  @override
  Map<String, Object?> toJsonWith(SchemaEncoder child) => {
    ..._base('array'),
    if (prefixItems.isNotEmpty)
      'prefixItems': [for (final item in prefixItems) child(item)],
    'items': child(items),
    if (minItems > 0) 'minItems': minItems,
    'maxItems': ?maxItems,
  };

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) {
    if (value is! List<Object?>) return _expect(false, path, 'an array');
    return [
      ..._expect(value.length >= minItems, path, 'at least $minItems items'),
      ..._expect(
        value.length <= (maxItems ?? value.length),
        path,
        'at most $maxItems items',
      ),
      for (var i = 0; i < value.length; i++)
        ...(i < prefixItems.length ? prefixItems[i] : items).validate(
          value[i],
          path: '$path[$i]',
        ),
    ];
  }
}
