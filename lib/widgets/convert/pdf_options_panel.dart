import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/pdf_export_options.dart';

/// The page settings for a PDF export.
///
/// Choices that would have no effect are hidden rather than disabled: a
/// fit-to-photo page has no direction and no border to set, so those rows
/// simply do not appear.
class PdfOptionsPanel extends StatelessWidget {
  final PdfExportOptions options;
  final ValueChanged<PdfExportOptions> onChanged;

  const PdfOptionsPanel({
    super.key,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFixedPage = options.pageSize != PdfPageSize.fitImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Title(text: l10n.pdfPageSizeLabel),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _chip(
              label: l10n.pdfPageA4,
              selected: options.pageSize == PdfPageSize.a4,
              onSelected: () =>
                  onChanged(options.copyWith(pageSize: PdfPageSize.a4)),
            ),
            _chip(
              label: l10n.pdfPageLetter,
              selected: options.pageSize == PdfPageSize.letter,
              onSelected: () =>
                  onChanged(options.copyWith(pageSize: PdfPageSize.letter)),
            ),
            _chip(
              label: l10n.pdfPageFitImage,
              selected: options.pageSize == PdfPageSize.fitImage,
              onSelected: () =>
                  onChanged(options.copyWith(pageSize: PdfPageSize.fitImage)),
            ),
          ],
        ),

        if (isFixedPage) ...<Widget>[
          const SizedBox(height: 16),
          _Title(text: l10n.pdfOrientationLabel),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(
                label: l10n.pdfOrientationAuto,
                selected: options.orientation == PdfOrientation.auto,
                onSelected: () => onChanged(
                  options.copyWith(orientation: PdfOrientation.auto),
                ),
              ),
              _chip(
                label: l10n.pdfOrientationPortrait,
                selected: options.orientation == PdfOrientation.portrait,
                onSelected: () => onChanged(
                  options.copyWith(orientation: PdfOrientation.portrait),
                ),
              ),
              _chip(
                label: l10n.pdfOrientationLandscape,
                selected: options.orientation == PdfOrientation.landscape,
                onSelected: () => onChanged(
                  options.copyWith(orientation: PdfOrientation.landscape),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Title(text: l10n.pdfFitLabel),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(
                label: l10n.pdfFitContain,
                selected: options.fitMode == PdfFitMode.contain,
                onSelected: () =>
                    onChanged(options.copyWith(fitMode: PdfFitMode.contain)),
              ),
              _chip(
                label: l10n.pdfFitFill,
                selected: options.fitMode == PdfFitMode.fill,
                onSelected: () =>
                    onChanged(options.copyWith(fitMode: PdfFitMode.fill)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Title(text: l10n.pdfMarginLabel),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _marginChip(l10n.pdfMarginNone, AppConstants.pdfNoMarginPoints),
              _marginChip(
                l10n.pdfMarginSmall,
                AppConstants.pdfSmallMarginPoints,
              ),
              _marginChip(
                l10n.pdfMarginMedium,
                AppConstants.pdfMediumMarginPoints,
              ),
              _marginChip(
                l10n.pdfMarginLarge,
                AppConstants.pdfLargeMarginPoints,
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),
        _Title(text: l10n.pdfQualityLabel),
        Slider(
          value: options.effectiveQuality.toDouble(),
          min: AppConstants.convertMinQuality.toDouble(),
          max: AppConstants.convertMaxQuality.toDouble(),
          divisions:
              AppConstants.convertMaxQuality - AppConstants.convertMinQuality,
          label: '${options.effectiveQuality}',
          onChanged: (value) =>
              onChanged(options.copyWith(imageQuality: value.round())),
        ),
      ],
    );
  }

  Widget _marginChip(String label, double points) {
    return _chip(
      label: label,
      selected: options.marginPoints == points,
      onSelected: () => onChanged(options.copyWith(marginPoints: points)),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (isSelected) {
        if (isSelected) onSelected();
      },
    );
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
