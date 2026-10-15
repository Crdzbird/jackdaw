/// [value] as English text, with [decimals] digits after the point when
/// set, up to three otherwise, and commas between thousands when
/// [grouping] is true.
String uiNumberText(num value, {int? decimals, bool grouping = true}) {
  final fixed = decimals != null
      ? value.toStringAsFixed(decimals.clamp(0, 20))
      : _shortest(value);
  final negative = fixed.startsWith('-') && fixed.contains(RegExp('[1-9]'));
  final digits = fixed.replaceFirst('-', '');
  final dot = digits.indexOf('.');
  final whole = dot < 0 ? digits : digits.substring(0, dot);
  final fraction = dot < 0 ? '' : digits.substring(dot);
  final grouped = grouping
      ? whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')
      : whole;
  return '${negative ? '-' : ''}$grouped$fraction';
}

String _shortest(num value) => value == value.roundToDouble()
    ? '${value.round()}'
    : value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
