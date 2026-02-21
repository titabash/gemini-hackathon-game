import 'package:integration_test/integration_test_driver.dart';

/// Web環境での統合テスト実行用ドライバー
///
/// Web環境で統合テストを実行するには、flutter driveコマンドと
/// このドライバーファイルが必要です。
///
/// 実行方法:
/// 1. ChromeDriverを起動:
///    npx @puppeteer/browsers install chromedriver@stable
///    chromedriver --port=4444
///
/// 2. テストを実行:
///    flutter drive \
///      --driver=test_driver/integration_test.dart \
///      --target=integration_test/app_test.dart \
///      -d chrome
Future<void> main() => integrationDriver();
