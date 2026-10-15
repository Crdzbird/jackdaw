import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/schema/ui_catalog_guide.dart';
import 'package:jackdaw/src/ui/schema/ui_message_schema.dart';

/// The schema of a model's answer for [catalog]: up to four messages,
/// where only the first may create a surface, with [created] as its list
/// of components, and the others are [updates]. Local models are shown the
/// catalog guide instead of the full schema.
Schema uiReplySchema(
  UiCatalog catalog, {
  required Schema created,
  required List<ObjectSchema> updates,
}) => Schema.summarized(
  Schema.array(
    prefixItems: [
      AnyOfSchema([uiCreateSurfaceMessage(catalog.id, created), ...updates]),
    ],
    items: AnyOfSchema(updates),
    minItems: 1,
    maxItems: 4,
    description: 'A2UI v1.0 messages, applied in order.',
  ),
  summary: uiCatalogGuide(catalog),
);
