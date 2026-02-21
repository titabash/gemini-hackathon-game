/// OneSignal通知サービス
///
/// プラットフォームに応じた実装を自動的に選択:
/// - iOS/Android: OneSignal Flutter SDK を使用した実装
/// - Web: スタブ実装（OneSignal Flutter SDK は Web 未対応）
///
/// Web向けプッシュ通知が必要な場合は、OneSignal Web SDK を
/// 別途 JavaScript で統合する必要がある。
library;

export 'onesignal_service_stub.dart'
    if (dart.library.io) 'onesignal_service_mobile.dart';
