# Flutter Boilerplate - AI Agent Instructions

このドキュメントは、Codex CLIなどのAIコーディングエージェント向けのプロジェクト指示です。

**注意**: Claude Code専用のより詳細なガイダンスは`CLAUDE.md`を参照してください。

## プロジェクト概要

Flutter monorepo（Melos管理）とSupabase backendを使用したフルスタックアプリケーションボイラープレート。

### 技術スタック

- **Frontend**: Flutter 3.35.6 (iOS, Android, Web) - Monorepo構造（Melos）
- **Backend**: Supabase Edge Functions (Deno/TypeScript) + Python FastAPI
- **Database**: Supabase PostgreSQL + Drizzle ORM
- **State Management**: Riverpod + Flutter Hooks
- **Navigation**: GoRouter
- **i18n**: slang package

## アーキテクチャ原則

### Backend as a Service戦略

- **Frontend-First**: フロントエンドはSupabaseクライアントで直接認証・DB操作
- **Edge Functions優先**: バックエンド実装はPython不要ならEdge Functions推奨
- **Python Backend**: トランザクション重視、Python特有ライブラリ使用時のみ

### Feature Sliced Design (FSD) 厳守

**レイヤー構造**:
```
lib/
├── app/           # アプリ設定
├── pages/         # ルートレベルページ
├── features/      # 機能モジュール
├── entities/      # 共有ビジネスエンティティ
└── shared/        # 共有ユーティリティ
```

**セグメント構造** (各レイヤー内):
- `api/`: 外部API統合、データフェッチ
- `model/`: 状態管理、ビジネスロジック、ドメインサービス
- `ui/`: UIコンポーネント、ウィジェット

**依存ルール**:
- 上位レイヤー → 下位レイヤーのみ依存可能
- 同一レイヤー間の依存は禁止

## MCP (Model Context Protocol) Tool活用

### 実装前に必ず使用すべきMCPツール

#### 1. Context7 MCP - 技術調査
- ベストプラクティス調査
- 新ライブラリ・フレームワーク調査
- 複雑な技術概念理解

#### 2. Supabase MCP - データベース操作
- テーブル構造確認
- RLS (Row Level Security) ポリシー検証
- インデックスとパフォーマンス考慮
- マイグレーション計画
- **重要**: DB変更前に必ず現在の構造を確認

#### 3. Dart/Flutter MCP - 実装パターン（利用可能な場合）
- ウィジェット実装パターン
- Riverpod状態管理
- Flutter最適化とパフォーマンスTips
- Dart言語機能とイディオム

#### 4. IDE MCP - コード診断
- 診断情報とエラー取得
- IDE状態確認

### MCP活用フロー

```
ユーザーリクエスト
  ↓
Context7でベストプラクティス調査
  ↓
Supabase MCPでDB構造確認
  ↓
Dart MCPでパターン確認
  ↓
実装
  ↓
IDE MCPで診断確認
  ↓
品質チェック
```

## セットアップと開発コマンド

### 初回セットアップ

```bash
make init  # プロジェクト全体初期化
```

### 開発サーバー起動

```bash
make run                     # バックエンド + Supabase
make frontend                # Flutter Web (ポート8080) ※必ずこれを使用
make frontend-ios            # iOS開発
make frontend-android        # Android開発
make stop                    # 全サービス停止
```

**重要**: フロントエンド起動は必ず`make frontend`を使用。Melos bootstrap、環境変数、ポート設定が自動実行される。

### Monorepo操作 (Melos)

```bash
make frontend-bootstrap      # ワークスペースセットアップ
make frontend-generate       # コード生成（Riverpod、Drift）
make frontend-clean          # 全パッケージクリーン
make frontend-test           # 全パッケージテスト
```

### データベース操作 (Drizzle)

```bash
make migrate-dev             # [開発] マイグレーション生成・適用・型生成
make migrate-deploy          # [本番] 既存マイグレーション適用
make migrate-status          # マイグレーション履歴
make drizzle-studio          # Drizzle Studio起動 (http://localhost:4983)
make db-reset                # [開発のみ] DB初期化
```

**Drizzleワークフロー**:
1. `drizzle/schema/*.ts`を編集（TypeScriptでスキーマ定義）
2. `make migrate-dev`実行（マイグレーション生成、DB適用、型生成）
3. `make drizzle-studio`で確認（オプション）

### コード生成 (Flutter)

```bash
make frontend-generate                              # 全コード生成（Riverpod、i18n、Drift）
cd frontend/apps/web && flutter pub run build_runner build --delete-conflicting-outputs  # 強制再生成
cd frontend/apps/web && flutter pub run build_runner watch  # ウォッチモード
```

### テスト

```bash
make test-all               # 全コンポーネントテスト
```

### 品質チェック & フォーマット

```bash
# 品質チェック
make check-quality          # 全コンポーネント
make check-flutter          # Flutter専用
make check-edge-functions   # Edge Functions専用
make check-backend          # Backend専用

# フォーマット自動修正
make fix-format             # 全コンポーネント
make fix-format-flutter     # Flutter専用
make fix-format-edge-functions # Edge Functions専用
make fix-format-backend     # Backend専用
```

