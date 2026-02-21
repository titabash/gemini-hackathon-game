import { pgEnum } from "drizzle-orm/pg-core";

// Enum: session_status - セッション状態
export const sessionStatusEnum = pgEnum("session_status", [
  "active",
  "completed",
  "abandoned",
]);

// Enum: gm_decision_type - AI GMの判断タイプ
export const gmDecisionTypeEnum = pgEnum("gm_decision_type", [
  "narrate",
  "choice",
  "roll",
  "clarify",
  "repair",
]);

// Enum: input_type - プレイヤーの入力タイプ
export const inputTypeEnum = pgEnum("input_type", [
  "start",
  "do",
  "say",
  "choice",
  "roll_result",
  "clarify_answer",
  "system",
]);

// Enum: objective_status - クエスト/目標の状態
export const objectiveStatusEnum = pgEnum("objective_status", [
  "active",
  "completed",
  "failed",
]);
