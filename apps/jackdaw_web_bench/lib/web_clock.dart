import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// The page clock in milliseconds, to 5 us on a cross-origin isolated
/// page.
double pageNow() => web.window.performance.now();

/// Completes at the start of the next animation frame.
Future<void> nextFrame() {
  final done = Completer<void>();
  web.window.requestAnimationFrame(((JSNumber _) => done.complete()).toJS);
  return done.future;
}

/// The memory the page uses, JavaScript and DOM together, in bytes, as
/// `performance.measureUserAgentSpecificMemory` reports it after a full
/// collection; 0 when the page is not cross-origin isolated.
Future<int> pageMemory() async {
  final performance = web.window.performance as JSObject;
  if (!performance.has('measureUserAgentSpecificMemory')) return 0;
  final measured = await performance
      .callMethod<JSPromise<JSObject>>('measureUserAgentSpecificMemory'.toJS)
      .toDart;
  return (measured['bytes']! as JSNumber).toDartInt;
}

/// Lets queued microtasks run, then calls [done], and keeps trying after
/// later tasks at most [tries] times; returns whether it became true.
Future<bool> settleUntil(bool Function() done, {int tries = 100}) async {
  await Future<void>.value();
  if (done()) return true;
  for (var i = 0; i < tries; i++) {
    await Future<void>.delayed(Duration.zero);
    if (done()) return true;
  }
  return false;
}
