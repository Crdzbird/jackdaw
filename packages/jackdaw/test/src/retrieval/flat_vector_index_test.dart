import 'dart:typed_data';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

Float32List _v(List<double> values) => Float32List.fromList(values);

void main() {
  test('search returns exact cosine order and respects k', () async {
    final index = FlatVectorIndex(2);
    await index.add({
      'east': _v([1, 0]),
      'north': _v([0, 3]),
      'northeast': _v([2, 2]),
      'west': _v([-1, 0]),
    });
    final hits = await index.search(_v([1, 0.1]), k: 3);
    expect(hits.map((h) => h.id), ['east', 'northeast', 'north']);
    expect(hits.first.score, closeTo(0.995, 0.001));
    expect(await index.search(_v([1, 0]), k: 0), isEmpty);
    expect('${hits.first}', startsWith('VectorMatch(east'));
  });

  test('add replaces by id and remove keeps rows consistent', () async {
    final index = FlatVectorIndex(2);
    for (var i = 0; i < 40; i++) {
      await index.add({
        'v$i': _v([i.toDouble(), 1]),
      });
    }
    expect(index.length, 40);
    await index.add({
      'v0': _v([-1, 0]),
    });
    expect(index.length, 40);
    expect(await index.remove('v3'), isTrue);
    expect(await index.remove('v39'), isTrue);
    expect(await index.remove('v3'), isFalse);
    expect(index.length, 38);
    expect((await index.search(_v([-1, 0]), k: 1)).single.id, 'v0');
    expect(index.ids, isNot(contains('v3')));
    final all = await index.search(_v([1, 1]), k: 100);
    expect(all, hasLength(38));
  });

  test('wrong sizes fail and zero vectors are allowed', () async {
    final index = FlatVectorIndex(3);
    expect(
      () => index.add({
        'a': _v([1]),
      }),
      throwsArgumentError,
    );
    expect(() => index.search(_v([1, 2])), throwsArgumentError);
    await index.add({'zero': Float32List(3)});
    expect((await index.search(_v([1, 0, 0]))).single.score, 0);
    expect(normalized(Float32List(2)), [0, 0]);
  });

  test('the codec round-trips and rejects damaged data', () async {
    final index = FlatVectorIndex(3);
    await index.add({
      'a': _v([1, 2, 3]),
      'b': _v([3, 2, 1]),
    });
    final bytes = encodeFlatIndex(index);
    final copy = await decodeFlatIndex(bytes);
    expect(copy.ids, ['a', 'b']);
    expect(copy.dimensions, 3);
    final hits = await copy.search(_v([1, 2, 3]));
    expect(hits.first.id, 'a');
    expect(hits.first.score, closeTo(1, 1e-6));
    final bad = Uint8List.fromList(bytes)..[0] = 0;
    expect(() => decodeFlatIndex(bad), throwsFormatException);
    expect(() => decodeFlatIndex(Uint8List(4)), throwsFormatException);
    final truncated = Uint8List.sublistView(bytes, 0, 20);
    expect(() => decodeFlatIndex(truncated), throwsFormatException);
    final header = ByteData.sublistView(Uint8List.fromList(bytes))
      ..setUint32(12, 1, Endian.little);
    final short = header.buffer.asUint8List(0, 16 + 12);
    expect(
      () => decodeFlatIndex(
        Uint8List.fromList([...short, ...'["a","b"]'.codeUnits]),
      ),
      throwsFormatException,
    );
  });
}
