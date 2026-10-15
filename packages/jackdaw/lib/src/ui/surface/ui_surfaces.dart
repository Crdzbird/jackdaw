import 'dart:collection';

import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/schema/ui_schemas.dart';
import 'package:jackdaw/src/ui/surface/json_pointer.dart';
import 'package:jackdaw/src/ui/surface/ui_apply_message.dart';
import 'package:jackdaw/src/ui/surface/ui_message_parts.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/surface/ui_problem_code.dart';
import 'package:jackdaw/src/ui/surface/ui_surface.dart';
import 'package:jackdaw/src/ui/surface/ui_surface_snapshot.dart';
import 'package:jackdaw/src/ui/surface/ui_tree_problems.dart';

/// The surfaces built from A2UI v1.0 messages for one catalog.
///
/// Each message is validated before it is applied; one that does not
/// match the schemas changes nothing. Problems come back as A2UI `error`
/// messages the agent can act on.
final class UiSurfaces {
  /// Creates an empty set of surfaces for [catalog].
  factory(UiCatalog catalog, {UiSchemas? schemas}) = UiSurfaces._;

  new _(this.catalog, {UiSchemas? schemas})
    : schemas = schemas ?? UiSchemas(catalog);

  /// The catalog surfaces are drawn with.
  final UiCatalog catalog;

  /// The schemas messages are validated against.
  final UiSchemas schemas;

  final Map<String, UiSurface> _surfaces = {};

  /// The surfaces by id.
  Map<String, UiSurface> get surfaces => UnmodifiableMapView(_surfaces);

  /// Applies [messages] in order, then checks the tree of every surface
  /// they touched, and returns every problem found. When [atomic] is true
  /// and a problem is more than a warning, the surfaces are put back as
  /// they were. With [replace], a valid `createSurface` for a surface that
  /// exists replaces it, as a delete followed by the create would.
  List<UiProblem> applyAll(
    Iterable<Object?> messages, {
    bool atomic = false,
    bool replace = false,
  }) {
    final saved = atomic ? uiSnapshot(_surfaces, messages) : null;
    final problems = <UiProblem>[];
    final touched = <String>{};
    for (final message in messages) {
      if (uiMessageParts(message)
          case ('createSurface', {'surfaceId': final String id})
          when replace && schemas.message.validate(message).isEmpty) {
        _surfaces.remove(id);
      }
      problems.addAll(apply(message));
      if (uiMessageParts(message)
          case (final kind, {'surfaceId': final String id})
          when kind != 'deleteSurface') {
        touched.add(id);
      }
    }
    problems.addAll([
      for (final id in touched)
        if (_surfaces[id] case final surface?) ...uiTreeProblems(surface),
    ]);
    if (saved != null && problems.any((p) => !p.warning)) {
      uiRestore(_surfaces, saved);
    }
    return problems;
  }

  /// Applies one message and returns the problems that kept it, or part of
  /// it, from applying.
  List<UiProblem> apply(Object? message) {
    final violations = schemas.message.validate(message);
    if (violations.isNotEmpty) {
      return [
        for (final v in violations)
          UiProblem(
            UiProblemCode.validationFailed,
            v.message,
            path: violationPointer(v.path),
          ),
      ];
    }
    return uiApplyMessage(_surfaces, catalog, message);
  }
}
