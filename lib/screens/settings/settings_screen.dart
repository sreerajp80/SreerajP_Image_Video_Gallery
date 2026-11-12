import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_flavor_config.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';

/// Hub screen displaying each settings category as a tappable card.
///
/// Tapping a card navigates to the dedicated settings sub-screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final flavor = AppFlavorConfig.current;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleSettings),
        actions: <Widget>[if (flavor.isDev) const _DevFlavorBadge()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: <Widget>[
            _SettingsCategoryCard(
              icon: Icons.palette_outlined,
              title: l10n.titleSettingsAppearance,
              subtitle: l10n.descSettingsAppearanceSubtitle,
              onTap: () => context.push(kRouteSettingsAppearance),
            ),
            _SettingsCategoryCard(
              icon: Icons.translate,
              title: l10n.titleSettingsLanguage,
              subtitle: l10n.descSettingsLanguageSubtitle,
              onTap: () => context.push(kRouteSettingsLanguage),
            ),
            _SettingsCategoryCard(
              icon: Icons.shield_outlined,
              title: l10n.titleSettingsSafety,
              subtitle: l10n.descSettingsSafetySubtitle,
              onTap: () => context.push(kRouteSettingsSafety),
            ),
            _SettingsCategoryCard(
              icon: Icons.photo_library_outlined,
              title: l10n.titleSettingsDefaultApp,
              subtitle: l10n.descSettingsDefaultAppCardSubtitle,
              onTap: () => context.push(kRouteSettingsDefaultApp),
            ),
            _SettingsCategoryCard(
              icon: Icons.lock_outline,
              title: l10n.titleSettingsPrivacy,
              subtitle: l10n.descSettingsPrivacySubtitle,
              onTap: () => context.push(kRouteSettingsPrivacy),
            ),
            _SettingsCategoryCard(
              icon: Icons.verified_user_outlined,
              title: l10n.titleSettingsPermissions,
              subtitle: l10n.descSettingsPermissionsSubtitle,
              onTap: () => context.push(kRouteSettingsPermissions),
            ),
            _SettingsCategoryCard(
              icon: Icons.backup_outlined,
              title: l10n.titleBackupOpen,
              subtitle: l10n.descBackupOpenSubtitle,
              onTap: () => context.push(kRouteBackup),
            ),
            _SettingsCategoryCard(
              icon: Icons.sync_alt,
              title: l10n.titleDeviceSync,
              subtitle: l10n.descDeviceSyncSubtitle,
              onTap: () => context.push(kRouteDeviceSync),
            ),
            _SettingsCategoryCard(
              icon: Icons.help_outline,
              title: l10n.helpSettings,
              subtitle: l10n.descSettingsHelpCardSubtitle,
              onTap: () => context.push(kRouteSettingsHelp),
            ),
            _SettingsCategoryCard(
              icon: Icons.info_outline,
              title: l10n.labelSettingsAbout,
              subtitle: l10n.descSettingsAboutSubtitle,
              onTap: () => context.push(kRouteAbout),
            ),
            if (flavor.isDev)
              _SettingsCategoryCard(
                icon: Icons.code,
                title: l10n.titleSettingsDeveloper,
                subtitle: l10n.descSettingsDeveloperSubtitle,
                onTap: () => context.push(kRouteSettingsDeveloper),
              ),
            const SizedBox(height: 8),
            _SettingsCategoryCard(
              icon: Icons.restart_alt,
              title: l10n.titleSettingsReset,
              subtitle: l10n.bodySettingsReset,
              isDestructive: true,
              onTap: () => _confirmReset(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Asks before resetting preferences to defaults.
  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.titleSettingsReset),
        content: Text(l10n.bodySettingsReset),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionSettingsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionSettingsResetConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(appSettingsProvider.notifier).resetToDefaults();
    messenger.showSnackBar(SnackBar(content: Text(l10n.bodySettingsResetDone)));
  }
}

/// A card representing one settings section in the hub screen.
class _SettingsCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsCategoryCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final containerColor = isDestructive
        ? colorScheme.errorContainer.withValues(alpha: 0.5)
        : colorScheme.primaryContainer.withValues(alpha: 0.6);
    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;
    final titleColor = isDestructive ? colorScheme.error : null;
    final subtitleColor = isDestructive
        ? colorScheme.error.withValues(alpha: 0.8)
        : colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDestructive
              ? colorScheme.error.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: isDestructive
                    ? colorScheme.error.withValues(alpha: 0.7)
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The little "DEV BUILD" chip in the app bar of a development build.
class _DevFlavorBadge extends StatelessWidget {
  const _DevFlavorBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          l10n.labelDevBanner,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: scheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
