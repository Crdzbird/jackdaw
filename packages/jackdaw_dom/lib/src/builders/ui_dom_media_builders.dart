import 'package:jackdaw_dom/src/builders/ui_dom_allowed_url.dart';
import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:jackdaw_dom/src/ui_dom_node_values.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';
import 'package:web/web.dart' as web;

/// An Image component, loaded only from hosts the app allows; any other
/// image shows as an empty box with its description.
UiDomPart uiDomImage(UiDomNode node) {
  final box = web.HTMLSpanElement()..className = 'jd-image';
  for (final key in ['variant', 'fit']) {
    if (node.component.props[key] case final String value) {
      box.setAttribute('data-$key', value);
    }
  }
  final image = web.HTMLImageElement();
  void update() {
    final url = uiDomAllowedUrl(node, node.text('url'));
    final description = node.text('description');
    image.alt = description;
    box
      ..setAttribute('role', 'img')
      ..setAttribute('aria-label', description)
      ..textContent = '';
    if (url == null) return;
    image.src = '$url';
    box
      ..removeAttribute('role')
      ..append(image);
  }

  update();
  return (element: box, update: update);
}

/// A Video component: the browser's player, for a video from a host the
/// app allows, with its poster when that is allowed too.
UiDomPart uiDomVideo(UiDomNode node) {
  final video = web.HTMLVideoElement()
    ..controls = true
    ..preload = 'metadata';
  final box = web.HTMLSpanElement()..className = 'jd-media';
  void update() {
    final url = uiDomAllowedUrl(node, node.text('url'));
    final poster = uiDomAllowedUrl(node, node.text('posterUrl'));
    box.textContent = '';
    if (url == null) return;
    video
      ..src = '$url'
      ..poster = poster == null ? '' : '$poster';
    box.append(video);
  }

  update();
  return (element: box, update: update);
}

/// An AudioPlayer component: the browser's player, for audio from a host
/// the app allows, under its description.
UiDomPart uiDomAudioPlayer(UiDomNode node) {
  final audio = web.HTMLAudioElement()..controls = true;
  final caption = web.HTMLSpanElement();
  final box = web.HTMLSpanElement()
    ..className = 'jd-media'
    ..append(caption);
  void update() {
    final url = uiDomAllowedUrl(node, node.text('url'));
    caption.textContent = node.text('description');
    audio.remove();
    if (url == null) return;
    audio.src = '$url';
    box.append(audio);
  }

  update();
  return (element: box, update: update);
}
