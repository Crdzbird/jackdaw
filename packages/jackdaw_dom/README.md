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

All 18 components of the basic catalog have a builder, and each uses the
browser's own element where there is one: `img`, `video` and `audio`,
loaded only from hosts the app allows; tab buttons with their roles; a
`dialog` for a Modal; radio buttons or checkboxes, as chips when asked,
for a ChoicePicker; and the date, time or date and time input for a
DateTimeInput. Icons are inline SVG, from paths converted from the
Material Icons font that ships with Flutter (by Google, CC BY 4.0; see
NOTICE). A component without a builder draws an empty element.
