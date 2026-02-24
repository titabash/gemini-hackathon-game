import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/game_menu/ui/game_menu_surface.dart';
import '../../../features/scenario_detail/api/fetch_scenario.dart';

/// ゲームメニューページ（ルートレベル）
class GameMenuPage extends ConsumerWidget {
  const GameMenuPage({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarioAsync = ref.watch(
      fetchScenarioProvider(scenarioId: scenarioId),
    );

    return scenarioAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                t.error.generic,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      data: (scenario) => GameMenuSurface(scenario: scenario),
    );
  }
}
