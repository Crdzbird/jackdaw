import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/schema/ui_schemas.dart';

final Expando<UiSchemas> _shared = Expando();

/// The schemas of a catalog, shared.
extension UiCatalogSchemas on UiCatalog {
  /// The [UiSchemas] of this catalog with the default limits, built once
  /// and shared by every surface set and target, since building them
  /// takes a while.
  UiSchemas get schemas => _shared[this] ??= UiSchemas(this);
}
