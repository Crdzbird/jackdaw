/// A model file to download: where it lives, its size and its SHA-256,
/// so a corrupted or replaced file is never loaded.
final class ModelFile {
  /// Describes the file saved as [name], fetched from [url], of [bytes]
  /// bytes whose SHA-256 is [sha256] in lower-case hex. [license] names
  /// the terms the weights are published under.
  const factory({
    required String name,
    required String url,
    required int bytes,
    required String sha256,
    String license,
  }) = ModelFile._;

  const new _({
    required this.name,
    required this.url,
    required this.bytes,
    required this.sha256,
    this.license = '',
  });

  /// Qwen2.5 1.5B Instruct in Q4_K_M, about 1.1 GB, under Apache-2.0. The
  /// default model: small enough for a phone, and reliable with tools and
  /// JSON. The URL is pinned to a commit of the Qwen repository.
  static const ModelFile qwen25Instruct = ModelFile._(
    name: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    url:
        'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/'
        '91cad51170dc346986eccefdc2dd33a9da36ead9/'
        'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    bytes: 1117320736,
    sha256: '6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e',
    license: 'Apache-2.0',
  );

  /// The file name in the download folder.
  final String name;

  /// Where the file is downloaded from.
  final String url;

  /// The exact size of the file.
  final int bytes;

  /// The SHA-256 of the file, in lower-case hex.
  final String sha256;

  /// The license of the weights, such as `Apache-2.0`.
  final String license;

  /// This file fetched from [url] instead, such as a mirror; the size and
  /// hash still have to match.
  ModelFile from(String url) => ModelFile._(
    name: name,
    url: url,
    bytes: bytes,
    sha256: sha256,
    license: license,
  );
}
