import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as log_pkg;

/// アプリケーションロガー
///
/// 開発環境: カラフルなコンソール出力
/// 本番環境: Warning/Error/Fatal のみ出力（将来: リモート送信対応）
class Logger {
  Logger._();

  static log_pkg.Logger? _instance;

  /// ロガーインスタンス（遅延初期化）
  static log_pkg.Logger get _logger {
    _instance ??= log_pkg.Logger(
      filter: _createFilter(),
      printer: log_pkg.PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: log_pkg.DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: _createOutput(),
    );
    return _instance!;
  }

  /// フィルター作成（環境別）
  static log_pkg.LogFilter _createFilter() {
    if (kDebugMode) {
      return log_pkg.DevelopmentFilter();
    }
    // 本番: Warning 以上のみ
    return _ProductionWarningFilter();
  }

  /// 出力先作成（将来のSentry/Crashlytics連携用フック）
  static log_pkg.LogOutput _createOutput() {
    // 開発: コンソール出力
    // 本番: 将来 MultiOutput で Sentry/Crashlytics へも送信
    return log_pkg.ConsoleOutput();
  }

  // --- Public API ---

  /// トレースログ - 詳細デバッグ用
  static void trace(
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// デバッグログ
  static void debug(
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 情報ログ
  static void info(
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 警告ログ
  static void warning(
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// エラーログ - 本番でも記録
  static void error(
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 致命的エラーログ - 本番でも記録
  static void fatal(
    dynamic message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// 本番用フィルター（Warning 以上のみ出力）
class _ProductionWarningFilter extends log_pkg.LogFilter {
  @override
  bool shouldLog(log_pkg.LogEvent event) {
    return event.level.index >= log_pkg.Level.warning.index;
  }
}
