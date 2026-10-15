import 'package:a2ui_core/a2ui_core.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_a2ui/jackdaw_a2ui.dart';
import 'package:test/test.dart';

const String minimal =
    'https://a2ui.org/specification/v0_9/catalogs/minimal/minimal_catalog.json';

const Map<String, Object?> form = {
  'surfaceId': 's',
  'root': {
    'component': 'Column',
    'children': [
      {'component': 'Text', 'text': 'Hello'},
      {
        'component': 'TextField',
        'label': 'Name',
        'value': {'@path': '/name'},
      },
      {
        'component': 'Button',
        'child': {'component': 'Text', 'text': 'Go'},
        'action': {
          'event': {'name': 'go'},
        },
      },
    ],
  },
  'dataModel': {'name': 'Ana'},
};

MessageProcessor<ComponentApi> processor() => MessageProcessor(
  catalogs: [MinimalCatalog()],
  protocolVersion: A2uiProtocolVersion.v0_9,
);

void main() {
  test('a tree from the agent reaches the a2ui_core processor', () async {
    final core = processor();
    final target = A2uiCoreTarget(basicCatalog, core, catalogId: minimal);
    expect(target.schemas.catalog, same(basicCatalog));
    final result = await uiTool(
      target,
    ).invoke(const ToolCallPart(id: 'c', name: 'render_ui', arguments: form));
    expect(result.isError, isFalse);
    final surface = core.groupModel.getSurface('s')!;
    expect(surface.componentsModel.all.map((c) => c.id), contains('root'));
    expect(surface.dataModel.get('/name'), 'Ana');
    expect(target.show(uiTreeMessages(form, basicCatalog)), isEmpty);
    expect(core.groupModel.allSurfaces, hasLength(1));
  });

  test('what a2ui_core rejects comes back as a problem', () {
    final target = A2uiCoreTarget(
      basicCatalog,
      processor(),
      catalogId: minimal,
    );
    final problems = target.show(
      uiTreeMessages({
        'surfaceId': 'c',
        'root': {
          'component': 'Card',
          'child': {'component': 'Text', 'text': 'x'},
        },
      }, basicCatalog),
    );
    expect(problems.single.code, UiProblemCode.validationFailed);
    final unnamed = A2uiCoreTarget(basicCatalog, processor());
    expect(unnamed.show(uiTreeMessages(form, basicCatalog)), isNotEmpty);
  });

  test('actions from a2ui_core become actions for the agent', () {
    final action = uiActionFromA2ui(
      A2uiClientAction(
        name: 'go',
        surfaceId: 's',
        sourceComponentId: 'button1',
        timestamp: DateTime.utc(2026),
        context: {'name': 'Ana'},
      ),
    );
    expect(uiActionMessage(action).text, contains('"context":{"name":"Ana"}'));
  });
}
