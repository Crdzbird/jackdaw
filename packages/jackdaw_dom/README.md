# jackdaw_dom

Draws jackdaw's A2UI surfaces in a web page as plain HTML elements, with
no framework. Pre-release. Web only.

```dart
final ui = UiDomController(basicCatalog);
web.document.head!.append(web.HTMLStyleElement()..textContent = uiDomStyles);
UiDomView(controller: ui, surfaceId: 'main', host: web.document.body!);
ui.applyAll(messages);
```

- Each component is built once as the element it is: a `p`, an `input`,
  a `label`, an `hr`. A data write goes through the same index of paths
  as jackdaw_flutter and sets one `textContent` or `value`; there is no
  virtual tree and nothing is compared.
- Messages are validated with jackdaw's schemas before they apply, and
  bindings, checks and functions are jackdaw's own, so a surface behaves
  the same here as in Flutter.
- Inputs write back to the data model, buttons run their actions, and a
  surface is built again only when its components change.
- The elements carry `jd-` classes; `uiDomStyles` is a starting point to
  extend or replace.

Builders so far: Text, Row, Column, List, Card, Divider, Button,
TextField, CheckBox and Slider. A component without a builder draws an
empty element.
