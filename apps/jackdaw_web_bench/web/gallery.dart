import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:web/web.dart' as web;

/// Every component of the basic catalog drawn by jackdaw_dom, to look at.
void main() {
  web.document.head!.append(web.HTMLStyleElement()..textContent = uiDomStyles);
  Map<String, Object?> c(String id, String type, Map<String, Object?> p) => {
    'id': id,
    'component': type,
    ...p,
  };
  final ui = UiDomController(basicCatalog)
    ..applyAll([
      {
        'version': 'v1.0',
        'createSurface': {
          'surfaceId': 'g',
          'components': [
            c('root', 'Column', {
              'children': [
                'title',
                'icons',
                'card',
                'tabs',
                'pick',
                'chips',
                'when',
                'slide',
                'field',
                'box',
                'go',
                'line',
                'modal',
              ],
            }),
            c('title', 'Text', {'text': 'Gallery'}),
            c('icons', 'Row', {
              'children': ['i1', 'i2', 'i3', 'i4'],
            }),
            c('i1', 'Icon', {'name': 'home'}),
            c('i2', 'Icon', {'name': 'favorite'}),
            c('i3', 'Icon', {'name': 'settings'}),
            c('i4', 'Icon', {'name': 'search'}),
            c('card', 'Card', {'child': 'inside'}),
            c('inside', 'Text', {
              'text': 'Inside a card',
              'variant': 'caption',
            }),
            c('tabs', 'Tabs', {
              'tabs': [
                {'title': 'First', 'child': 't1'},
                {'title': 'Second', 'child': 't2'},
              ],
            }),
            c('t1', 'Text', {'text': 'First tab'}),
            c('t2', 'Text', {'text': 'Second tab'}),
            c('pick', 'ChoicePicker', {
              'label': 'One color',
              'options': [
                {'label': 'Red', 'value': 'red'},
                {'label': 'Blue', 'value': 'blue'},
              ],
              'value': {'@path': '/color'},
            }),
            c('chips', 'ChoicePicker', {
              'label': 'Toppings',
              'variant': 'multipleSelection',
              'displayStyle': 'chips',
              'options': [
                {'label': 'Cheese', 'value': 'cheese'},
                {'label': 'Olives', 'value': 'olives'},
              ],
              'value': {'@path': '/toppings'},
            }),
            c('when', 'DateTimeInput', {
              'label': 'When',
              'value': {'@path': '/when'},
            }),
            c('slide', 'Slider', {
              'label': 'Level',
              'max': 10,
              'value': {'@path': '/level'},
            }),
            c('field', 'TextField', {
              'label': 'Name',
              'value': {'@path': '/name'},
            }),
            c('box', 'CheckBox', {
              'label': 'Agree',
              'value': {'@path': '/ok'},
            }),
            c('go', 'Button', {
              'child': 'go_text',
              'action': {
                'event': {'name': 'go'},
              },
            }),
            c('go_text', 'Text', {'text': 'Go'}),
            c('line', 'Divider', <String, Object?>{}),
            c('modal', 'Modal', {'trigger': 'open', 'content': 'body'}),
            c('open', 'Text', {'text': 'Open a dialog'}),
            c('body', 'Text', {'text': 'In the dialog'}),
          ],
          'dataModel': {
            'color': 'red',
            'toppings': ['cheese'],
            'when': '2026-10-16',
            'level': 4,
            'name': 'Ada',
            'ok': true,
          },
        },
      },
    ]);
  UiDomView(controller: ui, surfaceId: 'g', host: web.document.body!);
}
