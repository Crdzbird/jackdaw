import 'package:jackdaw/src/ui/eval/ui_host.dart';
import 'package:jackdaw/src/ui/eval/ui_scope.dart';

/// The implementation of a catalog function: it receives the resolved
/// [args], the [scope] of the call, the app's [host] and [evaluate], which
/// evaluates a nested A2UI value, as `formatString` does for placeholders.
typedef UiFunctionBody = Object? Function(
  Map<String, Object?> args,
  UiScope scope,
  UiHost host,
  Object? Function(Object? value) evaluate,
);
