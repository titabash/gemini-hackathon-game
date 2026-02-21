# Polar.sh Webhooks Edge Function

このEdge
Functionは、Polar.shからのWebhookイベントを受信し、データベースを更新します。

## 概要

Polar.shの決済プラットフォームから以下のイベントを受信して処理します：

- **Checkout Events**: チェックアウトセッションの作成・完了
- **Subscription Events**: サブスクリプションのライフサイクル管理
- **Order Events**: 単発購入の処理
- **Customer Events**: 顧客情報の管理

## アーキテクチャ

```
polar-webhooks/
├── index.ts                    # メインWebhookハンドラー（署名検証、ルーティング）
├── deno.json                   # Deno設定
├── README.md                   # このファイル
└── handlers/                   # イベント別ハンドラー
    ├── types.ts                # Polar.sh Webhook型定義
    ├── index.ts                # ハンドラーのエクスポート
    ├── checkout.ts             # チェックアウトイベント処理
    ├── subscription.ts         # サブスクリプションイベント処理
    ├── order.ts                # 注文イベント処理
    └── customer.ts             # 顧客イベント処理
```

## 処理フロー

### 1. Webhook受信

```
Polar.sh → Edge Function → 署名検証 → イベントルーティング → ハンドラー実行 → DB更新
```

### 2. 署名検証

Polar.shのWebhook署名をHMAC SHA-256で検証します：

- `webhook-id`: Webhook識別子
- `webhook-timestamp`: タイムスタンプ
- `webhook-signature`: HMAC署名（v1形式）

### 3. イベント処理

各イベントタイプに応じて適切なハンドラーを実行：

#### Subscription Events

- `subscription.created`: 新規サブスクリプション作成 →
  `subscriptions`テーブルにINSERT
- `subscription.updated`: サブスクリプション更新 → ステータス・期間をUPDATE
- `subscription.active`: サブスクリプション有効化 → statusを`active`に
- `subscription.canceled`: サブスクリプションキャンセル →
  `cancel_at_period_end`フラグ設定
- `subscription.revoked`: サブスクリプション取り消し → statusを`canceled`に
- `subscription.uncanceled`: キャンセル解除 → `cancel_at_period_end`をfalseに

#### Order Events

- `order.created`: 注文作成ログ（DB更新なし）
- `order.paid`: 支払い完了 → `orders`テーブルにINSERT
- `order.refunded`: 返金処理 → statusを`refunded`に

#### Checkout Events

- `checkout.created`: チェックアウト作成ログ（DB更新なし）
- `checkout.updated`: チェックアウト完了 →
  `general_user_profiles.polar_customer_id`をUPDATE

#### Customer Events

- `customer.created`: 顧客作成 →
  `general_user_profiles.polar_customer_id`をUPDATE
- `customer.updated`: 顧客更新ログ（DB更新なし）

## 環境変数

以下の環境変数が必要です（`env/secrets.env`に設定）：

```bash
# Polar.sh Webhook設定
POLAR_WEBHOOK_SECRET=whsec_xxxxx  # Polar.sh管理画面から取得

# Supabase設定（自動設定）
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJxxx...  # service_role権限が必要
```

## デプロイ

### ローカルテスト

```bash
# Supabaseをローカルで起動
npx dotenvx run -f env/backend/local.env -- supabase start

# Edge Functionをローカルで起動
npx dotenvx run -f env/backend/local.env -- supabase functions serve polar-webhooks --env-file env/secrets.env
```

### プロダクションデプロイ

```bash
# 環境変数を設定
npx dotenvx run -f env/secrets.env -- supabase secrets set --env-file env/secrets.env

# Edge Functionをデプロイ
make deploy-functions
```

## Polar.sh側の設定

1. [Polar.sh Dashboard](https://polar.sh/dashboard) にアクセス
2. **Settings → Webhooks** に移動
3. **Add Endpoint** をクリック
4. Webhook URLを設定：
   ```
   https://your-project.supabase.co/functions/v1/polar-webhooks
   ```
5. 以下のイベントを有効化：
   - ✅ `checkout.created`
   - ✅ `checkout.updated`
   - ✅ `subscription.created`
   - ✅ `subscription.updated`
   - ✅ `subscription.canceled`
   - ✅ `subscription.revoked`
   - ✅ `subscription.active`
   - ✅ `subscription.uncanceled`
   - ✅ `order.created`
   - ✅ `order.paid`
   - ✅ `order.refunded`
   - ✅ `customer.created`
   - ✅ `customer.updated`
6. Webhook Secretをコピーして`POLAR_WEBHOOK_SECRET`に設定

## テスト

### cURLでローカルテスト

```bash
# サンプルWebhookペイロード
curl -X POST http://localhost:54321/functions/v1/polar-webhooks \
  -H "Content-Type: application/json" \
  -H "webhook-id: evt_test" \
  -H "webhook-timestamp: $(date +%s)" \
  -H "webhook-signature: v1,test_signature" \
  -d '{
    "type": "subscription.created",
    "data": {
      "id": "sub_test123",
      "status": "active",
      "customer_id": "cus_test456",
      "product_id": "prod_test789",
      "price_id": "price_test012",
      "current_period_start": "2025-01-01T00:00:00Z",
      "current_period_end": "2025-02-01T00:00:00Z",
      "cancel_at_period_end": false,
      "started_at": "2025-01-01T00:00:00Z",
      "ended_at": null,
      "metadata": {
        "user_id": "your-test-user-uuid"
      }
    }
  }'
```

### Polar.shのTest Mode

Polar.shのTest Modeを使用して実際のWebhookをテストできます：

1. Polar.sh Dashboardで**Test Mode**を有効化
2. テスト用のCheckoutを作成
3. Webhookが正しく送信されることを確認
4. Supabase Logsでイベント処理を確認

## エラーハンドリング

- **署名検証失敗**: 401 Unauthorized
- **必須フィールド欠如** (`user_id`など): 400 Bad Request
- **データベースエラー**: 500 Internal Server Error

すべてのエラーは構造化ログに記録され、Supabase Logsで確認できます。

## ログ確認

```bash
# Edge Functionのログを確認
npx dotenvx run -f env/backend/local.env -- supabase functions logs polar-webhooks

# 特定の時間範囲のログ
npx dotenvx run -f env/backend/local.env -- supabase functions logs polar-webhooks --since 1h
```

## トラブルシューティング

### Webhookが受信されない

1. Polar.sh Dashboardでエンドポイントステータスを確認
2. URLが正しいか確認（`/functions/v1/polar-webhooks`）
3. Edge Functionがデプロイされているか確認

### 署名検証エラー

1. `POLAR_WEBHOOK_SECRET`が正しいか確認
2. Polar.sh DashboardでSecretを再生成して更新
3. ローカルとプロダクションで異なるSecretを使用しているか確認

### データベース更新エラー

1. `SUPABASE_SERVICE_ROLE_KEY`が設定されているか確認
2. RLSポリシーでservice_roleに権限があるか確認
3. テーブルスキーマが最新か確認（`make migrate-status`）

## セキュリティ

- ✅ Webhook署名検証（HMAC SHA-256）
- ✅ Service Role権限でDB操作
- ✅ CORS設定
- ✅ 環境変数での機密情報管理
- ✅ 構造化ログでの監査証跡

## 関連ドキュメント

- [Polar.sh Webhook Documentation](https://docs.polar.sh/api-reference/webhooks)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Drizzle Schema](../../drizzle/schema/schema.ts)
