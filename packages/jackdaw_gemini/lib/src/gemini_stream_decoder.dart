import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_gemini/src/gemini_mappings.dart';

/// Turns `streamGenerateContent` chunks into model events.
///
/// Thought parts are merged into one reasoning part that keeps its
/// signature. A function call's `thoughtSignature` travels in the call's
/// provider data, because Gemini requires it back on the next turn.
final class GeminiStreamDecoder {
  /// Creates a decoder for one response.
  factory() = GeminiStreamDecoder._;

  new _();

  final StringBuffer _thought = StringBuffer();
  String? _signature;
  int _calls = 0;
  FinishReason _reason = FinishReason.other;
  Usage _usage = const Usage();

  /// Returns the events contained in one decoded [chunk].
  Iterable<ModelEvent> accept(Object? chunk) sync* {
    if (chunk case {'usageMetadata': final Map<Object?, Object?> usage}) {
      _usage = readGeminiUsage(usage);
    }
    if (chunk case {'promptFeedback': {'blockReason': final String _}}) {
      _reason = FinishReason.contentFilter;
    }
    if (chunk case {
      'candidates': [final Map<Object?, Object?> candidate, ...],
    }) {
      if (candidate case {'content': {'parts': final List<Object?> parts}}) {
        for (final part in parts.whereType<Map<Object?, Object?>>()) {
          yield* _part(part);
        }
      }
      if (candidate case {'finishReason': final String reason}) {
        _reason = mapGeminiFinishReason(reason);
      }
    }
  }

  /// Returns pending reasoning and the finish event.
  List<ModelEvent> finish() => [
    ..._flushThought(),
    FinishEvent(
      reason: _calls > 0 && _reason == FinishReason.stop
          ? FinishReason.toolCalls
          : _reason,
      usage: _usage,
    ),
  ];

  Iterable<ModelEvent> _part(Map<Object?, Object?> part) sync* {
    final signature = part['thoughtSignature'];
    if (part case {'thought': true}) {
      if (part case {'text': final String text}) _thought.write(text);
      if (signature is String) _signature = signature;
      return;
    }
    yield* _flushThought();
    if (part case {'text': final String text} when text.isNotEmpty) {
      yield TextDelta(text);
    }
    if (part case {'functionCall': final Map<Object?, Object?> call}) {
      final index = _calls++;
      yield ToolCallEvent(
        ToolCallPart(
          id: call['id'] is String ? call['id']! as String : 'call_$index',
          name: '${call['name']}',
          arguments: call['args'] ?? <String, Object?>{},
          providerData: {
            if (signature is String) 'thoughtSignature': signature,
          },
        ),
      );
    }
  }

  List<ModelEvent> _flushThought() {
    if (_thought.isEmpty && _signature == null) return const [];
    final event = ReasoningEvent(
      ReasoningPart(
        provider: 'gemini',
        text: '$_thought',
        data: {
          'text': '$_thought',
          'thought': true,
          'thoughtSignature': ?_signature,
        },
      ),
    );
    _thought.clear();
    _signature = null;
    return [event];
  }
}
