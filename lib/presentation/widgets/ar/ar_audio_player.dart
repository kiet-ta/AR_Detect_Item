import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/utils/audio_player_helper.dart';
import '../common/big_button.dart';

/// Plays bilingual audio (English first, 500ms pause, Vietnamese).
/// Calls [AudioPlayerHelper.playBilingual] on tap.
class ARAudioPlayer extends StatefulWidget {
  const ARAudioPlayer({
    super.key,
    this.audioPathEn,
    this.audioPathVi,
  });

  final String? audioPathEn;
  final String? audioPathVi;

  @override
  State<ARAudioPlayer> createState() => _ARAudioPlayerState();
}

class _ARAudioPlayerState extends State<ARAudioPlayer> {
  bool _isPlaying = false;
  late final AudioPlayerHelper _helper;

  @override
  void initState() {
    super.initState();
    _helper = getIt<AudioPlayerHelper>();
  }

  Future<void> _onTap() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    await _helper.playBilingual(
      enPath: widget.audioPathEn,
      viPath: widget.audioPathVi,
    );
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return BigButton(
      icon: Icons.volume_up_rounded,
      onPressed: (widget.audioPathEn != null || widget.audioPathVi != null)
          ? _onTap
          : null,
      isLoading: _isPlaying,
      tooltip: 'Play pronunciation',
    );
  }
}
