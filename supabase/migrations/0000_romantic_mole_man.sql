CREATE TYPE "public"."gm_decision_type" AS ENUM('narrate', 'choice', 'roll', 'clarify', 'repair');--> statement-breakpoint
CREATE TYPE "public"."input_type" AS ENUM('do', 'say', 'choice', 'roll_result', 'clarify_answer', 'system');--> statement-breakpoint
CREATE TYPE "public"."objective_status" AS ENUM('active', 'completed', 'failed');--> statement-breakpoint
CREATE TYPE "public"."session_status" AS ENUM('active', 'completed', 'abandoned');--> statement-breakpoint
CREATE TABLE "context_summaries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"session_id" uuid NOT NULL,
	"plot_essentials" jsonb NOT NULL,
	"short_term_summary" text DEFAULT '' NOT NULL,
	"confirmed_facts" jsonb NOT NULL,
	"last_updated_turn" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "context_summaries_session_id_unique" UNIQUE("session_id")
);
--> statement-breakpoint
ALTER TABLE "context_summaries" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"session_id" uuid NOT NULL,
	"name" text NOT NULL,
	"description" text DEFAULT '' NOT NULL,
	"type" text DEFAULT '' NOT NULL,
	"image_path" text,
	"quantity" integer DEFAULT 1 NOT NULL,
	"is_equipped" boolean DEFAULT false NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp (3) with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "items" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "npc_relationships" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"npc_id" uuid NOT NULL,
	"affinity" integer DEFAULT 0 NOT NULL,
	"trust" integer DEFAULT 0 NOT NULL,
	"fear" integer DEFAULT 0 NOT NULL,
	"debt" integer DEFAULT 0 NOT NULL,
	"flags" jsonb NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "npc_relationships_npc_id_unique" UNIQUE("npc_id")
);
--> statement-breakpoint
ALTER TABLE "npc_relationships" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "npcs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"session_id" uuid NOT NULL,
	"name" text NOT NULL,
	"image_path" text,
	"profile" jsonb NOT NULL,
	"goals" jsonb NOT NULL,
	"state" jsonb NOT NULL,
	"location_x" integer DEFAULT 0 NOT NULL,
	"location_y" integer DEFAULT 0 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp (3) with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "npcs" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "objectives" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"session_id" uuid NOT NULL,
	"title" text NOT NULL,
	"description" text DEFAULT '' NOT NULL,
	"status" "objective_status" DEFAULT 'active' NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp (3) with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "objectives" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "player_characters" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"session_id" uuid NOT NULL,
	"name" text NOT NULL,
	"image_path" text,
	"stats" jsonb NOT NULL,
	"status_effects" jsonb NOT NULL,
	"location_x" integer DEFAULT 0 NOT NULL,
	"location_y" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "player_characters_session_id_unique" UNIQUE("session_id")
);
--> statement-breakpoint
ALTER TABLE "player_characters" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "scenarios" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"title" text NOT NULL,
	"description" text DEFAULT '' NOT NULL,
	"initial_state" jsonb NOT NULL,
	"win_conditions" jsonb NOT NULL,
	"fail_conditions" jsonb NOT NULL,
	"thumbnail_path" text,
	"created_by" uuid,
	"is_public" boolean DEFAULT true NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp (3) with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "scenarios" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "scene_backgrounds" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"scenario_id" uuid,
	"session_id" uuid,
	"location_name" text NOT NULL,
	"image_path" text,
	"description" text DEFAULT '' NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "at_least_one_parent" CHECK (scenario_id IS NOT NULL OR session_id IS NOT NULL)
);
--> statement-breakpoint
ALTER TABLE "scene_backgrounds" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"scenario_id" uuid NOT NULL,
	"title" text DEFAULT '' NOT NULL,
	"status" "session_status" DEFAULT 'active' NOT NULL,
	"current_state" jsonb NOT NULL,
	"current_turn_number" integer DEFAULT 0 NOT NULL,
	"ending_summary" text,
	"ending_type" text,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp (3) with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "sessions" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "turns" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"session_id" uuid NOT NULL,
	"turn_number" integer NOT NULL,
	"input_type" "input_type" NOT NULL,
	"input_text" text DEFAULT '' NOT NULL,
	"gm_decision_type" "gm_decision_type" NOT NULL,
	"output" jsonb NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "turns_session_id_turn_number_key" UNIQUE("session_id","turn_number")
);
--> statement-breakpoint
ALTER TABLE "turns" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY NOT NULL,
	"display_name" text DEFAULT '' NOT NULL,
	"account_name" text NOT NULL,
	"avatar_path" text,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "users_account_name_unique" UNIQUE("account_name")
);
--> statement-breakpoint
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "context_summaries" ADD CONSTRAINT "context_summaries_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "items" ADD CONSTRAINT "items_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "npc_relationships" ADD CONSTRAINT "npc_relationships_npc_id_npcs_id_fk" FOREIGN KEY ("npc_id") REFERENCES "public"."npcs"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "npcs" ADD CONSTRAINT "npcs_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "objectives" ADD CONSTRAINT "objectives_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "player_characters" ADD CONSTRAINT "player_characters_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "scenarios" ADD CONSTRAINT "scenarios_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "scene_backgrounds" ADD CONSTRAINT "scene_backgrounds_scenario_id_scenarios_id_fk" FOREIGN KEY ("scenario_id") REFERENCES "public"."scenarios"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "scene_backgrounds" ADD CONSTRAINT "scene_backgrounds_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_scenario_id_scenarios_id_fk" FOREIGN KEY ("scenario_id") REFERENCES "public"."scenarios"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "turns" ADD CONSTRAINT "turns_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE POLICY "all_policy_context_summaries" ON "context_summaries" AS PERMISSIVE FOR ALL TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = context_summaries.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = context_summaries.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "select_policy_context_summaries" ON "context_summaries" AS PERMISSIVE FOR SELECT TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = context_summaries.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "all_policy_items" ON "items" AS PERMISSIVE FOR ALL TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = items.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = items.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "select_policy_items" ON "items" AS PERMISSIVE FOR SELECT TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = items.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "all_policy_npc_relationships" ON "npc_relationships" AS PERMISSIVE FOR ALL TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM npcs
      JOIN sessions ON sessions.id = npcs.session_id
      WHERE npcs.id = npc_relationships.npc_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM npcs
      JOIN sessions ON sessions.id = npcs.session_id
      WHERE npcs.id = npc_relationships.npc_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "select_policy_npc_relationships" ON "npc_relationships" AS PERMISSIVE FOR SELECT TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM npcs
      JOIN sessions ON sessions.id = npcs.session_id
      WHERE npcs.id = npc_relationships.npc_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "all_policy_npcs" ON "npcs" AS PERMISSIVE FOR ALL TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = npcs.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = npcs.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "select_policy_npcs" ON "npcs" AS PERMISSIVE FOR SELECT TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = npcs.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "all_policy_objectives" ON "objectives" AS PERMISSIVE FOR ALL TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = objectives.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = objectives.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "select_policy_objectives" ON "objectives" AS PERMISSIVE FOR SELECT TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = objectives.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "all_policy_player_characters" ON "player_characters" AS PERMISSIVE FOR ALL TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = player_characters.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = player_characters.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "select_policy_player_characters" ON "player_characters" AS PERMISSIVE FOR SELECT TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = player_characters.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "all_policy_scenarios" ON "scenarios" AS PERMISSIVE FOR ALL TO "authenticated" USING ((SELECT auth.uid()) = created_by) WITH CHECK ((SELECT auth.uid()) = created_by);--> statement-breakpoint
