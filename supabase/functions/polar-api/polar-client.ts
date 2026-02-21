/**
 * Polar SDK Client Factory
 *
 * サーバーサイドでのみ使用（Access Token を含むため）
 */
import { Polar } from "@polar-sh/sdk";

/**
 * Polar クライアントを作成
 *
 * @returns Polar SDK クライアントインスタンス
 * @throws 環境変数が設定されていない場合
 */
export function createPolarClient(): Polar {
  const accessToken = Deno.env.get("POLAR_ACCESS_TOKEN");

  if (!accessToken) {
    throw new Error(
      "POLAR_ACCESS_TOKEN is not set. Please set it in your environment variables.",
    );
  }

  const server = (Deno.env.get("POLAR_SERVER") ?? "sandbox") as
    | "sandbox"
    | "production";

  return new Polar({
    accessToken,
    server,
  });
}

/**
 * Organization ID を取得
 *
 * @returns Polar Organization ID
 * @throws 環境変数が設定されていない場合
 */
export function getOrganizationId(): string {
  const orgId = Deno.env.get("POLAR_ORGANIZATION_ID");

  if (!orgId) {
    throw new Error(
      "POLAR_ORGANIZATION_ID is not set. Please set it in your environment variables.",
    );
  }

  return orgId;
}

/**
 * Polar クライアントのシングルトンインスタンス
 */
let polarClientInstance: Polar | null = null;

/**
 * Polar クライアントのシングルトンを取得
 *
 * @returns Polar SDK クライアントインスタンス
 */
export function getPolarClient(): Polar {
  if (!polarClientInstance) {
    polarClientInstance = createPolarClient();
  }
  return polarClientInstance;
}
