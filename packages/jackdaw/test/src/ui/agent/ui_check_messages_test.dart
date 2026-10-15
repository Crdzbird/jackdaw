import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../ui_fixtures.dart';

void main() {
  final evaluator = UiEvaluator(basicCatalog);

  UiSurface signup({bool send = false}) {
    final surfaces = UiSurfaces(basicCatalog)..applyAll([formSurface]);
    final created = surfaces.surfaces['signup']!;
    final surface = UiSurface(
      'signup',
      basicCatalog,
      sendDataModel: send,
      data: created.data,
    );
    surface.components.addAll(created.components);
    return surface;
  }

  test('failing checks keep an action from running', () {
    final surface = signup();
    final email = surface.components['email']!;
    expect(uiCheckMessages(email, evaluator, UiScope(surface.data)), [
      'Enter an email address.',
    ]);
    surface.data.write('/form/email', 'ana@x.io');
    expect(uiCheckMessages(email, evaluator, UiScope(surface.data)), isEmpty);
    const guarded = UiComponent('b', 'Button', {
      'child': 'x',
      'action': {
        'event': {'name': 'never'},
      },
      'checks': [
        {
          'condition': {
            '@call': 'required',
            'args': {
              'value': {'@path': '/none'},
            },
          },
        },
        {
          'condition': {'@call': 'missing'},
        },
        {
          'condition': {'@path': '/form/email'},
          'message': 'Not a boolean.',
        },
      ],
    });
    expect(uiCheckMessages(guarded, evaluator, UiScope(surface.data)), [
      'This value is not valid.',
      'This value is not valid.',
      'Not a boolean.',
    ]);
    expect(uiTrigger(surface, guarded, evaluator), isNull);
  });
}
