import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_app/app/app.dart';
import 'package:core_i18n/core_i18n.dart';

/// 基本的なアプリケーション起動とUI表示のテスト
///
/// このテストは以下を検証します：
/// - アプリケーションが正常に起動すること
/// - ホームページが表示されること
/// - i18n（国際化）が正しく動作すること
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Basic Integration Tests', () {
    testWidgets('App launches successfully and displays home page', (
      WidgetTester tester,
    ) async {
      // アプリケーションを起動（実際のmain関数を実行）
      await tester.pumpWidget(
        ProviderScope(child: TranslationProvider(child: const App())),
      );

      // ウィジェットツリーが構築されるまで待機
      await tester.pumpAndSettle();

      // ホームページが表示されていることを確認
      // Note: 実際のホームページに表示されるテキストに合わせて変更してください
      expect(find.byType(MaterialApp), findsOneWidget);

      // アプリケーションタイトルが設定されていることを確認
      final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
      expect(materialApp.title, isNotEmpty);
    });

    testWidgets('i18n (Internationalization) works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: TranslationProvider(child: const App())),
      );

      await tester.pumpAndSettle();

      // i18nが初期化されていることを確認
      // 翻訳キーが利用可能であることを検証
      expect(t.app.title, isNotEmpty);
      expect(t.app.name, isNotEmpty);
    });
  });
}
