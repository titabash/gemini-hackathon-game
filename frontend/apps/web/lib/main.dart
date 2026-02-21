import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_i18n/core_i18n.dart';
import 'package:core_utils/core_utils.dart';
import 'package:core_auth/core_auth.dart';
import 'app/app.dart';

// 条件付きインポート: Web環境ではurl_strategy_web.dart、それ以外ではurl_strategy_stub.dartをインポート
// dart.library.js_interopを使用してWasm対応の将来性を確保
import 'shared/config/url_strategy_stub.dart'
    if (dart.library.js_interop) 'shared/config/url_strategy_web.dart';

/// Entry point of the Flutter application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web環境でのURL戦略を設定（PathUrlStrategyを使用してクリーンなURLを実現）
  configureApp();

  // Initialize slang for i18n
  LocaleSettings.useDeviceLocale(); // Initialize with device locale

  // Initialize Supabase
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
  );

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Initialize and launch the application
  Logger.info('Starting Flutter application with Supabase');
  runApp(
    ProviderScope(
      child: TranslationProvider(child: const AuthListener(child: App())),
    ),
  );
}
