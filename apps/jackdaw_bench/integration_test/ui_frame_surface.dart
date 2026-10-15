/// A surface of [count] components: a column of texts, fields, a checkbox,
/// a slider and a button, bound to the data model.
Map<String, Object?> uiFrameSurface(int count) {
  final ids = [for (var i = 0; i < count - 1; i++) 'c$i'];
  Map<String, Object?> component(int i) => switch (i % 5) {
    0 => {
      'id': 'c$i',
      'component': 'Text',
      'text': {'@path': '/t$i'},
    },
    1 => {
      'id': 'c$i',
      'component': 'TextField',
      'label': 'Field $i',
      'value': {'@path': '/t$i'},
    },
    2 => {
      'id': 'c$i',
      'component': 'CheckBox',
      'label': 'Box $i',
      'value': {'@path': '/b$i'},
    },
    3 => {
      'id': 'c$i',
      'component': 'Slider',
      'max': 10,
      'value': {'@path': '/n$i'},
    },
    _ => {'id': 'c$i', 'component': 'Divider'},
  };
  return {
    'version': 'v1.0',
    'createSurface': {
      'surfaceId': 'bench',
      'components': [
        {'id': 'root', 'component': 'Column', 'children': ids},
        for (var i = 0; i < count - 1; i++) component(i),
      ],
      'dataModel': {for (var i = 0; i < count; i++) 't$i': 'Value $i'},
    },
  };
}
