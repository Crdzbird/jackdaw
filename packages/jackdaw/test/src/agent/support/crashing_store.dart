import 'package:jackdaw/jackdaw.dart';

import 'process_killed.dart';

/// A store that dies on its [crashAt]th append, before writing it, the way
/// a killed process would.
final class CrashingStore implements SessionStore {
  factory(SessionStore inner, {required int crashAt}) = CrashingStore._;

  new _(this._inner, {required this.crashAt});

  final SessionStore _inner;
  final int crashAt;
  int _appends = 0;

  @override
  Future<List<SessionRecord>> load(String sessionId) => _inner.load(sessionId);

  @override
  Future<void> append(String sessionId, SessionRecord record) async {
    _appends++;
    if (_appends == crashAt) throw const ProcessKilled();
    await _inner.append(sessionId, record);
  }
}
