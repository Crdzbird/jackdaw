# Native and Web Facts for the ADR (verified 2026-10-12)

Scope: a Dart/Flutter LLM agent framework with a C++20 core, published on
pub.dev under MIT, that must also run on Flutter web.

Verified column: Y means the value was read directly from the cited primary
source (docs page, pub.dev API, repository file, changelog or GitHub API) on
2026-10-12. P (partial) means the source supports part of the claim or is
internally inconsistent. N means the claim could not be confirmed from a
primary source and must not be relied on without further checking.

## 1. Dart build hooks (formerly native assets)

| Fact | Value | Source URL | Verified |
|---|---|---|---|
| Latest stable Dart SDK | 3.13.5, dated 2026-09-29 | https://storage.googleapis.com/dart-archive/channels/stable/release/latest/VERSION | Y |
| Latest Dart beta | 3.14.0-211.1.beta (2026-09-09); 3.14.0 is "Unreleased" in the changelog | https://storage.googleapis.com/dart-archive/channels/beta/release/latest/VERSION , https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md | Y |
| Latest stable Flutter | 3.47.7, released 2026-10-08, bundles Dart 3.13.5 (3.47.0 shipped 2026-08-12 with Dart 3.13.0) | https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json , https://docs.flutter.dev/release/release-notes | Y |
| Hooks stable since | Dart 3.10.0 (released 2025-11-12). Changelog: hooks "formerly know as native assets" are now stable | https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md (3.10.0, Hooks section) | Y |
| Flutter version pairing | Flutter 3.38.0 (2025-11-12) ships Dart 3.10.0. Flutter docs say that since 3.38 the `package_ffi` template (build hooks) is the recommended way to bind native code | https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json , https://docs.flutter.dev/platform-integration/bind-native-code | Y |
| Flutter feature flag | `enable-native-assets` is available and enabled by default on master, beta and stable | https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/features.dart | Y |
| Link hooks | `hook/link.dart` and recorded-use tree shaking arrived in Dart 3.13. `LinkInput.recordedUses` left experimental in hooks 2.1.0 | https://dart.dev/tools/hooks , https://github.com/dart-lang/native/blob/main/pkgs/hooks/CHANGELOG.md | Y |
| package:hooks | 2.2.0 (2026-08-18), publisher dart.dev, BSD-3-Clause, SDK >=3.10.0. 1.0.0 was "Stable release" | https://pub.dev/packages/hooks , https://pub.dev/api/packages/hooks , https://github.com/dart-lang/native/blob/main/pkgs/hooks/CHANGELOG.md | Y |
| package:code_assets | 2.1.0 (2026-09-16), publisher dart.dev. 2.0.0 now validates the ELF/Mach-O/PE header against the target arch and rejects multi-arch (fat) Mach-O output | https://pub.dev/packages/code_assets , https://github.com/dart-lang/native/blob/main/pkgs/code_assets/CHANGELOG.md | Y |
| package:native_toolchain_c | 0.19.5 (2026-09-16), publisher labs.dart.dev, labelled experimental (higher rate of breaking changes) | https://pub.dev/packages/native_toolchain_c | Y |
| package:data_assets | 0.20.0 (2026-05-18), publisher labs.dart.dev, experimental. The Flutter flag `enable-dart-data-assets` is only available on master. dart.dev says "the Dart SDK can use the CodeAsset type, but more asset types are planned" | https://pub.dev/packages/data_assets , https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/features.dart , https://dart.dev/tools/hooks | Y |
| package:native_assets_cli | 0.18.0, discontinued, "replaced by: hooks" | https://pub.dev/packages/native_assets_cli | Y |
| hook/build.dart shape | `void main(List<String> args) async { await build(args, (input, output) async { ... output.assets.code.add(CodeAsset(package: input.packageName, name: '...', linkMode: DynamicLoadingBundled(), file: uri)); }); }`. Target is read from `input.config.code.targetOS`, `.targetArchitecture` and `.iOS.targetSdk`. Hook deps go in `dependencies`, not `dev_dependencies` | https://pub.dev/packages/code_assets , https://dart.dev/tools/hooks , https://github.com/dart-lang/native/blob/main/pkgs/hooks/example/build/download_asset/hook/build.dart | Y |
| Link modes | `DynamicLoadingBundled`, `DynamicLoadingSystem`, `LookupInProcess`, `LookupInExecutable`, `StaticLinking`. StaticLinking is documented as "Not yet supported in the Dart and Flutter SDK" (sdk#49418) | https://github.com/dart-lang/native/blob/main/pkgs/code_assets/lib/src/code_assets/link_mode.dart | Y |
| OS enum | android, fuchsia, iOS, linux, macOS, windows. There is no web value | https://github.com/dart-lang/native/blob/main/pkgs/code_assets/lib/src/code_assets/os.dart | Y |
| Architecture enum | arm, arm64, arm64e (added in 2.1.0), ia32, riscv32, riscv64, x64 | https://github.com/dart-lang/native/blob/main/pkgs/code_assets/lib/src/code_assets/architecture.dart | Y |
| Android ABIs in Flutter apps | Defaults are armeabi-v7a, arm64-v8a, x86_64. The download example ships android arm, arm64, ia32, riscv64, x64 | https://docs.flutter.dev/deployment/android , https://github.com/dart-lang/native/blob/main/pkgs/hooks/example/build/download_asset/lib/src/hook_helpers/hashes.dart | Y |
| Platforms | Android, iOS, Linux, macOS, Windows (pub.dev platform tags of hooks/code_assets) | https://pub.dev/packages/hooks | Y |
| Commands that run hooks | Dart: hooks "are run automatically when invoking the run, build, or test commands". Flutter: native assets are built for each target platform, and `flutter test` (TargetPlatform.tester) maps to the host OS | https://dart.dev/tools/hooks , https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/isolated/native_assets/native_assets.dart | Y |
| Flutter web and hooks | flutter_tools throws `StateError('No dart builds for web yet.')` when mapping TargetPlatform.web to an OS | https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/isolated/native_assets/native_assets.dart | Y |
| C++ via native_toolchain_c | `CBuilder.library(..., language: Language.cpp, std: ..., cppLinkStdLib: ..., flags: ..., defines: ...)`. Language values are c, cpp, objectiveC | https://github.com/dart-lang/native/blob/main/pkgs/native_toolchain_c/lib/src/cbuilder/cbuilder.dart , https://github.com/dart-lang/native/blob/main/pkgs/native_toolchain_c/lib/src/cbuilder/language.dart | Y |
| libc++ on Android | 0.17.6 uses the NDK `libc++.a` linker script for `cppLinkStdLib: 'c++_static'`. Flutter docs point to `package:android_libcpp_shared` (0.3.1) for `libc++_shared.so` | https://github.com/dart-lang/native/blob/main/pkgs/native_toolchain_c/CHANGELOG.md , https://docs.flutter.dev/platform-integration/bind-native-code , https://pub.dev/packages/android_libcpp_shared | Y |
| CMake | No first-party CMake builder exists. Community `native_toolchain_cmake` 0.3.2 (publisher rainyl.dev, Apache-2.0, "experimental and may change without warning") | https://pub.dev/packages/native_toolchain_cmake , https://github.com/rainyl/native_toolchain_cmake | Y |
| Prebuilt download pattern | Officially recommended: download the binary in the hook, verify a file hash, write it to the output dir, emit `CodeAsset` with `DynamicLoadingBundled`. The example keys hashes by per-target file name and uses `HttpClient.findProxyFromEnvironment` | https://docs.flutter.dev/platform-integration/bind-native-code , https://github.com/dart-lang/native/blob/main/pkgs/hooks/example/build/download_asset/lib/src/hook_helpers/download.dart | Y |
| Checksum strength in example | The official example uses MD5, with a TODO asking whether a strong hash is needed against tampering. Use SHA-256 instead | https://github.com/dart-lang/native/blob/main/pkgs/hooks/example/build/download_asset/lib/src/hook_helpers/download.dart | Y |
| Output dirs and env | Write to `input.outputDirectory` (per arch/SDK) or `outputDirectoryShared`. Hooks run semi-hermetic and only allowlisted env vars (PATH, HOME, proxy, NDK, NIX_ etc.) pass through | https://dart.dev/tools/hooks , https://docs.flutter.dev/platform-integration/bind-native-code | Y |
| User defines | `hooks: user_defines: <pkg>:` in pubspec, read with `input.userDefines`. In a pub workspace it must be in the root pubspec | https://dart.dev/tools/hooks , https://pub.dev/packages/hooks | Y |
| Recent fix | Dart 3.13.3 fixed Windows-to-Linux cross compilation when hooks link native code | https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md | Y |

## 2. pub.dev limits and scoring

| Fact | Value | Source URL | Verified |
|---|---|---|---|
| Max compressed archive | 100 MiB (`maxArchiveSize = 100 * 1024 * 1024`; upload signer `maxUploadSize` same) | https://github.com/dart-lang/pub-dev/blob/master/pkg/pub_package_reader/lib/pub_package_reader.dart , https://github.com/dart-lang/pub-dev/blob/master/app/lib/package/upload_signer_service.dart | Y |
| Max uncompressed | 256 MiB (`maxUncompressedSize`) | https://github.com/dart-lang/pub-dev/blob/master/pkg/pub_package_reader/lib/pub_package_reader.dart | Y |
| Max file count | 65,536 (`maxFileCount = 64 * 1024`) | same as above | Y |
| Other limits | pubspec max 128 KiB. README/CHANGELOG content truncated at 256 KiB. description max 512 chars | same as above | Y |
| Docs wording | "We recommend less than 100 MB after gzip compression and less than 256 MB uncompressed". `dart pub publish` validator warns above 100 MB | https://dart.dev/tools/pub/publishing , https://github.com/dart-lang/pub/blob/master/lib/src/validator/size.dart | Y |
| Binaries policy | No explicit ban on binaries found. Policy says packages "must contain Dart source code". Publishers must have the right to redistribute everything uploaded | https://pub.dev/policy , https://dart.dev/tools/pub/publishing | P (absence of a rule cannot be fully proven) |
| Platform detection | Inferred from the transitive import graph of top-level libraries. `dart:ffi`, `dart:io` and `dart:isolate` are native-only. `dart:js_interop` is web-only. Override with a top-level `platforms:` key in pubspec | https://pub.dev/help/scoring , https://github.com/dart-lang/pana/blob/master/lib/src/tag/_specs.dart | Y |
| Points categories | Follow Dart file conventions 30. Provide documentation 20. Platform support 20. Pass static analysis 50. Support up-to-date dependencies 40. Total 160 | https://pub.dev/packages/hooks/score , https://github.com/dart-lang/pana/tree/master/lib/src/report | Y |
| Platform points rule | 20 for full support. 10 (partial) if web is supported but not Wasm-ready, or if iOS/macOS uses a legacy (non Swift PM) plugin build. 0 if no platform is detected | https://github.com/dart-lang/pana/blob/master/lib/src/report/multi_platform.dart | Y |
| Documentation rule | Needs an example and dartdoc on at least 20% of public API | https://pub.dev/help/scoring | Y |
| Dependencies rule | Includes a 20-point "compatible with dependency constraint lower bounds" check | https://github.com/dart-lang/pana/blob/master/lib/src/report/dependencies.dart | Y |

## 3. Android 16 KB pages and iOS packaging

| Fact | Value | Source URL | Verified |
|---|---|---|---|
| Play requirement | Apps targeting Android 15 (API 35)+ must support 16 KB pages on 64-bit devices. "Starting February 1, 2027", updates without 16 KB support cannot be released. Page last updated 2026-09-16 | https://developer.android.com/guide/practices/page-sizes | Y |
| NDK alignment | NDK r28+ aligns to 16 KB by default. r27 and lower need `-Wl,-z,max-page-size=16384` (and common-page-size) | https://developer.android.com/guide/practices/page-sizes | Y |
| AGP | AGP 8.5.1+ needed to zip-align uncompressed .so files at 16 KB | https://developer.android.com/guide/practices/page-sizes | Y |
| native_toolchain_c | Has produced 16 KB page-size Android dylibs by default since 0.7.0 | https://github.com/dart-lang/native/blob/main/pkgs/native_toolchain_c/CHANGELOG.md | Y |
| Flutter default NDK | `ndkVersion = "28.2.13676358"`, minSdk 24, targetSdk 36 (master branch file; stable may lag) | https://github.com/flutter/flutter/blob/master/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt | P (master, not stable tag) |
| Prebuilt .so implication | Downloaded prebuilt Android libraries need 16 KB-aligned LOAD segments (built with NDK r28+ or the flags) | derived from the rows above | Y (derived) |
| iOS standalone dylibs | "iOS, watchOS, and tvOS support third-party frameworks but don't support third-party standalone dynamic libraries" | https://developer.apple.com/documentation/bundleresources/placing-content-in-a-bundle | Y |
| Flutter iOS/macOS handling | Flutter wraps each dylib into a framework and builds XCFrameworks. It needs the same file name across archs (no `_arm64` suffix; slices are lipo'd), the same name across iphoneos and iphonesimulator, and the same asset set per SDK, or App Store validation can fail | https://docs.flutter.dev/platform-integration/bind-native-code | Y |
| Hooks must not emit fat binaries | code_assets 2.0.0 rejects multi-architecture Mach-O output. Hooks run once per target arch | https://github.com/dart-lang/native/blob/main/pkgs/code_assets/CHANGELOG.md | Y |
| App Store linker flag | native_toolchain_c 0.17.5 added `-encryptable` on iOS/macOS to fix an App Store issue | https://github.com/dart-lang/native/blob/main/pkgs/native_toolchain_c/CHANGELOG.md | Y |
| Privacy manifests | Third-party SDKs can ship `PrivacyInfo.xcprivacy`. It is required when the SDK is on Apple's listed SDKs or uses required-reason APIs | https://developer.apple.com/documentation/bundleresources/privacy-manifest-files | Y |
| XCFramework signatures | Xcode verifies XCFramework code signatures and errors if they are removed or changed | https://developer.apple.com/documentation/xcode/verifying-the-origin-of-your-xcframeworks | Y |
| Guideline 2.5.2 | Apps may not "download, install, or execute code which introduces or changes features". Native code must ship in the bundle. Downloading model weights as data is not addressed explicitly | https://developer.apple.com/app-store/review/guidelines/ | P (model weights not addressed) |

## 4. llama.cpp and alternative runtimes

| Fact | Value | Source URL | Verified |
|---|---|---|---|
| llama.cpp license | MIT (ggml also MIT) | https://github.com/ggml-org/llama.cpp/blob/master/LICENSE , https://github.com/ggml-org/ggml | Y |
| Release cadence | Versioned releases started: v0.2.0 (2026-08-21) through v0.6.0 (2026-10-05, "Latest"). Rolling b-builds continue (b11574 on 2026-10-12) | https://github.com/ggml-org/llama.cpp/releases | Y |
| C API stability | No stability guarantee. llama.h carries many DEPRECATED wrappers. API changes are tracked in open issue #9289 "changelog : libllama API". v0.6.0 added `llama_batch_ext`/`llama_process` and bumped session/state versions | https://github.com/ggml-org/llama.cpp/blob/master/include/llama.h , https://github.com/ggml-org/llama.cpp/issues/9289 , https://github.com/ggml-org/llama.cpp/releases/tag/v0.6.0 | Y |
| GGUF | Single-file, mmap-compatible format. Current format version v3 (adds big-endian). Spec lives in the ggml repo | https://github.com/ggml-org/ggml/blob/master/docs/gguf.md | Y |
| GBNF in the C API | `llama_sampler_init_grammar(vocab, grammar_str, grammar_root)` and `llama_sampler_init_grammar_lazy_patterns(...)` (the older `_lazy` variant is deprecated) | https://github.com/ggml-org/llama.cpp/blob/master/include/llama.h | Y |
| JSON Schema to GBNF | Converts a subset of JSON Schema. Lives in `common/json-schema-to-grammar.cpp`, not in llama.h. Known gaps: nested $ref broken, no remote $ref in C++, prefixItems broken, no patternProperties/uniqueItems/contains, numeric bounds only for integer | https://github.com/ggml-org/llama.cpp/blob/master/grammars/README.md , https://github.com/ggml-org/llama.cpp/tree/master/common | Y |
| Tokenizer | `llama_tokenize`, `llama_token_to_piece`, `llama_detokenize` are in llama.h | https://github.com/ggml-org/llama.cpp/blob/master/include/llama.h | Y |
| Backends | CPU (NEON, AVX, RVV), Metal (Apple Silicon), Vulkan, OpenCL (Adreno, tested on Android with Snapdragon 8 Gen 3/8 Elite), Hexagon (Snapdragon), WebGPU (Dawn; browser via Emscripten plus emdawnwebgpu), CUDA, HIP, SYCL and others | https://github.com/ggml-org/llama.cpp/blob/master/README.md , https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/OPENCL.md , https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md | Y |
| Android build | NDK CMake build documented for arm64-v8a with KleidiAI, `GGML_NATIVE=OFF`, `LLAMA_OPENSSL=OFF`, `GGML_LLAMAFILE=OFF` | https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md | Y |
| Vulkan on Android/iOS | Not documented as a supported mobile path in build.md. MoltenVK is mentioned for macOS only | https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md | N (not documented) |
| iOS packaging | Official releases include `llama-<tag>-xcframework.zip` (61 MB zipped for b11574) | https://github.com/ggml-org/llama.cpp/releases/tag/b11574 | Y |
| Binary size | Release archives for b11574 (with all CLI tools): macos-arm64 11 MB, android-arm64 71 MB, win-cpu-x64 18 MB, xcframework 61 MB. The size of libllama+ggml alone, stripped, was not measured | https://github.com/ggml-org/llama.cpp/releases/tag/b11574 | P (archive sizes only) |
| MLC LLM | Apache-2.0. Metal on iOS, OpenCL on Adreno/Mali on Android, WebGPU+WASM in browser | https://github.com/mlc-ai/mlc-llm | Y |
| ExecuTorch | BSD-3-Clause. v1.5.1 (2026-09-23). Android AAR on Maven Central, Apple via SwiftPM, C++ runtime. `.pte` compatibility for at least one following non-patch release | https://github.com/pytorch/executorch , https://github.com/pytorch/executorch/blob/main/LICENSE | Y |
| LiteRT-LM | Apache-2.0. v0.18.0 (2026-10-06). Described as "production-ready". C++ and Kotlin stable. Swift and JS in early preview. Flutter guide is community | https://github.com/google-ai-edge/LiteRT-LM | Y |
| MediaPipe LLM Inference | "now in maintenance-only mode". Google recommends migrating to LiteRT-LM | https://developers.google.com/edge/mediapipe/solutions/genai/llm_inference | Y |
| ONNX Runtime GenAI | MIT. v0.17.0 (2026-09-28). Linux, Windows, Mac and Android supported. iOS "on the roadmap". C/C++ API. Constrained decoding supported | https://github.com/microsoft/onnxruntime-genai | Y |

## 5. Web path

| Fact | Value | Source URL | Verified |
|---|---|---|---|
| Hooks emitting Wasm/JS assets | Not supported. dart-lang/native #988 ("web backends and WasmCode and JsCode assets") is open, last updated 2026-09-10. #156 "Compilation of native code to WASM" is open. The OS enum has no web, and Flutter throws for web | https://github.com/dart-lang/native/issues/988 , https://github.com/dart-lang/native/issues/156 | Y |
| Dart Wasm | Stable but "still in preview". It targets WasmGC in JS hosts (not wasmtime/wasmer). Only `dart:js_interop` is allowed | https://dart.dev/web/wasm | Y |
| Flutter Wasm | Needs Flutter 3.24+. `flutter build web --wasm` also emits JS and falls back to it when WasmGC is missing. Chromium 119+ works. Firefox and Safari are currently blocked by bugs. No iOS browser can run it. Multithreading needs COOP `same-origin` and COEP `credentialless` or `require-corp` | https://docs.flutter.dev/platform-integration/web/wasm | Y |
| dart2wasm changes in 3.14 (beta) | Requires native `wasm:js-string`. `dart.library.isolate` evaluates to false. Safari 26.5 `compileStreaming` workaround | https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md | Y |
| Legacy interop | dart2wasm rejects `dart:js_util`, `package:js` and `dart:js` since 3.3. In 3.14, dart2js/DDC gain `--no-deprecated-js-interop` | https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md | Y |
| js_interop on both compilers | dart:js_interop is the current interop. The SDK changelog describes dart2wasm behaviours of js_interop (JSPromise.toDart, typed arrays) | https://dart.dev/interop/js-interop , https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md | P (no explicit dart.dev sentence found) |
| wllama | MIT. 3.8.1 (2026-10-02). llama.cpp in WASM with SIMD, WebGPU since v3.1, and auto multithread (needs COOP/COEP). 2 GB per-file limit, so models are split into chunks of 512 MB or less | https://github.com/ngxson/wllama | Y |
| WebLLM | Apache-2.0. 0.2.86 (2026-10-11). WebGPU required. OpenAI-compatible API, JSON mode with custom schema, and Web Worker support | https://github.com/mlc-ai/web-llm | Y |
| transformers.js | Apache-2.0. 4.3.1 (2026-10-07). Runs on ONNX Runtime Web: WASM CPU by default, `device: 'webgpu'` optional | https://github.com/huggingface/transformers.js | Y |
| LiteRT-LM web | JavaScript API in early preview | https://github.com/google-ai-edge/LiteRT-LM | Y |
| Chrome Prompt API | Chrome Extensions: stable since Chrome 138. Web: the status table lists "Chrome 148" with Intent to Ship, but prose on the same page still says extensions only. Gemini Nano. Desktop only (Windows 10/11, macOS 13+, Linux, Chromebook Plus); Android and iOS not supported. Needs 22 GB free disk and >4 GB VRAM or 16 GB RAM. `responseConstraint` takes a JSON Schema | https://developer.chrome.com/docs/ai/built-in-apis , https://developer.chrome.com/docs/ai/prompt-api | P (web status inconsistent on page) |
| WebGPU Chrome | Chrome 113 (ChromeOS, macOS, Windows). Chrome 144 adds Linux (Intel Gen12+). Chrome Android 121 | https://github.com/mdn/browser-compat-data/blob/main/api/GPU.json | Y |
| WebGPU Safari | Safari 26 (desktop and iOS) | same as above | Y |
| WebGPU Firefox | Partial. Windows since 141, macOS Apple Silicon since 145/147. No Intel Mac, no Linux, no Firefox Android | same as above | Y |

## 6. Vector index, tokenizer and JSON libraries

| Fact | Value | Source URL | Verified |
|---|---|---|---|
| hnswlib | Apache-2.0. Header-only C++11, no deps. Optional no-exceptions API | https://github.com/nmslib/hnswlib | Y |
| USearch | Apache-2.0. v2.26.4 (2026-10-05). Single C++11 header. C99 API (`c/usearch.h`). Lists iOS, Android and WebAssembly (`wasm/` dir). C API supports filter predicates and user metrics | https://github.com/unum-cloud/USearch | Y |
| FAISS | MIT. C++ with a BLAS dependency. `c_api/` directory exists. No mobile/WASM support stated in README | https://github.com/facebookresearch/faiss | Y (mobile: N) |
| sqlite-vec | Dual MIT / Apache-2.0. Pure C, no deps, runs in browser WASM. "pre-v1, so expect breaking changes". Latest stable v0.1.9 (2026-03-31), alpha v0.1.10-alpha.4 | https://github.com/asg017/sqlite-vec | Y |
| HF tokenizers | Apache-2.0. Rust reference implementation with Python and Node bindings, no official C++ | https://github.com/huggingface/tokenizers | Y |
| tokenizers-cpp (MLC) | Apache-2.0. Cross-platform C++ binding over HF tokenizers (Rust) and sentencepiece | https://github.com/mlc-ai/tokenizers-cpp | Y (Rust toolchain need: N) |
| sentencepiece | Apache-2.0. C++. Includes "SentencePiece Lite", a zero-dependency C++20 runtime (~45 KB static lib, FlatBuffers model) | https://github.com/google/sentencepiece | Y |
| tiktoken | openai/tiktoken MIT (Python/Rust). C++ ports: meta-pytorch/tokenizers (BSD-3, includes Tiktoken, HF, SentencePiece and Tekken C++ tokenizers), sewenew/tokenizer (Apache-2.0) | https://github.com/openai/tiktoken , https://github.com/meta-pytorch/tokenizers , https://github.com/sewenew/tokenizer | Y |
| llama.cpp tokenizer | `llama_tokenize` uses the GGUF-embedded vocab, so no separate tokenizer is needed for GGUF models | https://github.com/ggml-org/llama.cpp/blob/master/include/llama.h | Y |
| valijson | BSD-2-Clause. Header-only, JSON Schema Draft 7, pluggable JSON adapters, has been compiled to WASM | https://github.com/tristanpenman/valijson | Y |
| pboettch/json-schema-validator | MIT. Draft 7. Depends on nlohmann/json >= 3.8.0 (MIT) | https://github.com/pboettch/json-schema-validator , https://github.com/nlohmann/json | Y |
| simdjson | Dual Apache-2.0 / MIT | https://github.com/simdjson/simdjson | Y |

## 7. Async FFI and concurrency

| Fact | Value | Source URL | Verified |
|---|---|---|---|
| NativeCallable introduced | Dart 3.1 (`NativeCallable.listener`). `isolateLocal` and `keepIsolateAlive` came later (3.2 era) | https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md , https://api.dart.dev/dart-ffi/NativeCallable-class.html | Y |
| listener semantics | Callable from any thread. Args are sent over a SendPort to the creating isolate. Void-only. Runs "at some time in the future". Pointers must stay valid until the call completes. Must be `close`d, which keeps the isolate alive until then. Calling after close is UB | https://api.dart.dev/dart-ffi/NativeCallable/NativeCallable.listener.html | Y |
| isolateGroupBound | Synchronous call from any thread inside the isolate group, documented as "an experimental feature". Dart 3.13 shipped experimental shared-memory Isolate APIs by accident. 3.14 unships them and gates `isolateGroupBound` behind `--experimental-shared-data` (sdk#64285) | https://api.dart.dev/dart-ffi/NativeCallable/NativeCallable.isolateGroupBound.html , https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md , https://github.com/dart-lang/sdk/issues/64285 | Y |
| Shared isolates | Still a language proposal (`working/333 - shared memory multithreading`, last commit 2026-04-13). Not a shipped feature | https://github.com/dart-lang/language/blob/main/working/333%20-%20shared%20memory%20multithreading/proposal.md | Y |
| Streaming tokens best practice | Not documented on dart.dev. Recommended pattern below is derived from the listener docs | https://api.dart.dev/dart-ffi/NativeCallable/NativeCallable.listener.html | N (no official guide) |

## Implications for the ADR

1. Native distribution. Use `hook/build.dart` with `package:hooks` and
   `package:code_assets` (both stable, dart.dev publisher, require Dart
   >=3.10 / Flutter >=3.38). Set the SDK floor to `^3.10.0`, or `^3.13.0`
   if link-hook tree shaking is wanted.
2. Build system. `native_toolchain_c` (experimental, labs) can compile C++20
   with `Language.cpp` and `std:`. Building llama.cpp's CMake tree from a hook
   means either a third-party experimental CMake wrapper or (preferred)
   prebuilt binaries downloaded in the hook. Offer a `local_build`
   user-define for source builds.
3. Prebuilt binaries. Publish one per OS, arch and iOS SDK, with the same
   file name across archs and SDKs. No fat Mach-O. Android .so must be
   16 KB aligned (NDK r28+). Pin SHA-256 hashes in Dart source rather than
   copying the example's MD5. Honour proxy env vars. Do not put binaries in
   the pub archive (100 MiB / 256 MiB / 65,536-file limits). Expect the iOS
   xcframework to be tens of MB.
4. Static linking is not available (`StaticLinking` unsupported), so the core
   ships as a dynamic library. It becomes a framework on Apple platforms
   automatically.
5. llama.cpp is MIT and fits the license. Its C API is unstable, so pin a
   release tag (v0.x now exists), isolate it behind the project's own C ABI
   shim in the C++20 core, and keep ffigen bindings against the shim only.
   JSON-schema-to-GBNF lives in `common/` with known gaps. Vendor it or use
   the GBNF API directly, and validate outputs with valijson (BSD-2) or
   pboettch (MIT).
6. Web. Hooks cannot produce Wasm or JS assets, and Flutter web skips them.
   The web backend must be a separate Dart implementation behind conditional
   imports (`dart.library.js_interop` vs `dart.library.ffi`), calling a JS
   engine (wllama for GGUF parity, WebLLM, transformers.js, or Chrome Prompt
   API where available) through `dart:js_interop`. The JS/WASM engine files
   must be shipped by the app (web/ assets or a CDN), not by hooks. Keep all
   web code free of `dart:html` and `package:js` to score Wasm-ready and
   get the full 20 platform points.
7. WebGPU now ships in Chrome, Safari 26 and Firefox on Windows, but Firefox
   Linux, Intel Mac and Android lack it. Keep a WASM CPU fallback. Flutter
   Wasm currently runs only on Chromium, and other browsers use the JS
   build. Chrome Prompt API is desktop-only and needs large hardware, so
   treat it as an optional provider.
8. Streaming tokens. Native worker thread calls a
   `NativeCallable.listener` (void) per token or chunk. The Dart side pushes
   into a `StreamController`. Copy token bytes in native-owned buffers that
   stay valid until Dart frees them, or pass a token id/index into a ring
   buffer. Close the callable on completion, cancel or error. Do not rely on
   `isolateGroupBound` or shared isolates (experimental, flag gated). Long
   synchronous calls such as model load should run on a background isolate
   or a native thread, never on the UI isolate.
9. pub.dev scoring. Declare `platforms:` explicitly if detection misfires.
   Provide example/, dartdoc on at least 20% of the API, and tested lower
   bounds (20 points). Full score is 160.
10. Items marked N or P need a spike before the ADR is finalised. These are
    measured stripped libllama size per ABI, llama.cpp Vulkan on Android, the
    final Chrome Prompt API web status, and Apple review stance on
    downloaded model weights.
