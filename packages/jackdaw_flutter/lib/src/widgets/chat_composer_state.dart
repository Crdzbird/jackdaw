part of 'chat_composer.dart';

final class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    _text.clear();
    await widget.controller.send(text);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: ValueListenableBuilder<ChatStatus>(
        valueListenable: widget.controller.status,
        builder: (context, status, _) {
          final busy =
              status == ChatStatus.responding ||
              status == ChatStatus.awaitingApproval;
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  textInputAction: TextInputAction.send,
                  onSubmitted: busy
                      ? null
                      : (_) async {
                          await _send();
                        },
                  decoration: InputDecoration(hintText: widget.hint),
                ),
              ),
              if (status == ChatStatus.responding)
                IconButton(
                  tooltip: 'Stop',
                  icon: const Icon(Icons.stop_circle_outlined),
                  onPressed: () async {
                    await widget.controller.stop();
                  },
                ),
              if (status != ChatStatus.responding)
                IconButton(
                  tooltip: 'Send',
                  icon: const Icon(Icons.send),
                  onPressed: busy
                      ? null
                      : () async {
                          await _send();
                        },
                ),
            ],
          );
        },
      ),
    ),
  );
}
