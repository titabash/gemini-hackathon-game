# Logging Policy

このドキュメントは Frontend (Flutter) と Backend (Python) 両方のロギングポリシーを定義する。

---

# Frontend (Flutter) Logging Policy

**MANDATORY**: Flutter アプリケーションログは統一された Logger クラスを使用する。

## 基本原則

| 環境 | 動作 |
|------|------|
| **Debug（開発）** | 全ログレベルをカラフルに出力 |
| **Profile** | Warning 以上のみ出力 |
| **Release（本番）** | Warning 以上のみ出力（将来: Sentry/Crashlytics へ送信） |

## Logger の使用方法

### インポート

```dart
import 'package:core_utils/core_utils.dart';
```

### ログレベル

| レベル | メソッド | 用途 | 本番出力 |
|--------|----------|------|----------|
| Trace | `Logger.trace()` | 詳細デバッグ（通常OFF） | ❌ |
| Debug | `Logger.debug()` | 開発時デバッグ情報 | ❌ |
| Info | `Logger.info()` | 重要な処理の開始・完了 | ❌ |
| Warning | `Logger.warning()` | 注意が必要な状況 | ✅ |
| Error | `Logger.error()` | エラー発生 | ✅ |
| Fatal | `Logger.fatal()` | 致命的エラー | ✅ |

### 使用例

```dart
// 情報ログ
Logger.info('Starting Flutter application');

// デバッグログ
Logger.debug('Fetching user data for id: $userId');

// 警告ログ
Logger.warning('Cache expired, fetching fresh data');

// エラーログ（error と stackTrace を含める）
try {
  await fetchData();
} catch (e, st) {
  Logger.error('Failed to fetch data', e, st);
}

// 致命的エラー
Logger.fatal('Database connection lost', error, stackTrace);
```

## 開発時の出力例

```
┌──────────────────────────────────────────────────────────────────────────────
│ 💡 Starting Flutter application with Supabase
└──────────────────────────────────────────────────────────────────────────────

┌──────────────────────────────────────────────────────────────────────────────
│ #0   CounterApi.getCounter (package:web/features/counter/api/counter_api.dart:15)
│ #1   CounterNotifier.build (package:web/features/counter/model/counter_provider.dart:23)
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ 💬 Fetching counter value from API
└──────────────────────────────────────────────────────────────────────────────

┌──────────────────────────────────────────────────────────────────────────────
│ ⛔ Failed to fetch counter
│ Error: SocketException: Connection refused
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ #0   CounterApi.getCounter (package:web/features/counter/api/counter_api.dart:18)
│ #1   CounterNotifier.build (package:web/features/counter/model/counter_provider.dart:23)
│ ...
└──────────────────────────────────────────────────────────────────────────────
```

## ログレベルの選択基準

### Logger.info() を使う場面

- アプリケーション起動・終了
- 重要な処理の開始・完了
- ユーザーアクション（ログイン、ログアウト等）
- API リクエストの開始

```dart
Logger.info('User logged in: $userId');
Logger.info('Payment completed: $orderId');
```

### Logger.debug() を使う場面

- 変数の値の確認
- 処理フローの追跡
- 開発時のみ必要な情報

```dart
Logger.debug('Request payload: $payload');
Logger.debug('Cache hit for key: $key');
```

### Logger.warning() を使う場面

- 非推奨機能の使用
- リトライが必要な一時的エラー
- パフォーマンス問題の兆候

```dart
Logger.warning('API response slow: ${response.duration}ms');
Logger.warning('Cache miss, fetching from network');
```

### Logger.error() を使う場面

- 例外のキャッチ
- API エラーレスポンス
- ビジネスロジックエラー

```dart
try {
  await api.fetchUser(id);
} catch (e, st) {
  Logger.error('Failed to fetch user: $id', e, st);
  rethrow; // または適切なエラーハンドリング
}
```

### Logger.fatal() を使う場面

- アプリケーションの続行が不可能なエラー
- データ破損の検出
- セキュリティ違反

```dart
Logger.fatal('Database integrity check failed', error, stackTrace);
```

## 禁止パターン

```dart
// ❌ print() の使用禁止
print('Debug: $value');

// ❌ debugPrint() の直接使用禁止
debugPrint('[ERROR] $message');

// ✅ Logger を使用
Logger.debug('Value: $value');
Logger.error('Error occurred', error, stackTrace);
```

## HTTP ログ（Dio Interceptor）

HTTP リクエスト/レスポンスのログは `core_api` パッケージの `LoggingInterceptor` が自動出力:

