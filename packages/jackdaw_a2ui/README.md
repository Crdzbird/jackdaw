# jackdaw_a2ui

A2UI renderers for [jackdaw](../jackdaw) agents.

jackdaw agents build UI with the A2UI v1.0 basic catalog. Where that UI
goes is a `UiTarget`: jackdaw's own surfaces drawn by `jackdaw_flutter`,
genui through `UiTarget.genui`, any renderer that reads A2UI through
`UiTarget.forward`, or one an app writes itself. This package adds
`A2uiCoreTarget`, which applies the UI to an
[a2ui_core](https://pub.dev/packages/a2ui_core) `MessageProcessor`, so
any renderer built on a2ui_core draws it.

```dart
final processor = MessageProcessor(
  catalogs: [myCatalog],
  protocolVersion: A2uiProtocolVersion.v0_9,
  onAction: (action) => chat.sendMessage(
    uiActionMessage(uiActionFromA2ui(action)),
  ),
);
final target = A2uiCoreTarget(basicCatalog, processor, catalogId: myCatalog.id);
final agent = Agent(model: model, tools: [uiTool(target)], store: store);
```

Messages are checked with jackdaw's rules before they reach the
processor, and what a2ui_core rejects comes back to the model as
problems. a2ui_core 0.2 reads A2UI v0.9, so messages are lowered first:
props new in v1.0, such as placeholders, slider steps and video posters,
are dropped.
