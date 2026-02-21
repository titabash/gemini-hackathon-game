# Clean Code Policy

**MANDATORY**: コードは常にクリーンな状態を維持する。

## 基本原則

このプロジェクトでは、Feature Sliced Design・モノレポ構成（Melos）・クリーンアーキテクチャを採用している。
これらのアーキテクチャの目的は**コードの整理と重複排除**である。

## 後方互換コードの扱い

**原則: 後方互換は保持しない**

- 未使用の変数・関数・クラスは即座に削除
- deprecated なコードは残さず完全に置換
- リネーム時に `_oldName` のようなエイリアスは作成しない
- re-export による互換レイヤーは作成しない

**例外**: ユーザーから明示的に「後方互換を保持してほしい」と指示があった場合のみ

### 禁止パターン

```dart
// ❌ 未使用のリネーム互換
@Deprecated('Use newFunction instead')
void oldFunction() => newFunction();

// ❌ deprecated コメントで残す
/// @deprecated Use newFunction instead
void oldFunction() { ... }

// ❌ typedef での互換維持
typedef OldType = NewType;

// ✅ 完全に置き換える
// oldFunction の呼び出し箇所をすべて newFunction に変更し、oldFunction を削除
```

## 重複コードの禁止

**原則: 同一処理の重複実装は禁止**

### 共通化の階層

| 範囲 | 配置先 |
|------|--------|
| 複数アプリ共通 | `frontend/packages/core/` または `packages/shared/` |
| 同一アプリ内共通 | `shared/` レイヤー |
| 同一feature内共通 | feature の `model/` または `lib/` |

### チェックリスト

コード追加前に確認：

1. 同じ処理が他の場所に存在しないか？
2. packages に共通化すべきか？（core/utils, core/api等）
3. shared レイヤーに配置すべきか？

## 未使用コードの削除

**原則: 使われていないコードは即座に削除**

- インポートされていないexport
- 呼び出されていない関数・メソッド
- 参照されていない型定義・クラス
- コメントアウトされたコード
- TODO/FIXME付きの放置コード
- 未使用のRiverpod Provider

```dart
// ❌ コメントアウトで残す
// void oldImplementation() { ... }

// ❌ 「後で使うかも」で残す
void maybeUseLater() { ... }

// ✅ 不要なら削除（git履歴で復元可能）
```

## 自動生成ファイルの扱い

**原則: 自動生成ファイルは編集しない**

以下のファイルは `build_runner` や `slang` によって自動生成されるため、直接編集禁止：
- `*.g.dart`
- `*.freezed.dart`
- `*.gr.dart`
- `*/generated/*`

変更が必要な場合は、元のソースファイルを修正して再生成：
```bash
make frontend-generate
```

## アーキテクチャとの関連

### Feature Sliced Design (FSD)

- 各レイヤーの責務を明確化し、適切な場所にコードを配置
- 上位レイヤーから下位レイヤーへの依存のみ許可
- 同一レイヤー内の重複を防ぐ

### モノレポ (Melos)

- 複数アプリで共通利用するコードは `packages/` に集約
- アプリ固有のコードのみ `apps/` に配置
- パッケージ間の重複を排除
- `melos.yaml` で依存関係を明確化

### クリーンアーキテクチャ

- ドメインロジックとインフラを分離
- 依存性逆転により疎結合を維持
- テスタビリティを確保

## Dart/Flutter 特有のクリーンコード

### Pub

lic API パターン

各featureやentityは `index.dart` で Public API を定義：

```dart
// ✅ 正しい Public API
// features/auth/index.dart
export 'model/auth_provider.dart';
export 'model/auth_state.dart';
export 'ui/login_form.dart';

// ❌ 内部実装を公開しない
// export 'model/auth_provider.g.dart';  // 自動生成
// export 'ui/widgets/login_button.dart';  // 内部Widget
```

### Riverpod Provider の命名

```dart
// ✅ 明確な命名
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;
}

// ❌ 曖昧な命名
@riverpod
class Data extends _$Data {  // 何のデータ？
  // ...
}
```

### Freezed Model の適切な使用

```dart
// ✅ immutable model
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
  }) = _User;
}

// ❌ mutable class（Freezedを使うべき）
class User {
  String id;
  String name;
  User(this.id, this.name);
}
```

## 強制事項

このポリシーは**交渉の余地なし**。違反するコードはレビューで却下される。

### 作業完了前チェックリスト

- [ ] 未使用のimport/exportを削除
- [ ] コメントアウトコードを削除
- [ ] 重複コードを共通化
- [ ] 後方互換コードを削除
- [ ] 自動生成ファイルを編集していない
- [ ] `make frontend-generate` 実行後も問題なし
