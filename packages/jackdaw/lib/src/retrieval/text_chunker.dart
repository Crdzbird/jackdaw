import 'dart:math' as math;

import 'package:jackdaw/src/retrieval/document.dart';

/// Splits long documents into chunks small enough to embed and to quote.
///
/// Chunks end at paragraph breaks where possible, then at sentence ends,
/// and only cut words when a single sentence is longer than [maxChars].
/// Each chunk repeats up to [overlap] characters of whole segments from the
/// end of the one before, so a fact split across a boundary is still found.
final class TextChunker {
  /// Creates a chunker; [overlap] must be smaller than [maxChars].
  factory({int maxChars = 1000, int overlap = 150}) {
    if (maxChars <= 0 || overlap < 0 || overlap >= maxChars) {
      throw ArgumentError('need 0 <= overlap < maxChars');
    }
    return TextChunker._(maxChars, overlap);
  }

  const new _(this.maxChars, this.overlap);

  /// Longest chunk, in characters.
  final int maxChars;

  /// Characters repeated from the previous chunk.
  final int overlap;

  static final RegExp _paragraphs = RegExp(r'\n\s*\n');
  static final RegExp _sentences = RegExp(r'(?<=[.!?])\s+');

  /// Splits [document] into chunks with ids `id#0`, `id#1` and so on; each
  /// keeps the metadata and adds `source` and `chunk`.
  List<Document> split(Document document) {
    final chunks = <List<String>>[];
    var current = <String>[];
    for (final segment in _segments(document.text)) {
      if (current.isNotEmpty && _size([...current, segment]) > maxChars) {
        chunks.add(current);
        current = [..._tail(current, maxChars - segment.length - 1)];
      }
      current.add(segment);
    }
    if (current.isNotEmpty) chunks.add(current);
    return [
      for (final (i, parts) in chunks.indexed)
        Document(
          id: '${document.id}#$i',
          text: parts.join(' '),
          metadata: {...document.metadata, 'source': document.id, 'chunk': i},
        ),
    ];
  }

  Iterable<String> _segments(String text) sync* {
    for (final paragraph in text.split(_paragraphs)) {
      for (final sentence in paragraph.trim().split(_sentences)) {
        var rest = sentence.trim();
        while (rest.length > maxChars) {
          yield rest.substring(0, maxChars);
          rest = rest.substring(maxChars);
        }
        if (rest.isNotEmpty) yield rest;
      }
    }
  }

  List<String> _tail(List<String> parts, int room) {
    final kept = <String>[];
    for (final part in parts.reversed) {
      if (_size([part, ...kept]) > math.min(overlap, room)) break;
      kept.insert(0, part);
    }
    return kept;
  }

  int _size(List<String> parts) =>
      parts.fold(parts.length - 1, (sum, p) => sum + p.length);
}
