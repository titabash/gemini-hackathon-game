import 'package:core_auth/core_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../entities/scenario/model/scenario.dart';

part 'fetch_scenario.g.dart';

/// 単一シナリオを取得するProvider（scenarioId パラメータ）
@riverpod
Future<Scenario> fetchScenario(Ref ref, {required String scenarioId}) async {
  final supabase = ref.read(supabaseClientProvider);
  final response = await supabase
      .from('scenarios')
      .select()
      .eq('id', scenarioId)
      .single();

  return Scenario.fromJson(response);
}
