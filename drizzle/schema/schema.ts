import { sql } from "drizzle-orm";
import {
  boolean,
  check,
  integer,
  jsonb,
  pgPolicy,
  pgTable,
  text,
  timestamp,
  unique,
  uuid,
} from "drizzle-orm/pg-core";
// NOTE: Deno互換のため、拡張子を明示
import {
  gmDecisionTypeEnum,
  inputTypeEnum,
  objectiveStatusEnum,
  sessionStatusEnum,
} from "./types.ts";

// ===== Users テーブル（RLS付き） =====
// Auth hook連携: auth.users作成時に自動挿入
export const users = pgTable("users", {
  id: uuid("id").primaryKey(),
  displayName: text("display_name").notNull().default(""),
  accountName: text("account_name").notNull().unique(),
  avatarPath: text("avatar_path"),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}).enableRLS();

// ===== Users RLS ポリシー =====

// Auth Hook用ポリシー（supabase_auth_admin専用）
export const insertPolicyUsers = pgPolicy("insert_policy_users", {
  for: "insert",
  to: "supabase_auth_admin",
  withCheck: sql`true`,
}).link(users);

// 全ユーザーが全usersを閲覧可能
export const selectPolicyUsers = pgPolicy("select_policy_users", {
  for: "select",
  to: ["anon", "authenticated"],
  using: sql`true`,
}).link(users);

// 自分のユーザー情報のみ編集可能
export const editPolicyUsers = pgPolicy("edit_policy_users", {
  for: "all",
  to: "authenticated",
  using: sql`(SELECT auth.uid()) = id`,
  withCheck: sql`(SELECT auth.uid()) = id`,
}).link(users);

// ===== Scenarios テーブル（RLS付き） =====
// シナリオテンプレート（再利用可能）
export const scenarios = pgTable("scenarios", {
  id: uuid("id").primaryKey().defaultRandom(),
  title: text("title").notNull(),
  description: text("description").notNull().default(""),
  initialState: jsonb("initial_state").notNull(),
  winConditions: jsonb("win_conditions").notNull(),
  failConditions: jsonb("fail_conditions").notNull(),
  thumbnailPath: text("thumbnail_path"),
  createdBy: uuid("created_by").references(() => users.id, {
    onDelete: "set null",
  }),
  isPublic: boolean("is_public").notNull().default(true),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}).enableRLS();

// ===== Scenarios RLS ポリシー =====

// 公開シナリオまたは自分のシナリオを閲覧可能
export const selectPolicyScenarios = pgPolicy("select_policy_scenarios", {
  for: "select",
  to: ["anon", "authenticated"],
  using: sql`is_public = true OR (SELECT auth.uid()) = created_by`,
}).link(scenarios);

// 自分のシナリオのみ全操作可能
export const allPolicyScenarios = pgPolicy("all_policy_scenarios", {
  for: "all",
  to: "authenticated",
  using: sql`(SELECT auth.uid()) = created_by`,
  withCheck: sql`(SELECT auth.uid()) = created_by`,
}).link(scenarios);

// シードデータ投入用（service_role）
export const insertPolicyScenariosServiceRole = pgPolicy(
  "insert_policy_scenarios_service_role",
  {
    for: "insert",
    to: "service_role",
    withCheck: sql`true`,
  },
).link(scenarios);

// ===== Sessions テーブル（RLS付き） =====
// ゲームプレイスルー
export const sessions = pgTable("sessions", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  scenarioId: uuid("scenario_id")
    .notNull()
    .references(() => scenarios.id, { onDelete: "restrict" }),
  title: text("title").notNull().default(""),
  status: sessionStatusEnum("status").notNull().default("active"),
  currentState: jsonb("current_state").notNull(),
  currentTurnNumber: integer("current_turn_number").notNull().default(0),
  endingSummary: text("ending_summary"),
  endingType: text("ending_type"),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}).enableRLS();

// ===== Sessions RLS ポリシー =====

export const selectPolicySessions = pgPolicy("select_policy_sessions", {
  for: "select",
  to: "authenticated",
  using: sql`(SELECT auth.uid()) = user_id`,
}).link(sessions);

export const allPolicySessions = pgPolicy("all_policy_sessions", {
  for: "all",
  to: "authenticated",
  using: sql`(SELECT auth.uid()) = user_id`,
  withCheck: sql`(SELECT auth.uid()) = user_id`,
}).link(sessions);

