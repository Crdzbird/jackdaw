part of 'ui_bound.dart';

final class _UiBoundState extends State<UiBound> {
  late Set<String> _reads = _paths();

  Set<String> _paths() =>
      uiBoundPaths(widget.node.component.props, widget.node.scope.path);

  void _watch(UiNode node) =>
      node.controller.changes.watch(node.surface.id, _reads, _changed);

  void _unwatch(UiNode node) =>
      node.controller.changes.unwatch(node.surface.id, _reads, _changed);

  @override
  void initState() {
    super.initState();
    _watch(widget.node);
  }

  @override
  void didUpdateWidget(UiBound old) {
    super.didUpdateWidget(old);
    final reads = _paths();
    if (identical(old.node.controller, widget.node.controller) &&
        old.node.surface.id == widget.node.surface.id &&
        setEquals(reads, _reads)) {
      return;
    }
    _unwatch(old.node);
    _reads = reads;
    _watch(widget.node);
  }

  @override
  void dispose() {
    _unwatch(widget.node);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    return uiSemantics(
      node,
      node.builders[node.component.type]?.call(node) ?? const SizedBox.shrink(),
    );
  }
}
