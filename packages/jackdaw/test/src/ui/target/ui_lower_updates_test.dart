import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('updates, deletes, actions and escapes are lowered too', () {
    final lowered = uiLowerToV09([
      {
        'version': 'v1.0',
        'updateComponents': {
          'surfaceId': 's',
          'components': [
            {
              'id': 'b',
              'component': 'Button',
              'child': 'l',
              'action': {
                'event': {
                  'name': 'go',
                  'userMessage': 'Going',
                  'context': {'@@raw': 1},
                },
              },
            },
            {
              'id': 'l',
              'component': 'Slider',
              'max': 3,
              'value': 1,
              'steps': 3,
              'action': {
                'functionCall': {
                  '@call': 'openUrl',
                  'args': {'url': 'https://a.example'},
                },
              },
            },
            {
              'id': 'm',
              'component': 'Text',
              'text': {'@call': 'mystery'},
            },
          ],
        },
      },
      {
        'version': 'v1.0',
        'updateDataModel': {'surfaceId': 's', 'path': '/a', 'value': null},
      },
      {
        'version': 'v1.0',
        'deleteSurface': {'surfaceId': 's'},
      },
      {'version': 'v1.0'},
      {
        'version': 'v1.0',
        'createSurface': {'surfaceId': 'c', 'catalogId': 'mine'},
      },
    ], basicCatalog);
    final components =
        (lowered[0]['updateComponents']! as Map)['components']! as List;
    expect((components[0]! as Map)['action'], {
      'event': {
        'name': 'go',
        'context': {'@raw': 1},
      },
    });
    expect((components[1]! as Map).containsKey('steps'), isFalse);
    expect(((components[1]! as Map)['action']! as Map)['functionCall'], {
      'call': 'openUrl',
      'args': {'url': 'https://a.example'},
      'returnType': 'void',
    });
    expect((components[2]! as Map)['text'], {
      'call': 'mystery',
      'returnType': 'boolean',
    });
    expect(lowered[1]['updateDataModel'], {'surfaceId': 's', 'path': '/a'});
    expect(lowered[2], {
      'version': 'v0.9',
      'deleteSurface': {'surfaceId': 's'},
    });
    expect(lowered, hasLength(4));
    expect((lowered[3]['createSurface']! as Map)['catalogId'], 'mine');
  });
}
