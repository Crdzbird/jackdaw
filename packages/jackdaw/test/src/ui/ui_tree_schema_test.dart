@TestOn('vm')
library;

import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'ui_tree_fixtures.dart';

void main() {
  final schemas = UiSchemas(basicCatalog, treeDepth: 3);

  test('a tree validates and its root is summarized by the guide', () {
    expect(schemas.tree.validate(signupTree), isEmpty);
    final root = schemas.tree.properties['root']! as SummarizedSchema;
    expect(root.summary, uiCatalogGuide(basicCatalog, format: UiFormat.tree));
    expect(root.summary, contains(uiTreeIntro));
    expect(root.summary, endsWith(uiGuideExample(UiFormat.tree)));
  });

  test('nesting stops at the tree depth and ids are not written', () {
    Map<String, Object?> card(Object? child) => {
      'component': 'Card',
      'child': child,
    };
    const text = {'component': 'Text', 'text': 'x'};
    Map<String, Object?> tree(Object? root) => {'surfaceId': 's', 'root': root};
    expect(schemas.tree.validate(tree(card(card(card(text))))), isEmpty);
    expect(
      schemas.tree.validate(tree(card(card(card(card(text)))))),
      isNotEmpty,
    );
    expect(schemas.tree.validate(tree({...text, 'id': 'x'})), isNotEmpty);
    expect(schemas.tree.validate(tree({'component': 'Marquee'})), isNotEmpty);
  });

  test('the tree grammar compiles', () {
    final grammar = GbnfCompiler().compile(UiSchemas(basicCatalog).tree);
    expect(grammar, contains(r'"\"template\""'));
    final corpus = Platform.environment['JACKDAW_GRAMMAR_CORPUS'];
    if (corpus != null) {
      File('$corpus/ui_tree.gbnf').writeAsStringSync(grammar);
    }
  });
}
