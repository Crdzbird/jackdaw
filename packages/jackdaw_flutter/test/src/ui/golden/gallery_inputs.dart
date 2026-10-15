/// The input components of the gallery.
const List<Map<String, Object?>> galleryInputs = [
  {
    'component': 'TextField',
    'label': 'Email',
    'value': {'@path': '/email'},
  },
  {
    'component': 'CheckBox',
    'label': 'Subscribe',
    'value': {'@path': '/subscribe'},
  },
  {
    'component': 'ChoicePicker',
    'label': 'Size',
    'displayStyle': 'chips',
    'options': [
      {'label': 'Small', 'value': 's'},
      {'label': 'Large', 'value': 'l'},
    ],
    'value': {'@path': '/size'},
  },
  {
    'component': 'Slider',
    'label': 'Volume',
    'max': 10,
    'value': {'@path': '/volume'},
  },
  {
    'component': 'DateTimeInput',
    'label': 'Date',
    'value': {'@path': '/date'},
  },
  {
    'component': 'List',
    'direction': 'horizontal',
    'children': [
      {
        'component': 'Button',
        'variant': 'primary',
        'child': {'component': 'Text', 'text': 'Save'},
        'action': {
          'event': {'name': 'save'},
        },
      },
      {
        'component': 'Button',
        'variant': 'borderless',
        'child': {'component': 'Text', 'text': 'Cancel'},
        'action': {
          'event': {'name': 'cancel'},
        },
      },
    ],
  },
];
