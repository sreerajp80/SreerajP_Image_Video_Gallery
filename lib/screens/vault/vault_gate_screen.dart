import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_auth_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_mode.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_state.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/vault/vault_screen.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/vault/vault_pin_rules.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/secure_screen.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/vault_pin_pad.dart';

/// The door in front of the vault.
///
/// It is the whole `/vault` route, not a dialog over the contents. Nothing
/// below it is ever built while the vault is shut, so a locked vault has no
/// decrypted bytes and no item list anywhere in the tree — locking is not a
/// matter of drawing something over the top.
///
/// Three states: set the vault up, unlock it, or explain why this device
/// cannot hold the key.
///
/// Set-up starts with the lock choice: phone lock (pre-selected when the
/// phone has a screen lock) or a vault PIN (pre-selected when it has none).
/// The PIN path is the only one that mentions there is no PIN recovery, and
/// it says so before a PIN is chosen rather than after.
class VaultGateScreen extends ConsumerStatefulWidget {
  const VaultGateScreen({super.key});

  @override
  ConsumerState<VaultGateScreen> createState() => _VaultGateScreenState();
}

class _VaultGateScreenState extends ConsumerState<VaultGateScreen> {
  final GlobalKey<VaultPinPadState> _padKey = GlobalKey<VaultPinPadState>();

  /// The first PIN of a set-up, held while the second is typed.
  String? _firstPin;

  String? _errorText;
  bool _busy = false;

  /// Whether the biometric prompt has already been offered this visit.
  ///
  /// Offered once. Re-prompting on every rebuild would trap someone who wants
  /// to type their PIN behind a dialog that keeps coming back.
  bool _biometricOffered = false;

  /// Whether Android's prompt has already been offered this visit, for a
  /// phone-lock vault. Once, for the same reason.
  bool _phoneLockOffered = false;

  /// The lock the user picked on the set-up screen, or null for "not
  /// touched yet", which then follows the phone: phone lock when it has a
  /// screen lock, the vault PIN when it has none.
  VaultLockMode? _setUpChoice;

