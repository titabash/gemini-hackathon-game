// core_genui - GenUI SDK integration with custom SSE ContentGenerator
//
// Provides a ContentGenerator backed by SSE to a Python FastAPI backend,
// conversation management, and a chat surface widget.

// Content Generator
export 'content_generator/content_generator_config.dart';
export 'content_generator/sse_content_generator.dart';

// Catalog
export 'catalog/app_catalog_items.dart';

// Models
export 'models/conversation_state.dart';
export 'models/genui_message.dart';

// Providers
export 'providers/content_generator_provider.dart';
export 'providers/conversation_provider.dart';
export 'providers/surface_provider.dart';

// Widgets
export 'widgets/genui_chat_surface.dart';
