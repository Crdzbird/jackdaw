import 'package:jackdaw_native/src/native/cpu_check.dart';
import 'package:test/test.dart';

const _pixel = 'processor : 0\nFeatures : fp asimd aes asimddp lrcpc\n';
const _a53 = 'processor : 0\nFeatures : fp asimd evtstrm aes pmull\n';

void main() {
  test('dotprod builds need asimddp', () {
    expect(cpuProblem('dotprod', _pixel), isNull);
    expect(cpuProblem('dotprod', _a53), contains('android_cpu: baseline'));
  });

  test('baseline builds and unreadable cpuinfo pass', () {
    expect(cpuProblem('', _a53), isNull);
    expect(cpuProblem('dotprod', ''), isNull);
  });

  test('checkCpu only acts on Android', () {
    expect(() => checkCpu(android: false), returnsNormally);
    expect(
      () => checkCpu(android: true, readCpuInfo: () => _pixel),
      returnsNormally,
    );
    expect(() => checkCpu(android: true), returnsNormally);
  });

  test('checkCpu throws before an unsupported CPU can crash', () {
    expect(
      () => checkCpu(
        android: true,
        requirements: 'dotprod',
        readCpuInfo: () => _a53,
      ),
      throwsUnsupportedError,
    );
  });
}
