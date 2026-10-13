import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_mcp/jackdaw_mcp.dart';
import 'package:test/test.dart';

import 'support/fake_session.dart';

void main() {
  test('names are prefixed, cleaned and approval is required', () async {
    final session = FakeSession([
      {
        'name': 'search.query',
        'description': 'x' * 2000,
        'inputSchema': {
          'type': 'object',
          'properties': {
            'q': {'type': 'string'},
          },
        },
      },
      {'name': 'fetch', 'inputSchema': 'bogus'},
      {'description': 'no name'},
    ]);
    final tools = await mcpTools(session, maxOutputChars: 50);
    expect(tools.map((t) => t.name), [
      'web_search_search_query',
      'web_search_fetch',
    ]);
    expect(tools.every((t) => t.requiresApproval && !t.idempotent), isTrue);
    expect(
      tools.first.description,
      endsWith('(tool from MCP server web search)'),
    );
    expect(
      tools.first.description.length,
      1024 + ' (tool from MCP server web search)'.length,
    );
    expect(tools.last.input.additionalProperties, isTrue);
    final result = await tools.first.invoke(
      const ToolCallPart(
        id: '1',
        name: 'web_search_search_query',
        arguments: {'q': 'kestrel'},
      ),
    );
    expect(session.calls.single.$1, 'search.query');
    expect(session.calls.single.$2, {'q': 'kestrel'});
    final output = result.output! as Map;
    expect(output['note'], mcpOutputNote);
    final text = ((output['content'] as List).single as Map)['text'] as String;
    expect(text, endsWith('[truncated]'));
    expect(text.length, 50 + ' [truncated]'.length);
  });

  test('clashing names fail and long names are cut to 64', () async {
    await expectLater(
      mcpTools(
        FakeSession([
          {'name': 'a.b'},
          {'name': 'a_b'},
        ]),
      ),
      throwsStateError,
    );
    final tools = await mcpTools(
      FakeSession([
        {'name': 'n' * 100},
      ]),
      prefix: 'p',
    );
    expect(tools.single.name.length, 64);
  });

  test('resource content is kept and unknown parts are labelled', () {
    final output = mcpOutput('s', {
      'content': [
        {
          'type': 'resource',
          'resource': {'uri': 'file:///a', 'text': 'body'},
        },
        {
          'type': 'resource',
          'resource': {'uri': 'file:///b', 'blob': 'AAAA'},
        },
        {'type': 'resource_link', 'uri': 'file:///c', 'name': 'c'},
        {'nothing': true},
        'not a map',
      ],
    }, 100);
    expect(output['content'], [
      {'type': 'resource', 'uri': 'file:///a', 'text': 'body'},
      {'type': 'resource', 'uri': 'file:///b'},
      {'type': 'resource_link', 'uri': 'file:///c', 'name': 'c'},
      {'type': 'unknown'},
    ]);
    expect(mcpOutput('s', {}, 10)['content'], isEmpty);
  });
}
