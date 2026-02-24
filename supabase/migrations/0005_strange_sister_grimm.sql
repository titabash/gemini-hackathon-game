ALTER TABLE "turns" ALTER COLUMN "gm_decision_type" SET DATA TYPE text;--> statement-breakpoint
DROP TYPE "public"."gm_decision_type";--> statement-breakpoint
CREATE TYPE "public"."gm_decision_type" AS ENUM('narrate', 'choice', 'clarify', 'repair');--> statement-breakpoint
ALTER TABLE "turns" ALTER COLUMN "gm_decision_type" SET DATA TYPE "public"."gm_decision_type" USING "gm_decision_type"::"public"."gm_decision_type";--> statement-breakpoint
ALTER TABLE "turns" ALTER COLUMN "input_type" SET DATA TYPE text;--> statement-breakpoint
DROP TYPE "public"."input_type";--> statement-breakpoint
CREATE TYPE "public"."input_type" AS ENUM('start', 'do', 'say', 'choice', 'clarify_answer', 'system');--> statement-breakpoint
ALTER TABLE "turns" ALTER COLUMN "input_type" SET DATA TYPE "public"."input_type" USING "input_type"::"public"."input_type";--> statement-breakpoint
ALTER TABLE "npcs" DROP COLUMN "is_active";