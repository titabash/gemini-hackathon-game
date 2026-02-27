DO $$
BEGIN
	IF to_regclass('public.bgm') IS NULL THEN
		IF to_regclass('public.bgm_cache') IS NOT NULL THEN
			ALTER TABLE public.bgm_cache RENAME TO bgm;
		ELSE
			CREATE TABLE public.bgm (
				id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
				scenario_id uuid NOT NULL,
				mood text NOT NULL,
				audio_path text NOT NULL,
				prompt_used text NOT NULL,
				duration_seconds integer DEFAULT 60 NOT NULL,
				created_at timestamp (3) with time zone DEFAULT now() NOT NULL
			);
		END IF;
	END IF;
END $$;
--> statement-breakpoint

DO $$
BEGIN
	IF to_regclass('public.bgm') IS NOT NULL
		AND to_regclass('public.bgm_cache') IS NOT NULL THEN
		INSERT INTO public.bgm (
			id,
			scenario_id,
			mood,
			audio_path,
			prompt_used,
			duration_seconds,
			created_at
		)
		SELECT
			id,
			scenario_id,
			mood,
			audio_path,
			prompt_used,
			duration_seconds,
			created_at
		FROM public.bgm_cache old
		WHERE NOT EXISTS (
			SELECT 1
			FROM public.bgm cur
			WHERE cur.scenario_id = old.scenario_id
				AND cur.mood = old.mood
		);

		DROP TABLE public.bgm_cache;
	END IF;
END $$;
--> statement-breakpoint

DO $$
BEGIN
	IF to_regclass('public.bgm') IS NULL THEN
		RETURN;
	END IF;

	IF EXISTS (
		SELECT 1
		FROM pg_constraint
		WHERE conrelid = 'public.bgm'::regclass
			AND conname = 'bgm_cache_pkey'
	) AND NOT EXISTS (
		SELECT 1
		FROM pg_constraint
		WHERE conrelid = 'public.bgm'::regclass
			AND conname = 'bgm_pkey'
	) THEN
		ALTER TABLE public.bgm
		RENAME CONSTRAINT bgm_cache_pkey TO bgm_pkey;
	END IF;

	IF EXISTS (
		SELECT 1
		FROM pg_constraint
		WHERE conrelid = 'public.bgm'::regclass
			AND conname = 'bgm_cache_scenario_id_mood_key'
	) AND NOT EXISTS (
		SELECT 1
		FROM pg_constraint
		WHERE conrelid = 'public.bgm'::regclass
			AND conname = 'bgm_scenario_id_mood_key'
	) THEN
		ALTER TABLE public.bgm
		RENAME CONSTRAINT bgm_cache_scenario_id_mood_key TO bgm_scenario_id_mood_key;
	END IF;

	IF EXISTS (
		SELECT 1
		FROM pg_constraint
		WHERE conrelid = 'public.bgm'::regclass
			AND conname = 'bgm_cache_scenario_id_scenarios_id_fk'
	) AND NOT EXISTS (
		SELECT 1
		FROM pg_constraint
		WHERE conrelid = 'public.bgm'::regclass
			AND conname = 'bgm_scenario_id_scenarios_id_fk'
	) THEN
		ALTER TABLE public.bgm
		RENAME CONSTRAINT bgm_cache_scenario_id_scenarios_id_fk TO bgm_scenario_id_scenarios_id_fk;
	END IF;

	IF NOT EXISTS (
		SELECT 1
		FROM pg_constraint
		WHERE conrelid = 'public.bgm'::regclass
			AND conname = 'bgm_scenario_id_mood_key'
	) THEN
		ALTER TABLE public.bgm
		ADD CONSTRAINT bgm_scenario_id_mood_key UNIQUE (scenario_id, mood);
	END IF;

	IF NOT EXISTS (
		SELECT 1
		FROM pg_constraint
		WHERE conrelid = 'public.bgm'::regclass
			AND conname = 'bgm_scenario_id_scenarios_id_fk'
	) THEN
		ALTER TABLE public.bgm
		ADD CONSTRAINT bgm_scenario_id_scenarios_id_fk
		FOREIGN KEY (scenario_id) REFERENCES public.scenarios(id) ON DELETE cascade;
	END IF;
END $$;
--> statement-breakpoint

ALTER TABLE public.bgm ENABLE ROW LEVEL SECURITY;
--> statement-breakpoint

DROP POLICY IF EXISTS select_policy_bgm_cache ON public.bgm;
--> statement-breakpoint
DROP POLICY IF EXISTS insert_policy_bgm_cache_service_role ON public.bgm;
--> statement-breakpoint
DROP POLICY IF EXISTS update_policy_bgm_cache_service_role ON public.bgm;
--> statement-breakpoint
DROP POLICY IF EXISTS select_policy_bgm ON public.bgm;
--> statement-breakpoint
DROP POLICY IF EXISTS insert_policy_bgm_service_role ON public.bgm;
--> statement-breakpoint
DROP POLICY IF EXISTS update_policy_bgm_service_role ON public.bgm;
--> statement-breakpoint

CREATE POLICY select_policy_bgm ON public.bgm AS PERMISSIVE FOR SELECT TO "anon", "authenticated" USING (
	EXISTS (
		SELECT 1 FROM scenarios
		WHERE scenarios.id = bgm.scenario_id
		AND (
			scenarios.is_public = true
			OR scenarios.created_by = (SELECT auth.uid())
		)
	)
);
--> statement-breakpoint

CREATE POLICY insert_policy_bgm_service_role ON public.bgm AS PERMISSIVE FOR INSERT TO "service_role" WITH CHECK (true);
--> statement-breakpoint

CREATE POLICY update_policy_bgm_service_role ON public.bgm AS PERMISSIVE FOR UPDATE TO "service_role" USING (true) WITH CHECK (true);
