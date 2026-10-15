import 'package:flutter_test/flutter_test.dart';

import 'ui_compare_bench.dart';
import 'ui_frame_bench.dart';

/// The UI frame benchmarks, which need no model, by mode name.
final Map<String, Future<Map<String, Object>> Function(WidgetTester)>
uiFrameModes = {'uiframes': runUiFrameBench, 'uicompare': runUiCompareBench};
