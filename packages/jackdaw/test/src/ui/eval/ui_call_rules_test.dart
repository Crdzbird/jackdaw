import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  final scope = UiScope(UiDataModel());
  final ui = UiEvaluator(basicCatalog);

  test('unknown, agent-only and gesture-only calls are refused', () {
    Matcher refused(String code) =>
        throwsA(isA<UiEvalException>().having((e) => e.code, 'code', code));
    expect(
      () => ui.evaluate({'@call': 'shout'}, scope),
      refused('EXPRESSION_ERROR'),
    );
    expect(
      () => ui.evaluate({'@call': 'not', 'args': 'x'}, scope),
      refused('EXPRESSION_ERROR'),
    );
    final open = {
      '@call': 'openUrl',
      'args': {'url': 'https://a.example'},
    };
    expect(() => ui.evaluate(open, scope), refused('EXPRESSION_ERROR'));
    final opened = <Uri>[];
    final allowed = UiEvaluator(
      basicCatalog,
      host: UiHost(
        allowUrl: (url) => url.host == 'a.example',
        openUrl: opened.add,
      ),
    )..evaluate(open, scope.activated());
    expect(opened.single.host, 'a.example');
    for (final url in ['javascript:alert(1)', 'https://b.example', '::']) {
      expect(
        () => allowed.evaluate({
          '@call': 'openUrl',
          'args': {'url': url},
        }, scope.activated()),
        refused('EXECUTION_ERROR'),
      );
    }
    final agentOnly = UiEvaluator(
      const UiCatalog(
        id: 'c',
        components: [],
        functions: [
          UiFunctionDefinition(
            name: 'not',
            description: 'Agent only.',
            args: ObjectSchema(properties: {}),
            returns: UiReturnType.boolean,
            callers: UiCaller.agentOnly,
          ),
        ],
      ),
    );
    expect(
      () => agentOnly.evaluate({'@call': 'not'}, scope),
      refused('EXPRESSION_ERROR'),
    );
  });

  test('failures read as their code and message', () {
    expect(
      '${const UiEvalException('EXECUTION_ERROR', 'It broke.')}',
      'EXECUTION_ERROR: It broke.',
    );
  });
}
