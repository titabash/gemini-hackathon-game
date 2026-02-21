import 'package:core_i18n/generated/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/trpg/model/trpg_session_provider.dart';
import '../../../features/trpg/ui/game/trpg_game.dart';
import '../../../features/trpg/ui/novel/novel_game_surface.dart';

/// Full-screen novel-game page hosting the Flame canvas and UI overlays.
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: t.game.backToList,
        ),
      ),
      body: NovelGameSurface(sessionId: sessionId, game: game),
    );
  }
}
