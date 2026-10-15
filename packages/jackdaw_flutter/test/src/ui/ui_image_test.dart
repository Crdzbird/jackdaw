import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';

import 'support/show_surface.dart';

void main() {
  final allowAll = UiHost(allowUrl: (url) => url.host == 'img.example');

  testWidgets('images load only from allowed hosts', (tester) async {
    await showSurface(tester, [
      c('root', 'Row', {
        'children': ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
      }),
      c('a', 'Image', {
        'url': 'https://img.example/a.png',
        'variant': 'avatar',
        'fit': 'cover',
      }),
      c('b', 'Image', {
        'url': 'https://img.example/b.png',
        'variant': 'icon',
        'fit': 'contain',
      }),
      c('c', 'Image', {
        'url': 'https://img.example/c.png',
        'variant': 'smallFeature',
        'fit': 'none',
      }),
      c('d', 'Image', {
        'url': 'https://img.example/d.png',
        'variant': 'largeFeature',
        'fit': 'scaleDown',
      }),
      c('e', 'Image', {
        'url': 'https://img.example/e.png',
        'variant': 'header',
      }),
      c('f', 'Image', {
        'url': 'https://other.example/f.png',
        'description': 'blocked',
      }),
      c('g', 'Image', {'url': 'ftp://img.example/g.png'}),
    ], host: allowAll);
    expect(find.byType(Image), findsNWidgets(5));
    expect(find.byIcon(Icons.image_not_supported), findsNWidgets(2));
    expect(find.byType(ClipOval), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image), findsWidgets);
  });

  testWidgets('video and audio open in the app that handles them', (
    tester,
  ) async {
    final opened = <Uri>[];
    await showSurface(tester, [
      c('root', 'Column', {
        'children': ['v', 'a', 'x'],
      }),
      c('v', 'Video', {
        'url': 'https://img.example/v.mp4',
        'posterUrl': 'https://img.example/p.png',
      }),
      c('a', 'AudioPlayer', {
        'url': 'https://img.example/a.mp3',
        'description': 'Song',
      }),
      c('x', 'AudioPlayer', {'url': 'https://other.example/x.mp3'}),
    ], host: UiHost(allowUrl: allowAll.allowUrl, openUrl: opened.add));
    await tester.tap(find.text('Song'));
    await tester.tap(find.text('https://img.example/v.mp4'));
    await tester.tap(find.text('https://other.example/x.mp3'));
    expect(opened.map((u) => u.path), ['/a.mp3', '/v.mp4']);
  });
}
