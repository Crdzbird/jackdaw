import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('the guide lists components, functions and an example', () {
    final guide = uiCatalogGuide(basicCatalog);
    expect(guide, contains('- Text(text*, variant caption|body, weight)'));
    expect(guide, contains('- formatString(value*) returns string'));
    expect(guide, contains(basicInstructions));
    expect(guide, endsWith(uiGuideExample));
    expect(guide.length, lessThan(6000));
  });

  test('catalogs without functions or example get a shorter guide', () {
    const plain = UiCatalog(
      id: 'plain',
      components: [
        UiComponentDefinition(
          name: 'Badge',
          description: 'A badge.',
          props: ObjectSchema(properties: {}),
        ),
      ],
    );
    final guide = uiCatalogGuide(plain, example: null);
    expect(guide, contains('- Badge(): A badge.'));
    expect(guide, isNot(contains('Functions:')));
    expect(UiSchemas(plain).reply, isA<SummarizedSchema>());
  });
}
