# jackdaw_native

On-device inference for `jackdaw`. Pre-release. Native platforms only.

`LocalModel` runs a GGUF model through a small C++ core built on
llama.cpp, and plugs into any jackdaw `Agent` like a cloud model.

- Structured output is enforced while decoding: a request's response schema
  is compiled to a GBNF grammar, so the model can only produce matching JSON.
- Generation runs on a native worker thread and never blocks the UI isolate.
- Cancelling the stream stops native decoding within milliseconds.
- The next turn of a chat reuses the cached prompt prefix.
- Token counts come from the model's own vocabulary.

```dart
final model = await LocalModel.open('/path/to/model.gguf');
final answer = await generateJson(
  model,
  [Message.user('Describe a jackdaw.')],
  const ObjectSchema(
    properties: {'name': Schema.string(), 'canFly': Schema.boolean()},
    required: ['name', 'canFly'],
  ),
);
model.close();
```

## Getting a model

Model weights are not bundled with the package. `LocalModel.download`
fetches one into a folder the app chooses, such as the support folder
from `path_provider`, the first time it is needed, and loads it:

```dart
final folder = await getApplicationSupportDirectory();
final model = await LocalModel.download(
  folder,
  onProgress: (p) => print('${(p.fraction * 100).floor()}%'),
);
```

The default is `ModelFile.qwen25Instruct`: Qwen2.5 1.5B Instruct in
Q4_K_M, about 1.1 GB, under Apache-2.0, pinned to a commit of the Qwen
repository on Hugging Face. Pass another `ModelFile` with its URL, size
and SHA-256 to use a different model, or `ModelFile.from` for a mirror.

- An interrupted download resumes where it stopped, in the same run after
  a dropped connection or on the next launch.
- The file is used only once its size and SHA-256 match. Mismatching bytes
  are deleted and `ModelDownloadException` is thrown.
- After the first check a marker file is kept, so later launches load the
  model without hashing it again.
- On Android the app needs the `INTERNET` permission in its release
  manifest; debug builds add it on their own.

`ModelDownloader` does the same without loading the model. Licenses differ
between models: check the terms of the weights you ship.

## Building the native library

The build hook downloads a prebuilt `libjackdaw` from the project's GitHub
release and checks its SHA-256 hash against the value pinned in the package,
so apps need no C++ toolchain. Prebuilt libraries exist for Android (arm64,
armv7, x86_64), macOS (arm64, x86_64), Linux x64 and Windows x64.

For iOS, or to build from source on any platform, add this to the root
`pubspec.yaml` of your app or workspace (CMake 3.25+ and Ninja required):

```yaml
hooks:
  user_defines:
    jackdaw_native:
      build: source
```

On Android the arm64 build uses ARMv8.2 dot-product instructions
(Cortex-A55/A75 and newer). On an older phone `LocalModel.open` throws an
`UnsupportedError` that says so, instead of crashing. To support such phones,
add `android_cpu: baseline` under the same `jackdaw_native` user defines;
that build runs everywhere but processes prompts about 2.5x slower. Models are never bundled; you supply the file and
its license applies. See `THIRD_PARTY_NOTICES.md` for the code compiled into
the library.
