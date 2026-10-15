import 'package:jackdaw/src/ui/surface/json_pointer.dart';
import 'package:jackdaw/src/ui/surface/ui_component.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/surface/ui_problem_code.dart';
import 'package:jackdaw/src/ui/surface/ui_surface.dart';

/// Adds or replaces the components of [list], found at the pointer [at] of
/// a validated message, on [surface], and reports ids it repeats.
List<UiProblem> uiAddComponents(
  UiSurface surface,
  List<Object?> list,
  String at,
) {
  final seen = <String>{};
  final problems = <UiProblem>[];
  for (final (i, item) in list.indexed) {
    final component = UiComponent.fromJson(item! as Map<String, Object?>);
    if (!seen.add(component.id)) {
      problems.add(
        UiProblem(
          UiProblemCode.validationFailed,
          'The id ${component.id} is used by more than one component.',
          surfaceId: surface.id,
          path: '$at${jsonPointer([i, 'id'])}',
        ),
      );
    }
    surface.components[component.id] = component;
  }
  return problems;
}
