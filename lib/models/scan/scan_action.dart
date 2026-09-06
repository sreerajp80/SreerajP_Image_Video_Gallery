/// Something the user can do with a scanned code.
enum ScanActionType {
  /// Put the raw payload on the clipboard.
  copy,

  /// Hand a web address to a browser.
  openUrl,

  /// Offer the number to the dialler, without calling it.
  dial,

  /// Start an email to the address.
  email,

  /// Start a text message to the number.
  sms,

  /// Show the point on a map.
  showOnMap,

  /// Copy the Wi-Fi password on its own.
  copyWifiPassword,

  /// Suggest the network and open the Wi-Fi settings.
  connectWifi,

  /// Save the text into this photo's notes.
  saveToNotes,
}

/// Why an action is offered but cannot be run.
///
/// A reason, not a message: the screen turns it into localised text, so this
/// layer needs no `AppLocalizations` and can be tested on its own.
enum ScanBlockReason {
  /// The scheme is not one the app will ever launch.
  unsupportedScheme,

  /// The address could not be read as a URL at all.
  malformedTarget,

  /// The Wi-Fi code is missing the network name or the password.
  incompleteWifi,

  /// The payload is longer than the app will carry.
  payloadTooLong,
}

/// One action, and whether it may run.
///
/// A blocked action is still returned rather than dropped, so the sheet can
/// show it greyed out with the reason. Hiding it would leave the user
/// wondering why a code they can plainly read does nothing.
class ScanAction {
  final ScanActionType type;

  /// Whether the action can run.
  final bool isAllowed;

  /// Why not, when it cannot.
  final ScanBlockReason? blockReason;

  /// What the action would act on, such as the URL or the phone number.
  ///
  /// Empty when the action is blocked.
  final String target;

  const ScanAction({
    required this.type,
    required this.isAllowed,
    this.blockReason,
    this.target = '',
  });

  /// An action that is ready to run.
  const ScanAction.allowed(this.type, this.target)
    : isAllowed = true,
      blockReason = null;

  /// An action that is shown but cannot run.
  const ScanAction.blocked(this.type, ScanBlockReason reason)
    : isAllowed = false,
      blockReason = reason,
      target = '';

  @override
  bool operator ==(Object other) {
    return other is ScanAction &&
        other.type == type &&
        other.isAllowed == isAllowed &&
        other.blockReason == blockReason &&
        other.target == target;
  }

  @override
  int get hashCode => Object.hash(type, isAllowed, blockReason, target);

  @override
  String toString() => 'ScanAction(${type.name}, allowed: $isAllowed)';
}
