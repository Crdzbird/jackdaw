import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_leaf.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';
import 'package:jackdaw_flutter/src/ui/ui_node_values.dart';

part 'ui_text_field_state.dart';

/// A TextField component bound to the data model. It shows the message of
/// its first failing check once the user has typed.
final class UiTextField extends StatefulWidget {
  /// Draws the text field of [node].
  const factory({required UiNode node, Key? key}) = UiTextField._;

  const new _({required this.node, super.key});

  /// The TextField component and its scope.
  final UiNode node;

  @override
  State<UiTextField> createState() => _UiTextFieldState();
}

/// Builds the [UiTextField] of [node].
Widget uiTextFieldWidget(UiNode node) => uiLeaf(UiTextField(node: node));
