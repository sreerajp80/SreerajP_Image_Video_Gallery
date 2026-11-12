import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_permissions.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media/delete_confirm_info.dart';
import 'package:in_sreerajp_imgvidgal/models/media/media_permission_status.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_permission_info.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';

/// Android version names for the API levels the manifest limits by.
const Map<int, String> _androidVersionForApi = <int, String>{
  28: '9',
  31: '12',
  32: '12',
  33: '13',
  34: '14',
};

/// Read-only list of every Android permission the app holds, the ones it
/// strips on purpose, and why. The list itself is [kAppPermissions].
class PermissionsSettingsScreen extends ConsumerWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    Widget section(AppPermissionKind kind, String heading, String body) {
      final List<AppPermissionInfo> items = kAppPermissions
          .where((p) => p.kind == kind)
          .toList();
      return _PermissionSection(heading: heading, body: body, items: items);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSettingsPermissions)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: <Widget>[
            _NoServerCard(
              title: l10n.titlePrivacyNoServer,
              body: l10n.bodyPrivacyNoServer,
            ),
            section(
              AppPermissionKind.explicit,
              l10n.labelPermissionsExplicit,
              l10n.descPermissionsExplicit,
            ),
            section(
              AppPermissionKind.special,
              l10n.labelPermissionsSpecial,
              l10n.descPermissionsSpecial,
            ),
            section(
              AppPermissionKind.implicit,
              l10n.labelPermissionsImplicit,
              l10n.descPermissionsImplicit,
            ),
            section(
              AppPermissionKind.removed,
              l10n.labelPermissionsRemoved,
              l10n.descPermissionsRemoved,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.descPermissionsManage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.labelOpenSettings),
                onPressed: () =>
                    ref.read(mediaPermissionServiceProvider).openSettings(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The plain statement that the app has no server, shown above the list
/// because it answers "why does a gallery need network access?".
class _NoServerCard extends StatelessWidget {
  final String title;
  final String body;

  const _NoServerCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.wifi_off_rounded, color: colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(body),
      ),
    );
  }
}

/// One group of permissions: a heading, a line of explanation, and a card of
/// rows.
class _PermissionSection extends StatelessWidget {
  final String heading;
  final String body;
  final List<AppPermissionInfo> items;

  const _PermissionSection({
    required this.heading,
    required this.body,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 1, indent: 16, endIndent: 16));
      }
      rows.add(_PermissionRow(info: items[i]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 24),
        Text(
          heading,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(children: rows),
        ),
      ],
    );
  }
}

/// One permission row: friendly name, live state where known, the reason,
/// and the Android names in small text.
class _PermissionRow extends ConsumerWidget {
  final AppPermissionInfo info;

  const _PermissionRow({required this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool removed = info.kind == AppPermissionKind.removed;

    Widget? status;
    if (info.id == AppPermissionId.photosVideos) {
      final MediaPermissionStatus? state = ref
          .watch(mediaPermissionStatusProvider)
          .value;
      if (state != null) status = _StatusChip(status: state);
    } else if (info.id == AppPermissionId.manageMedia) {
      final DeleteConfirmInfo? state = ref
          .watch(deleteConfirmInfoProvider)
          .value;
      if (state != null && state.manageMediaSupported) {
        status = _StatusChip(
          status: state.manageMediaGranted
              ? MediaPermissionStatus.granted
              : MediaPermissionStatus.denied,
        );
      }
    }

    final String names = info.androidNames
        .map((n) {
          final String? from = n.minApi == null
              ? null
              : _androidVersionForApi[n.minApi];
          final String? upTo = n.maxApi == null
              ? null
              : _androidVersionForApi[n.maxApi];
          final String? note = from != null
              ? l10n.labelPermAndroidFrom(from)
              : upTo != null
              ? l10n.labelPermAndroidUpTo(upTo)
              : null;
          return note == null ? n.name : '${n.name} ($note)';
        })
        .join('\n');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: removed
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconFor(info.id),
              color: removed
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _nameFor(l10n, info.id),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: removed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    ?status,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _reasonFor(l10n, info.id),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  names,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small coloured label with the live photos-and-videos permission state.
class _StatusChip extends StatelessWidget {
  final MediaPermissionStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final (String text, Color bg, Color fg) = switch (status) {
      MediaPermissionStatus.granted => (
        l10n.labelPermAllowed,
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      MediaPermissionStatus.partial => (
        l10n.labelPermSelectedOnly,
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      MediaPermissionStatus.denied ||
      MediaPermissionStatus.permanentlyDenied => (
        l10n.labelPermNotAllowed,
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
    };
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

IconData _iconFor(AppPermissionId id) => switch (id) {
  AppPermissionId.photosVideos => Icons.photo_library_outlined,
  AppPermissionId.camera => Icons.qr_code_scanner,
  AppPermissionId.biometric => Icons.fingerprint,
  AppPermissionId.network => Icons.lan_outlined,
  AppPermissionId.wifiState => Icons.wifi,
  AppPermissionId.networkState => Icons.network_check,
  AppPermissionId.changeWifi => Icons.wifi_find_outlined,
  AppPermissionId.receiverPrivate => Icons.shield_outlined,
  AppPermissionId.wakeLock => Icons.bedtime_off_outlined,
  AppPermissionId.recordAudio => Icons.mic_off_outlined,
  AppPermissionId.writeStorage => Icons.save_alt_outlined,
  AppPermissionId.manageMedia => Icons.perm_media_outlined,
};

String _nameFor(AppLocalizations l10n, AppPermissionId id) => switch (id) {
  AppPermissionId.photosVideos => l10n.labelPermPhotosVideos,
  AppPermissionId.camera => l10n.labelPermCamera,
  AppPermissionId.biometric => l10n.labelPermBiometric,
  AppPermissionId.network => l10n.labelPermNetwork,
  AppPermissionId.wifiState => l10n.labelPermWifiState,
  AppPermissionId.networkState => l10n.labelPermNetworkState,
  AppPermissionId.changeWifi => l10n.labelPermChangeWifi,
  AppPermissionId.receiverPrivate => l10n.labelPermReceiverPrivate,
  AppPermissionId.wakeLock => l10n.labelPermWakeLock,
  AppPermissionId.recordAudio => l10n.labelPermRecordAudio,
  AppPermissionId.writeStorage => l10n.labelPermWriteStorage,
  AppPermissionId.manageMedia => l10n.labelPermManageMedia,
};

String _reasonFor(AppLocalizations l10n, AppPermissionId id) => switch (id) {
  AppPermissionId.photosVideos => l10n.descPermPhotosVideos,
  AppPermissionId.camera => l10n.descPermCamera,
  AppPermissionId.biometric => l10n.descPermBiometric,
  AppPermissionId.network => l10n.descPermNetwork,
  AppPermissionId.wifiState => l10n.descPermWifiState,
  AppPermissionId.networkState => l10n.descPermNetworkState,
  AppPermissionId.changeWifi => l10n.descPermChangeWifi,
  AppPermissionId.receiverPrivate => l10n.descPermReceiverPrivate,
  AppPermissionId.wakeLock => l10n.descPermWakeLock,
  AppPermissionId.recordAudio => l10n.descPermRecordAudio,
  AppPermissionId.writeStorage => l10n.descPermWriteStorage,
  AppPermissionId.manageMedia => l10n.descPermManageMedia,
};
