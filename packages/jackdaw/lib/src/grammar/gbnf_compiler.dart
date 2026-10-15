import 'package:jackdaw/src/grammar/gbnf_members.dart';
import 'package:jackdaw/src/grammar/gbnf_primitives.dart';
import 'package:jackdaw/src/schema/schema.dart';

/// Compiles a [Schema] into a GBNF grammar whose root rule only accepts
/// JSON text that matches the schema.
///
/// Properties come in declaration order, optional ones only when the model
/// chooses to. A schema used twice, or two rules with the same body, share
/// one rule. Pure Dart, so native and web backends share one grammar.
final class GbnfCompiler {
  /// Creates a compiler for one grammar.
  factory() = GbnfCompiler._;

  new _();

  final Set<String> _primitives = {};
  final Map<Schema, String> _shared = Map.identity();
  final Map<String, String> _bodies = {};

  /// Returns the grammar text for [schema].
  String compile(Schema schema) => render(rule(schema));

  /// Adds a rule named after a counter with [body] and returns its name.
  String define(String body) => _named(body);

  /// Returns the grammar with [root] as the body of the root rule and
  /// every rule added so far.
  String render(String root) => [
    'root ::= $root',
    for (final MapEntry(key: body, value: name) in _bodies.entries)
      '$name ::= $body',
    for (final name in _primitives) gbnfPrimitives[name]!,
  ].join('\n');

  /// [text] as a GBNF string literal that matches it exactly.
  static String text(String text) => gbnfText(text);

  /// Adds the rules that match [schema] and returns the name of its rule,
  /// for building a grammar from several schemas.
  String rule(Schema schema) => _shared[schema] ??= switch (schema) {
    StringSchema(enumValues: final values?) => _named(
      values.map(gbnfLiteral).join(' | '),
    ),
    StringSchema() => _use('string'),
    IntegerSchema() => _use('integer'),
    NumberSchema() => _use('number'),
    BooleanSchema() => _use('boolean'),
    ArraySchema() => _array(schema),
    MapSchema(:final values) => _list(
      gbnfRepeat('"{"', '${_use('string')} ws ":" ws ${rule(values)}', '"}"'),
    ),
    ObjectSchema() => _object(schema),
    UnionSchema(:final alternatives) => _choice(alternatives.values),
    AnyOfSchema(:final options) => _choice(options),
    SummarizedSchema(schema: final inner) => rule(inner),
    RawSchema() => _value(),
  };

  String _value() => (['ws', 'string', 'number', 'value']..forEach(_use)).last;

  String _object(ObjectSchema schema) => _list(
    gbnfObjectBody([
      for (final MapEntry(:key, :value) in schema.properties.entries)
        (
          '${gbnfLiteral(key)} ws ":" ws ${rule(value)}',
          schema.required.contains(key),
        ),
    ]),
  );

  String _choice(Iterable<Schema> options) => options.isEmpty
      ? throw ArgumentError('a choice needs an option')
      : _named(options.map(rule).join(' | '));

  String _list(String body) => _named(body, uses: 'ws');

  String _array(ArraySchema schema) => _list(
    gbnfRepeat(
      '"["',
      rule(schema.items),
      '"]"',
      min: schema.minItems,
      max: schema.maxItems,
      prefix: schema.prefixItems.map(rule).toList(),
    ),
  );

  String _use(String primitive) =>
      (_primitives..add(primitive)).lookup(primitive)!;

  String _named(String body, {String? uses}) {
    if (uses != null) _use(uses);
    return _bodies[body] ??= 'rule${_bodies.length}';
  }
}
