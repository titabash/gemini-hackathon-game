/**
 * Drizzle ORM クライアント for Supabase Edge Functions
 *
 * Supabase Edge FunctionsでDrizzle ORMを使用するためのクライアント実装
 * - Deno互換のため拡張子を明示
 * - Transaction pool mode対応のため prepare: false を設定
 * - シングルトンパターンでデータベースインスタンスを管理
 *
 * 参考: https://orm.drizzle.team/docs/tutorials/drizzle-with-supabase-edge-functions
 */

import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";

// Drizzleスキーマをインポート（import_mapでマッピング）
// NOTE: shared/drizzle/にスキーマがコピーされる（build-model-functionsで実行）
import * as schema from "@drizzle-schema/index.ts";

/**
 * DATABASE_URLをパースして接続情報を取得
 */
function getDatabaseUrl(): string {
  // 本番環境: DATABASE_URL（Connection Pooler経由）
  // ローカル開発: SUPABASE_DB_URL または DATABASE_URL
  const databaseUrl = Deno.env.get("DATABASE_URL") || Deno.env.get("SUPABASE_DB_URL");

  if (!databaseUrl) {
    throw new Error(
      "DATABASE_URL or SUPABASE_DB_URL environment variable is required. " +
      "Please set the database connection string in your environment."
    );
  }

  return databaseUrl;
}

/**
 * Drizzleデータベースインスタンスを作成
 *
 * Transaction pool mode対応のため prepare: false を設定
 * 参考: "Disable prefetch as it is not supported for Transaction pool mode"
 */
function createDb() {
  const connectionString = getDatabaseUrl();

  // PostgreSQL接続クライアント（prepare: false でTransaction pool mode対応）
  const client = postgres(connectionString, { prepare: false });

  // クライアントの参照を保存（closeDb用）
  clientInstance = client;

  // Drizzle ORMインスタンスを作成（スキーマ付き）
  const db = drizzle({ client, schema });

  return db;
}

// シングルトンパターンでデータベースインスタンスを管理
let dbInstance: ReturnType<typeof createDb> | null = null;
let clientInstance: ReturnType<typeof postgres> | null = null;

/**
 * データベースインスタンスを取得
 *
 * シングルトンパターンにより、Edge Function内で単一のインスタンスを共有
 * @returns Drizzle ORMデータベースインスタンス
 */
export function getDb() {
  if (!dbInstance) {
    dbInstance = createDb();
  }
  return dbInstance;
}

/**
 * データベース接続を閉じる
 *
 * 通常、Edge Functionsでは明示的にクローズする必要はありませんが、
 * テストやクリーンアップ時に使用できます
 */
export async function closeDb(): Promise<void> {
  if (clientInstance) {
    // postgres-jsクライアントを閉じる
    await clientInstance.end();
    clientInstance = null;
    dbInstance = null;
  }
}

/**
 * スキーマの再エクスポート
 *
 * 型安全性を確保するため、スキーマオブジェクトを再エクスポートします
 * 使用例:
 *   import { getDb, schema } from "@infra/database/drizzle-client.ts";
 *   const users = await getDb().select().from(schema.generalUsers).limit(10);
 */
export { schema };

/**
 * Drizzle ORMの型をre-export
 *
 * Edge Functions内でDrizzle ORMの型を使用する際に便利です
 */
export { eq, and, or, sql } from "drizzle-orm";
export type { InferSelectModel, InferInsertModel } from "drizzle-orm";
