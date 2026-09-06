import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/playback_state.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/video/playback_speed_service.dart';

/// The control bar under a playing clip.
///
/// Everything it shows comes from an immutable [PlaybackState], and every
/// button calls back out. It owns no player and no timers.
class VideoControlsBar extends ConsumerWidget {
  final PlaybackState state;

  final VoidCallback onTogglePlay;
  final VoidCallback onStepForward;
  final VoidCallback onStepBackward;
  final VoidCallback onSkipForward;
  final VoidCallback onSkipBackward;
  final VoidCallback onToggleLoop;
  final ValueChanged<double> onSpeedSelected;
  final ValueChanged<Duration> onSeek;

  const VideoControlsBar({
    super.key,
    required this.state,
    required this.onTogglePlay,
    required this.onStepForward,
    required this.onStepBackward,
    required this.onSkipForward,
    required this.onSkipBackward,
    required this.onToggleLoop,
    required this.onSpeedSelected,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final gestures = ref.watch(videoGestureServiceProvider);
    final speeds = ref.watch(playbackSpeedServiceProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    gestures.formatDuration(state.position),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: state.progress,
                      onChanged: state.isReady
                          ? (value) => onSeek(
                              gestures.positionForFraction(
                                fraction: value,
                                duration: state.duration,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Text(
                    gestures.formatDuration(state.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: state.isReady ? onStepBackward : null,
                    icon: const Icon(Icons.skip_previous_outlined),
                    color: Colors.white,
                    tooltip: l10n.frameBackward,
                  ),
                  IconButton(
                    onPressed: state.isReady ? onSkipBackward : null,
                    icon: const Icon(Icons.replay_10_outlined),
                    color: Colors.white,
                    tooltip: l10n.skipBackward,
                  ),
                  IconButton.filled(
                    onPressed: state.isReady ? onTogglePlay : null,
                    icon: Icon(
                      state.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    tooltip: state.isPlaying ? l10n.pause : l10n.play,
                  ),
                  IconButton(
                    onPressed: state.isReady ? onSkipForward : null,
                    icon: const Icon(Icons.forward_10_outlined),
                    color: Colors.white,
                    tooltip: l10n.skipForward,
                  ),
                  IconButton(
                    onPressed: state.isReady ? onStepForward : null,
                    icon: const Icon(Icons.skip_next_outlined),
                    color: Colors.white,
                    tooltip: l10n.frameForward,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: state.isReady ? onToggleLoop : null,
                    icon: Icon(
                      state.isLooping
                          ? Icons.repeat_one_outlined
                          : Icons.repeat_outlined,
                    ),
                    color: state.isLooping
                        ? Colors.lightBlueAccent
                        : Colors.white,
                    tooltip: l10n.loopPlayback,
                  ),
                  PopupMenuButton<double>(
                    enabled: state.isReady,
                    tooltip: l10n.playbackSpeed,
                    onSelected: onSpeedSelected,
                    itemBuilder: (context) => [
                      for (final speed in PlaybackSpeedService.speeds)
                        PopupMenuItem<double>(
                          value: speed,
                          child: Text(speeds.label(speed)),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.speed_outlined, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            speeds.label(state.speed),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
