/// A form with a bound text field and a check, as one message.
const Map<String, Object?> formSurface = {
  'version': 'v1.0',
  'createSurface': {
    'surfaceId': 'signup',
    'catalogId':
        'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json',
    'components': [
      {
        'id': 'root',
        'component': 'Column',
        'children': ['email', 'send'],
      },
      {
        'id': 'email',
        'component': 'TextField',
        'label': 'Email',
        'value': {'@path': '/form/email'},
        'checks': [
          {
            'condition': {
              '@call': 'email',
              'args': {
                'value': {'@path': '/form/email'},
              },
            },
            'message': 'Enter an email address.',
          },
        ],
      },
      {
        'id': 'send',
        'component': 'Button',
        'child': 'sendLabel',
        'action': {
          'event': {
            'name': 'signup',
            'context': {
              'email': {'@path': '/form/email'},
            },
          },
        },
      },
      {
        'id': 'sendLabel',
        'component': 'Text',
        'text': {
          '@call': 'formatString',
          'args': {'value': r'Send to ${/form/email}'},
        },
      },
    ],
    'dataModel': {
      'form': {'email': ''},
    },
  },
};

/// A list repeated over the data model, then a data update.
const List<Map<String, Object?>> listMessages = [
  {
    'version': 'v1.0',
    'updateComponents': {
      'surfaceId': 'birds',
      'components': [
        {
          'id': 'root',
          'component': 'List',
          'children': {'componentId': 'bird', 'path': '/birds'},
          'direction': 'horizontal',
        },
        {
          'id': 'bird',
          'component': 'Image',
          'url': {'@path': 'url'},
          'accessibility': {'label': 'A bird'},
        },
      ],
    },
  },
  {
    'version': 'v1.0',
    'updateDataModel': {
      'surfaceId': 'birds',
      'path': '/birds',
      'value': <Object?>[],
    },
  },
  {
    'version': 'v1.0',
    'deleteSurface': {'surfaceId': 'birds'},
  },
];
