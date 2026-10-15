import 'package:jackdaw/src/ui/eval/ui_format_string.dart';
import 'package:jackdaw/src/ui/eval/ui_function_body.dart';

Map<String, Object?> _result(bool valid) => {'valid': valid};

final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

num? _number(Object? value) =>
    value is num ? value : num.tryParse(uiText(value).trim());

bool _within(num value, Map<String, Object?> args) =>
    value >= (args['min'] as num? ?? double.negativeInfinity) &&
    value <= (args['max'] as num? ?? double.infinity);

/// The basic catalog's validation functions; each returns a validation
/// result whose `valid` says whether the value passed.
final Map<String, UiFunctionBody> basicCheckBodies = {
  'required': (args, _, _, _) => _result(switch (args['value']) {
    null || '' => false,
    final List<Object?> list => list.isNotEmpty,
    _ => true,
  }),
  'regex': (args, _, _, _) {
    try {
      final pattern = RegExp(uiText(args['pattern']));
      return _result(pattern.hasMatch(uiText(args['value'])));
    } on FormatException {
      return _result(false);
    }
  },
  'length': (args, _, _, _) =>
      _result(_within(uiText(args['value']).runes.length, args)),
  'numeric': (args, _, _, _) => _result(switch (_number(args['value'])) {
    final num value => _within(value, args),
    null => false,
  }),
  'email': (args, _, _, _) => _result(_email.hasMatch(uiText(args['value']))),
};
