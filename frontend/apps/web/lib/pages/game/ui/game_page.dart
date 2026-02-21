import 'package:core_game/core_game.dart';
import 'package:core_genui/core_genui.dart';
import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Game page that hosts both the Flame game canvas and a GenUI chat surface.
class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameInstanceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.game.title)),
      body: Column(
        children: [
          Expanded(flex: 2, child: GameContainer(game: game)),
          const Divider(height: 1),
          const Expanded(child: GenuiChatSurface()),
        ],
      ),
    );
  }
}
