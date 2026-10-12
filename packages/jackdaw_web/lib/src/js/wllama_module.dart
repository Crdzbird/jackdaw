import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jackdaw_web/src/js/wllama.dart';

/// The wllama ES module, loaded with a dynamic `import()`.
extension type WllamaModule._(JSObject _) implements JSObject {
  /// Imports the module at [url].
  static Future<WllamaModule> load(String url) async =>
      WllamaModule._(await importModule(url.toJS).toDart);

  @JS('Wllama')
  external JSFunction get _wllama;

  /// Creates a `Wllama` whose wasm binary is fetched from [wasmUrl].
  Wllama create(String wasmUrl, {bool suppressNativeLog = true}) =>
      _wllama.callAsConstructor<Wllama>(
        {'default': wasmUrl}.jsify(),
        {'suppressNativeLog': suppressNativeLog}.jsify(),
      );
}
