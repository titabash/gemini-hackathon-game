# Polar API Edge Function

Flutter アプリから Polar.sh API へのリクエストをプロキシする Edge Function
です。

## 概要

このエッジ関数は、Flutter クライアントが安全に Polar.sh
の決済・サブスクリプション機能を利用できるようにします。Access Token
をサーバーサイドで管理し、クライアントに露出させません。

## アーキテクチャ

```
Flutter App → Edge Function (polar-api) → Polar.sh SDK → Polar.sh API
```

- **セキュリティ**: Access Token はサーバーサイド（Edge Function）で管理
- **型安全性**: TypeScript SDK による型チェック
- **スケーラビリティ**: Supabase Edge Runtime による自動スケーリング

## 環境変数

以下の環境変数を設定してください：

```bash
POLAR_ACCESS_TOKEN=polar_xxxx              # Polar.sh Access Token
POLAR_ORGANIZATION_ID=your-org-id          # Organization ID
POLAR_SERVER=sandbox                       # 'sandbox' または 'production'
POLAR_WEBHOOK_SECRET=your-webhook-secret   # Webhook 検証用
```

### 環境変数の設定方法

#### ローカル開発

`env/secrets.env` ファイルに環境変数を追加：

```bash
POLAR_ACCESS_TOKEN=polar_xxxx
POLAR_ORGANIZATION_ID=your-org-id
POLAR_SERVER=sandbox
POLAR_WEBHOOK_SECRET=your-webhook-secret
```

#### Supabase プロジェクト（本番環境）

```bash
supabase secrets set POLAR_ACCESS_TOKEN=polar_xxxx
supabase secrets set POLAR_ORGANIZATION_ID=your-org-id
supabase secrets set POLAR_SERVER=production
supabase secrets set POLAR_WEBHOOK_SECRET=your-webhook-secret
```

または、Supabase Dashboard の Settings → Edge Functions → Secrets から設定。

## API エンドポイント

### Checkout（チェックアウト）

#### チェックアウトセッション作成

```
POST /api/polar/checkouts
```

**Request Body**:

```json
{
  "productId": "prod_xxx",
  "productPriceId": "price_xxx",
  "customerId": "cus_xxx", // Optional
  "customerEmail": "user@example.com", // Optional
  "successUrl": "https://myapp.com/success",
  "metadata": { "userId": "123" } // Optional
}
```

**Response**: `Checkout` object

#### チェックアウトセッション取得

```
GET /api/polar/checkouts/:id
```

**Response**: `Checkout` object

---

### Subscriptions（サブスクリプション）

#### 顧客のサブスクリプション一覧

```
GET /api/polar/subscriptions/customer/:customerId
```

**Response**: Array of `Subscription` objects

#### サブスクリプション取得

```
GET /api/polar/subscriptions/:id
```

**Response**: `Subscription` object

#### サブスクリプションキャンセル

```
POST /api/polar/subscriptions/:id/cancel
```

**Response**: `Subscription` object (status: canceled)

---

### Customers（顧客）

#### 顧客情報取得

```
GET /api/polar/customers/:id
```

**Response**: `Customer` object

#### カスタマーポータル URL 取得

```
GET /api/polar/customer-portal/:customerId
```

**Response**:

```json
{
  "url": "https://polar.sh/portal/xxx"
}
```

---

### Orders（注文）

#### 顧客の注文一覧

```
GET /api/polar/orders/customer/:customerId
```

**Response**: Array of `Order` objects

#### 注文取得

```
GET /api/polar/orders/:id
```

**Response**: `Order` object

---

### Products（商品）

#### 商品一覧

```
GET /api/polar/products
```

**Response**: Array of `Product` objects

#### 商品取得

```
GET /api/polar/products/:id
```

**Response**: `Product` object

## ローカル開発

### 前提条件

- Deno 1.x 以上
- Supabase CLI

### 起動方法

```bash
# Edge Function を起動
supabase functions serve polar-api --env-file env/secrets.env

# または、すべての Edge Functions を起動
supabase start
```

### テスト方法

```bash
# 商品一覧を取得
curl http://localhost:54321/functions/v1/polar-api/api/polar/products

# チェックアウトセッションを作成
curl -X POST http://localhost:54321/functions/v1/polar-api/api/polar/checkouts \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "prod_xxx",
    "productPriceId": "price_xxx",
    "successUrl": "https://myapp.com/success"
  }'
```

## デプロイ

```bash
# 単一の Edge Function をデプロイ
supabase functions deploy polar-api

# すべての Edge Functions をデプロイ
make deploy-functions
```

## Flutter クライアントとの統合

Flutter アプリでは、`core_polar` パッケージを使用して API を呼び出します：

```dart
import 'package:core_polar/core_polar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 商品一覧を取得
final products = ref.watch(productsProvider);

// チェックアウトセッションを作成
final checkoutCreator = ref.read(checkoutCreatorProvider.notifier);
await checkoutCreator.createCheckout(
  productId: 'prod_xxx',
  productPriceId: 'price_xxx',
  successUrl: 'https://myapp.com/success',
);

// サブスクリプションをキャンセル
final subscriptionCanceller = ref.read(subscriptionCancellerProvider.notifier);
await subscriptionCanceller.cancelSubscription('sub_xxx');
```

## トラブルシューティング

### エラー: "POLAR_ACCESS_TOKEN is not set"

環境変数が設定されていません。`env/secrets.env` または Supabase Secrets
に設定してください。

### エラー: "Organization not found"

`POLAR_ORGANIZATION_ID` が正しく設定されているか確認してください。

### エラー: "Invalid server"

`POLAR_SERVER` は `sandbox` または `production` のいずれかである必要があります。

## 参考リンク

- [Polar.sh Documentation](https://polar.sh/docs)
- [Polar.sh TypeScript SDK](https://github.com/polarsource/polar-js)
- [Polar.sh Deno Adapter](https://polar.sh/docs/integrate/sdk/adapters/deno)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
