import 'package:supabase_flutter/supabase_flutter.dart';

/// アカウント名の重複チェック
/// 使用可能な場合は true、既に使用されている場合は false を返す
Future<bool> checkAccountNameAvailability({
  required SupabaseClient supabase,
  required String accountName,
}) async {
  final data = await supabase
      .from('users')
      .select('id')
      .eq('account_name', accountName)
      .maybeSingle();

  return data == null;
}
