import 'package:flutter_test/flutter_test.dart';

import 'bench_config.dart';
import 'compare_create.dart';
import 'compare_side.dart';
import 'compare_writes.dart';
import 'genui_side.dart';
import 'jackdaw_side.dart';

/// Claim C14 against genui: the same [count] components drawn by both,
/// each alone on screen, then written [updates] times with both on
/// screen, the sides taking turns one frame each. The sides create their
/// screens in alternating order: a warm-up round, then [rounds] reported.
Future<Map<String, Object>> runUiCompareBench(
  WidgetTester tester, {
  int count = 40,
  int updates = 120,
  int rounds = 5,
}) async {
  for (var round = 0; round <= rounds; round++) {
    final made = [JackdawSide(), GenuiSide()];
    final sides = <CompareSide>[...round.isEven ? made : made.reversed];
    final created = {
      for (final side in sides)
        side.name: await measureCreate(tester, side, count),
    };
    final written = await measureWrites(tester, sides, count, updates);
    if (round > 0) {
      for (final side in made) {
        benchReport('uicompare', {
          'side': side.name,
          ...created[side.name]!,
          ...written[side.name]!,
        });
      }
    }
    for (final side in made) {
      side.dispose();
    }
  }
  return {'components': count, 'updates': updates, 'rounds': rounds};
}
