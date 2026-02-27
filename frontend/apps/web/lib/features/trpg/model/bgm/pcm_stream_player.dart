import 'pcm_stream_player_interface.dart';
import 'pcm_stream_player_stub.dart'
    if (dart.library.js_interop) 'pcm_stream_player_web.dart';

export 'pcm_stream_player_interface.dart';

PcmStreamPlayer newPcmStreamPlayer() => createPcmStreamPlayer();
