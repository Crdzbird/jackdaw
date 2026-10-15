import 'dart:convert';

import 'package:jackdaw/src/grammar/gbnf_members.dart';
import 'package:jackdaw/src/grammar/gbnf_primitives.dart';
import 'package:jackdaw/src/schema/schema.dart';

/// Compiles a [Schema] into a GBNF grammar whose root rule only accepts
/// JSON text that matches the schema.
///
/// Object properties are emitted in declaration order; required ones always
/// and optional ones only when the model chooses to. A schema used in
/// several places compiles to one shared rule. The compiler is pure Dart,
/// so native and web inference backends share one grammar.
final class GbnfCompiler {
  /// Creates a compiler for one grammar.
  factory() = GbnfCompiler._;

  new _();

  final List<String> _rules = [];
  final Set<String> _primitives = {};
  final Map<Schema, String> _shared = Map.identity();
  int _count = 0;

  /// Returns the grammar text for [schema].
  String compile(Schema schema) => render(rule(schema));

  /// Adds a rule named after a counter with [body] and returns its name.
  String define(String body) => _named(body);

  /// Returns the grammar with [root] as the body of the root rule and
  /// every rule added so far.
  String render(String root) => [
    'root ::= $root',
    ..._rules,
    for (final name in _primitives) gbnfPrimitives[name]!,
  ].join('\n');

  /// [text] as a GBNF string literal that matches it exactly.
  static String text(String text) => gbnfText(text);

  /// Adds the rules that match [schema] and returns the name of its rule,
  /// for building a grammar from several schemas.
  String rule(Schema schema) => _shared[schema] ??= switch (schema) {
    StringSchema(enumValues: final values?) => _named(
      values.map(_literal).join(' | '),
    ),
    StringSchema() => _use('string'),
    IntegerSchema() => _use('integer'),
    NumberSchema() => _use('number'),
    BooleanSchema() => _use('boolean'),
    ArraySchema(:final items) => _array(items),
    ObjectSchema() => _object(schema),
    UnionSchema(:final alternatives) => _choice(alternatives.values),
    AnyOfSchema(:final options) => _choice(options),
    RawSchema() => _value(),
  };

  String _value() {
    ['ws', 'string', 'number'].forEach(_use);
    return _use('value');
  }

  String _object(ObjectSchema schema) {
    _use('ws');
    return _named(
      gbnfObjectBody([
        for (final MapEntry(:key, :value) in schema.properties.entries)
          (
            '${_literal(key)} ws ":" ws ${rule(value)}',
            schema.required.contains(key),
          ),
      ]),
    );
  }

  String _choice(Iterable<Schema> options) => options.isEmpty
      ? throw ArgumentError('a choice needs an option')
      : _named(options.map(rule).join(' | '));

  String _array(Schema items) {
    _use('ws');
    final item = rule(items);
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

  static String _literal(String value) => text(jsonEncode(value));
}
