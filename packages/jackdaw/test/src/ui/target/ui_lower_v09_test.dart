import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  final sent = <List<Map<String, Object?>>>[];
  final genui = UiTarget.genui(basicCatalog, send: sent.add);

  test('a create becomes create, components and data for genui', () {
    sent.clear();
    expect(
      genui.show([
        {
          'version': 'v1.0',
          'createSurface': {
            'surfaceId': 's',
            'sendDataModel': true,
            'components': [
              {
                'id': 'root',
                'component': 'TextField',
                'label': {
                  '@call': 'formatString',
                  'args': {'value': 'Hi'},
                },
                'value': {'@path': '/name'},
                'placeholder': 'Name',
                'checks': [
                  {
                    'condition': {
                      '@call': 'required',
                      'args': {
                        'value': {'@path': '/name'},
                      },
                    },
                  },
                ],
              },
            ],
            'dataModel': {'name': ''},
          },
        },
      ]),
      isEmpty,
    );
    final messages = sent.single;
    expect(messages.map((m) => m.keys.last), [
      'createSurface',
      'updateComponents',
      'updateDataModel',
    ]);
    expect(messages.every((m) => m['version'] == 'v0.9'), isTrue);
    expect(messages.first['createSurface'], {
      'surfaceId': 's',
      'catalogId':
          'https://a2ui.org/specification/v0_9/catalogs/basic/catalog.json',
      'sendDataModel': true,
    });
    final field =
        ((messages[1]['updateComponents']! as Map)['components']! as List)
            .single;
    expect(field, {
      'id': 'root',
      'component': 'TextField',
      'label': {
        'call': 'formatString',
        'args': {'value': 'Hi'},
        'returnType': 'string',
      },
      'value': {'path': '/name'},
      'checks': [
        {
          'condition': {
            'call': 'required',
            'args': {
              'value': {'path': '/name'},
            },
            'returnType': 'boolean',
          },
          'message': 'This value is not valid.',
        },
      ],
    });
    expect(messages.last['updateDataModel'], {
      'surfaceId': 's',
      'path': '/',
      'value': {'name': ''},
    });
  });
}
