import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Text that grows by appended pieces but notifies listeners at most once
/// per frame, however fast the pieces arrive.
///
/// A model can emit tokens faster than the display refreshes; rebuilding
/// for each one wastes UI-thread time, so pieces are buffered and flushed
/// in a frame callback.
final class FrameText extends ValueNotifier<String> {
  /// Creates empty text.
  factory() = FrameText._;

  new _() : super('');

  final StringBuffer _pending = StringBuffer();
  bool _scheduled = false;
  bool _disposed = false;

  /// Adds [piece]; listeners hear about it on the next frame.
  void append(String piece) {
    _pending.write(piece);
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) => flush());
  }

  /// Applies buffered pieces now.
  void flush() {
    _scheduled = false;
    if (_disposed || _pending.isEmpty) return;
    value = '$value$_pending';
    _pending.clear();
  }

  /// Drops all text, including buffered pieces.
  void clear() {
    _pending.clear();
    value = '';
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
