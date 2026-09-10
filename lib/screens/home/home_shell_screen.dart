import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/home/albums_tab.dart';
import 'package:in_sreerajp_imgvidgal/screens/home/folders_tab.dart';
import 'package:in_sreerajp_imgvidgal/screens/timeline/timeline_screen.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';

/// The top-level home screen with three tabs: Timeline, Folders, Albums.
///
/// Uses a [NavigationBar] (Material 3) at the bottom and an [IndexedStack]
/// to keep each tab's scroll position and state alive when switching.
///
/// Permission handling lives here because it applies to all three tabs:
/// none of them can show media without it.
class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permission = ref.watch(mediaPermissionStatusProvider);
    final selecting = ref.watch(selectionModeProvider);

    // While a selection is running, hide the tab bar so it cannot clash with
    // the batch action bar that the individual tab screens show.
    final showNavBar = !selecting;

    return Scaffold(
      body: permission.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PermissionMessage(
          icon: Icons.error_outline,
          title: l10n.scanFailed,
          actionLabel: l10n.scanMedia,
          onAction: () => ref.invalidate(mediaPermissionStatusProvider),
        ),
        data: (status) {
          if (!status.canRead) {
            final isPermanentlyDenied =
                status == MediaPermissionStatus.permanentlyDenied;
            return _PermissionMessage(
              icon: Icons.photo_library_outlined,
              title: l10n.permissionRequired,
              body: l10n.permissionRequiredBody,
              actionLabel: isPermanentlyDenied
                  ? l10n.openSettings
                  : l10n.grantPermission,
              onAction: () async {
                if (isPermanentlyDenied) {
                  await ref.read(mediaPermissionServiceProvider).openSettings();
                } else {
                  final newStatus = await ref
                      .read(mediaPermissionServiceProvider)
                      .request();
                  ref.invalidate(mediaPermissionStatusProvider);
                  if (newStatus.canRead) {
                    await ref.read(mediaScanControllerProvider.notifier).scan();
                  }
                }
              },
            );
          }

          return IndexedStack(
            index: _tabIndex,
            children: const <Widget>[
              TimelineScreen(),
              FoldersTab(),
              AlbumsTab(),
            ],
          );
        },
      ),
      bottomNavigationBar: showNavBar
          ? NavigationBar(
              selectedIndex: _tabIndex,
              onDestinationSelected: (index) {
                setState(() => _tabIndex = index);
              },
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.photo_library_outlined),
                  selectedIcon: const Icon(Icons.photo_library),
                  label: l10n.tabTimeline,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.folder_outlined),
                  selectedIcon: const Icon(Icons.folder),
                  label: l10n.tabFolders,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.photo_album_outlined),
                  selectedIcon: const Icon(Icons.photo_album),
                  label: l10n.tabAlbums,
                ),
              ],
            )
          : null,
    );
  }
}

/// Full-screen message for permission and error states.
class _PermissionMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String actionLabel;
  final VoidCallback onAction;

  const _PermissionMessage({
    required this.icon,
    required this.title,
    this.body,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
