import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('chunks follow paragraphs and sentences within the limit', () {
    final chunker = TextChunker(maxChars: 40, overlap: 15);
    final chunks = chunker.split(
      const Document(
        id: 'doc',
        text:
            'Kestrels hover. They hunt voles.\n\n'
            'Jackdaws are clever corvids. They cache food.',
        metadata: {'lang': 'en'},
      ),
    );
    expect(chunks.map((c) => c.text), [
      'Kestrels hover. They hunt voles.',
      'Jackdaws are clever corvids.',
      'They cache food.',
    ]);
    for (final chunk in chunks) {
      expect(chunk.text.length, lessThanOrEqualTo(40));
    }
    expect(chunks.first.id, 'doc#0');
    expect(chunks.first.metadata, {'lang': 'en', 'source': 'doc', 'chunk': 0});
  });

  test('a long sentence is cut and short text is one chunk', () {
    final chunker = TextChunker(maxChars: 10, overlap: 0);
    final chunks = chunker.split(Document(id: 'x', text: 'a' * 25));
    expect(chunks.map((c) => c.text.length), [10, 10, 5]);
    expect(
      TextChunker().split(const Document(id: 'y', text: 'hi')),
      hasLength(1),
    );
    expect(TextChunker().split(const Document(id: 'z', text: '  ')), isEmpty);
  });

  test('overlap repeats whole trailing sentences', () {
    final chunker = TextChunker(maxChars: 30, overlap: 12);
    final chunks = chunker.split(
      const Document(
        id: 'd',
        text: 'One two three. Four five. Six seven eight.',
      ),
    );
    expect(chunks.map((c) => c.text), [
      'One two three. Four five.',
      'Four five. Six seven eight.',
    ]);
  });

  test('invalid settings are rejected and documents round-trip', () {
    expect(() => TextChunker(maxChars: 0), throwsArgumentError);
    expect(() => TextChunker(maxChars: 10, overlap: 10), throwsArgumentError);
    const doc = Document(id: 'a', text: 'b', metadata: {'c': 1});
    final copy = Document.fromJson(doc.toJson());
    expect(copy.toJson(), doc.toJson());
  });
}
