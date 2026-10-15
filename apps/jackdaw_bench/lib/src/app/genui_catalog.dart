import 'package:flutter/material.dart';
import 'package:genui/genui.dart' as genui;
import 'package:jackdaw_bench/src/app/demo_catalog.dart';
import 'package:jackdaw_bench/src/app/demo_colors.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// The demo's Panel for genui: the same colored background as the
/// jackdaw_flutter one, as a genui catalog item.
final genui.CatalogItem genuiPanel = genui.CatalogItem(
  name: 'Panel',
  dataSchema: S.object(
    description: 'A colored background around one child.',
    properties: {
      'color': S.string(enumValues: [...demoColors.keys]),
      'child': genui.A2uiSchemas.componentReference(),
    },
    required: ['color', 'child'],
  ),
  widgetBuilder: (item) => switch (item.data) {
    {'color': final String? color, 'child': final String child} => ColoredBox(
      color: demoColor(color),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: item.buildChild(child),
      ),
    ),
    _ => const SizedBox.shrink(),
  },
);

/// genui's basic catalog plus [genuiPanel], under the id of
/// [demoCatalog], so genui draws every component jackdaw_flutter does.
final genui.Catalog demoGenuiCatalog = genui.BasicCatalogItems.asCatalog()
    .copyWith(newItems: [genuiPanel], catalogId: demoCatalog.id);
