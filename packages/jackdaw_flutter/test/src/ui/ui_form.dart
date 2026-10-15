/// A sign-up form: a bound email field with a check and a button that
/// sends it.
const Map<String, Object?> signupForm = {
  'version': 'v1.0',
  'createSurface': {
    'surfaceId': 'signup',
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
        'variant': 'primary',
        'child': 'sendLabel',
        'action': {
          'event': {
            'name': 'signup',
            'context': {
              'email': {'@path': '/form/email'},
            },
          },
        },
        'checks': [
          {
            'condition': {
              '@call': 'email',
              'args': {
                'value': {'@path': '/form/email'},
              },
            },
          },
        ],
      },
      {'id': 'sendLabel', 'component': 'Text', 'text': 'Sign up'},
    ],
    'dataModel': {
      'form': {'email': ''},
    },
  },
};
