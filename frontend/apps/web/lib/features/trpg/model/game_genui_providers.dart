import 'package:core_api/core_api.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_genui/core_genui.dart';
import 'package:genui/genui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides a [GameContentGenerator] for SSE communication with the GM backend.
///
/// Uses manual Provider because genui types are incompatible with
/// riverpod_generator.
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

/// Provides an [A2uiMessageProcessor] that manages genui surfaces.
///
/// A2UI event forwarding is handled in `TrpgSessionNotifier` so turn-level
/// buffering can defer UI updates for future turns.
final gameProcessorProvider = Provider<A2uiMessageProcessor>((ref) {
  final catalog = GameCatalogItems.asCatalog(
    resolveImageUrl: (path) => _resolveStorageUrl(ref, path),
  );
  final processor = A2uiMessageProcessor(catalogs: [catalog]);
  ref.onDispose(processor.dispose);
  return processor;
});
