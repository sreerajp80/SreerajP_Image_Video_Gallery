import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/video/video_clip_info.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/video_tools_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/video/frame_grab_panel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/video/gif_options_panel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/video/trim_range_bar.dart';
import 'package:path/path.dart' as p;

/// The three video tools, opened from the viewer.
///
/// Every tab writes a new file beside the clip and never touches the clip
/// itself. The trim is a stream copy, so it loses no quality; the frame grab
/// and the GIF read frames without changing anything.
class VideoToolsScreen extends ConsumerWidget {
  /// Id of the clip being worked on.
  final String mediaId;

  const VideoToolsScreen({super.key, required this.mediaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(timelineItemsProvider);

    return items.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => _MessageScaffold(message: l10n.scanFailed),
      data: (list) {
        final index = list.indexWhere((item) => item.id == mediaId);
        if (index < 0) {
          return _MessageScaffold(message: l10n.mediaUnavailable);
        }

        final item = list[index];
        if (!item.isVideo) {
          return _MessageScaffold(message: l10n.videoToolsUnavailable);
        }

        return _ClipLoader(item: item);
      },
    );
  }
}

/// Waits for the platform to describe the clip before showing the tabs.
class _ClipLoader extends ConsumerWidget {
  final MediaItem item;

  const _ClipLoader({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final info = ref.watch(videoClipInfoProvider(item));

    return info.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.videoToolsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _MessageScaffold(message: l10n.videoToolsUnavailable),
      data: (clip) {
        if (!clip.isUsable) {
          return _MessageScaffold(message: l10n.videoToolsUnavailable);
        }
        return _VideoToolsBody(item: item, clip: clip);
      },
    );
  }
}

/// The tabs themselves, once the clip is known to be readable.
class _VideoToolsBody extends ConsumerStatefulWidget {
  final MediaItem item;
  final VideoClipInfo clip;

  const _VideoToolsBody({required this.item, required this.clip});

  @override
  ConsumerState<_VideoToolsBody> createState() => _VideoToolsBodyState();
}

class _VideoToolsBodyState extends ConsumerState<_VideoToolsBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  /// The last frame that loaded, kept so dragging the scrubber does not flash
  /// an empty box between frames.
  Uint8List? _lastFrame;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = widget.clip.durationMs;
    final jobState = ref.watch(videoToolsControllerProvider);
    final progress = ref.watch(gifExportProgressProvider);

    _listenForResult();

    final isBusy = jobState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.videoToolsTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: <Widget>[
            Tab(text: l10n.videoTabFrame),
            Tab(text: l10n.videoTabGif),
            Tab(text: l10n.videoTabTrim),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          if (progress != null)
            LinearProgressIndicator(
              value: progress.total == 0 ? null : progress.fraction,
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: <Widget>[
                _buildFrameTab(duration),
                _buildGifTab(duration),
                _buildTrimTab(duration),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAction(l10n, duration, isBusy),
    );
  }

  // ------------------------------------------------------------ frame tab

  Widget _buildFrameTab(int duration) {
    final position = ref.watch(framePositionProvider);
    final format = ref.watch(frameFormatProvider);
    final frame = ref.watch(
      framePreviewProvider(
        FramePreviewRequest(path: widget.item.path, positionMs: position),
      ),
    );

    frame.whenData((bytes) {
      if (bytes != null) _lastFrame = bytes;
    });

    return FrameGrabPanel(
      frameBytes: _lastFrame,
      positionMs: position,
      clipDurationMs: duration,
      isLoading: frame.isLoading,
      format: format,
      onPositionChanged: (value) =>
          ref.read(framePositionProvider.notifier).state = value,
      onFormatChanged: (value) =>
          ref.read(frameFormatProvider.notifier).state = value,
    );
  }

  // -------------------------------------------------------------- gif tab

  Widget _buildGifTab(int duration) {
    final options = ref.watch(gifOptionsProvider(duration));
    final notifier = ref.read(gifOptionsProvider(duration).notifier);
    final planner = ref.watch(gifFramePlannerProvider);

    return GifOptionsPanel(
      options: options,
      clipDurationMs: duration,
      frameCount: planner.frameCount(
        options: options,
        clipDurationMs: duration,
      ),
      isCapped: planner.isCapped(options: options, clipDurationMs: duration),
      onFrameRateChanged: notifier.setFrameRate,
      onMaxSideChanged: notifier.setMaxSide,
      onLoopChanged: notifier.setLoop,
      onRangeChanged: notifier.setRange,
    );
  }

  // ------------------------------------------------------------- trim tab

  Widget _buildTrimTab(int duration) {
    final l10n = AppLocalizations.of(context)!;
    final range = ref.watch(trimRangeProvider(duration));
    final notifier = ref.read(trimRangeProvider(duration).notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: <Widget>[
        TrimRangeBar(
          range: range,
          clipDurationMs: duration,
          onStartChanged: notifier.setStart,
          onEndChanged: notifier.setEnd,
        ),
        const SizedBox(height: 20),
        if (!range.isValid)
          Text(
            l10n.trimTooShort,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        const SizedBox(height: 12),
        Text(
          l10n.trimLosslessNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // --------------------------------------------------------------- action

  Widget _buildAction(AppLocalizations l10n, int duration, bool isBusy) {
    final controller = ref.read(videoToolsControllerProvider.notifier);

    switch (_tabs.index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: isBusy
              ? null
              : () => controller.saveFrame(
                  sourcePath: widget.item.path,
                  positionMs: ref.read(framePositionProvider),
                  format: ref.read(frameFormatProvider),
                ),
          icon: const Icon(Icons.photo_camera_back_outlined),
          label: Text(isBusy ? l10n.videoWorking : l10n.frameSaveAction),
        );

      case 1:
        return FloatingActionButton.extended(
          onPressed: isBusy
              ? null
              : () => controller.exportGif(
                  sourcePath: widget.item.path,
                  options: ref.read(gifOptionsProvider(duration)),
                  clipDurationMs: duration,
                ),
          icon: const Icon(Icons.gif_box_outlined),
          label: Text(isBusy ? l10n.gifExporting : l10n.gifExportAction),
        );

      default:
        final range = ref.watch(trimRangeProvider(duration));
        return FloatingActionButton.extended(
          onPressed: isBusy || !range.isValid
              ? null
              : () => controller.trim(
                  sourcePath: widget.item.path,
                  range: range,
                  clipDurationMs: duration,
                ),
          icon: const Icon(Icons.content_cut_rounded),
          label: Text(isBusy ? l10n.videoWorking : l10n.trimAction),
        );
    }
  }

  /// Turns a finished job into a message, once per job.
  void _listenForResult() {
    ref.listen<AsyncValue<VideoJobOutcome?>>(videoToolsControllerProvider, (
      previous,
      next,
    ) {
      final l10n = AppLocalizations.of(context)!;
      final messenger = ScaffoldMessenger.of(context);

      next.whenOrNull(
        data: (outcome) {
          if (outcome == null) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.videoJobSavedAs(p.basename(outcome.path))),
            ),
          );
          ref.read(videoToolsControllerProvider.notifier).clear();
        },
        error: (_, _) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.videoJobFailed)));
          ref.read(videoToolsControllerProvider.notifier).clear();
        },
      );
    });
  }
}

class _MessageScaffold extends StatelessWidget {
  final String message;

  const _MessageScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.videoToolsTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
