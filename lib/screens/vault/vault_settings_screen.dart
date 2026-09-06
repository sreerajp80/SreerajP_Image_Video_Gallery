import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_auth_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_pin_rules.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/secure_screen.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/vault_auto_lock_scope.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/vault_pin_pad.dart';

/// How the vault behaves: when it locks, what opens it, and how hard it
/// shreds.
///
/// Each setting carries a line saying what it actually does, including where
/// it stops working. Shredding in particular says out loud that on flash
/// storage an overwrite is a strong measure and not a guarantee — a setting
/// that quietly oversells itself is worse than no setting.
class VaultSettingsScreen extends ConsumerWidget {
  const VaultSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(vaultSettingsProvider);

    return SecureScreen(
      child: VaultAutoLockScope(
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.vaultSettingsTitle)),
          body: settings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.vaultAuthError)),
            data: (value) => _SettingsList(settings: value),
          ),
        ),
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  final VaultSecuritySettings settings;

  const _SettingsList({required this.settings});

  /// Saves a change and refreshes everything watching the settings.
  Future<void> _save(WidgetRef ref, VaultSecuritySettings updated) async {
    await ref.read(vaultAuthServiceProvider).writeSettings(updated);
    ref.read(vaultRevisionProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      children: <Widget>[
        _SectionHeader(
          title: l10n.vaultAutoLockHeading,
          body: l10n.vaultAutoLockBody,
        ),
        RadioGroup<int>(
          groupValue: settings.autoLockSeconds,
          onChanged: (value) {
            if (value == null) return;
            _save(ref, settings.copyWith(autoLockSeconds: value));
          },
          child: Column(
            children: <Widget>[
              for (final seconds in AppConstants.vaultAutoLockChoicesSeconds)
                RadioListTile<int>(
                  value: seconds,
                  title: Text(
                    seconds < 60
                        ? l10n.vaultAutoLockSeconds(seconds)
                        : l10n.vaultAutoLockMinutes(seconds ~/ 60),
                  ),
                  dense: true,
                ),
            ],
          ),
        ),
        const Divider(),

        SwitchListTile(
          value: settings.biometricEnabled,
          onChanged: (value) =>
              _save(ref, settings.copyWith(biometricEnabled: value)),
          title: Text(l10n.vaultBiometricHeading),
          subtitle: Text(l10n.vaultBiometricBody),
        ),
        const Divider(),

        _SectionHeader(
          title: l10n.vaultShredHeading,
          body: l10n.vaultShredBody,
        ),
        RadioGroup<int>(
          groupValue: settings.shredPasses,
          onChanged: (value) {
            if (value == null) return;
            _save(ref, settings.copyWith(shredPasses: value));
          },
          child: Column(
            children: <Widget>[
              for (
                var passes = AppConstants.vaultMinShredPasses;
                passes <= AppConstants.vaultMaxShredPasses;
                passes++
              )
                RadioListTile<int>(
                  value: passes,
                  title: Text(l10n.vaultShredPassCount(passes)),
                  dense: true,
                ),
            ],
          ),
        ),
        SwitchListTile(
          value: settings.shredOnImportByDefault,
          onChanged: (value) =>
              _save(ref, settings.copyWith(shredOnImportByDefault: value)),
          title: Text(l10n.vaultShredDefaultHeading),
          subtitle: Text(l10n.vaultShredDefaultBody),
        ),
        const Divider(),

        ListTile(
          leading: const Icon(Icons.password_outlined),
          title: Text(l10n.vaultChangePin),
          onTap: () => _openChangePin(context, ref),
        ),
        const Divider(),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.vaultSecureScreenHeading,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.vaultSecureScreenBody,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openChangePin(BuildContext context, WidgetRef ref) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const _ChangePinPage()),
    );
    if (changed != true || !context.mounted) return;

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.vaultPinChanged)));
  }
}

/// Asks for the current PIN, then the new one.
///
/// The current PIN is required. Without it, anyone who picked up an unlocked
/// phone could set a new one and keep the vault for themselves.
class _ChangePinPage extends ConsumerStatefulWidget {
  const _ChangePinPage();

  @override
  ConsumerState<_ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends ConsumerState<_ChangePinPage> {
  final GlobalKey<VaultPinPadState> _padKey = GlobalKey<VaultPinPadState>();

  String? _currentPin;
  String? _errorText;
  bool _busy = false;

  Future<void> _onSubmit(String pin) async {
    final l10n = AppLocalizations.of(context)!;

    // First step: hold the current PIN and ask for the new one. It is not
    // checked yet, so a wrong one is reported at the end rather than telling
    // someone guessing whether they got the first half right.
    if (_currentPin == null) {
      setState(() {
        _currentPin = pin;
        _errorText = null;
      });
      _padKey.currentState?.clear();
      return;
    }

    if (!VaultPinRules.isValid(pin)) {
      setState(
        () =>
            _errorText = l10n.vaultPinTooShort(AppConstants.vaultPinMinLength),
      );
      _padKey.currentState?.clear();
      return;
    }

    setState(() => _busy = true);
    final outcome = await ref
        .read(vaultAuthServiceProvider)
        .changePin(currentPin: _currentPin!, newPin: pin);
    if (!mounted) return;

    if (outcome.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _busy = false;
      _currentPin = null;
      _errorText = outcome.status == VaultAuthStatus.invalidPin
          ? l10n.vaultPinNotDigits
          : l10n.vaultWrongPin;
    });
    _padKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.vaultChangePin)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: VaultPinPad(
            key: _padKey,
            prompt: _currentPin == null
                ? l10n.vaultCurrentPin
                : l10n.vaultNewPin,
            submitLabel: l10n.vaultChangePin,
            errorText: _errorText,
            enabled: !_busy,
            busy: _busy,
            onSubmit: _onSubmit,
          ),
        ),
      ),
    );
  }
}

/// A heading and its explanation above a group of choices.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String body;

  const _SectionHeader({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
