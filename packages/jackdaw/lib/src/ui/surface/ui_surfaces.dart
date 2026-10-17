import 'dart:collection';

import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/schema/schema_violation.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/schema/ui_catalog_schemas.dart';
import 'package:jackdaw/src/ui/schema/ui_schemas.dart';
import 'package:jackdaw/src/ui/surface/ui_apply_message.dart';
import 'package:jackdaw/src/ui/surface/ui_message_parts.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/surface/ui_surface.dart';
import 'package:jackdaw/src/ui/surface/ui_surface_snapshot.dart';
import 'package:jackdaw/src/ui/surface/ui_tree_problems.dart';
import 'package:jackdaw/src/ui/surface/ui_violation_problems.dart';
import 'package:jackdaw/src/ui/target/ui_target.dart';

/// The surfaces built from A2UI v1.0 messages for one catalog. Each
/// message is validated before it is applied; one that does not match the
/// schemas changes nothing. Problems come back as A2UI `error` messages.
final class UiSurfaces implements UiTarget {
  /// Creates an empty set of surfaces for [catalog].
  factory(UiCatalog catalog, {UiSchemas? schemas}) = UiSurfaces._;

  new _(this.catalog, {UiSchemas? schemas})
    : schemas = schemas ?? catalog.schemas;

  /// The catalog surfaces are drawn with.
  final UiCatalog catalog;

  /// The schemas messages are validated against.
  @override
  final UiSchemas schemas;

  final Map<String, UiSurface> _surfaces = {};

  /// The surfaces by id.
  Map<String, UiSurface> get surfaces => UnmodifiableMapView(_surfaces);

  @override
  List<UiProblem> show(List<Object?> messages, {bool partial = false}) =>
      applyAll(messages, atomic: !partial, replace: true);

  /// Applies [messages] in order, then checks the tree of every surface
  /// whose components they changed, and returns every problem found. When
  /// [atomic] is true and a problem is more than a warning, the surfaces
  /// are put back as they were. With [replace], a valid `createSurface`
  /// for a surface that exists replaces it, like a delete and a create.
  ///
  /// With [trusted], the messages skip the schema check and the tree check.
  /// Pass it only for messages from a source the app fully trusts, such as
  /// its own server, never for a model's or another agent's: a malformed
  /// message is then not caught, and may throw or draw wrongly.
  List<UiProblem> applyAll(
    Iterable<Object?> messages, {
    bool atomic = false,
    bool replace = false,
    bool trusted = false,
  }) {
    final saved = atomic ? uiSnapshot(_surfaces, messages) : null;
    final problems = <UiProblem>[];
    final touched = <String>{};
    for (final message in messages) {
      final violations = trusted
          ? const <SchemaViolation>[]
          : schemas.message.check(message);
      if (uiMessageParts(message)
          case ('createSurface', {'surfaceId': final String id})
          when replace && violations.isEmpty) {
        _surfaces.remove(id);
      }
      problems.addAll(_apply(message, violations));
      if (uiMessageParts(message) case (
        'createSurface' || 'updateComponents',
        {'surfaceId': final String id},
      )) {
        touched.add(id);
      }
    }
    problems.addAll([
      for (final id in trusted ? const <String>{} : touched)
        if (_surfaces[id] case final surface?) ...uiTreeProblems(surface),
    ]);
    if (saved != null && problems.any((p) => !p.warning)) {
      uiRestore(_surfaces, saved);
    }
    return problems;
  }

  /// Applies one message and returns the problems that kept it, or part of
  /// it, from applying.
  List<UiProblem> apply(Object? message) =>
      _apply(message, schemas.message.check(message));

  List<UiProblem> _apply(Object? message, List<SchemaViolation> violations) =>
      violations.isEmpty
      ? uiApplyMessage(_surfaces, catalog, message)
      : uiViolationProblems(violations);
}
