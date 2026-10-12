import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';

/// Accumulates the streamed fragments of one tool call.
final class ToolCallBuilder {
  /// Creates an empty builder.
  factory() = ToolCallBuilder._;

  new _();

  /// Call identifier, sent in the first fragment.
  String id = '';

  /// Tool name, sent in the first fragment.
  String name = '';

  /// Concatenated argument text.
  final StringBuffer arguments = StringBuffer();

  /// Returns the finished call.
  ///
  /// Empty arguments become an empty object. Arguments that are not valid
  /// JSON are kept as raw text so validation can report them to the model.
  ToolCallPart build() =>
      ToolCallPart(id: id, name: name, arguments: _decode('$arguments'));

  static Object? _decode(String raw) {
    if (raw.trim().isEmpty) return <String, Object?>{};
    try {
      return jsonDecode(raw);
    } on FormatException {
      return raw;
    }
  }
}
