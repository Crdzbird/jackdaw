part of 'schema.dart';

/// Schema for JSON arrays.
final class ArraySchema extends Schema {
  /// Creates an array schema whose elements match [items], with at least
  /// [minItems] and, when set, at most [maxItems] of them.
  const factory({
    required Schema items,
    int minItems,
    int? maxItems,
    String? description,
  }) = ArraySchema._;

  const new _({
    required this.items,
    this.minItems = 0,
    this.maxItems,
    super.description,
  }) : super._();

  /// Schema every element must match.
  final Schema items;

  /// The fewest elements allowed.
  final int minItems;

  /// The most elements allowed, or `null` for no limit.
  final int? maxItems;

  @override
  Map<String, Object?> toJsonWith(SchemaEncoder child) => {
    ..._base('array'),
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
        ...items.validate(value[i], path: '$path[$i]'),
    ];
  }
}
