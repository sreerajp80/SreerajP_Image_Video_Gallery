import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// The digit pad the vault is opened with.
///
/// Its own pad rather than a text field, for two reasons. A text field brings
/// the system keyboard, which on many devices means a keyboard app seeing every
/// digit of the PIN. And the entered value can be held here as a plain string
/// that is cleared the moment it has been checked, rather than living inside a
/// controller for as long as the screen does.
///
/// The widget owns only what has been typed. Whether it is right, how many
/// tries are left, and whether the pad is shut are all decided above and passed
/// down, so this stays a keypad and not a second copy of the lock rules.
class VaultPinPad extends StatefulWidget {
  /// Prompt above the dots.
  final String prompt;

  /// Error under the dots, or null when there is nothing to report.
  final String? errorText;

  /// Label of the confirm button.
  final String submitLabel;

  /// Called with the finished PIN.
  final ValueChanged<String> onSubmit;

  /// Called when the biometric button is pressed, or null to hide it.
  final VoidCallback? onBiometric;

  /// Whether the pad accepts input.
  final bool enabled;

  /// Whether a check is running, which shows a spinner on the button.
  final bool busy;

  const VaultPinPad({
    super.key,
    required this.prompt,
    required this.submitLabel,
    required this.onSubmit,
    this.errorText,
    this.onBiometric,
    this.enabled = true,
    this.busy = false,
  });

  @override
  State<VaultPinPad> createState() => VaultPinPadState();
}

class VaultPinPadState extends State<VaultPinPad> {
  String _pin = '';

  /// Empties the pad.
  ///
  /// Public so the screen can clear it after a wrong PIN, or between the two
  /// entries of a set-up, without reaching into the state itself.
  void clear() {
    if (!mounted) return;
    setState(() => _pin = '');
  }

  void _append(String digit) {
    if (!widget.enabled) return;
    if (_pin.length >= AppConstants.vaultPinMaxLength) return;
    setState(() => _pin += digit);
  }

  void _backspace() {
    if (!widget.enabled || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    if (!widget.enabled || _pin.length < AppConstants.vaultPinMinLength) return;
    final value = _pin;
    // Cleared before the callback runs, so the digits are not still sitting in
    // this widget while the check happens.
    setState(() => _pin = '');
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final canSubmit =
        widget.enabled &&
        !widget.busy &&
        _pin.length >= AppConstants.vaultPinMinLength;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          widget.prompt,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _PinDots(length: _pin.length, hasError: widget.errorText != null),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: widget.errorText == null
              ? null
              : Text(
                  widget.errorText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
        _buildKeypad(l10n),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: canSubmit ? _submit : null,
          child: widget.busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitLabel),
        ),
        if (widget.onBiometric != null) ...<Widget>[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.enabled && !widget.busy
                ? widget.onBiometric
                : null,
            icon: const Icon(Icons.fingerprint),
            label: Text(l10n.vaultUseBiometrics),
          ),
        ],
      ],
    );
  }

  Widget _buildKeypad(AppLocalizations l10n) {
    // Three rows of three, then a row holding zero and backspace. Laid out by
    // hand rather than with a grid so the backspace can sit beside the zero
    // where a thumb already is.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final row in const <List<String>>[
          <String>['1', '2', '3'],
          <String>['4', '5', '6'],
          <String>['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (final digit in row) _DigitKey(digit, () => _append(digit)),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(width: 76, height: 64),
            _DigitKey('0', () => _append('0')),
            SizedBox(
              width: 76,
              height: 64,
              child: IconButton(
                onPressed: widget.enabled ? _backspace : null,
                icon: const Icon(Icons.backspace_outlined),
                tooltip: l10n.vaultClearSelection,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One digit button.
class _DigitKey extends StatelessWidget {
  final String digit;
  final VoidCallback onPressed;

  const _DigitKey(this.digit, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 64,
      child: TextButton(
        onPressed: onPressed,
        child: Text(digit, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

/// The filled and empty dots showing how many digits have been typed.
///
/// The count is shown, never the digits. Anyone glancing over a shoulder
/// learns the length and nothing else.
class _PinDots extends StatelessWidget {
  final int length;
  final bool hasError;

  const _PinDots({required this.length, required this.hasError});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filledColor = hasError ? scheme.error : scheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var i = 0; i < AppConstants.vaultPinMaxLength; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < length ? filledColor : Colors.transparent,
                border: Border.all(
                  color: i < length ? filledColor : scheme.outlineVariant,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
