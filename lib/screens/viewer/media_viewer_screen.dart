import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/viewer_transform.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_intent_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/interactive_image_view.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_picker_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/photo_selector_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/tags/media_tag_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/media_details_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/video_player_view.dart';

/// The fullscreen viewer, opened by tapping a tile in the timeline.
///
/// It pages through the same list the timeline showed, in the same order. Each
/// page is either an [InteractiveImageView] or a [VideoPlayerView]. This widget
/// only wires them together: zoom, rotation, dismiss, gestures, and playback
/// all live in the service and provider layers.
class MediaViewerScreen extends ConsumerStatefulWidget {
  /// Id of the item to open first.
  final String mediaId;

  const MediaViewerScreen({super.key, required this.mediaId});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  PageController? _pageController;

  /// Whether the app bar and video controls are on screen.
  bool _showChrome = true;

  /// Hides the chrome again a few seconds after it was shown.
  Timer? _chromeTimer;

  /// Zoom, rotation, and dismiss state of the page in view.
  ViewerTransform _transform = ViewerTransform.initial;

  /// Where the current dismiss drag started, and when it last moved.
  Offset? _dismissStart;
  Duration? _lastMoveTime;
  double _lastMoveDy = 0;
  double _dismissVelocity = 0;

  @override
  void dispose() {
    _chromeTimer?.cancel();
    _pageController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Builds the page controller once the item list is known.
  PageController _controllerFor(int initialPage) {
    final existing = _pageController;
    if (existing != null) return existing;

    final controller = PageController(initialPage: initialPage);
    _pageController = controller;
    // The rest of the viewer reads the page from the provider, so it is seeded
    // here rather than left at zero.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(viewerPageIndexProvider.notifier).state = initialPage;
      }
    });
    return controller;
  }

  void _toggleChrome([MediaItem? item]) {
    setState(() => _showChrome = !_showChrome);
    _applySystemUi();
    _restartChromeTimer(item);
  }

  /// Hides the status and navigation bars while the chrome is hidden.
  void _applySystemUi() {
    SystemChrome.setEnabledSystemUIMode(
      _showChrome ? SystemUiMode.edgeToEdge : SystemUiMode.immersive,
    );
  }

  /// Starts the auto-hide countdown for a playing video.
  ///
  /// Only videos auto-hide. On a photo the buttons stay until the user taps,
  /// because there is nothing playing to get in the way of.
  void _restartChromeTimer([MediaItem? item]) {
    _chromeTimer?.cancel();
    if (!_showChrome) return;

    // Only videos auto-hide. On a photo the buttons stay until the user taps.
    if (item != null && !item.isVideo) return;

    _chromeTimer = Timer(
      const Duration(milliseconds: AppConstants.viewerChromeHideDelayMs),
      () {
        if (!mounted) return;
        setState(() => _showChrome = false);
        _applySystemUi();
      },
    );
  }

  void _onPageChanged(int index, List<MediaItem> list) {
    ref.read(viewerPageIndexProvider.notifier).state = index;
    // A new page starts unzoomed and unrotated.
    setState(() => _transform = ViewerTransform.initial);
    if (index >= 0 && index < list.length) {
      _restartChromeTimer(list[index]);
    }
  }

  void _onScaleChanged(double scale) {
    if ((scale - _transform.scale).abs() < 0.001) return;
    setState(() => _transform = _transform.copyWith(scale: scale));
  }

  void _rotate({required bool clockwise}) {
    final service = ref.read(viewerTransformServiceProvider);
    final next = clockwise
        ? service.rotateRight(_transform.rotationDegrees)
        : service.rotateLeft(_transform.rotationDegrees);
    setState(() => _transform = _transform.copyWith(rotationDegrees: next));
  }

  Future<void> _toggleFavorite(MediaItem item) async {
    await ref.read(mediaRepositoryProvider).toggleFavorite(item.id);
    // Reload the list so the star in the app bar and the grid agree.
    ref.invalidate(mediaItemsProvider);
  }

  /// Moves this item into the trash with a confirmation and undo action.
  Future<void> _moveToTrash(MediaItem item) async {
    final l10n = AppLocalizations.of(context)!;

    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.viewerTrashConfirmTitle),
        content: Text(l10n.viewerTrashConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.vaultCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: Text(l10n.batchActionMoveToTrash),
          ),
        ],
      ),
    );
    if (agreed != true || !mounted) return;

    final repo = ref.read(mediaRepositoryProvider);
    await repo.setTrash(item.id, true);
    ref.invalidate(mediaItemsProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.viewerTrashSuccess),
        action: SnackBarAction(
          label: l10n.viewerTrashUndo,
          onPressed: () async {
            await repo.setTrash(item.id, false);
            ref.invalidate(mediaItemsProvider);
          },
        ),
      ),
    );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Moves this item into the private vault.
  ///
  /// The original is kept. Destroying a public file is a heavier decision than
  /// belongs on a single toolbar button, so the shred choice lives in the
  /// vault's own import sheet where it comes with its own confirmation.
  ///
  /// The vault has to be open first. Encrypting into a locked vault would put
  /// the photo somewhere the user cannot immediately check, so a locked vault
  /// sends them to the gate instead.
  Future<void> _moveToVault(MediaItem item) async {
    final l10n = AppLocalizations.of(context)!;

    if (!ref.read(vaultLockControllerProvider).isUnlocked) {
      await context.push(kRouteVault);
      if (!mounted) return;
      if (!ref.read(vaultLockControllerProvider).isUnlocked) return;
    }

    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vaultMoveToVault),
        content: Text(l10n.vaultImportKeepOriginalBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.vaultCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.vaultMoveToVault),
          ),
        ],
      ),
    );
    if (agreed != true || !mounted) return;

    await ref.read(vaultBatchControllerProvider.notifier).import(<MediaItem>[
      item,
    ], shredOriginals: false);
    if (!mounted) return;

    // The item is hidden from every media query now, so the list it was being
    // paged through has to be rebuilt before this screen tries to show it.
    ref.invalidate(mediaItemsProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.vaultImportDone(1))));
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _comparePhoto(MediaItem currentItem) async {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.read(timelineItemsProvider).valueOrNull ?? <MediaItem>[];
    final currentIndex = items.indexWhere((i) => i.id == currentItem.id);

    MediaItem? prevItem;
    MediaItem? nextItem;
    if (currentIndex > 0) {
      final candidate = items[currentIndex - 1];
      if (candidate.isImage) prevItem = candidate;
    }
    if (currentIndex >= 0 && currentIndex < items.length - 1) {
      final candidate = items[currentIndex + 1];
      if (candidate.isImage) nextItem = candidate;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.compare_arrows),
                    const SizedBox(width: 12),
                    Text(
                      l10n.comparePhotosTitle,
                      style: Theme.of(sheetContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (prevItem != null)
                ListTile(
                  leading: const Icon(Icons.arrow_back),
                  title: Text(l10n.compareWithPrevious),
                  subtitle: Text(prevItem.displayName),
                  onTap: () => Navigator.of(sheetContext).pop(prevItem!.id),
                ),
              if (nextItem != null)
                ListTile(
                  leading: const Icon(Icons.arrow_forward),
                  title: Text(l10n.compareWithNext),
                  subtitle: Text(nextItem.displayName),
                  onTap: () => Navigator.of(sheetContext).pop(nextItem!.id),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.compareChooseFromGallery),
                onTap: () => Navigator.of(sheetContext).pop('pick'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) return;

    if (choice == 'pick') {
      final picked = await PhotoSelectorSheet.show(
        context,
        excludeMediaId: currentItem.id,
      );
      if (picked != null && mounted) {
        context.push(photoComparePath(currentItem.id, picked.id));
      }
    } else {
      context.push(photoComparePath(currentItem.id, choice));
    }
  }

  // --- Swipe down to dismiss -------------------------------------------------
  //
  // Raw pointer events are used instead of a drag recognizer because the image
  // page already owns the gesture arena through `InteractiveViewer`. A pointer
  // listener sits outside that contest, so both keep working. Dismiss is only
  // offered on an unzoomed photo: on a video the same drag is the brightness,
  // volume, and seek gesture.

  bool _canDismiss(MediaItem item) => item.isImage && _transform.isAtRest;

  void _onPointerDown(PointerDownEvent event, MediaItem item) {
    if (!_canDismiss(item)) return;
    _dismissStart = event.position;
    _lastMoveTime = event.timeStamp;
    _lastMoveDy = event.position.dy;
    _dismissVelocity = 0;
  }

  void _onPointerMove(PointerMoveEvent event, MediaItem item) {
    final start = _dismissStart;
    if (start == null || !_canDismiss(item)) return;

    final dy = event.position.dy - start.dy;
    final dx = (event.position.dx - start.dx).abs();

    // A mostly sideways move is a page swipe, so the drag is handed back.
    if (dy <= 0 || dx > dy.abs()) {
      if (_transform.isDismissing) {
        setState(() => _transform = _transform.copyWith(dismissOffset: 0));
      }
      return;
    }

    final lastTime = _lastMoveTime;
    if (lastTime != null) {
      final elapsed = (event.timeStamp - lastTime).inMicroseconds / 1000000;
      if (elapsed > 0) {
        _dismissVelocity = (event.position.dy - _lastMoveDy) / elapsed;
      }
    }
    _lastMoveTime = event.timeStamp;
    _lastMoveDy = event.position.dy;

    setState(() => _transform = _transform.copyWith(dismissOffset: dy));
  }

  void _onPointerUp(PointerUpEvent event, MediaItem item) {
    final service = ref.read(viewerTransformServiceProvider);
    final shouldClose = service.shouldDismissOnRelease(
      dismissOffset: _transform.dismissOffset,
      velocityPixelsPerSecond: _dismissVelocity,
    );

    _dismissStart = null;
    _lastMoveTime = null;
    _dismissVelocity = 0;

    if (shouldClose && mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        SystemNavigator.pop();
      }
      return;
    }
    if (_transform.isDismissing) {
      setState(() => _transform = _transform.copyWith(dismissOffset: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final externalItem = ref.watch(externalMediaItemProvider(widget.mediaId));
    final singleItemAsync = ref.watch(mediaItemProvider(widget.mediaId));
    final singleItem = externalItem ?? singleItemAsync.valueOrNull;

    final items = ref.watch(timelineItemsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: items.when(
        loading: () {
          if (singleItem != null) {
            return _buildContent(context, <MediaItem>[singleItem], 0, l10n);
          }
          return const ColoredBox(
            color: Colors.black,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        error: (error, _) {
          if (singleItem != null) {
            return _buildContent(context, <MediaItem>[singleItem], 0, l10n);
          }
          return _ViewerMessageScreen(message: l10n.scanFailed);
        },
        data: (list) {
          final startIndex = list.indexWhere(
            (item) => item.id == widget.mediaId,
          );
          final displayList = startIndex >= 0
              ? list
              : (singleItem != null
                    ? <MediaItem>[singleItem]
                    : const <MediaItem>[]);

          if (displayList.isEmpty) {
            return _ViewerMessageScreen(message: l10n.mediaUnavailable);
          }

          final effectiveStartIndex = startIndex >= 0 ? startIndex : 0;
          return _buildContent(context, displayList, effectiveStartIndex, l10n);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<MediaItem> list,
    int initialIndex,
    AppLocalizations l10n,
  ) {
    final controller = _controllerFor(initialIndex);
    final currentIndex = ref
        .watch(viewerPageIndexProvider)
        .clamp(0, list.length - 1);
    final currentItem = list[currentIndex];

    final service = ref.watch(viewerTransformServiceProvider);
    final dismissOffset = _transform.dismissOffset;
    final isChromeVisible = _showChrome && !_transform.isDismissing;

    return ColoredBox(
      color: Colors.black.withValues(
        alpha: service.backdropOpacity(dismissOffset),
      ),
      child: Listener(
        onPointerDown: (event) => _onPointerDown(event, currentItem),
        onPointerMove: (event) => _onPointerMove(event, currentItem),
        onPointerUp: (event) => _onPointerUp(event, currentItem),
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, dismissOffset),
              child: Transform.scale(
                scale: service.dismissScale(dismissOffset),
                child: PageView.builder(
                  controller: controller,
                  onPageChanged: (index) => _onPageChanged(index, list),
                  // Paging is locked while the photo is zoomed in, so a
                  // pan never jumps to the next item.
                  physics: _transform.isAtRest
                      ? const PageScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    if (item.isVideo) {
                      return VideoPlayerView(
                        key: ValueKey<String>('video-${item.id}'),
                        item: item,
                        isActive: index == currentIndex,
                        showControls: _showChrome,
                        onTap: () => _toggleChrome(item),
                      );
                    }
                    return InteractiveImageView(
                      key: ValueKey<String>('image-${item.id}'),
                      item: item,
                      rotationDegrees: index == currentIndex
                          ? _transform.rotationDegrees
                          : 0,
                      onScaleChanged: _onScaleChanged,
                      onTap: () => _toggleChrome(item),
                    );
                  },
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              top: isChromeVisible ? 0 : -100,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isChromeVisible ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !isChromeVisible,
                  child: _ViewerAppBar(
                    item: currentItem,
                    onToggleFavorite: () => _toggleFavorite(currentItem),
                    onShowDetails: () =>
                        MediaDetailsSheet.show(context, currentItem),
                    onMoveToTrash: () => _moveToTrash(currentItem),
                    onEdit: () => context.push(imageEditorPath(currentItem.id)),
                    onCompare: () => _comparePhoto(currentItem),
                    onConvert: () =>
                        context.push(formatConverterPath(currentItem.id)),
                    onVideoTools: () =>
                        context.push(videoToolsPath(currentItem.id)),
                    onEditTags: () =>
                        MediaTagSheet.show(context, currentItem.id),
                    onAddToAlbum: () =>
                        AlbumPickerSheet.show(context, currentItem.id),
                    onMoveToVault: () => _moveToVault(currentItem),
                    onScanCodes: () =>
                        context.push(imageScanPath(currentItem.id)),
                    onExtractText: () =>
                        context.push(extractedTextPath(currentItem.id)),
                    onOpenNotes: () =>
                        context.push(mediaNotesPath(currentItem.id)),
                  ),
                ),
              ),
            ),
            if (currentItem.isImage)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                bottom: isChromeVisible ? 0 : -100,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isChromeVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !isChromeVisible,
                    child: _ImageViewerBottomBar(
                      item: currentItem,
                      onEdit: () =>
                          context.push(imageEditorPath(currentItem.id)),
                      onRotateLeft: () => _rotate(clockwise: false),
                      onRotateRight: () => _rotate(clockwise: true),
                      onShowDetails: () =>
                          MediaDetailsSheet.show(context, currentItem),
                      onMoveToTrash: () => _moveToTrash(currentItem),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The high-contrast bar across the top of the viewer.
class _ViewerAppBar extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShowDetails;
  final VoidCallback onMoveToTrash;
  final VoidCallback onEdit;
  final VoidCallback onCompare;
  final VoidCallback onConvert;
  final VoidCallback onVideoTools;
  final VoidCallback onEditTags;
  final VoidCallback onAddToAlbum;
  final VoidCallback onMoveToVault;
  final VoidCallback onScanCodes;
  final VoidCallback onExtractText;
  final VoidCallback onOpenNotes;

  const _ViewerAppBar({
    required this.item,
    required this.onToggleFavorite,
    required this.onShowDetails,
    required this.onMoveToTrash,
    required this.onEdit,
    required this.onCompare,
    required this.onConvert,
    required this.onVideoTools,
    required this.onEditTags,
    required this.onAddToAlbum,
    required this.onMoveToVault,
    required this.onScanCodes,
    required this.onExtractText,
    required this.onOpenNotes,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.black54, Colors.transparent],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
            child: Row(
              children: [
                _ViewerCircleButton(
                  icon: Icons.arrow_back,
                  tooltip: l10n.viewerClose,
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      SystemNavigator.pop();
                    }
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AdaptiveDirectionality(
                    text: item.displayName,
                    child: Text(
                      item.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 8),
                          Shadow(color: Colors.black, blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _ViewerCircleButton(
                  icon: item.isFavorite ? Icons.star : Icons.star_border,
                  color: item.isFavorite ? Colors.amber : Colors.white,
                  tooltip: item.isFavorite
                      ? l10n.viewerRemoveFavorite
                      : l10n.viewerAddFavorite,
                  onPressed: onToggleFavorite,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<_ViewerMenuAction>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    tooltip: l10n.viewerMoreActions,
                    onSelected: (action) {
                      switch (action) {
                        case _ViewerMenuAction.edit:
                          onEdit();
                        case _ViewerMenuAction.compare:
                          onCompare();
                        case _ViewerMenuAction.scanCodes:
                          onScanCodes();
                        case _ViewerMenuAction.extractText:
                          onExtractText();
                        case _ViewerMenuAction.notes:
                          onOpenNotes();
                        case _ViewerMenuAction.convert:
                          onConvert();
                        case _ViewerMenuAction.videoTools:
                          onVideoTools();
                        case _ViewerMenuAction.editTags:
                          onEditTags();
                        case _ViewerMenuAction.addToAlbum:
                          onAddToAlbum();
                        case _ViewerMenuAction.moveToVault:
                          onMoveToVault();
                        case _ViewerMenuAction.details:
                          onShowDetails();
                        case _ViewerMenuAction.trash:
                          onMoveToTrash();
                      }
                    },
                    itemBuilder: (context) =>
                        <PopupMenuEntry<_ViewerMenuAction>>[
                          if (item.isVideo)
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.videoTools,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.movie_filter_outlined,
                                ),
                                title: Text(l10n.videoToolsOpen),
                              ),
                            ),
                          PopupMenuItem<_ViewerMenuAction>(
                            value: _ViewerMenuAction.addToAlbum,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.photo_album_outlined),
                              title: Text(l10n.albumPickerTitle),
                            ),
                          ),
                          PopupMenuItem<_ViewerMenuAction>(
                            value: _ViewerMenuAction.editTags,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.label_outline),
                              title: Text(l10n.tagSheetOpen),
                            ),
                          ),
                          PopupMenuItem<_ViewerMenuAction>(
                            value: _ViewerMenuAction.moveToVault,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.lock_outline),
                              title: Text(l10n.vaultMoveToVault),
                            ),
                          ),
                          if (item
                              .isImage) ...<PopupMenuEntry<_ViewerMenuAction>>[
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.compare,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.compare_arrows),
                                title: Text(l10n.comparePhotosTitle),
                              ),
                            ),
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.convert,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.transform),
                                title: Text(l10n.convertOpen),
                              ),
                            ),
                          ],
                          if (item
                              .isImage) ...<PopupMenuEntry<_ViewerMenuAction>>[
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.scanCodes,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.qr_code_scanner_outlined,
                                ),
                                title: Text(l10n.codeScanOpen),
                              ),
                            ),
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.extractText,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.text_fields_outlined),
                                title: Text(l10n.ocrOpen),
                              ),
                            ),
                          ],
                          PopupMenuItem<_ViewerMenuAction>(
                            value: _ViewerMenuAction.notes,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.sticky_note_2_outlined),
                              title: Text(l10n.notesOpen),
                            ),
                          ),
                          if (item.isVideo) ...[
                            const PopupMenuDivider(),
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.details,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.info_outline),
                                title: Text(l10n.detailsTitle),
                              ),
                            ),
                            PopupMenuItem<_ViewerMenuAction>(
                              value: _ViewerMenuAction.trash,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.delete_outline),
                                title: Text(l10n.batchActionMoveToTrash),
                              ),
                            ),
                          ],
                        ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular button with high-contrast background for viewer chrome.
