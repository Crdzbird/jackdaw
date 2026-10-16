import 'package:jackdaw_dom/src/ui_dom_node.dart';
import 'package:web/web.dart' as web;

/// What a builder makes of one component: its element and, for one that
/// reads data, how to bring that element up to date after a write. A
/// component that reads data and gives no update is built again.
typedef UiDomPart = ({web.HTMLElement element, void Function()? update});

/// Builds the element of one A2UI component from its [UiDomNode].
typedef UiDomBuilder = UiDomPart Function(UiDomNode node);
