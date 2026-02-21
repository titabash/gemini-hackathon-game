import 'package:core_game/core_game.dart';
import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/trpg/model/trpg_session_provider.dart';
import '../../../features/trpg/ui/game/trpg_game.dart';
import '../../../features/trpg/ui/trpg_chat_surface.dart';

/// Game page that hosts both the Flame game canvas and a TRPG chat surface.
class GamePage extends HookConsumerWidget {
  const GamePage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(trpgSessionProvider);
    final game = useMemoized(() => TrpgGame(visualState: session.visualState));

    // Reset previous session state and start the new one.
    useEffect(() {
      session
        ..reset()
        ..initSession(sessionId);
      return null;
    }, [sessionId]);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
          tooltip: t.game.backToList,
        ),
        title: Text(t.game.title),
      ),
      body: Column(
        children: [
          Expanded(flex: 2, child: GameContainer(game: game)),
          const Divider(height: 1),
          Expanded(child: TrpgChatSurface(sessionId: sessionId)),
        ],
      ),
    );
  }
}
