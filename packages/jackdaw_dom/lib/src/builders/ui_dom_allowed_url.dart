import 'package:jackdaw_dom/src/ui_dom_node.dart';

/// [text] as an http or https link the app allows through its host, or
/// `null`.
Uri? uiDomAllowedUrl(UiDomNode node, String text) {
  final url = Uri.tryParse(text);
  if (url == null || (url.scheme != 'https' && url.scheme != 'http')) {
    return null;
  }
  final allow = node.controller.evaluator.host.allowUrl;
  return allow != null && allow(url) ? url : null;
}
