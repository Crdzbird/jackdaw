part of 'schema.dart';

/// Schema for JSON arrays.
final class ArraySchema extends Schema {
  /// Creates an array schema whose elements match [items].
  const factory({required Schema items, String? description}) = ArraySchema._;

  const new _({required this.items, super.description}) : super._();

  /// Schema every element must match.
  final Schema items;

  @override
  Map<String, Object?> toJson() => {..._base('array'), 'items': items.toJson()};

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) {
    if (value is! List<Object?>) return _expect(false, path, 'an array');
    return [
      for (var i = 0; i < value.length; i++)
        ...items.validate(value[i], path: '$path[$i]'),
    ];
  }
}
