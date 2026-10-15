/// What a catalog function returns, as A2UI v1.0 names it.
enum UiReturnType {
  /// A string.
  string('string'),

  /// A number.
  number('number'),

  /// A boolean.
  boolean('boolean'),

  /// A list.
  array('array'),

  /// An object.
  object('object'),

  /// Any value.
  any('any'),

  /// Nothing; the function is called for its effect.
  none('void'),

  /// A validation result with `valid`, `code`, `message` and `severity`.
  validationResult('validationResult');

  new(this.wire);

  /// The name used in catalog documents.
  final String wire;
}
