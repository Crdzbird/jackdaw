import 'package:jackdaw/src/ui/schema/ui_format.dart';

/// How to write UI as a tree, at the start of the catalog guide.
const String uiTreeIntro =
    'Write one JSON object for the screen: a surfaceId, the root component '
    'and the dataModel the components read. A component is '
    '{"component": "Name", ...props}. Containers hold their children '
    'inside them: children is a list of components and child is one '
    'component. A value is a literal, {"@path": "/a/b"} to read the data '
    'model, or {"@call": "name", "args": {...}} to call a function.';

/// How to write UI as A2UI messages, at the start of the catalog guide.
const String uiMessagesIntro =
    'Write A2UI v1.0 messages as a JSON list. A screen is usually one '
    'createSurface message with every component and the initial '
    'dataModel. Each component has an id and a component name; the top '
    'one has the id root and children are listed by id. A value is a '
    'literal, {"@path": "/a/b"} to read the data model, or {"@call": '
    '"name", "args": {...}} to call a function.';

/// A small screen in the basic catalog in [format], shown to the model as
/// an example: a name field and a button that sends it.
String uiGuideExample(UiFormat format) => switch (format) {
  UiFormat.tree =>
    'Example, a name field and a button that sends it:\n'
        '{"surfaceId": "greet", "root": {"component": "Column", '
        '"children": [{"component": "TextField", "label": "Name", '
        '"value": {"@path": "/name"}}, {"component": "Button", "child": '
        '{"component": "Text", "text": "Say hi"}, "action": {"event": '
        '{"name": "greet", "context": {"name": {"@path": "/name"}}}}}]}, '
        '"dataModel": {"name": ""}}',
  UiFormat.messages =>
    'Example, a name field and a button that sends it:\n'
        '[{"version": "v1.0", "createSurface": {"surfaceId": "greet", '
        '"components": [ '
        '{"id": "root", "component": "Column", "children": ["name", "go"]}, '
        '{"id": "name", "component": "TextField", "label": "Name", '
        '"value": {"@path": "/name"}}, '
        '{"id": "go", "component": "Button", "child": "goText", '
        '"action": {"event": {"name": "greet", '
        '"context": {"name": {"@path": "/name"}}}}}, '
        '{"id": "goText", "component": "Text", "text": "Say hi"}], '
        '"dataModel": {"name": ""}}}]',
};
