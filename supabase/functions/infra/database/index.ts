/**
 * Database infrastructure exports
 *
 * Drizzle ORMを使用した型安全なデータベースアクセス層
 *
 * 使用方法:
 *   import { getDb, schema, eq } from "@infra/database";
 *
 *   // トランザクションやDirect DB操作（Drizzle ORM）
 *   const db = getDb();
 *   const users = await db.select().from(schema.generalUsers).limit(10);
 *
 *   // Supabase-jsを使う場合
 *   import { Database } from "./database-types.ts";
 *   import { createClient } from "@supabase/supabase-js";
 *   const supabase = createClient<Database>(...);
 */

// Drizzleクライアント
export { getDb, closeDb, schema, eq, and, or, sql } from "./drizzle-client.ts";
export type { InferSelectModel, InferInsertModel } from "./drizzle-client.ts";

// Supabase-js用のデータベース型定義（併用パターン）
// Supabaseクライアント（Auth, Storage, Realtime, RPC）を使う場合はこちらを使用
export type { Database } from "./database-types.ts";
