import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

part 'supabase_client_provider.g.dart';

/// Supabaseクライアントを提供するProvider
///
/// アプリ全体で共有されるSupabaseクライアントインスタンス
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

/// GoTrueClient（認証専用クライアント）を提供するProvider
@Riverpod(keepAlive: true)
GoTrueClient authClient(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth;
}

/// AuthServiceを提供するProvider
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  final authClient = ref.watch(authClientProvider);
  return AuthService(authClient);
}
