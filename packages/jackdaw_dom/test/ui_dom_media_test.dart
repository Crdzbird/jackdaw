@TestOn('browser')
library;

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'support/show_dom.dart';

final UiHost _host = UiHost(allowUrl: (url) => url.host == 'ok.test');

void main() {
  test('images, videos and audio load only from allowed hosts', () {
    final shown = showDom(
      [
        c('root', 'Column', {
          'children': ['photo', 'blocked', 'clip', 'song', 'mute'],
        }),
        c('photo', 'Image', {
          'url': {'@path': '/photo'},
          'description': 'A cat',
          'variant': 'avatar',
          'fit': 'cover',
        }),
        c('blocked', 'Image', {'url': 'https://elsewhere.test/a.png'}),
        c('clip', 'Video', {
          'url': 'https://ok.test/v.mp4',
          'posterUrl': 'https://ok.test/p.png',
        }),
        c('song', 'AudioPlayer', {
          'url': 'https://ok.test/s.mp3',
          'description': 'A song',
        }),
        c('mute', 'AudioPlayer', {'url': 'ftp://ok.test/s.mp3'}),
      ],
      data: {'photo': 'https://ok.test/cat.png'},
      links: _host,
    );
    final images = shown.host.querySelectorAll('img');
    expect(images.length, 1);
    final image = images.item(0)! as web.HTMLImageElement;
    expect(image.src, 'https://ok.test/cat.png');
    expect(image.alt, 'A cat');
    final boxes = shown.host.querySelectorAll('.jd-image');
    expect((boxes.item(0)! as web.Element).getAttribute('data-fit'), 'cover');
    expect((boxes.item(1)! as web.Element).getAttribute('role'), 'img');
    final video = shown.host.querySelector('video')! as web.HTMLVideoElement;
    expect(video.poster, 'https://ok.test/p.png');
    expect(shown.host.querySelectorAll('audio').length, 1);
    expect(shown.host.textContent, contains('A song'));
    shown.controller.applyAll([write('/photo', 'https://elsewhere.test/x')]);
    expect(shown.host.querySelectorAll('img').length, 0);
    shown.view.dispose();
  });

  test('a video from a host that is not allowed shows no player', () {
    final shown = showDom([
      c('root', 'Video', {'url': 'https://elsewhere.test/v.mp4'}),
    ]);
    expect(shown.host.querySelector('video'), isNull);
    shown.view.dispose();
  });
}
