import 'package:jackdaw_native/src/native/native_session_options.dart';

/// How a `LocalModel` loads and runs its model.
final class LocalModelOptions {
  /// Creates options with defaults suited to phones.
  const factory({int gpuLayers, bool mmap, NativeSessionOptions session}) =
      LocalModelOptions._;

  const new _({
    this.gpuLayers = -1,
    this.mmap = true,
    this.session = const NativeSessionOptions(),
  });

  /// Layers offloaded to a GPU backend; below zero offloads all of them.
  final int gpuLayers;

  /// Whether the model file is memory-mapped instead of copied into RAM.
  final bool mmap;

  /// Context and threading settings.
  final NativeSessionOptions session;
}
