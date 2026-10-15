import 'dart:math';

import 'package:jackdaw/jackdaw.dart';

const List<String> _awkward = [
  'name',
  'a"b',
  r'back\slash',
  'new\nline',
  'tab\there',
  'emoji \u{1F426}',
  '',
  ' ',
  '{"json": 1}',
  '<tool_call>',
  r'$ref',
];

/// Random schemas for grammar property tests, with names and enum values
/// that need escaping, nesting up to [depth] and raw documents.
Schema randomSchema(Random random, {int depth = 3}) {
  String text() => _awkward[random.nextInt(_awkward.length)];
  final kind = random.nextInt(depth <= 0 ? 6 : 9);
  return switch (kind) {
    0 => const Schema.string(),
    1 => Schema.string(enumValues: [text(), text()]),
    2 => const Schema.integer(),
    3 => const Schema.number(),
    4 => const Schema.boolean(),
    5 => const Schema.raw({}),
    6 => Schema.array(items: randomSchema(random, depth: depth - 1)),
    _ => ObjectSchema(
      properties: {
        for (var i = random.nextInt(4); i > 0; i--)
          '${text()}$i': randomSchema(random, depth: depth - 1),
      },
      additionalProperties: random.nextBool(),
    ),
  };
}
