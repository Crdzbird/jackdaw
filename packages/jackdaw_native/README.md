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
(Cortex-A55/A75 and newer). Models are never bundled; you supply the file and
its license applies. See `THIRD_PARTY_NOTICES.md` for the code compiled into
the library.
