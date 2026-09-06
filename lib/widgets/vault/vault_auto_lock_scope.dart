import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_lock_policy.dart';

/// Shuts the vault when the app is backgrounded or left alone.
///
/// Two triggers, and they are not the same strength. Leaving the foreground
/// locks the vault at once, whatever the timeout says, because that is the
/// moment somebody else can be looking at the screen. Sitting idle locks it
/// after the timeout the user chose.
///
/// The rules themselves live in [VaultLockPolicy], which is pure. This widget
/// only supplies the two things a pure function cannot have: a clock and a
/// stream of pointer events.
class VaultAutoLockScope extends ConsumerStatefulWidget {
  /// The vault screen being watched.
  final Widget child;

  const VaultAutoLockScope({super.key, required this.child});

  @override
  ConsumerState<VaultAutoLockScope> createState() => _VaultAutoLockScopeState();
}

class _VaultAutoLockScopeState extends ConsumerState<VaultAutoLockScope>
    with WidgetsBindingObserver {
  Timer? _idleTimer;

  /// The timeout in force, refreshed whenever the settings load or change.
  int _autoLockSeconds = AppConstants.vaultAutoLockTimeoutSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restartIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final locked = ref
        .read(vaultLockControllerProvider.notifier)
        .lockIfDue(lifecycle: state, autoLockSeconds: _autoLockSeconds);
    if (locked) _idleTimer?.cancel();
  }

  /// Records a touch and restarts the idle countdown.
  void _noteActivity() {
    ref.read(vaultLockControllerProvider.notifier).noteActivity();
    _restartIdleTimer();
  }

  /// Arms a single timer for exactly the time left, rather than polling.
  ///
  /// The timer is re-armed on every touch, so the common case is one pending
  /// timer and no work at all while the user is reading.
  void _restartIdleTimer() {
    _idleTimer?.cancel();
    if (_autoLockSeconds <= 0) return;
    _idleTimer = Timer(Duration(seconds: _autoLockSeconds), _onIdleElapsed);
  }

  /// Checks the policy when the timer fires.
  ///
  /// It asks rather than assumes: a timer can fire slightly early, and the
  /// state can have changed since it was armed.
  void _onIdleElapsed() {
    final controller = ref.read(vaultLockControllerProvider.notifier);
    final state = ref.read(vaultLockControllerProvider);
    if (!state.isUnlocked) return;

    if (VaultLockPolicy.isIdle(
      lastActivityAt: state.lastActivityAt,
      autoLockSeconds: _autoLockSeconds,
      now: DateTime.now(),
    )) {
      controller.lock();
      return;
    }

    // Touched after the timer was armed. Wait out what is actually left.
    final remainingMs = VaultLockPolicy.remainingIdleMs(
      lastActivityAt: state.lastActivityAt,
      autoLockSeconds: _autoLockSeconds,
      now: DateTime.now(),
    );
    _idleTimer = Timer(Duration(milliseconds: remainingMs), _onIdleElapsed);
  }

  @override
  Widget build(BuildContext context) {
    // Keep the timeout in step with the settings, so changing it in vault
    // settings takes effect without leaving the vault.
    final settings = ref.watch(vaultSettingsProvider);
    settings.whenData((value) {
      if (value.autoLockSeconds != _autoLockSeconds) {
        _autoLockSeconds = value.autoLockSeconds;
        _restartIdleTimer();
      }
    });

    return Listener(
      // Listener rather than GestureDetector: it sees every pointer event on
      // the way down without competing with the buttons and scrollables
      // underneath for the gesture.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _noteActivity(),
      onPointerMove: (_) => _noteActivity(),
      child: widget.child,
    );
  }
}
