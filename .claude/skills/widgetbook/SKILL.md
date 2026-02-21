---
name: widgetbook
description: Widgetbook UI component catalog for Flutter (Storybook equivalent). Use when creating UI component previews, adding Widgetbook use cases, or setting up component documentation.
---

# Widgetbook Skill

Flutter 向け UI コンポーネントカタログツール（Storybook 相当）。

## 概要

Widgetbook は Flutter アプリケーションの UI コンポーネントを独立してプレビュー・テストするためのツールです。

- **バージョン**: widgetbook ^3.20.2
- **場所**: `frontend/widgetbook/`
- **起動コマンド**: `make frontend-widgetbook`
- **URL**: http://localhost:9000

## ディレクトリ構成

```
frontend/
├── widgetbook/                              # Widgetbook パッケージ
│   ├── lib/
│   │   ├── main.dart                        # Widgetbook app (@App annotation)
│   │   ├── main.directories.g.dart          # Generated
│   │   └── use_cases/                       # Use Cases organized by source package
│   │       └── shared_ui/
│   │           └── components/
│   │               └── app_button_use_case.dart
│   └── pubspec.yaml
│
├── packages/shared/ui/                      # ソースコンポーネント
│   └── lib/components/
│       └── app_button.dart                  # 実際のコンポーネント
│
└── apps/web/                                # メインアプリ
    └── lib/features/*/ui/                   # Feature UI コンポーネント
```

## Use Case の追加方法

### 1. Use Case ファイルを作成

`frontend/widgetbook/lib/use_cases/` にソースパッケージの構造を反映して作成:

```dart
// frontend/widgetbook/lib/use_cases/shared_ui/components/my_widget_use_case.dart
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:shared_ui/shared_ui.dart';

@widgetbook.UseCase(
  name: 'Default',
  type: MyWidget,
  path: '[Packages]/[Shared UI]/[Components]',  // メニュー階層
)
Widget defaultMyWidget(BuildContext context) {
  return Center(
    child: MyWidget(
      // props...
    ),
  );
}

@widgetbook.UseCase(
  name: 'Disabled',
  type: MyWidget,
  path: '[Packages]/[Shared UI]/[Components]',
)
Widget disabledMyWidget(BuildContext context) {
  return const Center(
    child: MyWidget(
      enabled: false,
    ),
  );
}
```

### 2. main.dart にインポートを追加

```dart
// frontend/widgetbook/lib/main.dart
// ignore: unused_import
import 'use_cases/shared_ui/components/my_widget_use_case.dart';
```

### 3. コード生成を実行

```bash
make frontend-widgetbook-generate
# または
cd frontend/widgetbook && dart run build_runner build --delete-conflicting-outputs
```

## path パラメータの命名規則

`path` パラメータはメニュー階層を定義します:

| ソースパッケージ | path |
|-----------------|------|
| `packages/shared/ui/lib/components/` | `[Packages]/[Shared UI]/[Components]` |
| `packages/shared/ui/lib/widgets/` | `[Packages]/[Shared UI]/[Widgets]` |
| `apps/web/lib/features/auth/ui/` | `[Apps]/[Web]/[Features]/[Auth]` |
| `apps/web/lib/entities/user/ui/` | `[Apps]/[Web]/[Entities]/[User]` |

## Addons（プレビュー設定）

main.dart で設定済みの Addons:

| Addon | 機能 |
|-------|------|
| `ViewportAddon` | デバイスフレーム（iPhone, Android 等） |
| `MaterialThemeAddon` | Light/Dark テーマ切り替え |
| `LocalizationAddon` | 言語切り替え（en/ja） |
| `TextScaleAddon` | テキストスケール（0.85x〜2.0x） |
| `GridAddon` | アライメントグリッド表示 |

## Knobs（動的パラメータ）

Use Case 内でパラメータを動的に変更可能にする:

```dart
@widgetbook.UseCase(
  name: 'With Knobs',
  type: AppButton,
  path: '[Packages]/[Shared UI]/[Components]',
)
Widget appButtonWithKnobs(BuildContext context) {
  return Center(
    child: AppButton(
      text: context.knobs.string(
        label: 'Button Text',
        initialValue: 'Click me',
      ),
      onPressed: context.knobs.boolean(
        label: 'Enabled',
        initialValue: true,
      )
          ? () {}
          : null,
    ),
  );
}
```

### 利用可能な Knobs

| メソッド | 用途 |
|---------|------|
| `context.knobs.string()` | テキスト入力 |
| `context.knobs.boolean()` | ON/OFF トグル |
| `context.knobs.int.slider()` | 整数スライダー |
| `context.knobs.double.slider()` | 小数スライダー |
| `context.knobs.list()` | ドロップダウン選択 |
| `context.knobs.color()` | カラーピッカー |

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `make frontend-widgetbook` | Bootstrap + コード生成 + 起動 |
| `make frontend-widgetbook-generate` | コード生成のみ |
| `make frontend-widgetbook-build` | Web ビルド |

## ベストプラクティス

### 1. 全状態をカバー

各コンポーネントに対して以下の Use Case を作成:

- Default（デフォルト状態）
- Disabled（無効状態）
- Loading（読み込み中）
- Error（エラー状態）
- Edge cases（長いテキスト、空データ等）

### 2. 一貫した命名

- Use Case 名: `Default`, `Disabled`, `With Icon`, `Long Text` など
- ファイル名: `{component_name}_use_case.dart`
- 関数名: `{useCase}{ComponentName}` (e.g., `defaultAppButton`)

### 3. パス構造の一貫性

ソースパッケージの構造を反映した `path` を使用し、メニューを整理。

## トラブルシューティング

### Use Case が表示されない

1. `main.dart` で Use Case ファイルをインポートしているか確認
2. `@widgetbook.UseCase` アノテーションが正しいか確認
3. `make frontend-widgetbook-generate` を再実行

### コード生成エラー

```bash
# クリーンビルド
cd frontend/widgetbook && flutter clean && flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### テーマが適用されない

`AppTheme.lightTheme` / `AppTheme.darkTheme` が正しくエクスポートされているか確認。
