# 統合テスト（Integration Tests）

このディレクトリには、アプリケーション全体のエンドツーエンドテストが含まれています。

## テストファイル

- `app_test.dart` - 基本的なアプリケーション起動とUI表示のテスト
- `navigation_test.dart` - GoRouterを使用したナビゲーションのテスト
- `auth_flow_test.dart` - 認証フローの統合テスト

## プラットフォーム別実行方法

### macOS / iOS / Androidデバイス

デバイスまたはシミュレータを接続した状態で：

```bash
# すべての統合テストを実行
flutter test integration_test/

# 特定のテストファイルを実行
flutter test integration_test/app_test.dart

# macOSで実行
flutter test integration_test/app_test.dart -d macos

# iOSシミュレータで実行
flutter test integration_test/app_test.dart -d ios

# Androidエミュレータで実行
flutter test integration_test/app_test.dart -d android
```

### Web環境（Chrome）

**重要**: Web環境での統合テストには特別な手順が必要です。

#### 前提条件

ChromeDriverのインストールと起動：

```bash
# ChromeDriverをインストール
npx @puppeteer/browsers install chromedriver@stable

# ChromeDriverを起動（別のターミナルで）
chromedriver --port=4444
```

#### テスト実行

```bash
# Web統合テストを実行
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome

# 特定のテストファイルを実行
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/auth_flow_test.dart \
  -d chrome
```

## Makeコマンドでの実行

プロジェクトルートから：

```bash
# すべての統合テストを実行（利用可能なデバイスで）
make frontend-integration-test

# Web app専用の統合テストを実行
make frontend-integration-test-web

# すべてのテスト（ユニット、ウィジェット、統合）を実行
make frontend-test-all
```

## テスト作成のベストプラクティス

### 1. IntegrationTestWidgetsFlutterBindingの初期化

すべての統合テストファイルで必須：

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // テストコード...
}
```

### 2. ウィジェットにキーを設定

テスト対象のウィジェットには識別用のキーを付与：

```dart
FloatingActionButton(
  key: const ValueKey('increment_button'),
  onPressed: _incrementCounter,
  child: const Icon(Icons.add),
)
```

### 3. 非同期処理の待機

アニメーションや状態更新を待つには`pumpAndSettle()`を使用：

```dart
await tester.tap(find.byKey(const ValueKey('increment_button')));
await tester.pumpAndSettle(); // アニメーション完了まで待機
expect(find.text('1'), findsOneWidget);
```

### 4. 外部依存のモック化

Supabaseなど外部サービスはProviderScopeでモック化：

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      supabaseProvider.overrideWithValue(FakeSupabaseClient()),
    ],
    child: const App(),
  ),
);
```

### 5. テストの独立性

各テストは独立して実行できるように：

- 共有状態を避ける
- 各テストで新しいProviderScopeを作成
- テスト間で副作用を持たない

## トラブルシューティング

### Web環境で "Web devices are not supported for integration tests yet" エラー

→ `flutter test`ではなく`flutter drive`を使用してください。

### "No devices are connected" エラー

→ デバイス/シミュレータを接続するか、`-d <device_id>`でデバイスを指定してください。

### ChromeDriverが見つからない

→ ChromeDriverをインストールして起動してください：
```bash
npx @puppeteer/browsers install chromedriver@stable
chromedriver --port=4444
```

### CocoaPodsエラー（macOS/iOS）

→ CocoaPodsを更新してください：
```bash
sudo gem install cocoapods
pod repo update
```

## 参考資料

- [Flutter公式 - Integration testing](https://docs.flutter.dev/testing/integration-tests)
- [integration_testパッケージ](https://pub.dev/packages/integration_test)
- [Riverpod - Testing](https://riverpod.dev/docs/essentials/testing)
