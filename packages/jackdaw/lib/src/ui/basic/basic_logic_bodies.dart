import 'package:jackdaw/src/ui/eval/ui_eval_exception.dart';
import 'package:jackdaw/src/ui/eval/ui_format_string.dart';
import 'package:jackdaw/src/ui/eval/ui_function_body.dart';
import 'package:jackdaw/src/ui/eval/ui_host.dart';
import 'package:jackdaw/src/ui/eval/ui_truth.dart';

List<Object?> _values(Map<String, Object?> args) => switch (args['values']) {
  final List<Object?> values => values,
  _ => const [],
};

Object? _open(Map<String, Object?> args, UiHost host) {
  final url = Uri.tryParse(uiText(args['url']));
  if (url == null || (url.scheme != 'https' && url.scheme != 'http')) {
    throw const UiEvalException(
      'EXECUTION_ERROR',
      'Only http and https links can be opened.',
    );
  }
  if (host.allowUrl?.call(url) != true) {
    throw UiEvalException('EXECUTION_ERROR', 'The app does not open $url.');
  }
  host.openUrl?.call(url);
  return null;
}

/// The basic catalog's link and logic functions. A link opens only when
/// it is http or https and the [UiHost] allows it.
final Map<String, UiFunctionBody> basicLogicBodies = {
  'openUrl': (args, _, host, _) => _open(args, host),
  'and': (args, _, _, _) => _values(args).every(uiTruth),
  'or': (args, _, _, _) => _values(args).any(uiTruth),
  'not': (args, _, _, _) => !uiTruth(args['value']),
};
