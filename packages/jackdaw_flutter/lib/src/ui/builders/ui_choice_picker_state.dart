part of 'ui_choice_picker.dart';

final class _UiChoicePickerState extends State<UiChoicePicker> {
  String _filter = '';

  UiNode get _node => widget.node;

  bool get _exclusive =>
      _node.component.props['variant'] != 'multipleSelection';

  List<(String, String)> get _options => [
    if (_node.component.props['options'] case final List<Object?> options)
      for (final option in options.whereType<Map<String, Object?>>())
        if (option['value'] case final String value)
          (
            uiText(
              _node.controller.evaluator.evaluate(option['label'], _node.scope),
            ),
            value,
          ),
  ];

  Set<String> get _chosen => switch (_node.value('value')) {
    final List<Object?> values => {for (final v in values) uiText(v)},
    final String value => {value},
    _ => const {},
  };

  void _choose(String value, {required bool on}) {
    final chosen = _chosen;
    _node.write('value', switch ((_exclusive, on)) {
      (true, true) => [value],
      (true, false) => <String>[],
      (false, true) => [...chosen, value],
      (false, false) => [...chosen.where((v) => v != value)],
    });
  }

  void _filtered(String text) {
    setState(() {
      _filter = text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chosen = _chosen;
    final shown = [
      for (final option in _options)
        if (option.$1.toLowerCase().contains(_filter)) option,
    ];
    final label = _node.text('label');
    final messages = _node.checkMessages;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) Text(label),
        if (_node.truth('filterable'))
          TextField(
            decoration: const InputDecoration(hintText: 'Filter'),
            onChanged: _filtered,
          ),
        uiChoiceList(
          chips: _node.component.props['displayStyle'] == 'chips',
          exclusive: _exclusive,
          shown: shown,
          chosen: chosen,
          choose: _choose,
        ),
        if (messages.isNotEmpty)
          Text(
            messages.first,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
