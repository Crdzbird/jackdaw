export class Wllama {
  constructor(paths, config) {
    globalThis.fakeWllama = { paths, config, aborted: false };
  }
  async loadModelFromUrl(url, params) {
    globalThis.fakeWllama.url = url;
    globalThis.fakeWllama.params = params;
  }
  async createChatCompletion(options) {
    const state = globalThis.fakeWllama;
    state.options = options;
    options.abortSignal.addEventListener('abort', () => { state.aborted = true; });
    if (globalThis.fakeError) throw new Error(globalThis.fakeError);
    for (const chunk of globalThis.fakeChunks) {
      if (options.abortSignal.aborted) return;
      options.onData(chunk);
      await new Promise((resolve) => setTimeout(resolve, 5));
    }
  }
  async createEmbedding(options) {
    const state = globalThis.fakeWllama;
    state.embedOptions = options;
    if (globalThis.fakeError) throw new Error(globalThis.fakeError);
    if (globalThis.fakeEmbedShort) return { object: 'list', data: [] };
    state.embedInputs = (state.embedInputs || []).concat([options.input]);
    const first = Array.isArray(options.input) ? options.input[0] : options.input;
    const data = [{ object: 'embedding', index: 0, embedding: [first.length, 0, 3] }];
    return { object: 'list', data, model: 'fake' };
  }
  async exit() {
    globalThis.fakeWllama.exited = true;
  }
}
