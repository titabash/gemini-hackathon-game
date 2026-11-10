import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../catalog/app_catalog_items.dart';
import '../conversation/genui_conversation.dart';
import 'content_generator_provider.dart';

/// Provides a [GenuiConversation] instance wired to the SSE content generator.
///
/// Uses a manual Provider to keep the shape it had with genui's
/// `GenUiConversation`, which was not compatible with riverpod_generator's
/// code generation.
final genuiConversationProvider = Provider<GenuiConversation>((ref) {
  final contentGenerator = ref.watch(contentGeneratorProvider);
  final catalog = AppCatalogItems.asCatalog();

  final processor = MessageProcessor<ComponentImplementation>(
    catalogs: [catalog],
    validationConfig: ValidationConfig.relaxed,
    reportErrorsOnly: true,
  );

  final conversation = GenuiConversation(
    contentGenerator: contentGenerator,
    processor: processor,
  );

  ref.onDispose(conversation.dispose);

  return conversation;
});
