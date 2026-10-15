import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

import 'ui_form.dart';

Widget app(UiSurfaceController controller, String id) => MaterialApp(
  home: Scaffold(
    body: UiSurfaceView(controller: controller, surfaceId: id),
  ),
);

void main() {
  testWidgets('a form is drawn, edited and sent', (tester) async {
    final actions = <UiAction>[];
    final controller = UiSurfaceController(basicCatalog, onAction: actions.add);
    expect(controller.applyAll([signupForm]), isEmpty);
    await tester.pumpWidget(app(controller, 'signup'));
    expect(find.text('Email'), findsOneWidget);
    final button = find.widgetWithText(FilledButton, 'Sign up');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pump();
    expect(find.text('Enter an email address.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ana@x.io');
    await tester.pump();
    expect(find.text('Enter an email address.'), findsNothing);
    expect(
      controller.surfaces.surfaces['signup']!.data.read('/form/email'),
      'ana@x.io',
    );
    await tester.tap(button);
    expect(actions.single.context, {'email': 'ana@x.io'});
  });

  testWidgets('a missing surface or root draws nothing', (tester) async {
    final controller = UiSurfaceController(basicCatalog);
    await tester.pumpWidget(app(controller, 'none'));
    expect(find.byType(Material), findsWidgets);
    controller.applyAll([
      {
        'version': 'v1.0',
        'createSurface': {'surfaceId': 'empty'},
      },
    ]);
    await tester.pumpWidget(app(controller, 'empty'));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('the data model redraws bound text', (tester) async {
    final controller = UiSurfaceController(basicCatalog)
      ..applyAll([
        {
          'version': 'v1.0',
          'createSurface': {
            'surfaceId': 's',
            'components': [
              {
                'id': 'root',
                'component': 'Text',
                'text': {'@path': '/greeting'},
                'variant': 'caption',
              },
            ],
            'dataModel': {'greeting': 'Hello'},
          },
        },
      ]);
    await tester.pumpWidget(app(controller, 's'));
    expect(find.text('Hello'), findsOneWidget);
    controller.write('s', '/greeting', 'Bye');
    await tester.pump();
    expect(find.text('Bye'), findsOneWidget);
  });
}
