import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_config.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/build_date.g.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/scan_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';
import 'package:in_sreerajp_imgvidgal/widgets/made_with_love.dart';

/// What this app is, who made it, and which version is running.
///
/// Every value comes from `assets/config/app_config.json` through
/// `ConfigService`, in the user's language. Row labels come from the ARB key
/// `aboutDetail<Key>`. Nothing on this screen is a hard-coded field name:
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
      appBar: AppBar(title: Text(l10n.titleAbout)),
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
    final lang = Localizations.localeOf(context).languageCode;
    final appName = config.appName.resolve(lang);
    final description = config.description.resolve(lang);

    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      children: <Widget>[
        // The three fixed rows. Everything below them is data.
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: AdaptiveDirectionality(text: appName, child: Text(appName)),
          subtitle: AdaptiveDirectionality(
            text: description,
            child: Text(description),
          ),
          isThreeLine: true,
        ),
        ListTile(
          leading: const Icon(Icons.numbers_outlined),
          title: Text(l10n.titleVersion),
          subtitle: Text(
            '${config.version} — ${l10n.bodyAboutBuild(config.build)}',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today_outlined),
          title: Text(l10n.titleAboutBuildDate),
          subtitle: const Text(kBuildDate),
        ),
        const Divider(),

        for (final entry in config.details.entries)
          if (entry.key.trim().isNotEmpty &&
              entry.value.resolve(lang).trim().isNotEmpty)
            _DetailRow(
              detailKey: entry.key,
              label: aboutDetailLabel(l10n, entry.key),
              value: entry.value.resolve(lang),
            ),

        // Always the last thing on the screen (guideline.md §1.7).
        const MadeWithLove(),
      ],
    );
  }
}

/// Maps a config detail key to its translated label.
///
/// The raw key is the last resort, so a row added to the config file still
/// shows before its label is added to the ARB files.
String aboutDetailLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'author':
      return l10n.aboutDetailAuthor;
    case 'license':
      return l10n.aboutDetailLicense;
    case 'ideUsed':
      return l10n.aboutDetailIdeUsed;
    case 'aiUsed':
      return l10n.aboutDetailAiUsed;
    case 'storageModel':
      return l10n.aboutDetailStorageModel;
    case 'networkPolicy':
      return l10n.aboutDetailNetworkPolicy;
    case 'security':
      return l10n.aboutDetailSecurity;
    case 'languages':
      return l10n.aboutDetailLanguages;
    case 'email':
      return l10n.aboutDetailEmail;
    case 'privacyPolicy':
      return l10n.aboutDetailPrivacyPolicy;
    default:
      return key;
  }
}

/// One row from the config's `details` map.
class _DetailRow extends ConsumerWidget {
  final String detailKey;
  final String label;
  final String value;

  const _DetailRow({
    required this.detailKey,
    required this.label,
    required this.value,
  });

  /// Whether this row holds an email address, whatever case it was written in.
  bool get _isEmail => detailKey.trim().toLowerCase() == 'email';

  /// Whether this row's value is a web link, such as the privacy policy.
  /// Only `https` is opened; a plain `http` link is shown, not tapped.
  bool get _isLink => value.trim().toLowerCase().startsWith('https://');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      // The value comes out of a file the app does not control, and the
      // label may be the raw key, so both take their direction from what
      // they actually say.
      title: AdaptiveDirectionality(text: label, child: Text(label)),
      subtitle: AdaptiveDirectionality(text: value, child: Text(value)),
      trailing: _isEmail
          ? const Icon(Icons.mail_outline)
          : _isLink
          ? const Icon(Icons.open_in_new)
          : null,
      onTap: _isEmail
          ? () => _open(context, ref, 'mailto:${value.trim()}')
          : _isLink
          ? () => _open(context, ref, value.trim())
          : null,
    );
  }

  /// Hands an address to whatever mail app or browser the phone has.
  ///
  /// Goes through the same [IntentChannel] every scanned code goes through,
  /// rather than a channel of its own. That keeps one gate on outgoing
  /// intents: `mailto` and `https` are on the permitted list, and adding a
  /// scheme stays a change in one place. No message is composed, nothing is
  /// sent, and the app never opens a connection of its own: the other app
  /// does any fetching.
  Future<void> _open(BuildContext context, WidgetRef ref, String uri) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(intentChannelProvider).openUri(uri);
    } catch (_) {
      // A phone with no mail app is a normal state, not an error worth more
      // than a line at the bottom of the screen.
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorAboutMailFailed)),
      );
    }
  }
}
