import 'package:core_auth/core_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../entities/scenario/model/scenario.dart';

part 'fetch_scenarios.g.dart';

/// 公開シナリオ一覧を取得するProvider
@riverpod
class FetchScenarios extends _$FetchScenarios {
  @override
  Future<List<Scenario>> build() async {
    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase
        .from('scenarios')
        .select()
        .eq('is_public', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Scenario.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// プルダウンリフレッシュ
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
