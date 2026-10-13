import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/bench_case.dart';

const _text = Schema.string();

/// Five harder schema shapes for [topic]: enums with flags, deep nesting,
/// numbers, lists of text and an array at the root.
List<BenchCase> moreShapes(String topic) => [
  BenchCase(
    'Classify a well known $topic: its category, whether it is popular, '
    'old and expensive.',
    const ObjectSchema(
      properties: {
        'name': _text,
        'category': Schema.string(enumValues: ['common', 'rare', 'unique']),
        'popular': Schema.boolean(),
        'old': Schema.boolean(),
        'expensive': Schema.boolean(),
      },
      required: ['name', 'category', 'popular', 'old', 'expensive'],
    ),
  ),
  BenchCase(
    'Give a profile of a $topic with its origin and two tags.',
    const ObjectSchema(
      properties: {
        'profile': ObjectSchema(
          properties: {
            'name': _text,
            'facts': ObjectSchema(
              properties: {
                'origin': _text,
                'tags': Schema.array(items: _text),
              },
              required: ['origin', 'tags'],
            ),
          },
          required: ['name', 'facts'],
        ),
      },
      required: ['profile'],
    ),
  ),
  BenchCase(
    'Estimate numbers for a $topic: a size in meters, a count and a share '
    'between 0 and 1.',
    const ObjectSchema(
      properties: {
        'name': _text,
        'meters': Schema.number(),
        'count': Schema.integer(),
        'share': Schema.number(),
      },
      required: ['name', 'meters', 'count', 'share'],
    ),
  ),
  BenchCase(
    'Weigh up a $topic: two pros, two cons and a one sentence summary.',
    const ObjectSchema(
      properties: {
        'pros': Schema.array(items: _text),
        'cons': Schema.array(items: _text),
        'summary': _text,
      },
      required: ['pros', 'cons', 'summary'],
    ),
  ),
  BenchCase(
    'Score three examples of a $topic from 0 to 1.',
    const Schema.array(
      items: ObjectSchema(
        properties: {'name': _text, 'score': Schema.number()},
        required: ['name', 'score'],
      ),
    ),
  ),
];
