import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_choice_list.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_leaf.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';
import 'package:jackdaw_flutter/src/ui/ui_node_values.dart';

part 'ui_choice_picker_state.dart';

/// A ChoicePicker component bound to a list of chosen values: chips or
/// checkboxes, one choice or several, with a filter field when the
/// component is filterable.
final class UiChoicePicker extends StatefulWidget {
  /// Draws the choice picker of [node].
  const factory({required UiNode node, Key? key}) = UiChoicePicker._;

  const new _({required this.node, super.key});

  /// The ChoicePicker component and its scope.
  final UiNode node;

  @override
  State<UiChoicePicker> createState() => _UiChoicePickerState();
}

/// Builds the [UiChoicePicker] of [node].
Widget uiChoicePickerWidget(UiNode node) => uiLeaf(UiChoicePicker(node: node));
