import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';

/// The grid of photos a PDF export can be built from.
///
/// The tick shows the page number rather than a plain mark, because the
/// order photos are picked in is the order they appear in the document, and
/// that is not otherwise visible.
class PdfImagePickerGrid extends StatelessWidget {
  /// Photos offered, newest first.
  final List<MediaItem> items;

  /// Ids already picked, in page order.
  final List<String> selectedIds;

  final ValueChanged<MediaItem> onToggle;

  const PdfImagePickerGrid({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final page = selectedIds.indexOf(item.id);
        final isSelected = page >= 0;

        return GestureDetector(
          onTap: () => onToggle(item),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              MediaThumbnail(item: item, size: double.infinity),
              if (isSelected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.primary, width: 3),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected
                      ? colorScheme.primary
                      : colorScheme.surface.withValues(alpha: 0.7),
                  child: isSelected
                      ? Text(
                          '${page + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.circle_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
