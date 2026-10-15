import 'package:jackdaw/src/ui/surface/json_pointer.dart';
import 'package:jackdaw/src/ui/surface/ui_data_model.dart';

/// Where a value is evaluated: the surface data, the path relative paths
/// start from, the item index inside a list template, and whether a user
/// gesture started the evaluation.
final class UiScope {
  /// Creates the root scope of [data].
  const factory(
    UiDataModel data, {
    String path,
    int? index,
    bool userActivation,
  }) = UiScope._;

  const new _(
    this.data, {
    this.path = '/',
    this.index,
    this.userActivation = false,
  });

  /// The data bindings read.
  final UiDataModel data;

  /// The JSON Pointer relative paths are resolved against.
  final String path;

  /// The index of the list item being drawn, inside a template only.
  final int? index;

  /// Whether a user gesture, such as a press, started the evaluation.
  final bool userActivation;

  /// The scope of item [index] of the list at [list], relative to this one.
  UiScope item(String list, int index) => UiScope(
    data,
    path: '${resolveJsonPointer(list, path)}/$index',
    index: index,
    userActivation: userActivation,
  );

  /// This scope, started by a user gesture.
  UiScope activated() =>
      UiScope(data, path: path, index: index, userActivation: true);

  /// The value at [pointer], absolute or relative to [path].
  Object? read(String pointer) => data.read(resolveJsonPointer(pointer, path));
}
