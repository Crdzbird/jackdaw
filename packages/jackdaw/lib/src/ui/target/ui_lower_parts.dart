import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/catalog/ui_return_type.dart';

const Set<String> _newInV10 = {'placeholder', 'steps', 'posterUrl'};

/// [component] written for A2UI v0.9: checks with a message, events
/// without a user message, and no props new in v1.0.
Map<String, Object?> uiLowerComponentV09(
  Map<String, Object?> component,
  UiCatalog c,
) => {
  for (final MapEntry(:key, :value) in component.entries)
    if (!_newInV10.contains(key))
      key: switch (key) {
        'checks' => [
          if (value case final List<Object?> rules)
            for (final rule in rules.whereType<Map<String, Object?>>())
              {
                'condition': uiLowerValueV09(rule['condition'], c),
                'message': rule['message'] ?? 'This value is not valid.',
              },
        ],
        'action' => switch (value) {
          {'event': final Map<String, Object?> event} => {
            'event': {
              for (final MapEntry(:key, :value) in event.entries)
                if (key != 'userMessage') key: uiLowerValueV09(value, c),
            },
          },
          _ => uiLowerValueV09(value, c),
        },
        _ => uiLowerValueV09(value, c),
      },
};

/// The dynamic value [value] written for A2UI v0.9: bindings and calls
/// without the `@` prefix, calls with their return type, and escaped `@@`
/// keys unescaped.
Object? uiLowerValueV09(Object? value, UiCatalog c) => switch (value) {
  {'@call': final String name} && final Map<Object?, Object?> call => {
    'call': name,
    if (call['args'] case final Object args) 'args': uiLowerValueV09(args, c),
    'returnType': switch (c.function(name)?.returns) {
      UiReturnType.validationResult || null => 'boolean',
      final returns => returns.wire,
    },
  },
  {'@path': final Object path} => {'path': path},
  Map() => {
    for (final MapEntry(:key, :value) in value.entries)
      '$key'.startsWith('@@') ? '$key'.substring(1) : '$key': uiLowerValueV09(
        value,
        c,
      ),
  },
  List() => [for (final item in value) uiLowerValueV09(item, c)],
  _ => value,
};
