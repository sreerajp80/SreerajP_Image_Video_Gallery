import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/viewer_transform.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_intent_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/trash_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/interactive_image_view.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_picker_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/delete_choice_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/compare/photo_selector_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/tags/media_tag_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/media_details_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/viewer_app_bar.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/viewer_bottom_bar.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/viewer_dialogs.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/video_player_view.dart';
import 'package:in_sreerajp_imgvidgal/widgets/privacy/media_privacy_sheet.dart';

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

  /// Id of the item in view.
  ///
  /// The page index alone is not enough: when the list is rebuilt (after a
  /// star tap, a scan, or a trash undo) the same index can point at another
  /// item. The viewer follows this id and moves the page back to it.
  String? _currentItemId;

  /// Whether the app bar and video controls are on screen.
  bool _showChrome = true;

  /// Hides the chrome again a few seconds after it was shown.
  Timer? _chromeTimer;

  /// Zoom, rotation, and dismiss state of the page in view.
  ViewerTransform _transform = ViewerTransform.initial;

  /// How many fingers are currently touching the screen.
  ///
  /// Dismiss is only allowed with exactly one pointer. A second finger means
  /// the user is pinching to zoom, not swiping to close.
  int _activePointers = 0;

  /// Whether two or more fingers are touching the screen.
  ///
  /// PageView navigation is disabled while multi-touch is active, so two-finger
  /// swipes or pinch gestures never navigate to adjacent items. Only single-finger
  /// horizontal swipes change pages.
  bool _isMultiTouch = false;

  /// Where the current dismiss drag started, and when it last moved.
  Offset? _dismissStart;
  Duration? _lastMoveTime;
  double _lastMoveDy = 0;
  double _dismissVelocity = 0;

  @override
  void initState() {
    super.initState();
    // A snackbar left over from the last screen (for example "Moved to
    // trash · Undo") would sit right over the bottom bar's Delete button,
    // so a tap meant for Delete could press Undo instead. Clear it first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    });
  }

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
    setState(() {
      _transform = ViewerTransform.initial;
      if (index >= 0 && index < list.length) _currentItemId = list[index].id;
    });
    if (index >= 0 && index < list.length) {
      _restartChromeTimer(list[index]);
    }
  }

  /// Moves the page and the stored index to [index] after this frame, if
  /// either one is somewhere else.
  ///
  /// It runs after the frame because a page jump and a provider write are not
  /// allowed while the widget tree is being built.
  void _syncPageTo(int index) {
    bool isOff() {
      final controller = _pageController;
      final pageOff =
          controller != null &&
          controller.hasClients &&
          controller.page?.round() != index;
      return pageOff || ref.read(viewerPageIndexProvider) != index;
    }

    if (!isOff()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !isOff()) return;
      final controller = _pageController;
      if (controller != null &&
          controller.hasClients &&
          controller.page?.round() != index) {
        controller.jumpToPage(index);
      }
      ref.read(viewerPageIndexProvider.notifier).state = index;
    });
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
    setState(
      () => _transform = _transform.copyWith(rotationDegrees: next, scale: 1.0),
    );
  }

  Future<void> _toggleFavorite(MediaItem item) async {
    await ref.read(viewerActionsProvider).toggleFavorite(item.id);
  }

  /// Asks how to delete this item: to the trash, or for good.
  Future<void> _delete(MediaItem item) async {
    final choice = await showDeleteChoiceSheet(
      context,
      count: 1,
      secureDelete: ref.read(appSettingsProvider).secureDelete,
    );
    if (!mounted) return;
    switch (choice) {
      case DeleteChoice.trash:
        await _moveToTrash(item);
      case DeleteChoice.permanent:
        await _deletePermanently(item);
      case null:
        break;
    }
  }

  /// Moves this item into the trash with an undo action.
  ///
  /// No extra confirmation: picking "Move to trash" in the choice sheet was
  /// the deliberate step, and the snackbar can undo it.
  Future<void> _moveToTrash(MediaItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final actions = ref.read(viewerActionsProvider);
    await actions.moveToTrash(item.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.bodyViewerTrashSuccess),
        // A snackbar with an action stays until tapped unless told
        // otherwise. This one hides after the usual few seconds; the trash
        // screen can still restore the item after that.
        persist: false,
        action: SnackBarAction(
          label: l10n.actionViewerTrashUndo,
          onPressed: () => actions.restoreFromTrash(item.id),
        ),
      ),
    );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Restores a trashed item back to the main library.
  Future<void> _restoreFromTrash(MediaItem item) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(trashControllerProvider.notifier).restoreItem(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.bodyTrashRestoredSnackbar)));
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Permanently removes this item from device storage and the gallery,
  /// written over first when Secure delete is on.
  Future<void> _deletePermanently(MediaItem item) async {
    final l10n = AppLocalizations.of(context)!;
    // Android's own prompt, when it shows one, is the confirmation.
    final mustConfirm = await appMustConfirmPermanentDelete(ref);
    if (!mounted) return;
    if (mustConfirm) {
      final confirmed = await confirmViewerDeletePermanently(context);
      if (!confirmed || !mounted) return;
    }

    final result = await ref
        .read(viewerActionsProvider)
        .deletePermanently(item);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(deleteResultMessage(l10n, result))));
    if (result.anyDeleted && Navigator.of(context).canPop()) {
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

    final agreed = await confirmViewerMoveToVault(context);
    if (!agreed || !mounted) return;

    await ref.read(vaultBatchControllerProvider.notifier).import(<MediaItem>[
      item,
    ], shredOriginals: false);
    if (!mounted) return;

    // The item is hidden from every media query now, so the list it was being
    // paged through has to be rebuilt before this screen tries to show it.
    ref.invalidate(mediaItemsProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.bodyVaultImportDone(1))));
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _comparePhoto(MediaItem currentItem) async {
    final items = ref.read(timelineItemsProvider).value ?? <MediaItem>[];
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

    final choice = await showCompareChoiceSheet(
      context,
      prevItem: prevItem,
      nextItem: nextItem,
    );

    if (!mounted || choice == null) return;

    if (choice == compareChoicePick) {
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
    _activePointers++;

    // Two or more fingers touching: multi-touch gesture (pinch zoom or 2-finger touch).
    // Disable PageView scrolling immediately so horizontal pinch or two-finger
    // swipes never scroll to the next image.
    if (_activePointers >= 2) {
      if (!_isMultiTouch) {
        setState(() {
          _isMultiTouch = true;
          if (_transform.isDismissing) {
            _transform = _transform.copyWith(dismissOffset: 0);
          }
        });
      }
      _dismissStart = null;
      return;
    }

    if (!_canDismiss(item)) return;
    _dismissStart = event.position;
    _lastMoveTime = event.timeStamp;
    _lastMoveDy = event.position.dy;
    _dismissVelocity = 0;
  }

  void _onPointerMove(PointerMoveEvent event, MediaItem item) {
    // More than one finger on the screen means a pinch-to-zoom, not a dismiss.
    if (_activePointers >= 2) return;

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
    _activePointers = (_activePointers - 1).clamp(0, 99);
    if (_activePointers == 0 && _isMultiTouch) {
      setState(() => _isMultiTouch = false);
    }

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

  void _onPointerCancel(PointerCancelEvent event, MediaItem item) {
    _activePointers = (_activePointers - 1).clamp(0, 99);
    if (_activePointers == 0 && _isMultiTouch) {
      setState(() => _isMultiTouch = false);
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
    final singleItem = externalItem ?? singleItemAsync.value;

    final items = ref.watch(timelineItemsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: items.when(
        // A reload (for example after a star tap) keeps the old list on screen.
        // Dropping to the one-item fallback here would move the page to 0
        // without telling the rest of the viewer, so the picture and the title
        // would show different items.
        skipLoadingOnReload: true,
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
          return _ViewerMessageScreen(message: l10n.errorScanFailed);
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
            return _ViewerMessageScreen(message: l10n.labelMediaUnavailable);
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
    _currentItemId ??= list[initialIndex.clamp(0, list.length - 1)].id;

    // Follow the item by id. If the list changed under it, its index may have
    // moved, so the page is moved to match.
    final trackedIndex = list.indexWhere((item) => item.id == _currentItemId);
    final storedIndex = ref.watch(viewerPageIndexProvider);
    final currentIndex = (trackedIndex >= 0 ? trackedIndex : storedIndex).clamp(
      0,
      list.length - 1,
    );
    final currentItem = list[currentIndex];
    if (trackedIndex >= 0) {
      _syncPageTo(trackedIndex);
    } else {
      // The item left the list. Follow whatever now sits at this page.
      _currentItemId = currentItem.id;
    }

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
        onPointerCancel: (event) => _onPointerCancel(event, currentItem),
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, dismissOffset),
              child: Transform.scale(
                scale: service.dismissScale(dismissOffset),
                child: PageView.builder(
                  controller: controller,
                  onPageChanged: (index) => _onPageChanged(index, list),
                  // Paging is locked while the photo is zoomed in or during multi-touch
                  // gestures, so pinch-to-zoom and two-finger swipes never jump to the next item.
                  physics: (_transform.isAtRest && !_isMultiTouch)
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
                      onInteractionStart: () {
                        if (!_isMultiTouch) {
                          setState(() => _isMultiTouch = true);
                        }
                      },
                      onInteractionEnd: () {
                        if (_activePointers == 0 && _isMultiTouch) {
                          setState(() => _isMultiTouch = false);
                        }
                      },
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
                  child: ViewerAppBar(
                    item: currentItem,
                    onToggleFavorite: () => _toggleFavorite(currentItem),
                    onShowDetails: () =>
                        MediaDetailsSheet.show(context, currentItem),
                    onDelete: () => _delete(currentItem),
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
                    onPrivacyScrubber: () =>
                        MediaPrivacySheet.show(context, currentItem),
                  ),
                ),
              ),
            ),
            if (currentItem.isImage || currentItem.isTrash)
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
                    child: ImageViewerBottomBar(
                      item: currentItem,
                      onEdit: () =>
                          context.push(imageEditorPath(currentItem.id)),
                      onRotateLeft: () => _rotate(clockwise: false),
                      onRotateRight: () => _rotate(clockwise: true),
                      onShowDetails: () =>
                          MediaDetailsSheet.show(context, currentItem),
                      onDelete: () => _delete(currentItem),
                      onRestore: () => _restoreFromTrash(currentItem),
                      onDeletePermanently: () =>
                          _deletePermanently(currentItem),
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
              child: Text(l10n.tooltipViewerClose),
            ),
          ],
        ),
      ),
    );
  }
}
