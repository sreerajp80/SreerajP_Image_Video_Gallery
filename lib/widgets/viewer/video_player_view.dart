import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/playback_state.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/device/screen_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_gesture_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/gesture_hud.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/video_controls_bar.dart';
import 'package:video_player/video_player.dart';

/// One video page of the fullscreen viewer.
///
/// The clip itself is driven by `VideoPlaybackController` through Riverpod, so
/// this widget only draws the surface, reads gestures, and forwards them. The
/// meaning of a gesture is decided by `VideoGestureService`, never here.
class VideoPlayerView extends ConsumerStatefulWidget {
  final MediaItem item;

  /// Whether this page is the one the user is looking at.
  ///
  /// A page that scrolls out of view pauses itself, so swiping away from a
  /// clip never leaves audio playing behind.
  final bool isActive;

  /// Whether the viewer chrome (app bar and controls) is visible.
  final bool showControls;

  /// Called on a single tap, which shows or hides the chrome.
  final VoidCallback onTap;

  const VideoPlayerView({
    super.key,
    required this.item,
    required this.isActive,
    required this.showControls,
    required this.onTap,
  });

  @override
  ConsumerState<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends ConsumerState<VideoPlayerView> {
  /// What the active drag is doing, or none when no drag is running.
  VideoGestureKind _gestureKind = VideoGestureKind.none;

  /// Where the current drag started, used to pick brightness or volume.
  Offset _dragStart = Offset.zero;

  /// Brightness or volume being changed, shown by the HUD.
  double _gestureLevel = 0;

  /// Seek target while a horizontal drag is running.
  Duration _seekTarget = Duration.zero;

  /// Held in a field because `dispose` may no longer read providers.
  late final ScreenSettingsService _screenSettings;

  @override
  void initState() {
    super.initState();
    _screenSettings = ref.read(screenSettingsServiceProvider);
    // The provider is read after the first frame so the notifier exists before
    // anything asks it to load.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void didUpdateWidget(VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _notifier.pause();
      _screenSettings.setKeepScreenOn(false);
    }
  }

  @override
  void dispose() {
    // The screen may sleep again as soon as this clip goes away.
    _screenSettings.setKeepScreenOn(false);
    super.dispose();
  }

  VideoPlaybackController get _notifier =>
      ref.read(videoPlaybackControllerProvider(widget.item).notifier);

  Future<void> _initialize() async {
    if (!mounted) return;
    await _notifier.initialize(autoPlay: widget.isActive);
    if (!mounted) return;
    await _screenSettings.setKeepScreenOn(true);
  }

  void _onDragStart(DragStartDetails details) {
    _dragStart = details.localPosition;
    _gestureKind = VideoGestureKind.none;
  }

  Future<void> _onDragUpdate(DragUpdateDetails details) async {
    final size = context.size;
    if (size == null) return;

    final gestures = ref.read(videoGestureServiceProvider);
    final settings = _screenSettings;
    final state = ref.read(videoPlaybackControllerProvider(widget.item));

    // The first movement decides what the whole drag does, so the gesture does
    // not flip between seeking and volume halfway through.
    if (_gestureKind == VideoGestureKind.none) {
      final kind = gestures.classify(
        startPosition: _dragStart,
        delta: details.delta,
        surfaceSize: size,
      );
      if (kind == VideoGestureKind.none) return;

      _gestureKind = kind;
      switch (kind) {
        case VideoGestureKind.brightness:
          _gestureLevel = await settings.getBrightness();
        case VideoGestureKind.volume:
          _gestureLevel = state.volume;
        case VideoGestureKind.seek:
          _seekTarget = state.position;
        case VideoGestureKind.none:
          return;
      }
      if (!mounted) return;
    }

    switch (_gestureKind) {
      case VideoGestureKind.brightness:
        final next = gestures.applyLevelDrag(
          currentLevel: _gestureLevel,
          deltaY: details.delta.dy,
        );
        await settings.setBrightness(next);
        if (mounted) setState(() => _gestureLevel = next);
      case VideoGestureKind.volume:
        final next = gestures.applyLevelDrag(
          currentLevel: _gestureLevel,
          deltaY: details.delta.dy,
        );
        await _notifier.setVolume(next);
        if (mounted) setState(() => _gestureLevel = next);
      case VideoGestureKind.seek:
        final next = gestures.applySeekDrag(
          position: _seekTarget,
          duration: state.duration,
          deltaX: details.delta.dx,
        );
        if (mounted) setState(() => _seekTarget = next);
      case VideoGestureKind.none:
        return;
    }
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_gestureKind == VideoGestureKind.seek) {
      await _notifier.seekTo(_seekTarget);
    }
    if (mounted) setState(() => _gestureKind = VideoGestureKind.none);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(videoPlaybackControllerProvider(widget.item));
    final controller = ref
        .watch(videoPlaybackControllerProvider(widget.item).notifier)
        .controller;
    final frameStep = ref.watch(frameStepServiceProvider);
    final gestures = ref.watch(videoGestureServiceProvider);

    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: _surface(state, controller, l10n)),

            if (state.isBuffering && !state.hasError)
              const Center(child: CircularProgressIndicator()),

            GestureHud(
              kind: _gestureKind,
              level: _gestureLevel,
              seekLabel:
                  '${gestures.formatDuration(_seekTarget)} / '
                  '${gestures.formatDuration(state.duration)}',
            ),

            if (widget.showControls && !state.hasError)
              Align(
                alignment: Alignment.bottomCenter,
                child: VideoControlsBar(
                  state: state,
                  onTogglePlay: _notifier.togglePlay,
                  onStepForward: _notifier.stepForward,
                  onStepBackward: _notifier.stepBackward,
                  onSkipForward: () => _notifier.seekTo(
                    frameStep.skipForward(
                      position: state.position,
                      duration: state.duration,
                    ),
                  ),
                  onSkipBackward: () => _notifier.seekTo(
                    frameStep.skipBackward(
                      position: state.position,
                      duration: state.duration,
                    ),
                  ),
                  onToggleLoop: _notifier.toggleLooping,
                  onSpeedSelected: _notifier.setSpeed,
                  onSeek: _notifier.seekTo,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The video surface, a loading spinner, or a friendly failure message.
  Widget _surface(
    PlaybackState state,
    VideoPlayerController? controller,
    AppLocalizations l10n,
  ) {
    if (state.hasError) {
      return _PlaybackErrorMessage(
        message: state.error == PlaybackError.unsupportedFormat
            ? l10n.videoFormatUnsupported
            : l10n.videoCannotPlay,
      );
    }

    if (!state.isInitialized || controller == null) {
      return const CircularProgressIndicator();
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );
  }
}

/// Message shown when a clip cannot be played at all.
class _PlaybackErrorMessage extends StatelessWidget {
  final String message;

  const _PlaybackErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.videocam_off_outlined,
          size: 48,
          color: Colors.white70,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
