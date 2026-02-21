-- =============================================
-- Post-Migration SQL: Functions & Triggers
-- =============================================
-- このファイルはマイグレーション適用後に実行されます。
-- 関数やトリガーなどのカスタムSQLを定義します。
-- =============================================

-- Auth Hook関数: 新規ユーザー作成時の処理
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 新規ユーザーのIDをusersテーブルに挿入
  -- 仮のaccount_nameをUUID由来で自動生成（オンボーディングで正式名を設定）
  INSERT INTO public.users(id, account_name)
  VALUES (NEW.id, 'user_' || LEFT(REPLACE(NEW.id::text, '-', ''), 8));
  RETURN NEW;
END;
$$;

-- Auth Hookトリガー
-- auth.usersテーブルに新規レコードが挿入された後にhandle_new_user関数を実行
DROP TRIGGER IF EXISTS auth_hook ON auth.users;
CREATE TRIGGER auth_hook
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION handle_new_user();

-- =============================================
-- updated_at 自動更新関数
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- =============================================
-- updated_at 自動更新トリガー
-- updated_atカラムを持つ全テーブルに適用
-- =============================================

-- users
DROP TRIGGER IF EXISTS trigger_update_users_updated_at ON public.users;
CREATE TRIGGER trigger_update_users_updated_at
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- scenarios
DROP TRIGGER IF EXISTS trigger_update_scenarios_updated_at ON public.scenarios;
CREATE TRIGGER trigger_update_scenarios_updated_at
BEFORE UPDATE ON public.scenarios
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- sessions
DROP TRIGGER IF EXISTS trigger_update_sessions_updated_at ON public.sessions;
CREATE TRIGGER trigger_update_sessions_updated_at
BEFORE UPDATE ON public.sessions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- player_characters
DROP TRIGGER IF EXISTS trigger_update_player_characters_updated_at ON public.player_characters;
CREATE TRIGGER trigger_update_player_characters_updated_at
BEFORE UPDATE ON public.player_characters
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- npcs
DROP TRIGGER IF EXISTS trigger_update_npcs_updated_at ON public.npcs;
CREATE TRIGGER trigger_update_npcs_updated_at
BEFORE UPDATE ON public.npcs
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- npc_relationships
DROP TRIGGER IF EXISTS trigger_update_npc_relationships_updated_at ON public.npc_relationships;
CREATE TRIGGER trigger_update_npc_relationships_updated_at
BEFORE UPDATE ON public.npc_relationships
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- context_summaries
DROP TRIGGER IF EXISTS trigger_update_context_summaries_updated_at ON public.context_summaries;
CREATE TRIGGER trigger_update_context_summaries_updated_at
BEFORE UPDATE ON public.context_summaries
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- objectives
DROP TRIGGER IF EXISTS trigger_update_objectives_updated_at ON public.objectives;
CREATE TRIGGER trigger_update_objectives_updated_at
BEFORE UPDATE ON public.objectives
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- items
DROP TRIGGER IF EXISTS trigger_update_items_updated_at ON public.items;
CREATE TRIGGER trigger_update_items_updated_at
BEFORE UPDATE ON public.items
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
