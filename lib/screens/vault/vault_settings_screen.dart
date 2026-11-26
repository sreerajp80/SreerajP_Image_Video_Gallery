import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_auth_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_mode.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/vault/vault_gate_screen.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/vault/vault_pin_rules.dart';
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

    // This page is reachable from app Settings as well as from inside the
    // vault, and go_router builds only this page, not the gate in front of
    // it. So it guards itself: a shut vault shows the gate here, and the
    // settings appear once it is opened. Only the open/shut flag is watched,
    // not every touch.
    final unlocked = ref.watch(
      vaultLockControllerProvider.select((lock) => lock.isUnlocked),
    );
    if (!unlocked) return const VaultGateScreen();

    final settings = ref.watch(vaultSettingsProvider);

    return SecureScreen(
      child: VaultAutoLockScope(
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.titleVaultSettings)),
          body: SafeArea(
            child: settings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.errorVaultAuth)),
              data: (value) => _SettingsList(settings: value),
            ),
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

    final mode = ref.watch(vaultLockModeProvider).value;
    final phoneLockAvailable =
        ref.watch(vaultPhoneLockAvailableProvider).value ?? false;
    final isPin = mode == VaultLockMode.vaultPin;

    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            l10n.titleVaultLockHeading,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (mode != null)
          RadioGroup<VaultLockMode>(
            groupValue: mode,
            onChanged: (value) {
              if (value == null || value == mode) return;
              _switchLock(context, ref, value);
            },
            child: Column(
              children: <Widget>[
                RadioListTile<VaultLockMode>(
                  value: VaultLockMode.phoneLock,
                  // Always selectable when it is the current lock, so it is
                  // never shown greyed out as if it were not chosen.
                  enabled: phoneLockAvailable || !isPin,
                  title: Text(l10n.labelVaultLockPhone),
                  subtitle: Text(
                    phoneLockAvailable || !isPin
                        ? l10n.descVaultLockPhone
                        : l10n.descVaultLockPhoneUnavailable,
                  ),
                ),
                RadioListTile<VaultLockMode>(
                  value: VaultLockMode.vaultPin,
                  title: Text(l10n.labelVaultLockPin),
                  subtitle: Text(l10n.descVaultLockPin),
                ),
              ],
            ),
          ),
        const Divider(),

        _SectionHeader(
          title: l10n.titleVaultAutoLockHeading,
          body: l10n.bodyVaultAutoLock,
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
                        ? l10n.bodyVaultAutoLockSeconds(seconds)
                        : l10n.bodyVaultAutoLockMinutes(seconds ~/ 60),
                  ),
                  dense: true,
                ),
            ],
          ),
        ),
        const Divider(),

        // A shortcut over the vault PIN only. In phone-lock mode the
        // fingerprint is already part of Android's prompt.
        if (isPin) ...<Widget>[
          SwitchListTile(
            value: settings.biometricEnabled,
            onChanged: (value) =>
                _save(ref, settings.copyWith(biometricEnabled: value)),
            title: Text(l10n.titleVaultBiometricHeading),
            subtitle: Text(l10n.bodyVaultBiometric),
          ),
          const Divider(),
        ],

        _SectionHeader(
          title: l10n.titleVaultShredHeading,
          body: l10n.bodyVaultShred,
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
                  title: Text(l10n.bodyVaultShredPassCount(passes)),
                  dense: true,
                ),
            ],
          ),
        ),
        SwitchListTile(
          value: settings.shredOnImportByDefault,
          onChanged: (value) =>
              _save(ref, settings.copyWith(shredOnImportByDefault: value)),
          title: Text(l10n.titleVaultShredDefaultHeading),
          subtitle: Text(l10n.bodyVaultShredDefault),
        ),
        const Divider(),

        if (isPin) ...<Widget>[
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: Text(l10n.titleVaultChangePin),
            onTap: () => _openChangePin(context, ref),
          ),
          const Divider(),
        ],

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.titleVaultSecureScreenHeading,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.bodyVaultSecureScreen,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Moves the vault to the other lock.
  ///
  /// To phone lock: Android's prompt must pass first, then the PIN is erased.
  /// To a PIN: a new PIN is chosen and typed twice. The vault is already open
  /// here (this page shows the gate otherwise), so no old secret is asked
  /// for again.
  Future<void> _switchLock(
    BuildContext context,
    WidgetRef ref,
    VaultLockMode target,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final bool switched;
    if (target == VaultLockMode.phoneLock) {
      final outcome = await ref
          .read(vaultAuthServiceProvider)
          .switchToPhoneLock(reason: l10n.bodyVaultUnlockReason);
      switched = outcome.isSuccess;
      if (!switched && outcome.status == VaultAuthStatus.phoneLockUnavailable) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.errorVaultPhoneLockUnavailable)),
        );
      }
    } else {
      switched =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(builder: (_) => const _SetPinPage()),
          ) ==
          true;
    }
    if (!switched) return;

    ref.read(vaultRevisionProvider.notifier).state++;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          target == VaultLockMode.phoneLock
              ? l10n.bodyVaultSwitchedToPhoneLock
              : l10n.bodyVaultSwitchedToPin,
        ),
      ),
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
    ).showSnackBar(SnackBar(content: Text(l10n.bodyVaultPinChanged)));
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
        () => _errorText = l10n.bodyVaultPinTooShort(
          AppConstants.vaultPinMinLength,
        ),
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
          ? l10n.bodyVaultPinNotDigits
          : l10n.bodyVaultWrongPin;
    });
    _padKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.titleVaultChangePin)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: VaultPinPad(
              key: _padKey,
              prompt: _currentPin == null
                  ? l10n.labelVaultCurrentPin
                  : l10n.labelVaultNewPin,
              submitLabel: l10n.titleVaultChangePin,
              errorText: _errorText,
              enabled: !_busy,
              busy: _busy,
              onSubmit: _onSubmit,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chooses a new vault PIN (typed twice) for a vault moving off phone lock.
class _SetPinPage extends ConsumerStatefulWidget {
  const _SetPinPage();

  @override
  ConsumerState<_SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends ConsumerState<_SetPinPage> {
  final GlobalKey<VaultPinPadState> _padKey = GlobalKey<VaultPinPadState>();

  String? _firstPin;
  String? _errorText;
  bool _busy = false;

  Future<void> _onSubmit(String pin) async {
    final l10n = AppLocalizations.of(context)!;

    if (!VaultPinRules.isValid(pin)) {
      setState(
        () => _errorText = l10n.bodyVaultPinTooShort(
          AppConstants.vaultPinMinLength,
        ),
      );
      _padKey.currentState?.clear();
      return;
    }

    if (_firstPin == null) {
      setState(() {
        _firstPin = pin;
        _errorText = null;
      });
      _padKey.currentState?.clear();
      return;
    }

    if (_firstPin != pin) {
      setState(() {
        _firstPin = null;
        _errorText = l10n.bodyVaultPinMismatch;
      });
      _padKey.currentState?.clear();
      return;
    }

    setState(() => _busy = true);
    final outcome = await ref
        .read(vaultAuthServiceProvider)
        .switchToVaultPin(pin);
    if (!mounted) return;

    if (outcome.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _firstPin = null;
      _errorText = l10n.errorVaultAuth;
    });
    _padKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.titleVaultSetPin)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                Text(
                  l10n.bodyVaultNoRecoveryWarning,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                VaultPinPad(
                  key: _padKey,
                  prompt: _firstPin == null
                      ? l10n.labelVaultChoosePin
                      : l10n.bodyVaultConfirmPin,
                  submitLabel: _firstPin == null
                      ? l10n.labelVaultNext
                      : l10n.titleVaultSetPin,
                  errorText: _errorText,
                  enabled: !_busy,
                  busy: _busy,
                  onSubmit: _onSubmit,
                ),
              ],
            ),
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
