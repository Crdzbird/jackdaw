import 'package:flutter/widgets.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';

/// Builds the widget of one A2UI component from its [UiNode].
typedef UiWidgetBuilder = Widget Function(UiNode node);
