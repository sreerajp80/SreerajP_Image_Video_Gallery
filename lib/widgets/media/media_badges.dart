import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Smallest pixel edge at which a media item is marked as high resolution.
const int kHighResolutionMinEdge = 1080;

/// Formats [durationMs] as `m:ss`, or `h:mm:ss` once it passes an hour.
///
/// Returns null for a missing or non-positive duration, so the caller can skip
/// the badge instead of drawing "0:00" on a broken file.
String? formatMediaDuration(int? durationMs) {
  if (durationMs == null || durationMs <= 0) return null;

  final totalSeconds = durationMs ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  final paddedSeconds = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
  }
  return '$minutes:$paddedSeconds';
}

/// Whether [item] should carry the high resolution badge.
bool isHighResolution(MediaItem item) {
  final width = item.width;
  final height = item.height;
  if (width == null || height == null) return false;
  if (width <= 0 || height <= 0) return false;
  return (width < height ? width : height) >= kHighResolutionMinEdge;
}

/// Draws the badge overlay on top of a media tile.
///
/// Type chips (GIF, RAW, HD) sit in the top-left; a video duration pill sits in
/// the bottom-right. Every value is read straight off [MediaItem], so no extra
/// decoding or file access happens here.
class MediaBadges extends StatelessWidget {
  final MediaItem item;

  /// Scales the badges down on very small tiles.
  final bool compact;

  const MediaBadges({super.key, required this.item, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = formatMediaDuration(item.durationMs);

    final chips = <String>[
      if (item.mediaType == MediaType.gif) l10n.badgeGif,
      if (item.mediaType == MediaType.rawImage) l10n.badgeRaw,
      if (isHighResolution(item)) l10n.badgeHd,
    ];

    if (chips.isEmpty && duration == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(compact ? 2 : 4),
      child: Stack(
        children: [
          if (chips.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  for (final chip in chips)
                    _Badge(label: chip, compact: compact),
                ],
              ),
            ),
          if (duration != null)
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Semantics(
                label: l10n.badgeVideoDuration(duration),
                child: _Badge(
                  label: duration,
                  compact: compact,
                  icon: Icons.play_arrow_rounded,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single dark pill with light text, readable over any thumbnail.
class _Badge extends StatelessWidget {
  final String label;
  final bool compact;
  final IconData? icon;

  const _Badge({required this.label, required this.compact, this.icon});

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 8.0 : 10.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 3 : 5,
          vertical: compact ? 1 : 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 2, color: Colors.white),
              const SizedBox(width: 2),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
