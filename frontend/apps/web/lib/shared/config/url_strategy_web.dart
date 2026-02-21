import 'package:flutter_web_plugins/url_strategy.dart';

/// Web環境用のURL戦略を設定します。
/// PathUrlStrategyを使用してクリーンなURL（#なし）を実現します。
void configureApp() {
  // PathUrlStrategyを設定して、URLから#を削除
  usePathUrlStrategy();
}
