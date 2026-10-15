# jackdaw_bench

On-device benchmarks for the jackdaw native core. See docs/benchmarks.

## The demo app

`lib/main.dart` is a demo with three tabs: an agent chat, a generative UI
tab and a raw playground. On first launch it downloads Qwen2.5 1.5B
Instruct, about 1.1 GB, with `LocalModel.download` and keeps it in the
app's files folder.

The UI tab turns a request into a screen, and later requests change that
screen. Its catalog is the A2UI basic catalog plus a `Panel` component
with a background color, in `lib/src/app/demo_catalog.dart`, to show how
an app adds its own components: the v1.0 basic catalog has no colors.

Defines for development:

- `JACKDAW_MODEL=<path>` loads that GGUF file and downloads nothing; the
  benchmarks use it with `tool/push_model.sh`.
- `JACKDAW_MODEL_URL=<url>` downloads the default model from a mirror. The
  size and hash must still match.
