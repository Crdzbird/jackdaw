import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_icon_names.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_leaf.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_svg_icon_painter.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_svg_path_reader.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';
import 'package:jackdaw_flutter/src/ui/ui_node_values.dart';

/// [text] as an http or https link the app allows, or `null`.
Uri? uiAllowedUrl(UiNode node, String? text) {
  final url = Uri.tryParse(text ?? '');
  if (url == null || (url.scheme != 'https' && url.scheme != 'http')) {
    return null;
  }
  final allow = node.controller.evaluator.host.allowUrl;
  return allow != null && allow(url) ? url : null;
}

BoxFit _fit(Object? value) => switch (value) {
  'contain' => BoxFit.contain,
  'cover' => BoxFit.cover,
  'none' => BoxFit.none,
  'scaleDown' => BoxFit.scaleDown,
  _ => BoxFit.fill,
};

/// An Image component, loaded only from hosts the app allows.
Widget uiImageWidget(UiNode node) {
  final variant = node.component.props['variant'];
  final size = switch (variant) {
    'icon' => 24.0,
    'avatar' => 40.0,
    'smallFeature' => 64.0,
    'largeFeature' => 240.0,
    'header' => 200.0,
    _ => 160.0,
  };
  final square =
      variant == 'icon' || variant == 'avatar' || variant == 'smallFeature';
  final description = node.text('description');
  final url = uiAllowedUrl(node, node.text('url'));
  final image = url == null
      ? Icon(
          Icons.image_not_supported,
          size: square ? size : 48,
          semanticLabel: description,
        )
      : Image.network(
          '$url',
          height: size,
          width: square ? size : null,
          fit: _fit(node.component.props['fit']),
          semanticLabel: description,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
        );
  return uiLeaf(variant == 'avatar' ? ClipOval(child: image) : image);
}

/// An Icon component: a built-in icon by name, or one drawn from an SVG
/// path in a 24 by 24 box.
Widget uiIconWidget(UiNode node) => Builder(
  builder: (context) {
    final name = node.value('name');
    final path = switch (name) {
      {'svgPath': final String data} => UiSvgPathReader(data).read(),
      _ => null,
    };
    if (path != null) {
      final theme = IconTheme.of(context);
      return uiLeaf(
        CustomPaint(
          size: Size.square(theme.size ?? 24),
          painter: UiSvgIconPainter(
            path,
            theme.color ?? const Color(0xFF000000),
          ),
        ),
      );
    }
    return uiLeaf(
      Icon(
        uiIconNames[name] ?? Icons.help_outline,
        semanticLabel: name is String ? name : null,
      ),
    );
  },
);
