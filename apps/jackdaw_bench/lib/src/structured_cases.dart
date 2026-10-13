import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/bench_case.dart';
import 'package:jackdaw_bench/src/structured_shapes.dart';

const _topics = [
  'bird',
  'city',
  'book',
  'planet',
  'recipe',
  'car',
  'movie',
  'programming language',
  'mountain',
  'river',
  'song',
  'painting',
  'sport',
  'tree',
  'museum',
  'board game',
  'island',
  'instrument',
  'festival',
  'dish',
];

const _name = Schema.string(description: 'Name');

/// The 200 structured-output cases of claim C1: twenty topics in ten
/// schema shapes; ten topics in the first five are the Phase 2 slice.
List<BenchCase> structuredCases({int topics = 20, bool harder = true}) => [
  for (final topic in _topics.take(topics)) ...[
    ..._casesFor(topic),
    if (harder) ...moreShapes(topic),
  ],
];

List<BenchCase> _casesFor(String topic) => [
  BenchCase(
    'Describe a famous $topic. Rate it from 1 to 10 and say if you '
    'recommend it.',
    const ObjectSchema(
      properties: {
        'name': _name,
        'rating': Schema.integer(),
        'recommended': Schema.boolean(),
      },
      required: ['name', 'rating', 'recommended'],
    ),
  ),
  BenchCase(
    'Pick a $topic and classify its size. Give a score between 0 and 1.',
    const ObjectSchema(
      properties: {
        'name': _name,
        'size': Schema.string(enumValues: ['small', 'medium', 'large']),
        'score': Schema.number(),
      },
      required: ['name', 'size', 'score'],
    ),
  ),
  BenchCase(
    'Name a $topic and list three keywords about it.',
    const ObjectSchema(
      properties: {
        'name': _name,
        'keywords': Schema.array(items: _name),
      },
      required: ['name', 'keywords'],
    ),
  ),
  BenchCase(
    'Describe a $topic, where it comes from and a year linked to it.',
    const ObjectSchema(
      properties: {
        'name': _name,
        'details': ObjectSchema(
          properties: {'origin': Schema.string(), 'year': Schema.integer()},
          required: ['origin', 'year'],
        ),
      },
      required: ['name', 'details'],
    ),
  ),
  BenchCase(
    'List the top three of any kind of $topic with their rank.',
    const ObjectSchema(
      properties: {
        'items': Schema.array(
          items: ObjectSchema(
            properties: {'name': _name, 'rank': Schema.integer()},
            required: ['name', 'rank'],
          ),
        ),
      },
      required: ['items'],
    ),
  ),
];