```
→ GET https://api.example.com/users
← 200 OK (152ms)
```

詳細は `frontend/packages/core/api/lib/interceptors/logging_interceptor.dart` を参照。

## 将来の拡張（エラーモニタリング）

本番環境でのアラート検知のため、`Logger` クラスは `LogOutput` インターフェースで拡張可能:

```dart
// 将来実装予定
class SentryOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    if (event.level.index >= Level.error.index) {
      Sentry.captureMessage(event.lines.join('\n'));
    }
  }
}
```

## 実装場所

| ファイル | 説明 |
|----------|------|
| `frontend/packages/core/utils/lib/logger/logger.dart` | Logger クラス本体 |
| `frontend/packages/core/api/lib/interceptors/logging_interceptor.dart` | HTTP ログ |

## Enforcement

このフロントエンドロギングポリシーは **NON-NEGOTIABLE**。`print()` や `debugPrint()` の直接使用は却下される。

---

# Backend (Python) Logging Policy

**MANDATORY**: バックエンド Python のログは `src/util/logging.py` の統一ロガーを使用する。

## 基本原則

| 環境 | 動作 |
|------|------|
| **Development** | カラフルなコンソール出力（ConsoleRenderer） |
| **Production** | JSON 出力（orjson シリアライズ） |

## Logger の使用方法

### インポートと初期化

```python
from src.util.logging import configure_logging, get_logger

# アプリ起動時に1回だけ呼び出し（app.py で実行済み）
configure_logging()

# ロガー取得
logger = get_logger(__name__)
```

### ログ出力

```python
# 情報ログ
logger.info("User logged in", user_id=user_id)

# デバッグログ
logger.debug("Fetching data", endpoint=endpoint, params=params)

# 警告ログ
logger.warning("Cache miss", key=cache_key)

# エラーログ（例外情報付き）
try:
    await fetch_data()
except Exception as e:
    logger.error("Failed to fetch data", error=str(e), exc_info=True)

# 構造化データ付きログ
logger.info(
    "Request processed",
    method=request.method,
    path=request.url.path,
    status_code=response.status_code,
    duration_ms=duration * 1000,
)
```

### リクエストコンテキスト追跡

ミドルウェアで自動設定されるコンテキスト情報：

```python
from src.util.logging import set_request_context, clear_request_context

# リクエスト開始時（ミドルウェアで自動実行）
set_request_context(request_id="uuid-xxx", user_id="user-123")

# リクエスト終了時（ミドルウェアで自動実行）
clear_request_context()

# ログには自動的に request_id, user_id が含まれる
logger.info("Processing request")  # → {"request_id": "uuid-xxx", "user_id": "user-123", ...}
```

## ログレベル

| レベル | メソッド | 用途 |
|--------|----------|------|
| DEBUG | `logger.debug()` | 開発時デバッグ情報 |
| INFO | `logger.info()` | 重要な処理の開始・完了 |
| WARNING | `logger.warning()` | 注意が必要な状況 |
| ERROR | `logger.error()` | エラー発生 |
| CRITICAL | `logger.critical()` | 致命的エラー |

ログレベルは `LOG_LEVEL` 環境変数で制御（デフォルト: `INFO`）。

## 開発時の出力例

```
2024-01-15T10:30:00.123456Z [info     ] User logged in                 request_id=abc-123 user_id=user-456
2024-01-15T10:30:00.234567Z [debug    ] Fetching data                  endpoint=/api/users params={'limit': 10}
2024-01-15T10:30:00.345678Z [error    ] Failed to fetch data           error=Connection refused
```

## 本番時の出力例（JSON）

```json
{"event": "User logged in", "level": "info", "timestamp": "2024-01-15T10:30:00.123456Z", "request_id": "abc-123", "user_id": "user-456"}
```

## 禁止パターン

```python
# ❌ print() の使用禁止
print("Debug: ", value)

# ❌ 標準 logging の直接使用禁止
import logging
logging.info("message")

# ❌ f-string でログメッセージを構築（構造化が失われる）
logger.info(f"User {user_id} logged in")

# ✅ 構造化パラメータを使用
logger.info("User logged in", user_id=user_id)
```

## 実装場所

| ファイル | 説明 |
|----------|------|
| `backend-py/app/src/util/logging.py` | ロギング設定・ユーティリティ |
| `backend-py/app/src/middleware/` | リクエストコンテキスト設定 |

## Enforcement

このバックエンドロギングポリシーは **NON-NEGOTIABLE**。`print()` や標準 `logging` モジュールの直接使用は却下される。
