import 'package:jackdaw/src/schema/schema_violation.dart';
import 'package:jackdaw/src/ui/surface/json_pointer.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/surface/ui_problem_code.dart';

/// The problems a message has because of [violations] of the schemas.
List<UiProblem> uiViolationProblems(List<SchemaViolation> violations) => [
  for (final v in violations)
    UiProblem(
      UiProblemCode.validationFailed,
      v.message,
      path: violationPointer(v.path),
    ),
];
