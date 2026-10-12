import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/bench_case.dart';

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
];

const _name = Schema.string(description: 'Name');

/// The 50 structured-output cases: ten topics in five schema shapes.
List<BenchCase> structuredCases() => [
  for (final topic in _topics) ..._casesFor(topic),
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
