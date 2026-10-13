/// Two-way map between document ids and the integer keys a native index
/// stores.
final class IndexKeys {
  /// Creates an empty map.
  factory() = IndexKeys._;

  new _();

  /// Reads a map written by [toJson].
  factory fromJson(Map<String, Object?> json) {
    final keys = IndexKeys._().._next = json['next']! as int;
    final numbers = json['keys']! as List<Object?>;
    final ids = json['ids']! as List<Object?>;
    if (numbers.length != ids.length) {
      throw const FormatException('keys and ids differ in length');
    }
    for (var i = 0; i < ids.length; i++) {
      keys._add(ids[i]! as String, numbers[i]! as int);
    }
    return keys;
  }

  final Map<String, int> _byId = {};
  final Map<int, String> _byKey = {};
  int _next = 1;

  /// Number of ids with a key.
  int get length => _byId.length;

  /// The key for [id], assigning a fresh one when it has none.
  int keyFor(String id) => _byId[id] ?? _add(id, _next++);

  /// The id stored under [key], if any.
  String? idFor(int key) => _byKey[key];

  /// Forgets [id] and returns the key it had.
  int? release(String id) {
    final key = _byId.remove(id);
    if (key != null) _byKey.remove(key);
    return key;
  }

  /// A JSON form of the map.
  Map<String, Object?> toJson() => {
    'next': _next,
    'keys': _byKey.keys.toList(),
    'ids': _byKey.values.toList(),
  };

  int _add(String id, int key) {
    _byId[id] = key;
    _byKey[key] = id;
    return key;
  }
}
