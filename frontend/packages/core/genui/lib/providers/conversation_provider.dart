import 'package:genui/genui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../catalog/app_catalog_items.dart';
import 'content_generator_provider.dart';

/// Provides a [GenUiConversation] instance wired to the SSE content generator.
///
/// Uses a manual Provider because genui's [GenUiConversation] type is not
/// compatible with riverpod_generator's code generation.
final genuiConversationProvider = Provider<GenUiConversation>((ref) {
  final contentGenerator = ref.watch(contentGeneratorProvider);
  final catalog = AppCatalogItems.asCatalog();

  final processor = A2uiMessageProcessor(catalogs: [catalog]);

  final conversation = GenUiConversation(
    contentGenerator: contentGenerator,
    a2uiMessageProcessor: processor,
  );

  ref.onDispose(conversation.dispose);

  return conversation;
});
