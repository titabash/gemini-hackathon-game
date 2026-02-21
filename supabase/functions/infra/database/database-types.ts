import { Generated, Insertable, Selectable, Updateable } from "kysely";
import { Database as SupabaseDatabase } from "@domain/entity/__generated__/schema.ts";

// Kysely用の型定義
// Supabaseの型からKysely用の型に変換

// general_users テーブルの型定義
export interface GeneralUsersTable {
  id: Generated<number>;
  name: string;
}

// corporate_users テーブルの型定義
export interface CorporateUsersTable {
  id: Generated<number>;
  name: string;
  organizationId: number;
}

// organizations テーブルの型定義
export interface OrganizationsTable {
  id: Generated<number>;
  name: string;
}

// posts テーブルの型定義
export interface PostsTable {
  id: Generated<number>;
  title: string;
  body: string;
  general_user_id: number;
}

// Database スキーマの定義
export interface Database {
  general_users: GeneralUsersTable;
  corporate_users: CorporateUsersTable;
  organizations: OrganizationsTable;
  posts: PostsTable;
}

// 各テーブルのCRUD用の型
export type GeneralUser = Selectable<GeneralUsersTable>;
export type NewGeneralUser = Insertable<GeneralUsersTable>;
export type GeneralUserUpdate = Updateable<GeneralUsersTable>;

export type CorporateUser = Selectable<CorporateUsersTable>;
export type NewCorporateUser = Insertable<CorporateUsersTable>;
export type CorporateUserUpdate = Updateable<CorporateUsersTable>;

export type Organization = Selectable<OrganizationsTable>;
export type NewOrganization = Insertable<OrganizationsTable>;
export type OrganizationUpdate = Updateable<OrganizationsTable>;

export type Post = Selectable<PostsTable>;
export type NewPost = Insertable<PostsTable>;
export type PostUpdate = Updateable<PostsTable>;