CREATE POLICY "insert_policy_scenarios_service_role" ON "scenarios" AS PERMISSIVE FOR INSERT TO "service_role" WITH CHECK (true);--> statement-breakpoint
CREATE POLICY "select_policy_scenarios" ON "scenarios" AS PERMISSIVE FOR SELECT TO "anon", "authenticated" USING (is_public = true OR (SELECT auth.uid()) = created_by);--> statement-breakpoint
CREATE POLICY "all_policy_scene_backgrounds" ON "scene_backgrounds" AS PERMISSIVE FOR ALL TO "authenticated" USING (
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
  ) WITH CHECK (
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
  );--> statement-breakpoint
CREATE POLICY "insert_policy_scene_backgrounds_service_role" ON "scene_backgrounds" AS PERMISSIVE FOR INSERT TO "service_role" WITH CHECK (true);--> statement-breakpoint
CREATE POLICY "select_policy_scene_backgrounds" ON "scene_backgrounds" AS PERMISSIVE FOR SELECT TO "anon", "authenticated" USING (
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
  );--> statement-breakpoint
CREATE POLICY "all_policy_sessions" ON "sessions" AS PERMISSIVE FOR ALL TO "authenticated" USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);--> statement-breakpoint
CREATE POLICY "select_policy_sessions" ON "sessions" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((SELECT auth.uid()) = user_id);--> statement-breakpoint
CREATE POLICY "all_policy_turns" ON "turns" AS PERMISSIVE FOR ALL TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = turns.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = turns.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "select_policy_turns" ON "turns" AS PERMISSIVE FOR SELECT TO "authenticated" USING (
    EXISTS (
      SELECT 1 FROM sessions
      WHERE sessions.id = turns.session_id
      AND sessions.user_id = (SELECT auth.uid())
    )
  );--> statement-breakpoint
CREATE POLICY "edit_policy_users" ON "users" AS PERMISSIVE FOR ALL TO "authenticated" USING ((SELECT auth.uid()) = id) WITH CHECK ((SELECT auth.uid()) = id);--> statement-breakpoint
CREATE POLICY "insert_policy_users" ON "users" AS PERMISSIVE FOR INSERT TO "supabase_auth_admin" WITH CHECK (true);--> statement-breakpoint
CREATE POLICY "select_policy_users" ON "users" AS PERMISSIVE FOR SELECT TO "anon", "authenticated" USING (true);