import 'package:genui/genui.dart';

/// Application-specific catalog items for the genui SDK.
///
/// Extend this class to register custom widget builders that the LLM
/// can instantiate via A2UI messages.
class AppCatalogItems {
  const AppCatalogItems._();

  /// Returns a [Catalog] containing the core items plus any
  /// application-specific items.
  static Catalog asCatalog({List<CatalogItem>? additionalItems}) {
    final coreCatalog = CoreCatalogItems.asCatalog();
    if (additionalItems == null || additionalItems.isEmpty) {
      return coreCatalog;
    }
    return coreCatalog.copyWith(additionalItems);
  }
}
