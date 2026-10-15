import 'package:jackdaw/src/ui/surface/json_pointer.dart';

/// The data of one surface: a JSON value read and written by JSON Pointer.
///
/// Writes copy the value, so the model owns its data and later changes to
/// a message do not reach it. Writing `null` deletes the value at a path.
final class UiDataModel {
  /// Creates a data model holding [data], or an empty object.
  factory([Object? data]) = UiDataModel._;

  new _([Object? data]) : _root = _copy(data) ?? <String, Object?>{};

  Object? _root;

  /// The whole data model.
  Object? get root => _root;

  /// The value at [pointer], or `null` when there is none.
  Object? read(String pointer) => jsonPointerTokens(pointer).fold(_root, _at);

  /// Writes [value] at [pointer], creating objects along the way; `null`
  /// deletes the value, and `-` as the last token appends to a list.
  void write(String pointer, Object? value) {
    final tokens = jsonPointerTokens(pointer);
    if (tokens.isEmpty) {
      _root = _copy(value) ?? <String, Object?>{};
      return;
    }
    if (_root is! Map<String, Object?> && _root is! List<Object?>) {
      _root = <String, Object?>{};
    }
    var node = _root;
    for (final token in tokens.take(tokens.length - 1)) {
      node = _child(node, token);
    }
    _set(node, tokens.last, _copy(value));
  }

  static Object? _at(Object? node, String token) => switch (node) {
    Map<String, Object?>() => node[token],
    List<Object?>() => switch (int.tryParse(token)) {
      final i? when i >= 0 && i < node.length => node[i],
      _ => null,
    },
    _ => null,
  };

  static Object? _child(Object? node, String token) {
    final existing = _at(node, token);
    if (existing is Map<String, Object?> || existing is List<Object?>) {
      return existing;
    }
    final created = <String, Object?>{};
    _set(node, token, created);
    return created;
  }

  static void _set(Object? node, String token, Object? value) {
    if (node is Map<String, Object?>) {
      if (value == null) node.remove(token);
      if (value != null) node[token] = value;
      return;
    }
    if (node is! List<Object?>) return;
    final index = token == '-' ? node.length : int.tryParse(token);
    if (index == null || index < 0 || index > node.length) return;
    if (value == null && index < node.length) node.removeAt(index);
    if (value != null && index == node.length) node.add(value);
    if (value != null && index < node.length) node[index] = value;
  }

  static Object? _copy(Object? value) => switch (value) {
    Map() => <String, Object?>{
      for (final MapEntry(:key, :value) in value.entries) '$key': _copy(value),
    },
    List() => <Object?>[for (final item in value) _copy(item)],
    _ => value,
  };
}
