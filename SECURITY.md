# Security Policy

## Supported Versions

現在サポートされているバージョン:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

セキュリティ上の脆弱性を発見した場合は、以下の手順に従ってください:

### 報告方法

1. **公開のIssueトラッカーには投稿しないでください**
   - セキュリティの脆弱性は公開されるべきではありません

2. **プライベートな報告**
   - GitHub Security Advisoriesを使用して報告してください
   - または、プロジェクトメンテナーに直接メールで連絡してください

### 報告に含めるべき情報

- 脆弱性の種類（例: SQL injection, XSS, CSRF等）
- 脆弱性の影響を受けるファイル/コンポーネントのパス
- 脆弱性を再現する手順
- 概念実証（Proof of Concept: PoC）コード（可能であれば）
- 潜在的な影響の説明

### レスポンス時間

- 初期応答: 48時間以内
- 修正パッチのリリース: 脆弱性の深刻度に応じて1週間〜1ヶ月以内

## セキュリティのベストプラクティス

### 環境変数の管理

- `env/secrets.env`ファイルを**絶対に**コミットしないでください
- 本番環境では環境変数を安全に管理してください（AWS Secrets Manager, HashiCorp Vault等）
- `.env`ファイルが`.gitignore`に含まれていることを確認してください

### 認証・認可

- Supabase Auth使用時は`getUser()`を使用し、`getSession()`は避けてください
- JWTトークンを適切に検証してください
- フロントエンド（Flutter）では、Supabase Flutter clientの認証機能を使用してください

### データベース

- RLS（Row Level Security）ポリシーを必ず設定してください
- SQLインジェクション対策として、パラメータ化されたクエリを使用してください
- Drizzle ORMの宣言的なRLSポリシー定義を活用してください

### 依存関係

- 定期的に依存関係を更新してください:
  ```bash
  # Flutter Monorepo
  cd frontend
  melos bootstrap        # パッケージの再リンク
  melos run upgrade      # 依存関係の更新

  # または、個別パッケージ
  cd frontend/apps/web
  flutter pub upgrade

  # Drizzle (Database)
  cd drizzle
  npm update
  bun update

  # Backend Python
  cd backend-py/app
  uv lock --upgrade
  uv sync
  ```

- Dependabotによる自動更新を有効にしてください（設定済み）
- 更新後は必ず `make check-quality` と `make test-all` を実行してください

### API セキュリティ

- すべてのAPIエンドポイントで適切な認証・認可を実装してください
- レート制限を設定し、DDoS攻撃を防いでください
- 入力バリデーションを厳格に行ってください
- エラーメッセージに機密情報を含めないでください

### フロントエンド セキュリティ

- XSS攻撃を防ぐため、ユーザー入力を適切にサニタイズしてください
- Flutterの標準的なセキュリティプラクティスに従ってください
- 機密情報をローカルストレージに保存しないでください
- HTTPS接続を使用してください

### Edge Functions セキュリティ

- Deno Edge Functionsでは、環境変数を安全に管理してください
- CORS設定を適切に構成してください
- タイムアウトとメモリ制限を設定してください

## OWASP Top 10 対策

このプロジェクトは、以下のOWASP Top 10の脆弱性に対して対策を実施しています：

1. **Injection**: パラメータ化クエリ（SQLModel, Drizzle ORM）
2. **Broken Authentication**: Supabase Auth + JWT
3. **Sensitive Data Exposure**: 環境変数管理、RLS
4. **XML External Entities (XXE)**: JSON使用
5. **Broken Access Control**: RLSポリシー、認証ミドルウェア
6. **Security Misconfiguration**: 設定ファイルのバージョン管理
7. **Cross-Site Scripting (XSS)**: Flutterの自動エスケープ
8. **Insecure Deserialization**: 型安全なデシリアライゼーション
9. **Using Components with Known Vulnerabilities**: Dependabot
10. **Insufficient Logging & Monitoring**: 構造化ログ（実装推奨）

## セキュリティチェックリスト

デプロイ前に以下を確認してください：

- [ ] すべてのテーブルにRLSポリシーが設定されている
- [ ] 環境変数が適切に管理されている
- [ ] 認証・認可が正しく実装されている
- [ ] 依存関係が最新である
- [ ] HTTPS接続が強制されている
- [ ] 入力バリデーションが実装されている
- [ ] エラーハンドリングが適切である
- [ ] ログに機密情報が含まれていない

## 既知の脆弱性

現在、既知の重大な脆弱性はありません。

## セキュリティアップデート

セキュリティ関連のアップデートは、GitHub Releasesとこのファイルで通知されます。

## 参考リンク

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth)
- [Flutter Security](https://flutter.dev/docs/deployment/security)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)
