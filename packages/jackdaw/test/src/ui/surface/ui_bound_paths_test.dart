import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('bound paths cover bindings, calls, templates and formats', () {
    expect(
      uiBoundPaths({
        'text': {'@path': 'name'},
        'checks': [
          {
            '@call': 'required',
            'args': {
              'value': {'@path': '/email'},
            },
          },
        ],
        'children': {'componentId': 'row', 'path': '/items'},
      }, '/form'),
      {'/form/name', '/email', '/items'},
    );
    expect(uiBoundPaths({'text': r'Hi ${/name}'}, ''), {'/'});
  });
}
