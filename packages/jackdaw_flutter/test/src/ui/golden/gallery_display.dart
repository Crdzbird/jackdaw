/// The display and layout components of the gallery.
const List<Map<String, Object?>> galleryDisplay = [
  {'component': 'Text', 'text': 'Heading text', 'variant': 'body'},
  {'component': 'Text', 'text': 'A caption', 'variant': 'caption'},
  {
    'component': 'Row',
    'children': [
      {'component': 'Icon', 'name': 'home'},
      {'component': 'Icon', 'name': 'star'},
      {
        'component': 'Image',
        'url': 'https://img.example/a.png',
        'variant': 'icon',
      },
    ],
  },
  {'component': 'Video', 'url': 'https://media.example/v.mp4'},
  {
    'component': 'AudioPlayer',
    'url': 'https://media.example/a.mp3',
    'description': 'A song',
  },
  {
    'component': 'Card',
    'child': {'component': 'Text', 'text': 'Inside a card'},
  },
  {'component': 'Divider'},
  {
    'component': 'Tabs',
    'tabs': [
      {
        'title': 'First',
        'child': {'component': 'Text', 'text': 'First tab'},
      },
      {
        'title': 'Second',
        'child': {'component': 'Text', 'text': 'Second tab'},
      },
    ],
  },
  {
    'component': 'Modal',
    'trigger': {
      'component': 'Button',
      'child': {'component': 'Text', 'text': 'Open'},
      'action': {
        'event': {'name': 'open'},
      },
    },
    'content': {'component': 'Text', 'text': 'Dialog'},
  },
];
