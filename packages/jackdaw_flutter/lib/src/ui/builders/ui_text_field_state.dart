part of 'ui_text_field.dart';

final class _UiTextFieldState extends State<UiTextField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.node.text('value') ?? '',
  );
  bool _edited = false;

  @override
  void didUpdateWidget(UiTextField old) {
    super.didUpdateWidget(old);
    final value = widget.node.text('value') ?? '';
    if (widget.node.pointer('value') != null && value != _text.text) {
      _text.text = value;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _edited = true;
    widget.node.write('value', text);
    if (widget.node.pointer('value') == null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final variant = node.component.props['variant'];
    final messages = node.checkMessages;
    return TextField(
      controller: _text,
      obscureText: variant == 'obscured',
      keyboardType: switch (variant) {
        'number' => TextInputType.number,
        'longText' => TextInputType.multiline,
        _ => TextInputType.text,
      },
      minLines: variant == 'longText' ? 3 : null,
      maxLines: variant == 'longText' ? null : 1,
      decoration: InputDecoration(
        labelText: node.text('label'),
        hintText: node.text('placeholder'),
        errorText: _edited && messages.isNotEmpty ? messages.first : null,
      ),
      onChanged: _changed,
    );
  }
}