  @override
  void initState() {
    super.initState();
    // After the first frame, so the notifier is not written to during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vaultLockControllerProvider.notifier).refreshStatus();
    });
  }

  // -------------------------------------------------------------- set-up

  Future<void> _onSetUpPin(String pin) async {
    final l10n = AppLocalizations.of(context)!;

    final rejection = VaultPinRules.validate(pin);
    if (rejection != null) {
      setState(() => _errorText = _messageForRejection(rejection, l10n));
      _padKey.currentState?.clear();
      return;
    }

    // First of the two entries: hold it and ask again.
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
        .read(vaultLockControllerProvider.notifier)
        .setUp(pin);
    if (!mounted) return;

    setState(() {
      _busy = false;
      _firstPin = null;
      if (!outcome.isSuccess) _errorText = _messageForOutcome(outcome, l10n);
    });
  }

  Future<void> _onSetUpPhoneLock() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final outcome = await ref
        .read(vaultLockControllerProvider.notifier)
        .setUpWithPhoneLock(l10n.bodyVaultUnlockReason);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _errorText =
          outcome.isSuccess || outcome.status == VaultAuthStatus.cancelled
          ? null
          : _messageForOutcome(outcome, l10n);
    });
  }

  // -------------------------------------------------------------- unlock

  Future<void> _onPhoneLock() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final outcome = await ref
        .read(vaultLockControllerProvider.notifier)
        .unlockWithPhoneLock(l10n.bodyVaultUnlockReason);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _errorText =
          outcome.isSuccess || outcome.status == VaultAuthStatus.cancelled
          ? null
          : _messageForOutcome(outcome, l10n);
    });
  }

  /// Shows Android's prompt once, when a phone-lock vault is shut.
  void _maybeOfferPhoneLock(VaultLockState lock) {
    if (_phoneLockOffered) return;
    if (lock.status != VaultLockStatus.locked) return;
    _phoneLockOffered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onPhoneLock();
    });
  }

  Future<void> _onUnlockPin(String pin) async {
    setState(() => _busy = true);
    final outcome = await ref
        .read(vaultLockControllerProvider.notifier)
        .unlockWithPin(pin);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = false;
      _errorText = outcome.isSuccess ? null : _messageForOutcome(outcome, l10n);
    });
    _padKey.currentState?.clear();
  }

  Future<void> _onBiometric() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final outcome = await ref
        .read(vaultLockControllerProvider.notifier)
        .unlockWithBiometrics(l10n.bodyVaultUnlockReason);
    if (!mounted) return;

    setState(() {
      _busy = false;
      // Backing out of the prompt is a choice, not a failure, so it says
      // nothing and leaves the PIN pad ready.
      _errorText =
          outcome.isSuccess || outcome.status == VaultAuthStatus.cancelled
          ? null
          : _messageForOutcome(outcome, l10n);
    });
  }

  /// Offers the biometric prompt once, when the vault is shut and set up.
  void _maybeOfferBiometric(VaultLockState lock) {
    if (_biometricOffered) return;
    if (lock.status != VaultLockStatus.locked) return;
    if (lock.isLockedOutAt(DateTime.now())) return;
    if (!(ref.read(vaultBiometricAvailableProvider).value ?? false)) {
      return;
    }
    _biometricOffered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onBiometric();
    });
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lock = ref.watch(vaultLockControllerProvider);
    final keystoreReady = ref.watch(vaultKeystoreReadyProvider);

    // Once open, the gate steps aside entirely and the vault itself is the
    // route. Locking rebuilds this and the contents go with it.
    if (lock.isUnlocked) return const VaultScreen();

    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.titleVault)),
        body: SafeArea(
          child: keystoreReady.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _KeystoreUnavailable(l10n: l10n),
            data: (ready) {
              if (!ready) return _KeystoreUnavailable(l10n: l10n);
              return _buildGate(lock, l10n);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGate(VaultLockState lock, AppLocalizations l10n) {
    switch (lock.status) {
      case VaultLockStatus.unknown:
        return const Center(child: CircularProgressIndicator());
      case VaultLockStatus.notSetUp:
        return _buildSetUp(l10n);
      case VaultLockStatus.locked:
      case VaultLockStatus.unlocked:
        return _buildUnlock(lock, l10n);
    }
  }

  Widget _buildSetUp(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final phoneLockAsync = ref.watch(vaultPhoneLockAvailableProvider);
    if (phoneLockAsync.isLoading && !phoneLockAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final phoneLockAvailable = phoneLockAsync.value ?? false;
    // Phone lock is the default, but only when the phone has a screen lock;
    // without one the vault PIN is the only choice.
    final choice = phoneLockAvailable
        ? (_setUpChoice ?? VaultLockMode.phoneLock)
        : VaultLockMode.vaultPin;
    final usePin = choice == VaultLockMode.vaultPin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            l10n.titleVaultSetUp,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bodyVaultSetUp,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _LockChoice(
            l10n: l10n,
            choice: choice,
            phoneLockAvailable: phoneLockAvailable,
            // Switching resets a half-typed PIN, so a first entry is never
            // carried across.
            onChanged: _busy
                ? null
                : (mode) => setState(() {
                    _setUpChoice = mode;
                    _firstPin = null;
                    _errorText = null;
                  }),
          ),
          const SizedBox(height: 16),
          if (!usePin) ...<Widget>[
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton.icon(
              onPressed: _busy ? null : _onSetUpPhoneLock,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.phonelink_lock_outlined),
              label: Text(l10n.labelVaultCreate),
            ),
          ],
          // Said before a PIN is chosen, not after. Someone who would rather
          // not take that risk should find out while they still have the
          // choice.
          if (usePin) ...<Widget>[
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.warning_amber_outlined,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.bodyVaultNoRecoveryWarning,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            VaultPinPad(
              key: _padKey,
              prompt: _firstPin == null
                  ? l10n.labelVaultChoosePin
                  : l10n.bodyVaultConfirmPin,
              submitLabel: _firstPin == null
                  ? l10n.labelVaultNext
                  : l10n.labelVaultCreate,
              errorText: _errorText,
              enabled: !_busy,
              busy: _busy,
              onSubmit: _onSetUpPin,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnlock(VaultLockState lock, AppLocalizations l10n) {
    final mode = ref.watch(vaultLockModeProvider);
    if (!mode.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (mode.value == VaultLockMode.phoneLock) {
      return _buildPhoneLockUnlock(lock, l10n);
    }

    _maybeOfferBiometric(lock);

    final now = DateTime.now();
    final lockedOut = lock.isLockedOutAt(now);
    final biometricAvailable =
        ref.watch(vaultBiometricAvailableProvider).value ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Icon(
            Icons.lock_outline,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          VaultPinPad(
            key: _padKey,
            prompt: l10n.labelVaultEnterPin,
            submitLabel: l10n.labelVaultUnlock,
            errorText: lockedOut
                ? l10n.bodyVaultLockedOut(lock.remainingLockoutSeconds(now))
                : _errorText,
            enabled: !_busy && !lockedOut,
            busy: _busy,
            onSubmit: _onUnlockPin,
            onBiometric: biometricAvailable ? _onBiometric : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLockUnlock(VaultLockState lock, AppLocalizations l10n) {
    _maybeOfferPhoneLock(lock);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Icon(
            Icons.phonelink_lock_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.bodyVaultPhoneLockPrompt,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton.icon(
            onPressed: _busy ? null : _onPhoneLock,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_open_outlined),
            label: Text(l10n.labelVaultUnlockWithPhoneLock),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- messages

  String _messageForRejection(
    VaultPinRejection rejection,
    AppLocalizations l10n,
  ) {
    switch (rejection) {
      case VaultPinRejection.empty:
      case VaultPinRejection.tooShort:
        return l10n.bodyVaultPinTooShort(AppConstants.vaultPinMinLength);
      case VaultPinRejection.tooLong:
        return l10n.bodyVaultPinTooLong(AppConstants.vaultPinMaxLength);
      case VaultPinRejection.notDigits:
        return l10n.bodyVaultPinNotDigits;
      case VaultPinRejection.allSameDigit:
        return l10n.bodyVaultPinAllSame;
      case VaultPinRejection.sequential:
        return l10n.bodyVaultPinSequential;
    }
  }

  String _messageForOutcome(VaultAuthOutcome outcome, AppLocalizations l10n) {
    switch (outcome.status) {
      case VaultAuthStatus.success:
        return '';
      case VaultAuthStatus.wrongPin:
        final left =
            AppConstants.vaultMaxFailedAttempts - outcome.failedAttempts;
        return left > 0
            ? '${l10n.bodyVaultWrongPin} — ${l10n.bodyVaultAttemptsLeft(left)}'
            : l10n.bodyVaultWrongPin;
      case VaultAuthStatus.invalidPin:
        return l10n.bodyVaultPinTooShort(AppConstants.vaultPinMinLength);
      case VaultAuthStatus.lockedOut:
        return l10n.bodyVaultLockedOut(
          outcome.lockoutSeconds > 0
              ? outcome.lockoutSeconds
              : AppConstants.vaultLockoutSeconds,
        );
      case VaultAuthStatus.biometricFailed:
        return l10n.errorVaultBiometricFailed;
      case VaultAuthStatus.biometricUnavailable:
        return l10n.bodyVaultBiometricUnavailable;
      case VaultAuthStatus.cancelled:
        return '';
      case VaultAuthStatus.error:
        return l10n.errorVaultAuth;
      case VaultAuthStatus.phoneLockUnavailable:
        return l10n.errorVaultPhoneLockUnavailable;
    }
  }
}

/// The two ways a vault can be locked, as a pair of radio tiles.
///
/// Phone lock is greyed out, with the reason, when the phone has no screen
/// lock.
class _LockChoice extends StatelessWidget {
  final AppLocalizations l10n;
  final VaultLockMode choice;
  final bool phoneLockAvailable;
  final ValueChanged<VaultLockMode>? onChanged;

  const _LockChoice({
    required this.l10n,
    required this.choice,
    required this.phoneLockAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void select(VaultLockMode? mode) {
      if (mode != null) onChanged?.call(mode);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.titleVaultLockChoice, style: theme.textTheme.titleMedium),
        RadioGroup<VaultLockMode>(
          groupValue: choice,
          onChanged: select,
          child: Column(
            children: <Widget>[
              RadioListTile<VaultLockMode>(
                value: VaultLockMode.phoneLock,
                enabled: phoneLockAvailable && onChanged != null,
                title: Text(l10n.labelVaultLockPhone),
                subtitle: Text(
                  phoneLockAvailable
                      ? l10n.descVaultLockPhone
                      : l10n.descVaultLockPhoneUnavailable,
                ),
              ),
              RadioListTile<VaultLockMode>(
                value: VaultLockMode.vaultPin,
                enabled: onChanged != null,
                title: Text(l10n.labelVaultLockPin),
                subtitle: Text(l10n.descVaultLockPin),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What is shown when this device has no usable keystore.
///
/// The vault stays shut rather than falling back to a key the app made up
/// itself: that would look like a vault while giving almost none of its
/// protection, which is worse than being honest.
class _KeystoreUnavailable extends StatelessWidget {
  final AppLocalizations l10n;

  const _KeystoreUnavailable({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.no_encryption_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.titleVaultKeystoreUnavailable,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bodyVaultKeystoreUnavailable,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
