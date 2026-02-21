# UI Testing Policy

**MANDATORY**: UI コンポーネント（Widget）は **Widgetbook** で品質を担保する。単体テストは基本的に不要。

## 基本方針

| 対象 | テスト方法 |
|------|-----------|
| **UI Widget** | Widgetbook（単体テスト基本不要） |
| **ビジネスロジック（Riverpod）** | 単体テスト（TDD 必須） |
| **API / データ取得** | 単体テスト（TDD 必須） |
| **ユーティリティ関数** | 単体テスト（TDD 必須） |
| **複雑なWidget** | Widget Test（条件付き） |
| **E2Eフロー** | Patrol（E2Eテスト） |

## UI Widget の定義

以下は **Widgetbook 対象**（単体テスト基本不要）：

- `frontend/packages/shared/ui/lib/` - 共有 UI コンポーネント
- `frontend/apps/web/lib/shared/ui/` - アプリ内共有 UI
- `frontend/apps/web/lib/entities/*/ui/` - エンティティ UI
- `frontend/apps/web/lib/features/*/ui/` - フィーチャー UI
- `frontend/apps/web/lib/pages/*/` - ページ UI

## Widgetbook 必須要件

UI Widget を作成・変更した場合、**必ず Widgetbook Use Case を作成**する。

### Use Case ファイルの配置（モノレポ対応）

Widgetbook generator は `@App()` があるパッケージ内のみスキャンするため、
Use Case は `frontend/widgetbook/lib/use_cases/` に配置し、ソースパッケージの構造を反映する：

```
frontend/widgetbook/lib/use_cases/
├── shared_ui/
│   └── components/
│       └── app_button_use_case.dart  # shared_ui のコンポーネント用
├── web_app/
│   ├── features/
│   │   └── auth/
│   │       └── login_form_use_case.dart
│   └── entities/
│       └── user/
│           └── user_avatar_use_case.dart
```

### Use Case に含めるべき内容

1. **Default**: 基本状態
2. **バリエーション**: パラメータの組み合わせ
3. **状態**: Loading, Error, Disabled など
4. **エッジケース**: 長いテキスト、空データなど

```dart
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: CustomButton)
Widget defaultButton(BuildContext context) {
  return CustomButton(
    label: context.knobs.string(label: 'Label', initialValue: 'Button'),
    onPressed: () {},
  );
}

@widgetbook.UseCase(name: 'Loading', type: CustomButton)
Widget loadingButton(BuildContext context) {
  return const CustomButton(
    label: 'Loading',
    isLoading: true,
    onPressed: null,
  );
}

@widgetbook.UseCase(name: 'Disabled', type: CustomButton)
Widget disabledButton(BuildContext context) {
  return const CustomButton(
    label: 'Disabled',
    onPressed: null,
  );
}
```

### Widgetbook Addons

Use Case では以下の Addons を活用：

- **DeviceFrameAddon**: 複数デバイスでプレビュー
- **ThemeAddon**: Light/Dark テーマ切り替え
- **LocalizationAddon**: 言語切り替え（en/ja）
- **Knobs**: パラメータをリアルタイム変更

## Widget Test が必要な場合

基本的に Widget Test は不要だが、以下の場合のみ作成：

### Widget Test が必要なケース

1. **状態によって表示が変わる Widget**
   ```dart
   testWidgets('shows loading indicator when isLoading is true', (tester) async {
     await tester.pumpWidget(
       const CustomButton(label: 'Test', isLoading: true),
     );
     expect(find.byType(CircularProgressIndicator), findsOneWidget);
   });
   ```

2. **ユーザー入力を受け付ける Widget**
   ```dart
   testWidgets('calls onPressed when tapped', (tester) async {
     bool pressed = false;
     await tester.pumpWidget(
       CustomButton(label: 'Test', onPressed: () => pressed = true),
     );
     await tester.tap(find.byType(CustomButton));
     expect(pressed, true);
   });
   ```

3. **複雑なレイアウトロジック**
   - スクロール動作
   - アニメーション
   - 条件付き表示/非表示

### Widget Test が不要なケース

- 単純な静的 Widget（Text, Icon のみ）
- Material Design 標準 Widget のラッパー
- レイアウトのみの Widget（Row, Column, Container）

## 単体テストが必要なもの

UI Widget 内でも、以下は**単体テスト対象（TDD 必須）**：

- `model/` 内の Riverpod Provider
- `api/` 内のデータ取得関数
- `lib/` 内のユーティリティ関数
- Freezed モデル（ロジック部分）

```
features/auth/
├── ui/
│   ├── login_form.dart           # Widgetbook
│   └── login_form.widgetbook.dart # Widgetbook
├── model/
│   ├── login_form_provider.dart  # 単体テスト（ロジック）
│   └── login_form_provider_test.dart
└── api/
    ├── login_api.dart            # 単体テスト
    └── login_api_test.dart
```

## E2E テスト（Patrol）

完全なユーザーフローのテストには Patrol を使用：

```dart
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'ログインフロー',
    ($) async {
      await $.pumpWidgetAndSettle(const App());

      await $(#emailField).enterText('test@example.com');
      await $(#passwordField).enterText('password123');
      await $(#loginButton).tap();

      await $(#dashboard).waitUntilVisible();
    },
  );
}
```

## 禁止事項

**NEVER**:
- 単純な静的 Widget に対して Widget Test を書く
- Widgetbook で十分なケースで Widget Test を書く
- スナップショットテスト（Flutter では不安定）

```dart
// ❌ 禁止: 単純な静的 Widget の Widget Test
testWidgets('renders text', (tester) async {
  await tester.pumpWidget(const Text('Hello'));
  expect(find.text('Hello'), findsOneWidget);
})

// ✅ 代わりに: Widgetbook Use Case
@widgetbook.UseCase(name: 'Default', type: CustomText)
Widget defaultText(BuildContext context) {
  return const CustomText('Hello');
}
```

## 理由

1. **Widgetbook の利点**:
   - 視覚的な確認が可能
   - デザイナーとの協業に有用
   - ドキュメントとして機能
   - 複数デバイス・テーマで確認可能
   - リアルタイムでパラメータ変更可能

2. **Widget Test の限界**:
   - 視覚的な確認ができない
   - レイアウトの正確性を検証できない
   - テスト記述に時間がかかる

3. **Patrol の利点**:
   - 実機に近い環境でテスト
   - ユーザーフロー全体を検証
   - Native 機能のテストも可能

## コマンド

| 操作 | コマンド |
|------|---------|
| **Widgetbook起動** | `make frontend-widgetbook` |
| **Widget Test実行** | `make frontend-test` |
| **Patrol実行** | `make frontend-patrol` |
| **全テスト実行** | `make test-all` |

## ワークフロー

```
1. Widget作成
2. Widgetbook Use Case追加（必須）
3. 必要に応じてWidget Test追加（条件付き）
4. ビジネスロジックに単体テスト（TDD）
5. E2Eフローに Patrol テスト（重要フロー）
```

## Enforcement

この UI テストポリシーは **NON-NEGOTIABLE**。UI Widget に対する不要な単体テストは却下される。
