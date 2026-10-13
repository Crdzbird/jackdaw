import 'dart:convert';

/// URL of `fake_wllama.js`, a stand-in for the wllama ES module.
///
/// It records what it receives on `globalThis.fakeWllama` and streams the
/// chunks found in `globalThis.fakeChunks`, one per macrotask, stopping when
/// the abort signal fires. It is served next to the tests, so coverage can
/// treat it like any other script.
String fakeWllamaUrl() => Uri.base.resolve('fake_wllama.js').toString();

/// Encodes [chunks] for `globalThis.fakeChunks`.
String chunksJson(List<Map<String, Object?>> chunks) => jsonEncode(chunks);
