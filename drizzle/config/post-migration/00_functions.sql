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
  -- 新規ユーザーのIDをgeneral_usersテーブルに挿入
  INSERT INTO public.general_users(id, account_name)
  VALUES (NEW.id, NEW.raw_user_meta_data ->> 'account_name');
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
