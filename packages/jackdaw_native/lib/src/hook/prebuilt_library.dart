import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:jackdaw_native/src/hook/native_target.dart';
import 'package:jackdaw_native/src/hook/prebuilt_hashes.dart';

/// Downloads a CI-built `libjackdaw` and verifies its SHA-256 hash.
final class PrebuiltLibrary {
  /// Creates a downloader using [hashes] and the release [tag].
  const factory({Map<String, String> hashes, String tag, String baseUrl}) =
      PrebuiltLibrary._;

  const new _({
    this.hashes = prebuiltHashes,
    this.tag = prebuiltRelease,
    this.baseUrl = 'https://github.com/Crdzbird/jackdaw/releases/download',
  });

  /// Expected SHA-256 per target key.
  final Map<String, String> hashes;

  /// GitHub release tag holding the libraries.
  final String tag;

  /// Root of the release download URLs.
  final String baseUrl;

  /// Downloads the library for [target] into [directory].
  ///
  /// Throws when no prebuilt exists for the target or when the downloaded
  /// bytes do not match the pinned hash; a mismatching file is deleted.
  Future<Uri> fetch(NativeTarget target, Uri directory) async {
    final expected = hashes[target.key];
    if (expected == null) {
      throw UnsupportedError(
        'No prebuilt libjackdaw for ${target.key}. Add the user define '
        '"jackdaw_native: build: source" to compile it locally.',
      );
    }
    final file = File.fromUri(directory.resolve(target.fileName));
    if (file.existsSync() && await _hash(file) == expected) return file.uri;
    await _download(_url(target), file);
    final actual = await _hash(file);
    if (actual != expected) {
      file.deleteSync();
      throw StateError('libjackdaw hash mismatch: $actual, want $expected');
    }
    return file.uri;
  }

  Uri _url(NativeTarget target) =>
      Uri.parse('$baseUrl/$tag/${target.key}-${target.fileName}');

  static Future<String> _hash(File file) async =>
      '${await sha256.bind(file.openRead()).first}';

  static Future<void> _download(Uri url, File file) async {
    final client = HttpClient()
      ..findProxy = HttpClient.findProxyFromEnvironment;
    try {
      final response = await (await client.getUrl(url)).close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: url);
      }
      await file.parent.create(recursive: true);
      await response.pipe(file.openWrite());
    } finally {
      client.close();
    }
  }
}
