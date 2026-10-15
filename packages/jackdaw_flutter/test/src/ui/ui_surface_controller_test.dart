import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

import 'ui_form.dart';

void main() {
  test('the tool shows its UI and notifies listeners', () async {
    final controller = UiSurfaceController(basicCatalog);
    var notified = 0;
    controller.addListener(() => notified++);
    final tool = controller.tool(name: 'ui', format: UiFormat.messages);
    final result = await tool.invoke(
      const ToolCallPart(
        id: 'c',
        name: 'ui',
        arguments: {
          'messages': [signupForm],
        },
      ),
    );
    expect(result.isError, isFalse);
    expect(controller.surfaces.surfaces.keys, ['signup']);
    expect(notified, 1);
  });

  test('generate asks for UI as a whole answer', () async {
    final controller = UiSurfaceController(basicCatalog);
    final model = ScriptedModel([
      textTurn([
        jsonEncode({
          'surfaceId': 'signup',
          'root': {
            'component': 'Column',
            'children': [
              {'component': 'Text', 'text': 'Welcome'},
            ],
          },
        }),
      ]),
    ]);
    final problems = await controller.generate(model, [
      Message.user('Sign up'),
    ]);
    expect(problems, isEmpty);
    expect(controller.surfaces.surfaces['signup']!.root!.type, 'Column');
  });

  test('actions on missing surfaces are ignored', () {
    final controller = UiSurfaceController(basicCatalog)
      ..trigger(
        'none',
        const UiComponent('x', 'Button', {}),
        UiScope(UiDataModel()),
      )
      ..write('none', '/a', 1);
    expect(controller.surfaces.surfaces, isEmpty);
  });
}
