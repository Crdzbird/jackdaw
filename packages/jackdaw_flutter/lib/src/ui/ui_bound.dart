import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/ui_layer.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';
import 'package:jackdaw_flutter/src/ui/ui_semantics.dart';

part 'ui_bound_state.dart';

/// One component as a widget of its own, which redraws by itself when a
/// data write touches what its props read, so a write redraws only the
/// components bound near it rather than the whole surface.
final class UiBound extends StatefulWidget {
  /// Draws [node], stretched across its column when [stretch] is set.
  const factory({required UiNode node, bool stretch, Key? key}) = UiBound._;

  const new _({required this.node, this.stretch = false, super.key});

  /// The component and its scope.
  final UiNode node;

  /// Whether it takes the full width of its column; see [UiLayer].
  final bool stretch;

  @override
  State<UiBound> createState() => _UiBoundState();
}
