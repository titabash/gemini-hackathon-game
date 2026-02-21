# Date/Time Handling Policy

**MANDATORY**: 日時はUTCでデータベースに保存し、フロントエンドでローカルタイムゾーンに変換する。

## 基本原則

| レイヤー | タイムゾーン | 理由 |
|---------|-----------|------|
| **Database** | UTC | グローバル標準、タイムゾーン問題回避 |
| **Backend API** | UTC | タイムゾーン変換不要 |
| **Frontend Display** | Local | ユーザーの現在地時刻で表示 |

## データベース（PostgreSQL）

```sql
-- ✅ CORRECT: timestamp with time zone (timestamptz)
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
updated_at TIMESTAMP WITH TIME ZONE

-- ❌ WRONG: timestamp without time zone
created_at TIMESTAMP DEFAULT NOW()  -- タイムゾーン情報なし
```

**Drizzle スキーマ**:
```typescript
import { timestamp } from 'drizzle-orm/pg-core'

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow(),
})
```

## Backend (Python FastAPI)

```python
from datetime import datetime, timezone

# ✅ CORRECT: UTC で返す
def get_user():
    return {
        "created_at": datetime.now(timezone.utc).isoformat()  # UTC
    }

# ❌ WRONG: ローカルタイムゾーンで返す
def get_user():
    return {
        "created_at": datetime.now().isoformat()  # ローカルタイムゾーン（非推奨）
    }
```

## Frontend (Flutter)

### データベース/API からの受信

```dart
// API/DBからはUTC文字列で受信
final userJson = {
  'created_at': '2024-01-15T10:30:00Z',  // ISO 8601 UTC
};

// Dart DateTime に変換（UTC）
final createdAt = DateTime.parse(userJson['created_at'] as String);
print(createdAt.isUtc);  // true
```

### ユーザーへの表示（ローカルタイムゾーン）

```dart
import 'package:intl/intl.dart';

// UTC → Local 変換
final localTime = createdAt.toLocal();

// フォーマット
final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
final formattedTime = formatter.format(localTime);

// 表示
Text(formattedTime)  // "2024-01-15 19:30:00" (JST の場合)
```

### 相対時間表示

```dart
import 'package:timeago/timeago.dart' as timeago;

// 日本語設定
timeago.setLocaleMessages('ja', timeago.JaMessages());

// 相対時間
final relative = timeago.format(
  createdAt,
  locale: 'ja',
);
Text(relative)  // "1時間前"
```

### データベース/API への送信

```dart
// ユーザー入力（ローカルタイムゾーン）
final selectedDate = DateTime(2024, 1, 15, 10, 30);  // Local

// UTC に変換してから送信
final utcDate = selectedDate.toUtc();
final isoString = utcDate.toIso8601String();

// API送信
await apiClient.createEvent(startTime: isoString);
```

## パターン例

### 現在時刻の取得

```dart
// ✅ CORRECT: UTC で取得
final now = DateTime.now().toUtc();

// ❌ WRONG: ローカルタイムゾーンで取得（DB保存用には使わない）
final now = DateTime.now();
```

### タイムスタンプの比較

```dart
// すべてUTCに統一してから比較
final date1Utc = date1.toUtc();
final date2Utc = date2.toUtc();

if (date1Utc.isAfter(date2Utc)) {
  // ...
}
```

### 日付選択（ユーザー入力）

```dart
// DatePickerで日付選択（ローカルタイムゾーン）
final selectedDate = await showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2000),
  lastDate: DateTime(2100),
);

// API送信前にUTCに変換
if (selectedDate != null) {
  final utcDate = selectedDate.toUtc();
  await apiClient.updateBirthday(birthday: utcDate.toIso8601String());
}
```

## Freezed モデルでの扱い

```dart
@freezed
class Event with _$Event {
  const factory Event({
    required String id,
    required DateTime createdAt,  // UTC として保存
    required DateTime startTime,  // UTC として保存
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}

// 使用例
final event = Event.fromJson(apiResponse);
final localStartTime = event.startTime.toLocal();  // 表示時にLocal変換
```

## ベストプラクティス

1. **データベース保存**: 常に UTC
2. **API 送受信**: ISO 8601 形式（`2024-01-15T10:30:00Z`）
3. **フロントエンド表示**: ユーザーのローカルタイムゾーン
4. **計算・比較**: すべて UTC に統一してから実行
5. **日付のみ**: 時刻が不要な場合も UTC の 00:00:00 を使用

## タイムゾーン関連のバグを防ぐ

```dart
// ❌ BAD: タイムゾーンが混在
final localNow = DateTime.now();
final utcCreatedAt = user.createdAt;  // UTC
if (localNow.isAfter(utcCreatedAt)) {  // 比較が不正確
  // ...
}

// ✅ GOOD: すべてUTCに統一
final utcNow = DateTime.now().toUtc();
final utcCreatedAt = user.createdAt;  // UTC
if (utcNow.isAfter(utcCreatedAt)) {
  // ...
}
```

## Enforcement

この日時処理ポリシーは **NON-NEGOTIABLE**。タイムゾーンを考慮しない実装は却下される。
