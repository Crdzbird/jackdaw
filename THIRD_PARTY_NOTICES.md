# Third-party notices

The native library `libjackdaw`, built from `native/` and shipped by
`jackdaw_native`, statically links the components below. Nothing else is
compiled into it.

## llama.cpp and ggml

- Source: https://github.com/ggml-org/llama.cpp, tag v0.6.0
- Archive SHA-256: 09b36dba235fcac180efff18514da7038e65d8e5b9e4aefa59238468abfdec12
- License: MIT

```text
MIT License

Copyright (c) 2023-2026 The ggml authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Test-only dependencies

GoogleTest v1.18.0 (BSD-3-Clause) is fetched only when the C++ tests are
built. It is never linked into `libjackdaw`.

## Models

No model weights are distributed. Models you load keep their own licenses.
