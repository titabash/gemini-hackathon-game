import 'package:flutter/material.dart';

import '../../../features/game_menu/ui/saved_session_list.dart';

/// セーブデータ一覧ページ（ルートレベル）
class SavedSessionsPage extends StatelessWidget {
  const SavedSessionsPage({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  Widget build(BuildContext context) {
    return SavedSessionGrid(scenarioId: scenarioId);
  }
}
