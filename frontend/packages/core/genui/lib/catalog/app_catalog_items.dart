import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/v0_9/basic_catalog.dart' as v0_9;

/// Application-specific catalog items for the A2UI renderer.
///
/// Extend this class to register custom widget builders that the LLM
/// can instantiate via A2UI messages.
class AppCatalogItems {
  const AppCatalogItems._();

  /// Returns a [CatalogImplementation] containing the A2UI v0.9 basic
  /// components plus any application-specific items.
  static CatalogImplementation asCatalog({
    List<ComponentImplementation>? additionalItems,
  }) {
    final basicCatalog = v0_9.basicCatalog();
    if (additionalItems == null || additionalItems.isEmpty) {
      return basicCatalog;
    }
    return basicCatalog.derive(
      catalogId: basicCatalog.id,
      addComponents: additionalItems,
    );
  }
}
