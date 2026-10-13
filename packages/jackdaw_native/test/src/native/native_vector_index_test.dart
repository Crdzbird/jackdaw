import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

Float32List _random(Random random, int dims) => Float32List.fromList([
  for (var i = 0; i < dims; i++) random.nextDouble() * 2 - 1,
]);

void main() {
  test('matches the exact Dart index on random data', () async {
    final random = Random(5);
    final native = NativeVectorIndex(32);
    final exact = FlatVectorIndex(32);
    final vectors = {for (var i = 0; i < 2000; i++) 'v$i': _random(random, 32)};
    await native.add(vectors);
    await exact.add(vectors);
    expect(native.length, 2000);
    var found = 0;
    for (var q = 0; q < 30; q++) {
      final query = _random(random, 32);
      final want = (await exact.search(query)).map((m) => m.id).toSet();
      final got = await native.search(query);
      found += got.where((m) => want.contains(m.id)).length;
      expect(
        got.first.score,
        closeTo((await exact.search(query, k: 1)).single.score, 0.05),
      );
    }
    expect(found / 300, greaterThanOrEqualTo(0.95));
    native.dispose();
  });

  test('replaces, removes and checks sizes', () async {
    final index = NativeVectorIndex(2);
    await index.add({
      'a': Float32List.fromList([1, 0]),
      'b': Float32List.fromList([0, 1]),
    });
    await index.add({
      'a': Float32List.fromList([-1, 0]),
    });
    expect(index.length, 2);
    final west = await index.search(Float32List.fromList([-1, 0.1]), k: 1);
    expect(west.single.id, 'a');
    expect(await index.remove('a'), isTrue);
    expect(await index.remove('a'), isFalse);
    expect(index.length, 1);
    expect(() => index.add({'c': Float32List(3)}), throwsArgumentError);
    expect(() => index.search(Float32List(1)), throwsArgumentError);
    await expectLater(
      index.add({
        'nan': Float32List.fromList([double.nan, 0]),
      }),
      throwsA(isA<NativeException>()),
    );
    index.dispose();
  });

  test('saves and reopens with ids, and rejects mismatched files', () async {
    final dir = await Directory.systemTemp.createTemp('jackdaw_index');
    final path = '${dir.path}/kb.index';
    final index = NativeVectorIndex(3);
    await index.add({
      'x': Float32List.fromList([1, 2, 3]),
      'y': Float32List.fromList([3, 2, 1]),
    });
    await saveIndex(index, path);
    final reopened = await openIndex(path);
    expect(reopened.length, 2);
    expect(
      (await reopened.search(Float32List.fromList([1, 2, 3]), k: 1)).single.id,
      'x',
    );
    await reopened.add({
      'z': Float32List.fromList([0, 0, 1]),
    });
    expect(reopened.keys.keyFor('z'), 3);
    await File('$path.ids.json')
        .writeAsString('{"next":2,"keys":[1],"ids":["x"]}');
    await expectLater(openIndex(path), throwsFormatException);
    await File('$path.ids.json')
        .writeAsString('{"next":2,"keys":[1,2],"ids":["x"]}');
    await expectLater(openIndex(path), throwsFormatException);
    await File(path).writeAsString('junk');
    await expectLater(openIndex(path), throwsA(isA<NativeException>()));
    index.dispose();
    reopened.dispose();
    await dir.delete(recursive: true);
  });
}
