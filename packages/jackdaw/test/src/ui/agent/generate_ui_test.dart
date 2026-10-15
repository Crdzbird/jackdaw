import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../support/replies_model.dart';
import '../ui_fixtures.dart';

Map<String, Object?> broken() => {
  'version': 'v1.0',
  'createSurface': {
    'surfaceId': 'signup',
    'components': [
      {'id': 'root', 'component': 'Card', 'child': 'gone'},
    ],
  },
};

void main() {
  test('a valid answer is applied at once', () async {
    final surfaces = UiSurfaces(basicCatalog);
    final model = RepliesModel([
      [formSurface],
    ]);
    final problems = await generateUi(model, [
      Message.user('Sign up'),
    ], surfaces);
    expect(problems, isEmpty);
    expect(surfaces.surfaces['signup']!.components, hasLength(4));
    expect(model.requests.single.responseSchema, same(surfaces.schemas.reply));
  });

  test('problems are sent back and the answer is asked for again', () async {
    final surfaces = UiSurfaces(basicCatalog);
    final model = RepliesModel([
      [broken()],
      [formSurface],
    ]);
    final problems = await generateUi(model, [
      Message.user('Sign up'),
    ], surfaces);
    expect(problems, isEmpty);
    final retry = model.requests.last.messages;
    expect(retry, hasLength(3));
    expect(retry.last.text, contains('/components/root/child: There is no'));
    expect(surfaces.surfaces['signup']!.root!.type, 'Column');
  });

  test('the last problems come back when repairs run out', () async {
    final surfaces = UiSurfaces(basicCatalog);
    final model = RepliesModel([
      [broken()],
    ]);
    final problems = await generateUi(
      model,
      [Message.user('Sign up')],
      surfaces,
      repairs: 0,
    );
    expect(problems.single.path, '/components/root/child');
  });
}
