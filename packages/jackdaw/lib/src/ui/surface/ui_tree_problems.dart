import 'package:jackdaw/src/ui/surface/json_pointer.dart';
import 'package:jackdaw/src/ui/surface/ui_child_refs.dart';
import 'package:jackdaw/src/ui/surface/ui_component.dart';
import 'package:jackdaw/src/ui/surface/ui_placement_problems.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/surface/ui_problem_code.dart';
import 'package:jackdaw/src/ui/surface/ui_surface.dart';

/// Problems with the component tree of [surface]: no root, references to
/// missing components, cycles, nesting deeper than [maxDepth], placements
/// the catalog does not allow, and, as warnings, components the root never
/// reaches.
List<UiProblem> uiTreeProblems(UiSurface surface, {int maxDepth = 32}) {
  final problems = <UiProblem>[];
  void report(UiProblemCode code, String path, String message) =>
      problems.add(UiProblem(code, message, surfaceId: surface.id, path: path));
  final components = surface.components;
  final root = surface.root;
  if (root == null) {
    if (components.isNotEmpty) {
      report(
        UiProblemCode.validationFailed,
        '/components',
        'No component has the id root.',
      );
    }
    return problems;
  }
  final reached = <String>{};
  void visit(UiComponent node, String parent, List<String> stack) {
    final at = jsonPointer(['components', node.id]);
    if (stack.contains(node.id)) {
      report(
        UiProblemCode.integrityError,
        at,
        'The component ${node.id} contains itself.',
      );
      return;
    }
    uiPlacementProblems(surface, node, parent, at, report);
    if (!reached.add(node.id)) return;
    if (stack.length >= maxDepth) {
      report(
        UiProblemCode.validationFailed,
        at,
        'Components are nested more than $maxDepth deep.',
      );
      return;
    }
    final definition = surface.catalog.component(node.type);
    if (definition == null) return;
    for (final (path, id) in uiChildRefs(definition.props, node.props)) {
      final child = components[id];
      if (child == null) {
        report(
          UiProblemCode.validationFailed,
          '$at$path',
          'There is no component with the id $id.',
        );
        continue;
      }
      visit(child, node.type, [...stack, node.id]);
    }
  }

  visit(root, 'Surface', const []);
  for (final id in components.keys.where((id) => !reached.contains(id))) {
    problems.add(
      UiProblem(
        UiProblemCode.validationFailed,
        'The component $id is not reachable from root, so it is not shown.',
        surfaceId: surface.id,
        path: jsonPointer(['components', id]),
        warning: true,
      ),
    );
  }
  return problems;
}
