---
name: supabase-codegen
description: Generate type-safe Dart classes from Supabase database schema. Use when setting up supabase_codegen, generating Flutter types from PostgreSQL schema, or understanding the generated type patterns.
---

# supabase_codegen Skill

Supabase データベーススキーマから Flutter 用の型安全な Dart クラスを自動生成するツール。

## 概要

- **パッケージ**: [supabase_codegen](https://pub.dev/packages/supabase_codegen)
- **目的**: PostgreSQL スキーマから型安全な Dart モデルを生成
- **生成先**: `lib/shared/supabase/generated/`

## 設定ファイル

### `.supabase_codegen.yaml`

```yaml
# 環境変数ファイル
env: ../../../env/frontend/supabase_codegen.env

# 出力先
output: lib/shared/supabase/generated

# デバッグモード
debug: false

# スキーマオーバーライド（必要に応じて）
# override:
#   table_name:
#     column_name:
#       data_type: String
#       is_nullable: true
```

### 環境変数 (`env/frontend/supabase_codegen.env`)

```env
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key
```

## 使用方法

### 型生成

```bash
# Supabase が起動している状態で実行
make run                          # Supabase 起動
make frontend-supabase-codegen    # 型生成
```

### 生成されるファイル

| ファイル | 内容 |
|----------|------|
| `enums.dart` | PostgreSQL enum 型の Dart enum |
| `{table_name}_table.dart` | テーブルクラス |
| `{table_name}_row.dart` | 行データクラス（CRUD メソッド付き） |

### 生成されるクラスの特徴

```dart
// 生成された Row クラスの例
class UsersRow extends SupabaseDataRow {
  // 型安全なフィールドアクセス
  String get id => getValue('id');
  String get name => getValue('name');
  String? get email => getValue('email');

  // immutable 更新
  UsersRow copyWith({String? name, String? email});

  // JSON シリアライズ
  Map<String, dynamic> toJson();
  factory UsersRow.fromJson(Map<String, dynamic> json);

  // フィールド名定数
  static const String idField = 'id';
  static const String nameField = 'name';
}
```

## 既存アーキテクチャとの統合

### Freezed との併用

supabase_codegen で生成した型は **DTOとして使用** し、
ドメインモデルは **Freezed で手動定義** する戦略を推奨：

```dart
// 生成された DTO (自動生成)
import 'package:web_app/shared/supabase/generated/users_row.dart';

// ドメインモデル (手動定義)
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    String? email,
  }) = _User;

  // DTO からの変換
  factory User.fromRow(UsersRow row) => User(
    id: row.id,
    name: row.name,
    email: row.email,
  );
}
```

### 直接 Supabase クライアントと併用

```dart
// 生成されたテーブルクラスを使用
final usersTable = UsersTable();

// CRUD 操作
final user = await usersTable.querySingleRow(
  queryFn: (q) => q.eq(UsersRow.idField, userId),
);

// または既存の supabase.from() を継続使用
final response = await supabase
    .from('users')
    .select()
    .eq('id', userId)
    .single();

// 型変換
final user = UsersRow.fromJson(response);
```

## PostgreSQL → Dart 型マッピング

| PostgreSQL | Dart |
|------------|------|
| text, varchar, char | String |
| int2, int4 | int |
| int8 | BigInt |
| float4, float8 | double |
| bool | bool |
| timestamp, timestamptz | DateTime |
| date | DateTime |
| json, jsonb | Map<String, dynamic> |
| array | List |
| uuid | String |
| enum | enum (自動生成) |

## 注意事項

1. **生成ファイルは編集禁止** - `lib/shared/supabase/generated/` 内のファイルは自動生成
2. **Supabase 起動必須** - 型生成時は `make run` で Supabase が起動している必要あり
3. **RLS は別管理** - 型生成は RLS ポリシーに依存しない
4. **スキーマ変更時は再生成** - `make migrate-dev` 後に `make frontend-supabase-codegen`

## トラブルシューティング

### 接続エラー

```
Error: Could not connect to Supabase
```

→ `make run` で Supabase を起動してから再実行

### 型が見つからない

→ `.supabase_codegen.yaml` の `output` パスを確認

### カスタム型が必要

→ `.supabase_codegen.yaml` の `override` セクションで型を指定

```yaml
override:
  my_table:
    json_column:
      data_type: MyCustomType
```

## 参考リンク

- [supabase_codegen (pub.dev)](https://pub.dev/packages/supabase_codegen)
- [GitHub Repository](https://github.com/Khuwn-Soulutions/supabase_codegen)
