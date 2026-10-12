/// Where the demo looks for the GGUF model on the device.
const String modelPath = String.fromEnvironment(
  'JACKDAW_MODEL',
  defaultValue: '/data/user/0/dev.crdzbird.jackdaw_bench/files/model.gguf',
);
