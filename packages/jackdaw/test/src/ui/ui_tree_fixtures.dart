/// The sign-up form written as a tree.
const Map<String, Object?> signupTree = {
  'surfaceId': 'signup',
  'root': {
    'component': 'Column',
    'children': [
      {
        'component': 'TextField',
        'label': 'Email',
        'value': {'@path': '/form/email'},
      },
      {
        'component': 'Button',
        'child': {'component': 'Text', 'text': 'Send'},
        'action': {
          'event': {'name': 'signup'},
        },
      },
      {
        'component': 'Tabs',
        'tabs': [
          {
            'title': 'More',
            'child': {
              'component': 'List',
              'children': {
                'template': {
                  'component': 'Text',
                  'text': {'@path': 'name'},
                },
                'path': '/items',
              },
            },
          },
        ],
      },
    ],
  },
  'dataModel': {
    'form': {'email': ''},
    'items': <Object?>[],
  },
};
