import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../ui_fixtures.dart';

void main() {
  final evaluator = UiEvaluator(basicCatalog);
  final when = DateTime.utc(2026, 1, 16, 9);

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

  test('an event becomes an action with its context resolved', () {
    final surface = signup()..data.write('/form/email', 'ana@x.io');
    final action = uiTrigger(
      surface,
      surface.components['send']!,
      evaluator,
      now: when,
    )!;
    expect(action.toJson(), {
      'version': 'v1.0',
      'action': {
        'name': 'signup',
        'surfaceId': 'signup',
        'sourceComponentId': 'send',
        'timestamp': '2026-01-16T09:00:00.000Z',
        'context': {'email': 'ana@x.io'},
      },
    });
    final now = uiTrigger(surface, surface.components['send']!, evaluator)!;
    expect(DateTime.now().difference(now.timestamp).inSeconds, lessThan(5));
    final message = uiActionMessage(action);
    expect(message.role, Role.user);
    expect(message.text, startsWith('UI action: {"version":"v1.0"'));
  });

  test('a surface that sends its data adds it, with the user message', () {
    final surface = signup(send: true);
    const button = UiComponent('go', 'Button', {
      'child': 'x',
      'action': {
        'event': {
          'name': 'go',
          'userMessage': {
            '@call': 'formatString',
            'args': {'value': r'Sign up ${/form/email}'},
          },
        },
      },
    });
    final action = uiTrigger(surface, button, evaluator, now: when)!;
    expect(action.userMessage, 'Sign up ');
    expect(action.dataModel, {
      'form': {'email': ''},
    });
    final text = uiActionMessage(action).text;
    expect(text, startsWith('Sign up \nUI action:'));
    expect(text, endsWith('Data model of signup: {"form":{"email":""}}'));
  });

  test('a function call runs on the renderer', () {
    final opened = <Uri>[];
    final host = UiEvaluator(
      basicCatalog,
      host: UiHost(allowUrl: (_) => true, openUrl: opened.add),
    );
    final surface = signup();
    const link = UiComponent('l', 'Button', {
      'child': 'x',
      'action': {
        'functionCall': {
          '@call': 'openUrl',
          'args': {'url': 'https://a.example'},
        },
      },
    });
    expect(uiTrigger(surface, link, host), isNull);
    expect(opened.single.host, 'a.example');
    expect(
      uiTrigger(surface, const UiComponent('t', 'Text', {'text': 'x'}), host),
      isNull,
    );
  });
}