## 必須開発フロー

### コード変更後の必須手順

**Frontend変更時**:
```bash
make frontend-generate
make fix-format-flutter
make check-flutter
```

**Edge Functions変更時**:
```bash
make fix-format-edge-functions
make check-edge-functions
```

**Backend変更時**:
```bash
make fix-format-backend
make check-backend
```

**データベーススキーマ変更時**:
```bash
# 1. Supabase MCPで現在のスキーマ確認
# 2. drizzle/schema/*.ts を編集
make migrate-dev
# 3. Supabase MCPで変更検証
make build-model
```

## フロントエンドアーキテクチャ詳細

### Monorepo構造

```
frontend/
├── apps/
│   └── web/                 # メインWebアプリ（FSD構造）
└── packages/
    ├── core/
    │   ├── api/             # HTTP client (Dio + Retrofit)
    │   ├── auth/            # 認証状態管理
    │   ├── i18n/            # 国際化（slang）
    │   └── utils/           # コアユーティリティ
    └── shared/
        └── ui/              # 共有UIコンポーネント
```

### 状態管理 (Riverpod)

```dart
// ✅ Good: Riverpod with code generation
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}

// Consumer with hooks
class CounterView extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    return Text('$counter');
  }
}

// ❌ Bad: StatefulWidget without Riverpod
class CounterView extends StatefulWidget {
  // Don't use StatefulWidget for business logic
}
```

### ナビゲーション (GoRouter)

**認証対応の宣言的ルーティング**:

```dart
// ✅ Good: Declarative navigation with context
context.go('/dashboard');           // Replace route
context.push('/settings');          // Push new route
context.pop();                      // Go back

// ❌ Bad: Direct Navigator usage (avoid in GoRouter projects)
Navigator.of(context).push(...);
```

**認証フロー**:
- 未認証 → `/auth/login`へリダイレクト
- 認証済み → 認証ルートから`/dashboard`へリダイレクト

### 国際化 (i18n) - slang package

**型安全な翻訳アクセス**:
```dart
import 'package:core_i18n/generated/strings.g.dart';

Text(t.home.title)                      // 型安全アクセス
Text(t.welcome.message(name: userName))  // パラメータ付き
```

**言語切り替え**:
```dart
import 'package:core_i18n/providers/locale_provider.dart';

final localeNotifier = ref.read(localeNotifierProvider.notifier);
localeNotifier.changeLocale(AppLocale.ja);
localeNotifier.toggleLocale();  // サイクル切り替え
```

### サーバー送信イベント (SSE)

- **利用ライブラリ**: `flutter_client_sse`（直接使用禁止）
- **必須ラッパー**: `frontend/packages/core/api/lib/realtime/sse_client_factory.dart`
  - `SseClientFactory`を`ref.read(sseClientFactoryProvider)`で取得し、`connect()`から`SseConnection`を受け取る
  - `SseConnection.messages`（JSONパース済み）と`rawEvents`（`SSEModel`）を用途に応じて使い分ける
- **設定**:
  - SSEエンドポイントは `SSE_SERVER_URL`（必要な場合は`SSE_DEBUG_KEY`）を`--dart-define`で注入
  - 共通ヘッダーはファクトリが付与するため、追加ヘッダーのみ `connect(headers: ...)` で渡す
- **禁止事項**:
  - `SSEClient.subscribeToSSE` を直接呼び出さない（ヘッダー・ライフサイクルが統一できないため）
  - 使い終わったら `SseConnection.close()` を呼び、共有クライアントを明示的に解放する

## バックエンドアーキテクチャ

### Edge Functions (Supabase)

**場所**: `supabase/functions/`
**ランタイム**: Deno (TypeScript)

**必須事項**:
- CORSヘッダー設定
- 適切なエラーハンドリング
- ステータスコード管理

### Python Backend (FastAPI)

**場所**: `backend-py/app/`

**レイヤードアーキテクチャ**:
- **Controller**: HTTPエンドポイント
- **Use Case**: ビジネスロジックオーケストレーション
- **Service**: ドメインサービス、ビジネスルール
- **Gateway**: データアクセス、リポジトリパターン
- **Infrastructure**: 外部サービス統合

**コーディング規約**:
- 型ヒント必須
- SQLModelで同期DB操作
- Ruff linting (88文字制限)
- McCabe複雑度3以下

## Test-Driven Development (TDD)

### 必須TDDワークフロー

1. **テストファースト**: 期待される入出力に基づきテスト作成
2. **Red-Green-Refactor**: 失敗確認 → 実装 → リファクタリング
3. **カバレッジ**: 90%以上目標
4. **回帰テスト**: 既存機能変更時は回帰テスト追加

### Supabase テスト要件

**必須パッケージ**: `mock_supabase_http_client`

