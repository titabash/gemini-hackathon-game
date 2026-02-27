CREATE TABLE "bgm" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"scenario_id" uuid NOT NULL,
	"mood" text NOT NULL,
	"audio_path" text NOT NULL,
	"prompt_used" text NOT NULL,
	"duration_seconds" integer DEFAULT 60 NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "bgm_scenario_id_mood_key" UNIQUE("scenario_id","mood")
);
--> statement-breakpoint
ALTER TABLE "bgm" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "bgm" ADD CONSTRAINT "bgm_scenario_id_scenarios_id_fk" FOREIGN KEY ("scenario_id") REFERENCES "public"."scenarios"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE POLICY "insert_policy_bgm_service_role" ON "bgm" AS PERMISSIVE FOR INSERT TO "service_role" WITH CHECK (true);--> statement-breakpoint
CREATE POLICY "select_policy_bgm" ON "bgm" AS PERMISSIVE FOR SELECT TO "anon", "authenticated" USING (
    EXISTS (
      SELECT 1 FROM scenarios
      WHERE scenarios.id = bgm.scenario_id
      AND (
        scenarios.is_public = true
        OR scenarios.created_by = (SELECT auth.uid())
      )
    )
  );--> statement-breakpoint
CREATE POLICY "update_policy_bgm_service_role" ON "bgm" AS PERMISSIVE FOR UPDATE TO "service_role" USING (true) WITH CHECK (true);
