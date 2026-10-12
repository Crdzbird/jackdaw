import 'package:jackdaw/jackdaw.dart';

/// Shape the demo asks for when JSON mode is on.
const ObjectSchema demoSchema = ObjectSchema(
  properties: {
    'answer': Schema.string(description: 'Short answer'),
    'confidence': Schema.number(description: 'Between 0 and 1'),
    'keywords': Schema.array(items: Schema.string()),
  },
  required: ['answer', 'confidence', 'keywords'],
);