- フロントエンドのSupabase統合機能は必ず `mock_supabase_http_client` でテストする
- ネットワーク呼び出しを行わず、インメモリでモックデータを返す
- `frontend/pubspec.yaml` の dev_dependencies に含まれており、全パッケージで利用可能

**TDDサイクルでの利用**:

```dart
// Step 1: テストファースト（RED）
test('fetch user posts returns list', () async {
  final mockHttpClient = MockSupabaseHttpClient();
  final mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );

  // テストデータをセットアップ
  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Post 1', 'user_id': 1},
  ]);

  // Step 2: 実装（GREEN）
  final posts = await mockSupabase
      .from('posts')
      .select()
      .eq('user_id', 1);

  // Step 3: アサート（REFACTOR）
  expect(posts.length, 1);
  expect(posts.first['title'], 'Post 1');
});
```

**Riverpod統合**:

```dart
testWidgets('widget displays posts from Supabase', (tester) async {
  final mockHttpClient = MockSupabaseHttpClient();
  final mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );

  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Test Post'},
  ]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseProvider.overrideWithValue(mockSupabase),
      ],
      child: const MyApp(),
    ),
  );

  await tester.pumpAndSettle();
  expect(find.text('Test Post'), findsOneWidget);
});
```

**テスト実行**:

```bash
# 全テスト実行
make frontend-test
cd frontend && melos run test

# テストウォッチモード（TDD推奨）
cd frontend/apps/web && flutter test --watch
```

**詳細ガイド**: `CLAUDE.md` の "Supabase Mocking" セクション、または `.agent/rules/supabase-testing.md` を参照

## セキュリティ

### 必須セキュリティ対策

- APIキー・秘密情報をハードコード禁止
- 環境変数で設定管理
- 最小権限原則（DBアクセス）
- 入力バリデーション・サニタイゼーション
- **Supabase MCPでRLSポリシー検証必須**（デプロイ前）

### Supabase認証（重要）

```dart
// ✅ Good: Secure authentication check
final response = await supabase.auth.getUser();
final user = response.user;

// ❌ Bad: Session-based (can be spoofed)
final session = supabase.auth.currentSession;
```

## Git ワークフロー

- **ブランチ戦略**: `main`からfeatureブランチ
- **コミット規約**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`)
- **PR必須**: mainへのマージはPR経由
- **CI チェック**: 全CI checksパス必須

## 重要な注意事項

### コード変更時の注意

1. **Frontend変更後は必ずコード生成**: `make frontend-generate`
2. **DB変更前にSupabase MCPで確認**: 現在のスキーマ・RLSポリシー確認
3. **品質チェック必須**: 変更後は必ず`make check-quality`
4. **テスト実行**: `make test-all`でカバレッジ確認
5. **MCP優先**: 推測で実装せず、MCPツールで調査してから実装

### MCPツール優先順位

1. **Supabase MCP** > 一般的なDB知識
2. **Dart MCP** > 汎用Flutterパターン
3. **Context7** > 古いドキュメント・慣習
4. **IDE MCP** > 手動エラーチェック

## ベストプラクティスまとめ

### Frontend (Flutter)
- ✅ Riverpod + Flutter Hooks for state management
- ✅ FSD layer hierarchy
- ✅ Code generation for Riverpod, i18n, Drift
- ✅ Type-safe translations with slang
- ✅ GoRouter for navigation
- ❌ StatefulWidget for business logic 禁止
- ❌ グローバル状態の直接変更禁止

### Backend (Python)
- ✅ Clean Architecture
- ✅ すべての関数に型アノテーション
- ✅ I/Oには async/await
- ✅ Google スタイルの docstring
- ❌ ブロッキング I/O 禁止
- ❌ 複雑な関数（McCabe > 3）禁止

### Edge Functions (Deno)
- ✅ Deno.serve native API
- ✅ `npm:` プレフィックスでインポート
- ✅ エラーハンドリングの型ガード
- ✅ 適切なCORS設定
- ❌ JSR や HTTP imports 禁止
- ❌ `getSession()` 使用禁止

### Database (Drizzle)
- ✅ Drizzle ORM TypeScript schema
- ✅ `pgPolicy` で宣言的な RLS
- ✅ マイグレーションベースのワークフロー
- ❌ 手動 SQL ファイル禁止
- ❌ スキーマドリフト禁止

## リソースリンク

- **CLAUDE.md**: より詳細なClaude Code向けガイド
- **README.md**: プロジェクト概要、セットアップ手順
- **CONTRIBUTING.md**: コントリビューションガイド
- **SECURITY.md**: セキュリティポリシー

## Codex CLI追加コンテキスト

Codex CLIを使用する場合、以下も参照してください:
- `.codex/config.toml` - Codex CLI設定
- `.codex/instructions.md` - プロジェクト固有の追加指示
- `README-CODEX.md` - Codex CLI導入・使用ガイド

---

**このプロジェクトは本番対応ボイラープレートです。常にMCPツールで最新・正確な情報を取得し、高品質コード、包括的テスト、適切なドキュメントを維持してください。**
