import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/features/trpg/model/bgm/pcm_stream_player.dart';

void main() {
  test('stub player accepts calls without throwing', () async {
    final player = newPcmStreamPlayer();

    await player.playChunk(Uint8List.fromList([0, 0, 0, 0]));
    player.setVolume(0.5);
    player.stop();
    player.dispose();
  });
}