// ===== Player Characters テーブル（RLS付き） =====
// PCデータ（1セッション1体）
export const playerCharacters = pgTable("player_characters", {
  id: uuid("id").primaryKey().defaultRandom(),
  sessionId: uuid("session_id")
    .notNull()
    .unique()
    .references(() => sessions.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  imagePath: text("image_path"),
  stats: jsonb("stats").notNull(),
  statusEffects: jsonb("status_effects").notNull(),
  locationX: integer("location_x").notNull().default(0),
  locationY: integer("location_y").notNull().default(0),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}).enableRLS();

// ===== Player Characters RLS ポリシー =====

export const selectPolicyPlayerCharacters = pgPolicy(
  "select_policy_player_characters",
  {
    for: "select",
    to: "authenticated",
    using: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = player_characters.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
  },
).link(playerCharacters);

export const allPolicyPlayerCharacters = pgPolicy(
  "all_policy_player_characters",
  {
    for: "all",
    to: "authenticated",
    using: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = player_characters.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
    withCheck: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = player_characters.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
  },
).link(playerCharacters);

// ===== NPCs テーブル（RLS付き） =====
// NPCテンプレート（シナリオ定義）+ セッション固有インスタンス
export const npcs = pgTable("npcs", {
  id: uuid("id").primaryKey().defaultRandom(),
  scenarioId: uuid("scenario_id").references(() => scenarios.id, {
    onDelete: "cascade",
  }),
  sessionId: uuid("session_id").references(() => sessions.id, {
    onDelete: "cascade",
  }),
  name: text("name").notNull(),
  imagePath: text("image_path"),
  profile: jsonb("profile").notNull(),
  goals: jsonb("goals").notNull(),
  state: jsonb("state").notNull(),
  locationX: integer("location_x").notNull().default(0),
  locationY: integer("location_y").notNull().default(0),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}, () => ({
  atLeastOneParent: check(
    "npcs_at_least_one_parent",
    sql`scenario_id IS NOT NULL OR session_id IS NOT NULL`,
  ),
})).enableRLS();

// ===== NPCs RLS ポリシー =====

// シナリオ定義のNPC: 公開シナリオまたは自分のシナリオ
// セッション固有のNPC: 自分のセッション
export const selectPolicyNpcs = pgPolicy("select_policy_npcs", {
  for: "select",
  to: ["anon", "authenticated"],
  using: sql`
    (
      scenario_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM scenarios
        WHERE scenarios.id = npcs.scenario_id
        AND (scenarios.is_public = true OR scenarios.created_by = (SELECT auth.uid()))
      )
    )
    OR
    (
      session_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM sessions
        WHERE sessions.id = npcs.session_id
        AND sessions.user_id = (SELECT auth.uid())
      )
    )
  `,
}).link(npcs);

export const allPolicyNpcs = pgPolicy("all_policy_npcs", {
  for: "all",
  to: "authenticated",
  using: sql`
    (
      scenario_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM scenarios
        WHERE scenarios.id = npcs.scenario_id
        AND scenarios.created_by = (SELECT auth.uid())
      )
    )
    OR
    (
      session_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM sessions
        WHERE sessions.id = npcs.session_id
        AND sessions.user_id = (SELECT auth.uid())
      )
    )
  `,
  withCheck: sql`
    (
      scenario_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM scenarios
        WHERE scenarios.id = npcs.scenario_id
        AND scenarios.created_by = (SELECT auth.uid())
      )
    )
    OR
    (
      session_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM sessions
        WHERE sessions.id = npcs.session_id
        AND sessions.user_id = (SELECT auth.uid())
      )
    )
  `,
}).link(npcs);

// シードデータ投入用（service_role）
export const insertPolicyNpcsServiceRole = pgPolicy(
  "insert_policy_npcs_service_role",
  {
    for: "insert",
    to: "service_role",
    withCheck: sql`true`,
  },
).link(npcs);

// ===== NPC Relationships テーブル（RLS付き） =====
// NPC→PC関係値（シングルプレイヤーのため1NPC:1関係）
export const npcRelationships = pgTable("npc_relationships", {
  id: uuid("id").primaryKey().defaultRandom(),
  npcId: uuid("npc_id")
    .notNull()
    .unique()
    .references(() => npcs.id, { onDelete: "cascade" }),
  affinity: integer("affinity").notNull().default(0),
  trust: integer("trust").notNull().default(0),
  fear: integer("fear").notNull().default(0),
  debt: integer("debt").notNull().default(0),
  flags: jsonb("flags").notNull(),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}).enableRLS();

// ===== NPC Relationships RLS ポリシー =====

export const selectPolicyNpcRelationships = pgPolicy(
  "select_policy_npc_relationships",
  {
    for: "select",
    to: "authenticated",
    using: sql`
    EXISTS (
      SELECT 1 FROM npcs
      JOIN sessions ON sessions.id = npcs.session_id
      WHERE npcs.id = npc_relationships.npc_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
  },
).link(npcRelationships);

export const allPolicyNpcRelationships = pgPolicy(
  "all_policy_npc_relationships",
  {
    for: "all",
    to: "authenticated",
    using: sql`
    EXISTS (
      SELECT 1 FROM npcs
      JOIN sessions ON sessions.id = npcs.session_id
      WHERE npcs.id = npc_relationships.npc_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
    withCheck: sql`
    EXISTS (
      SELECT 1 FROM npcs
      JOIN sessions ON sessions.id = npcs.session_id
      WHERE npcs.id = npc_relationships.npc_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
  },
).link(npcRelationships);

// ===== Turns テーブル（RLS付き） =====
// ターンログ（入出力記録）
export const turns = pgTable("turns", {
  id: uuid("id").primaryKey().defaultRandom(),
  sessionId: uuid("session_id")
    .notNull()
    .references(() => sessions.id, { onDelete: "cascade" }),
  turnNumber: integer("turn_number").notNull(),
  inputType: inputTypeEnum("input_type").notNull(),
  inputText: text("input_text").notNull().default(""),
  gmDecisionType: gmDecisionTypeEnum("gm_decision_type").notNull(),
  output: jsonb("output").notNull(),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}, (table) => [
  unique("turns_session_id_turn_number_key").on(
    table.sessionId,
    table.turnNumber,
  ),
]).enableRLS();

// ===== Turns RLS ポリシー =====

export const selectPolicyTurns = pgPolicy("select_policy_turns", {
  for: "select",
  to: "authenticated",
  using: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = turns.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
}).link(turns);

export const allPolicyTurns = pgPolicy("all_policy_turns", {
  for: "all",
  to: "authenticated",
  using: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = turns.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
  withCheck: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = turns.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
}).link(turns);

// ===== Context Summaries テーブル（RLS付き） =====
// AI GMコンテキスト管理（1セッション1コンテキスト）
export const contextSummaries = pgTable("context_summaries", {
  id: uuid("id").primaryKey().defaultRandom(),
  sessionId: uuid("session_id")
    .notNull()
    .unique()
    .references(() => sessions.id, { onDelete: "cascade" }),
  plotEssentials: jsonb("plot_essentials").notNull(),
  shortTermSummary: text("short_term_summary").notNull().default(""),
  confirmedFacts: jsonb("confirmed_facts").notNull(),
  lastUpdatedTurn: integer("last_updated_turn").notNull().default(0),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}).enableRLS();

// ===== Context Summaries RLS ポリシー =====

export const selectPolicyContextSummaries = pgPolicy(
  "select_policy_context_summaries",
  {
    for: "select",
    to: "authenticated",
    using: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = context_summaries.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
  },
).link(contextSummaries);

export const allPolicyContextSummaries = pgPolicy(
  "all_policy_context_summaries",
  {
    for: "all",
    to: "authenticated",
    using: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = context_summaries.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
    withCheck: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = context_summaries.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
  },
).link(contextSummaries);

// ===== Objectives テーブル（RLS付き） =====
// クエスト/目標の進捗追跡（セッション単位）
export const objectives = pgTable("objectives", {
  id: uuid("id").primaryKey().defaultRandom(),
  sessionId: uuid("session_id")
    .notNull()
    .references(() => sessions.id, { onDelete: "cascade" }),
  title: text("title").notNull(),
  description: text("description").notNull().default(""),
  status: objectiveStatusEnum("status").notNull().default("active"),
  sortOrder: integer("sort_order").notNull().default(0),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}).enableRLS();

// ===== Objectives RLS ポリシー =====

export const selectPolicyObjectives = pgPolicy("select_policy_objectives", {
  for: "select",
  to: "authenticated",
  using: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = objectives.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
}).link(objectives);

export const allPolicyObjectives = pgPolicy("all_policy_objectives", {
  for: "all",
  to: "authenticated",
  using: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = objectives.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
  withCheck: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = objectives.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
}).link(objectives);

// ===== Items テーブル（RLS付き） =====
// セッション単位のアイテム（1セッション=1PCのためsession_idで暗黙的にPC所有）
export const items = pgTable("items", {
  id: uuid("id").primaryKey().defaultRandom(),
  sessionId: uuid("session_id")
    .notNull()
    .references(() => sessions.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  description: text("description").notNull().default(""),
  type: text("type").notNull().default(""),
  imagePath: text("image_path"),
  quantity: integer("quantity").notNull().default(1),
  isEquipped: boolean("is_equipped").notNull().default(false),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp("updated_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}).enableRLS();

// ===== Items RLS ポリシー =====

export const selectPolicyItems = pgPolicy("select_policy_items", {
  for: "select",
  to: "authenticated",
  using: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = items.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
}).link(items);

export const allPolicyItems = pgPolicy("all_policy_items", {
  for: "all",
  to: "authenticated",
  using: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = items.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
  withCheck: sql`
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = items.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  `,
}).link(items);

// ===== Scene Backgrounds テーブル（RLS付き） =====
// ロケーション背景画像（シナリオ定義 + セッション中の動的生成）
export const sceneBackgrounds = pgTable("scene_backgrounds", {
  id: uuid("id").primaryKey().defaultRandom(),
  scenarioId: uuid("scenario_id").references(() => scenarios.id, {
    onDelete: "cascade",
  }),
  sessionId: uuid("session_id").references(() => sessions.id, {
    onDelete: "cascade",
  }),
  locationName: text("location_name").notNull(),
  imagePath: text("image_path"),
  description: text("description").notNull().default(""),
  createdAt: timestamp("created_at", {
    withTimezone: true,
    precision: 3,
  })
    .notNull()
    .defaultNow(),
}, () => ({
  atLeastOneParent: check(
    "at_least_one_parent",
    sql`scenario_id IS NOT NULL OR session_id IS NOT NULL`,
  ),
})).enableRLS();

// ===== Scene Backgrounds RLS ポリシー =====

// シナリオ定義の背景: 公開シナリオまたは自分のシナリオ
// セッション動的生成の背景: 自分のセッション
export const selectPolicySceneBackgrounds = pgPolicy(
  "select_policy_scene_backgrounds",
  {
    for: "select",
    to: ["anon", "authenticated"],
    using: sql`
    (
      scenario_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM scenarios
        WHERE scenarios.id = scene_backgrounds.scenario_id
        AND (scenarios.is_public = true OR scenarios.created_by = (SELECT auth.uid()))
      )
    )
    OR
    (
      session_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM sessions
        WHERE sessions.id = scene_backgrounds.session_id
        AND sessions.user_id = (SELECT auth.uid())
      )
    )
  `,
  },
).link(sceneBackgrounds);

export const allPolicySceneBackgrounds = pgPolicy(
  "all_policy_scene_backgrounds",
  {
    for: "all",
    to: "authenticated",
    using: sql`
    (
      scenario_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM scenarios
        WHERE scenarios.id = scene_backgrounds.scenario_id
        AND scenarios.created_by = (SELECT auth.uid())
      )
    )
    OR
    (
      session_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM sessions
        WHERE sessions.id = scene_backgrounds.session_id
        AND sessions.user_id = (SELECT auth.uid())
      )
    )
  `,
    withCheck: sql`
    (
      scenario_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM scenarios
        WHERE scenarios.id = scene_backgrounds.scenario_id
        AND scenarios.created_by = (SELECT auth.uid())
      )
    )
    OR
    (
      session_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM sessions
        WHERE sessions.id = scene_backgrounds.session_id
        AND sessions.user_id = (SELECT auth.uid())
      )
    )
  `,
  },
).link(sceneBackgrounds);

// シードデータ投入用（service_role）
export const insertPolicySceneBackgroundsServiceRole = pgPolicy(
  "insert_policy_scene_backgrounds_service_role",
  {
    for: "insert",
    to: "service_role",
    withCheck: sql`true`,
  },
).link(sceneBackgrounds);

// ===== 型エクスポート（Inferで自動推論） =====
import type { InferInsertModel, InferSelectModel } from "drizzle-orm";

// SELECT型（既存レコードの型）
export type User = InferSelectModel<typeof users>;
export type Scenario = InferSelectModel<typeof scenarios>;
export type Session = InferSelectModel<typeof sessions>;
export type PlayerCharacter = InferSelectModel<typeof playerCharacters>;
export type Npc = InferSelectModel<typeof npcs>;
export type NpcRelationship = InferSelectModel<typeof npcRelationships>;
export type Turn = InferSelectModel<typeof turns>;
export type ContextSummary = InferSelectModel<typeof contextSummaries>;
export type Objective = InferSelectModel<typeof objectives>;
export type Item = InferSelectModel<typeof items>;
export type SceneBackground = InferSelectModel<typeof sceneBackgrounds>;

// INSERT型（新規作成時の型）
export type NewUser = InferInsertModel<typeof users>;
export type NewScenario = InferInsertModel<typeof scenarios>;
export type NewSession = InferInsertModel<typeof sessions>;
export type NewPlayerCharacter = InferInsertModel<typeof playerCharacters>;
export type NewNpc = InferInsertModel<typeof npcs>;
export type NewNpcRelationship = InferInsertModel<typeof npcRelationships>;
export type NewTurn = InferInsertModel<typeof turns>;
export type NewContextSummary = InferInsertModel<typeof contextSummaries>;
export type NewObjective = InferInsertModel<typeof objectives>;
export type NewItem = InferInsertModel<typeof items>;
export type NewSceneBackground = InferInsertModel<typeof sceneBackgrounds>;
