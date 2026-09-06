import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_group.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/media_details_sheet.dart';

/// One duplicate group in the cleaner list.
class DuplicateGroupCard extends StatelessWidget {
  /// The group to show.
  final DuplicateGroup group;

  /// Opens the side-by-side comparison.
  final VoidCallback onCompare;

  /// Side of each preview thumbnail.
  static const double previewSize = 84;

  const DuplicateGroupCard({
    super.key,
    required this.group,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isExact = group.kind == DuplicateGroupKind.exact;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: InkWell(
        onTap: onCompare,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    isExact ? Icons.content_copy : Icons.auto_awesome_motion,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExact ? l10n.cleanerKindExact : l10n.cleanerKindSimilar,
                    style: theme.textTheme.labelLarge,
                  ),
                  const Spacer(),
                  Text(
                    l10n.cleanerMemberCount(group.memberCount),
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: previewSize,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: group.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) => MediaThumbnail(
                    item: group.items[index],
                    size: previewSize,
                    borderRadius: 8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.cleanerReclaimable(
                        formatFileSize(group.reclaimableBytes),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: onCompare,
                    child: Text(l10n.cleanerCompare),
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
