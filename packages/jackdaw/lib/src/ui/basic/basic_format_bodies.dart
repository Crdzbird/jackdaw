import 'package:jackdaw/src/ui/basic/basic_date_text.dart';
import 'package:jackdaw/src/ui/eval/ui_eval_exception.dart';
import 'package:jackdaw/src/ui/eval/ui_format_string.dart';
import 'package:jackdaw/src/ui/eval/ui_function_body.dart';
import 'package:jackdaw/src/ui/eval/ui_number_text.dart';

const Map<String, String> _symbols = {
  'USD': r'$',
  'EUR': '\u20AC',
  'GBP': '\u00A3',
  'JPY': '\u00A5',
  'INR': '\u20B9',
};

const Set<String> _whole = {'JPY', 'KRW', 'VND', 'CLP', 'ISK', 'PYG'};

num _number(Object? value, String function) => switch (value) {
  final num n => n,
  _ =>
    num.tryParse(uiText(value).trim()) ??
        (throw UiEvalException('EXECUTION_ERROR', '$function needs a number.')),
};

int? _int(Object? value) => value is num ? value.toInt() : null;

String _currency(Map<String, Object?> args) {
  final code = uiText(args['currency']).toUpperCase();
  final amount = _number(args['value'], 'formatCurrency');
  final text = uiNumberText(
    amount.abs(),
    decimals: _int(args['decimals']) ?? (_whole.contains(code) ? 0 : 2),
    grouping: args['grouping'] != false,
  );
  final sign = amount < 0 ? '-' : '';
  return switch (_symbols[code]) {
    final symbol? => '$sign$symbol$text',
    null => '$sign$code\u00A0$text',
  };
}

/// The basic catalog's functions that build text, in English.
final Map<String, UiFunctionBody> basicFormatBodies = {
  'formatString': (args, _, _, evaluate) =>
      uiFormatString(uiText(args['value']), evaluate),
  'formatNumber': (args, _, _, _) => uiNumberText(
    _number(args['value'], 'formatNumber'),
    decimals: _int(args['decimals']),
    grouping: args['grouping'] != false,
  ),
  'formatCurrency': (args, _, _, _) => _currency(args),
  'formatDate': (args, _, _, _) =>
      basicDateText(args['value'], uiText(args['format'])),
  'pluralize': (args, _, _, _) {
    final count = _number(args['value'], 'pluralize');
    final category = count == 1 ? 'one' : 'other';
    return uiText(args[category] ?? args['other']);
  },
};
