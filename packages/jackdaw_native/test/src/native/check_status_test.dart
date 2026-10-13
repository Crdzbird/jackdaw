import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';
import 'package:test/test.dart';

void main() {
  test('rejects a library built for another ABI', () {
    expect(() => checkAbiVersion(999), throwsStateError);
    expect(() => checkAbiVersion(JACKDAW_ABI_VERSION), returnsNormally);
    expect(checkAbi, returnsNormally);
  });

  test('native exceptions describe themselves', () {
    const error = NativeException(4, 'grammar does not parse');
    expect('$error', 'NativeException(4): grammar does not parse');
    expect(error.status, 4);
  });
}