class _ViewerCircleButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ViewerCircleButton({
    required this.icon,
    this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Colors.black38,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color ?? Colors.white),
        tooltip: tooltip,
      ),
    );
  }
}

/// The bottom bar with quick action buttons for images.
class _ImageViewerBottomBar extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onEdit;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onShowDetails;
  final VoidCallback onMoveToTrash;

  const _ImageViewerBottomBar({
    required this.item,
    required this.onEdit,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onShowDetails,
    required this.onMoveToTrash,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.black54, Colors.transparent],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ViewerBottomAction(
                  icon: Icons.tune,
                  label: l10n.editorOpen,
                  onPressed: onEdit,
                ),
                _ViewerBottomAction(
                  icon: Icons.rotate_left,
                  label: l10n.viewerRotateLeft,
                  onPressed: onRotateLeft,
                ),
                _ViewerBottomAction(
                  icon: Icons.rotate_right,
                  label: l10n.viewerRotateRight,
                  onPressed: onRotateRight,
                ),
                _ViewerBottomAction(
                  icon: Icons.info_outline,
                  label: l10n.detailsTitle,
                  onPressed: onShowDetails,
                ),
                _ViewerBottomAction(
                  icon: Icons.delete_outline,
                  label: l10n.batchActionMoveToTrash,
                  onPressed: onMoveToTrash,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Action item in the image viewer bottom bar.
class _ViewerBottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ViewerBottomAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the viewer's overflow menu can do.
enum _ViewerMenuAction {
  edit,
  compare,
  scanCodes,
  extractText,
  notes,
  convert,
  videoTools,
  editTags,
  addToAlbum,
  moveToVault,
  details,
  trash,
}

/// Full-screen message used when the viewer has nothing to show.
class _ViewerMessageScreen extends StatelessWidget {
  final String message;

  const _ViewerMessageScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Colors.white70,
            ),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.viewerClose),
            ),
          ],
        ),
      ),
    );
  }
}
