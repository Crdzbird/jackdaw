/// Whether [value] counts as true where A2UI expects a boolean: `true`, or
/// a validation result whose `valid` is true.
bool uiTruth(Object? value) =>
    value == true || (value is Map && value['valid'] == true);
