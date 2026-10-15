@TestOn('vm')
library;

import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'ui_fixtures.dart';

void main() {
  final schemas = UiSchemas(basicCatalog);
  List<String> check(Object? value) =>
      schemas.message.validate(value).map((v) => '$v').toList();
  Map<String, Object?> text(Object? value) => {
    'version': 'v1.0',
    'updateComponents': {
      'surfaceId': 's',
      'components': [
        {'id': 'root', 'component': 'Text', 'text': value},
      ],
    },
  };

  test('surfaces built from the basic catalog validate', () {
    expect(check(formSurface), isEmpty);
    expect(schemas.messages.validate(listMessages), isEmpty);
  });

  test('components and props outside the catalog are rejected', () {
    final unknown = text('x');
    ((unknown['updateComponents']! as Map)['components']! as List)[0] = {
      'id': 'root',
      'component': 'Marquee',
    };
    expect(check(unknown), isNotEmpty);
    expect(check(text(null)), isNotEmpty);
    expect(
      check({
        'version': 'v0.9',
        'deleteSurface': {'surfaceId': 's'},
      }),
      isNotEmpty,
    );
    expect(
      check({
        'version': 'v1.0',
        'updateDataModel': {'surfaceId': 's'},
      }),
      isNotEmpty,
    );
  });

  test('values may only call functions of the right type and depth', () {
    Map<String, Object?> format(Object? value) => {
      '@call': 'formatString',
      'args': {'value': value},
    };
    expect(check(text(format('a'))), isEmpty);
    expect(check(text(format(format('a')))), isEmpty);
    expect(check(text(format(format(format('a'))))), isNotEmpty);
    expect(
      check(
        text({
          '@call': 'required',
          'args': {'value': 'a'},
        }),
      ),
      isNotEmpty,
    );
    expect(
      UiSchemas(basicCatalog, callDepth: 0).message.validate(text(format('a'))),
      isNotEmpty,
    );
  });

  test('the message grammar names every component', () {
    final grammar = GbnfCompiler().compile(schemas.messages);
    for (final component in basicCatalog.components) {
      expect(grammar, contains('"\\"${component.name}\\""'));
    }
    final corpus = Platform.environment['JACKDAW_GRAMMAR_CORPUS'];
    if (corpus != null) {
      File('$corpus/ui_basic.gbnf').writeAsStringSync(grammar);
    }
  });
}
