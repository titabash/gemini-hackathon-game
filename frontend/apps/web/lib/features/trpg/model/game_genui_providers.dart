import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:core_api/core_api.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_genui/core_genui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides a [GameContentGenerator] for SSE communication with the GM backend.
///
/// Uses a manual Provider rather than riverpod_generator.
final gameContentGeneratorProvider = Provider<GameContentGenerator>((ref) {
  final sseFactory = ref.read(sseClientFactoryProvider);
  final generator = GameContentGenerator(sseClientFactory: sseFactory);
  ref.onDispose(generator.dispose);
  return generator;
});

/// Resolves a raw storage path (e.g. `scenario-assets/npcs/wizard.png`)
/// to a full Supabase public URL using `getPublicUrl`.
String _resolveStorageUrl(Ref ref, String path) {
  final sep = path.indexOf('/');
  if (sep == -1) return path;
  final bucket = path.substring(0, sep);
  final objectPath = path.substring(sep + 1);
  final supabase = ref.read(supabaseClientProvider);
  return supabase.storage.from(bucket).getPublicUrl(objectPath);
}

/// Provides the A2UI [MessageProcessor] that manages the game surfaces.
///
/// A2UI event forwarding is handled in `TrpgSessionNotifier` so turn-level
/// buffering can defer UI updates for future turns. Rejected messages are
/// reported on `processor.model.onError` instead of being thrown.
final gameProcessorProvider =
    Provider<MessageProcessor<ComponentImplementation>>((ref) {
      final catalog = GameCatalogItems.asCatalog(
        resolveImageUrl: (path) => _resolveStorageUrl(ref, path),
      );
      final processor = MessageProcessor<ComponentImplementation>(
        catalogs: [catalog],
        validationConfig: ValidationConfig.relaxed,
        reportErrorsOnly: true,
      );
      ref.onDispose(processor.dispose);
      return processor;
    });
