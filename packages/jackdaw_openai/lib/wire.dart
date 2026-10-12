/// OpenAI chat-completions wire format, for engines that speak it.
///
/// `encodeChatRequest` builds a request body and `OpenAiStreamDecoder` turns
/// streamed chunks into model events. Use these to bridge other
/// OpenAI-compatible engines, such as wllama in the browser.
library;

export 'src/open_ai_request_encoder.dart';
export 'src/open_ai_stream_decoder.dart';
