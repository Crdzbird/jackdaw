/// On-device inference for jackdaw.
///
/// `LocalModel` runs GGUF models through the native core and plugs into
/// any jackdaw `Agent`. `NativeEmbedder` and `NativeVectorIndex` give
/// retrieval on the device, and `ModelDownloader` fetches and checks the
/// model files. Native platforms only; there is no web build.
library;

export 'src/download/model_download_exception.dart';
export 'src/download/model_download_progress.dart';
export 'src/download/model_downloader.dart';
export 'src/download/model_file.dart';
export 'src/local_model.dart';
export 'src/local_model_options.dart';
export 'src/native/index_files.dart';
export 'src/native/index_keys.dart';
export 'src/native/native_embedder.dart';
export 'src/native/native_exception.dart';
export 'src/native/native_generate_options.dart';
export 'src/native/native_model.dart';
export 'src/native/native_session.dart';
export 'src/native/native_session_options.dart';
export 'src/native/native_stats.dart';
export 'src/native/native_vector_index.dart';
