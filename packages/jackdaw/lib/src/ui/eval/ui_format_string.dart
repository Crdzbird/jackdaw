import 'dart:convert';

import 'package:jackdaw/src/ui/eval/ui_expression_parser.dart';

/// [template] with each `${expression}` replaced by the text of its value,
/// found with [evaluate]; `\${` stands for a literal `${`.
String uiFormatString(String template, Object? Function(Object?) evaluate) {
  final out = StringBuffer();
  var at = 0;
  while (at < template.length) {
    if (template.startsWith(r'\${', at)) {
      out.write(r'${');
      at += 3;
      continue;
    }
    if (!template.startsWith(r'${', at)) {
      out.write(template[at]);
      at++;
      continue;
    }
    final parser = UiExpressionParser(template, at + 2);
    final value = evaluate(parser.expression());
    parser.expect('}');
    out.write(uiText(value));
    at = parser.at;
  }
  return out.toString();
}

/// [value] as text: nothing for `null`, whole numbers without a fraction,
/// and lists and objects as JSON.
String uiText(Object? value) => switch (value) {
  null => '',
  final double d when d == d.roundToDouble() && d.isFinite => '${d.toInt()}',
  String() || num() || bool() => '$value',
  _ => jsonEncode(value),
};
