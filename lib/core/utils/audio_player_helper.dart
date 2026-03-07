import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';

import 'logger.dart';

/// Manages bilingual audio playback for vocabulary words.
///
/// Plays English first, then Vietnamese after a short pause.
/// Registered as a singleton — one player instance reused across sessions.
@singleton
final class AudioPlayerHelper {
  AudioPlayerHelper() : _player = AudioPlayer();

  final AudioPlayer _player;

  /// Plays bilingual audio: [enPath] first, then [viPath] after [pauseMs]ms.
  /// Skips playback for any null path.
  Future<void> playBilingual({
    String? enPath,
    String? viPath,
    int pauseMs = 500,
  }) async {
    if (enPath != null) await playFile(enPath);
    await Future<void>.delayed(Duration(milliseconds: pauseMs));
    if (viPath != null) await playFile(viPath);
  }

  /// Plays a single audio file from an absolute local [path].
  Future<void> playFile(String path) async {
    try {
      await _player.setFilePath(path);
      await _player.play();
      await _player.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed);
    } on Exception catch (e) {
      AppLogger.w('AudioPlayerHelper: failed to play $path', e);
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
