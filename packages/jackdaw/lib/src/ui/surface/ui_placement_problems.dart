import 'package:jackdaw/src/ui/surface/ui_component.dart';
import 'package:jackdaw/src/ui/surface/ui_problem_code.dart';
import 'package:jackdaw/src/ui/surface/ui_surface.dart';

/// Reports through [report] when [node], found at [at], sits in a [parent]
/// its catalog entry does not allow, or [parent] may not contain it.
void uiPlacementProblems(
  UiSurface surface,
  UiComponent node,
  String parent,
  String Function() at,
  void Function(UiProblemCode, String, String) report,
) {
  final catalog = surface.catalog;
  final definition = catalog.component(node.type);
  if (definition == null) {
    report(
      UiProblemCode.validationFailed,
      at(),
      'The catalog has no component ${node.type}.',
    );
    return;
  }
  if (definition.allowedParents case final parents?
      when !parents.contains(parent)) {
    report(
      UiProblemCode.unallowedParent,
      at(),
      '${node.type} may only be placed in ${parents.join(', ')}.',
    );
  }
  if (catalog.component(parent)?.allowedChildren case final children?
      when !children.contains(node.type)) {
    report(
      UiProblemCode.unallowedChild,
      at(),
      '$parent may only contain ${children.join(', ')}.',
    );
  }
}
