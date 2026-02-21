/**
 * Polar API Edge Function
 *
 * Flutter アプリからの Polar.sh API リクエストをプロキシします
 * Access Token をサーバーサイドで管理し、クライアントに露出しません
 */
import { createFunctionLogger } from "../shared/logger/index.ts";
import { getOrganizationId, getPolarClient } from "./polar-client.ts";

const logger = createFunctionLogger("polar-api");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};

/**
 * エラーレスポンスを返す
 */
function errorResponse(message: string, status = 500) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * 成功レスポンスを返す
 */
function successResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * URLから IDとエンドポイント を抽出
 */
function parseUrl(url: URL) {
  const path = url.pathname;
  const segments = path.split("/").filter(Boolean);
  return { path, segments };
}

Deno.serve(async (req: Request) => {
  // CORS プリフライト
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const { segments } = parseUrl(url);
    const method = req.method;

    // Polar クライアント初期化
    const polar = getPolarClient();
    const organizationId = getOrganizationId();

    logger.info("Request received", { method, path: url.pathname });

    // ==================== Checkout Endpoints ====================

    // POST /api/polar/checkouts - チェックアウトセッション作成
    if (
      method === "POST" && segments[2] === "checkouts" && segments.length === 3
    ) {
      const body = await req.json();
      const {
        productId,
        productPriceId,
        customerId,
        customerEmail,
        successUrl,
        cancelUrl: _cancelUrl,
        metadata,
      } = body;

      const checkout = await polar.checkouts.custom.create({
        productId,
        productPriceId,
        customerId,
        customerEmail,
        successUrl,
        ...(metadata && { metadata }),
      });

      return successResponse(checkout);
    }

    // GET /api/polar/checkouts/:id - チェックアウトセッション取得
    if (
      method === "GET" && segments[2] === "checkouts" && segments.length === 4
    ) {
      const checkoutId = segments[3];
      const checkout = await polar.checkouts.custom.get({ id: checkoutId });
      return successResponse(checkout);
    }

    // ==================== Subscription Endpoints ====================

    // GET /api/polar/subscriptions/customer/:customerId - 顧客のサブスクリプション一覧
    if (
      method === "GET" &&
      segments[2] === "subscriptions" &&
      segments[3] === "customer" &&
      segments.length === 5
    ) {
      const customerId = segments[4];
      const response = await polar.subscriptions.list({
        customerId,
        organizationId,
      });

      return successResponse(response.result?.items ?? []);
    }

    // GET /api/polar/subscriptions/:id - サブスクリプション取得
    if (
      method === "GET" && segments[2] === "subscriptions" &&
      segments.length === 4
    ) {
      const subscriptionId = segments[3];
      const subscription = await polar.subscriptions.get({
        id: subscriptionId,
      });
      return successResponse(subscription);
    }

    // POST /api/polar/subscriptions/:id/cancel - サブスクリプションキャンセル
    if (
      method === "POST" &&
      segments[2] === "subscriptions" &&
      segments[4] === "cancel" &&
      segments.length === 5
    ) {
      const subscriptionId = segments[3];
      const subscription = await polar.subscriptions.cancel({
        id: subscriptionId,
      });
      return successResponse(subscription);
    }

    // ==================== Customer Endpoints ====================

    // GET /api/polar/customers/:id - 顧客情報取得
    if (
      method === "GET" && segments[2] === "customers" && segments.length === 4
    ) {
      const customerId = segments[3];
      const customer = await polar.customers.get({ id: customerId });
      return successResponse(customer);
    }

    // GET /api/polar/customer-portal/:customerId - カスタマーポータル URL 取得
    if (
      method === "GET" && segments[2] === "customer-portal" &&
      segments.length === 4
    ) {
      const customerId = segments[3];
      const portalUrl = await polar.customerSessions.create({ customerId });
      return successResponse({ url: portalUrl.customerPortalUrl });
    }

    // ==================== Order Endpoints ====================

    // GET /api/polar/orders/customer/:customerId - 顧客の注文一覧
    if (
      method === "GET" &&
      segments[2] === "orders" &&
      segments[3] === "customer" &&
      segments.length === 5
    ) {
      const customerId = segments[4];
      const response = await polar.orders.list({
        customerId,
        organizationId,
      });
      return successResponse(response.result?.items ?? []);
    }

    // GET /api/polar/orders/:id - 注文取得
    if (method === "GET" && segments[2] === "orders" && segments.length === 4) {
      const orderId = segments[3];
      const order = await polar.orders.get({ id: orderId });
      return successResponse(order);
    }

    // ==================== Product Endpoints ====================

    // GET /api/polar/products - 商品一覧
    if (
      method === "GET" && segments[2] === "products" && segments.length === 3
    ) {
      const response = await polar.products.list({ organizationId });
      return successResponse(response.result?.items ?? []);
    }

    // GET /api/polar/products/:id - 商品取得
    if (
      method === "GET" && segments[2] === "products" && segments.length === 4
    ) {
      const productId = segments[3];
      const product = await polar.products.get({ id: productId });
      return successResponse(product);
    }

    // ==================== Not Found ====================

    return errorResponse("Endpoint not found", 404);
  } catch (error) {
    const errorMessage = error instanceof Error
      ? error.message
      : "Unknown error";
    logger.error("Error processing request", { error: errorMessage });
    return errorResponse(errorMessage, 500);
  }
});
