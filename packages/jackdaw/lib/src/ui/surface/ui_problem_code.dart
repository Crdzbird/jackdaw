/// The A2UI v1.0 error codes a renderer reports to the agent.
enum UiProblemCode {
  /// A message or component does not match the protocol or the catalog.
  validationFailed('VALIDATION_FAILED'),

  /// A component is placed in a parent its catalog entry does not allow.
  unallowedParent('UNALLOWED_PARENT'),

  /// A container holds a child its catalog entry does not allow.
  unallowedChild('UNALLOWED_CHILD'),

  /// The component tree is broken, for example by a cycle.
  integrityError('INTEGRITY_ERROR');

  new(this.wire);

  /// The code as written in an A2UI `error` message.
  final String wire;
}
