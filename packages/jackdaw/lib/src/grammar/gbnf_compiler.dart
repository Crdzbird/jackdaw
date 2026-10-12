import 'dart:convert';

import 'package:jackdaw/src/grammar/gbnf_primitives.dart';
import 'package:jackdaw/src/schema/schema.dart';

/// Compiles a [Schema] into a GBNF grammar whose root rule only accepts
/// JSON text that matches the schema.
///
/// Objects are emitted with every declared property, in declaration order,
/// which always satisfies the schema. The compiler is pure Dart, so native
/// and web inference backends share one grammar.
final class GbnfCompiler {
  /// Creates a compiler for one grammar.
  factory() = GbnfCompiler._;

  new _();

  final List<String> _rules = [];
  final Set<String> _primitives = {};
  int _count = 0;

  /// Returns the grammar text for [schema].
  String compile(Schema schema) {
    final root = _rule(schema);
    return [
      'root ::= $root',
      ..._rules,
      for (final name in _primitives) gbnfPrimitives[name]!,
    ].join('\n');
  }

  String _rule(Schema schema) => switch (schema) {
    StringSchema(enumValues: final values?) => _named(
      values.map(_literal).join(' | '),
    ),
    StringSchema() => _use('string'),
    IntegerSchema() => _use('integer'),
    NumberSchema() => _use('number'),
    BooleanSchema() => _use('boolean'),
    ArraySchema(:final items) => _array(items),
    ObjectSchema(:final properties) => _object(properties),
  };

  String _object(Map<String, Schema> properties) {
    _use('ws');
    final members = [
      for (final MapEntry(:key, :value) in properties.entries)
        '${_literal(key)} ws ":" ws ${_rule(value)}',
    ];
    if (members.isEmpty) return _named('"{" ws "}"');
    return _named('"{" ws ${members.join(' ws "," ws ')} ws "}"');
  }

  String _array(Schema items) {
    _use('ws');
    final item = _rule(items);
    return _named('"[" ws ($item (ws "," ws $item)*)? ws "]"');
  }

  String _use(String primitive) {
    _primitives.add(primitive);
    return primitive;
  }

  String _named(String body) {
    final name = 'rule${_count++}';
    _rules.add('$name ::= $body');
    return name;
  }

  static String _literal(String value) {
    final json = jsonEncode(value);
    return '"${json.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
  }
}
