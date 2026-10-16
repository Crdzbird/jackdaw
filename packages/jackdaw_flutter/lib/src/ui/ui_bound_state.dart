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

  /// Each component sits on a layer of its own, so a write repaints only
  /// the components that read it. A write that changes a size lays the
  /// column out again, and Flutter repaints what it lays out, so components
  /// that read no data need a layer too.
  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final drawn = uiSemantics(
      node,
      node.builders[node.component.type]?.call(node) ?? const SizedBox.shrink(),
    );
    return RepaintBoundary(child: drawn);
  }
}
