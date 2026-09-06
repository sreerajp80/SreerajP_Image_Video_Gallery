import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_config.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/build_date.g.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/scan_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';

/// What this app is, who made it, and which version is running.
///
/// Every value comes from `assets/config/app_config.json` through
/// `ConfigService`. Nothing on this screen is a hard-coded field name:
/// adding a row to `details` in that file is the only change needed to make
/// it appear here, and removing one is the only change needed to take it
/// away. That rule is set by `docs/guidelines/guideline.md` section 1.6.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final configAsync = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // The loader already degrades to the built-in values rather than
        // throwing, so this branch is all but unreachable. If it is ever
        // reached, show the fallback rather than an error: an About screen
        // is not worth failing over.
        error: (_, _) => const _AboutBody(config: AppConfig.fallback),
        data: (config) => _AboutBody(config: config),
      ),
    );
  }
}

class _AboutBody extends StatelessWidget {
  final AppConfig config;

  const _AboutBody({required this.config});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        // The three fixed rows. Everything below them is data.
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: AdaptiveDirectionality(
            text: config.appName,
            child: Text(config.appName),
          ),
          subtitle: AdaptiveDirectionality(
            text: config.description,
            child: Text(config.description),
          ),
          isThreeLine: true,
        ),
        ListTile(
          leading: const Icon(Icons.numbers_outlined),
          title: Text(l10n.version),
          subtitle: Text(
            '${config.version} — ${l10n.aboutBuild(config.build)}',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today_outlined),
          title: Text(l10n.aboutBuildDate),
          subtitle: const Text(kBuildDate),
        ),
        const Divider(),

        for (final entry in config.details.entries)
          if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
            _DetailRow(label: entry.key, value: entry.value),
      ],
    );
  }
}

/// One key and value straight out of the config's `details` map.
class _DetailRow extends ConsumerWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  /// Whether this row holds an email address, whatever case it was written in.
  bool get _isEmail => label.trim().toLowerCase() == 'email';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      // Both the label and the value come out of a file the app does not
      // control, so both take their direction from what they actually say.
      title: AdaptiveDirectionality(text: label, child: Text(label)),
      subtitle: AdaptiveDirectionality(text: value, child: Text(value)),
      trailing: _isEmail ? const Icon(Icons.mail_outline) : null,
      onTap: _isEmail ? () => _openMail(context, ref) : null,
    );
  }

  /// Hands the address to whatever mail app the phone has.
  ///
  /// Goes through the same [IntentChannel] every scanned code goes through,
  /// rather than a channel of its own. That keeps one gate on outgoing
  /// intents: `mailto` is on the permitted list, and adding a scheme stays a
  /// change in one place. No message is composed, nothing is sent, and the
  /// app never opens a connection of its own.
  Future<void> _openMail(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(intentChannelProvider).openUri('mailto:${value.trim()}');
    } catch (_) {
      // A phone with no mail app is a normal state, not an error worth more
      // than a line at the bottom of the screen.
      messenger.showSnackBar(SnackBar(content: Text(l10n.aboutMailFailed)));
    }
  }
}
