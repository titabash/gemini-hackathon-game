ALTER TABLE "npcs" ALTER COLUMN "session_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "npcs" ADD COLUMN "scenario_id" uuid;--> statement-breakpoint
ALTER TABLE "npcs" ADD CONSTRAINT "npcs_scenario_id_scenarios_id_fk" FOREIGN KEY ("scenario_id") REFERENCES "public"."scenarios"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "npcs" ADD CONSTRAINT "npcs_at_least_one_parent" CHECK (scenario_id IS NOT NULL OR session_id IS NOT NULL);--> statement-breakpoint
CREATE POLICY "insert_policy_npcs_service_role" ON "npcs" AS PERMISSIVE FOR INSERT TO "service_role" WITH CHECK (true);--> statement-breakpoint
ALTER POLICY "all_policy_npcs" ON "npcs" TO authenticated USING (
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
  ) WITH CHECK (
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
  );--> statement-breakpoint
ALTER POLICY "select_policy_npcs" ON "npcs" TO anon,authenticated USING (
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
  );