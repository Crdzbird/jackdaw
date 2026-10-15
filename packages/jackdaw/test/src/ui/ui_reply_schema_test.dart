import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'ui_fixtures.dart';

void main() {
  final schemas = UiSchemas(basicCatalog);

  test('a reply may create one surface, root first, then update it', () {
    final reply = schemas.reply;
    expect(reply, isA<SummarizedSchema>());
    expect((reply as SummarizedSchema).summary, uiCatalogGuide(basicCatalog));
    expect(reply.validate([formSurface, ...listMessages]), isEmpty);
    expect(reply.validate(listMessages), isEmpty);
  });

  test('a reply may not create twice or put the root later', () {
    expect(schemas.reply.validate([formSurface, formSurface]), isNotEmpty);
    expect(schemas.messages.validate([formSurface, formSurface]), isEmpty);
    final body = formSurface['createSurface']! as Map<String, Object?>;
    final components = [...body['components']! as List<Object?>];
    final late = {
      'version': 'v1.0',
      'createSurface': {
        ...body,
        'components': [...components.skip(1), components.first],
      },
    };
    expect(schemas.reply.validate([late]), isNotEmpty);
    expect(schemas.messages.validate([late]), isEmpty);
  });
}
