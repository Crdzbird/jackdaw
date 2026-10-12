import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('emits the tail after the source completes', () async {
    var flushed = false;
    final events = await Stream.fromIterable([1, 2])
        .transform(
          appendOnDone(() {
            flushed = true;
            return [3, 4];
          }),
        )
        .toList();
    expect(events, [1, 2, 3, 4]);
    expect(flushed, isTrue);
  });
}
