import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_leaf.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_media_builders.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';
import 'package:jackdaw_flutter/src/ui/ui_node_values.dart';

/// A Video component: a tile with its poster that opens the video, since
/// jackdaw_flutter plays no media itself.
Widget uiVideoWidget(UiNode node) => _tile(
  node,
  Icons.play_circle,
  node.text('url'),
  poster: uiAllowedUrl(node, node.text('posterUrl')),
);

/// An AudioPlayer component: a tile that opens the audio.
Widget uiAudioPlayerWidget(UiNode node) =>
    _tile(node, Icons.audiotrack, node.text('description') ?? node.text('url'));

Widget _tile(UiNode node, IconData icon, String? title, {Uri? poster}) {
  final url = uiAllowedUrl(node, node.text('url'));
  final open = node.controller.evaluator.host.openUrl;
  return uiLeaf(
    ListTile(
      leading: poster == null
          ? Icon(icon)
          : Image.network(
              '$poster',
              width: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(icon),
            ),
      title: Text(title ?? ''),
      enabled: url != null && open != null,
      onTap: url == null || open == null ? null : () => open(url),
    ),
  );
}
