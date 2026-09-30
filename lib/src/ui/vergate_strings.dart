/// All user-facing texts of Vergate.
///
/// Every field has an English default, so you only override what you need:
/// ```dart
/// const VergateStrings(updateNow: 'Get the update')
/// ```
///
/// For localized apps, pass a `stringsBuilder` to `VergateGate` and fill
/// this class from your own localization system.
///
/// The `{version}` placeholder in [softUpdateMessage] and
/// [forceUpdateMessage] is replaced with the latest version number.
class VergateStrings {
  /// Creates a set of texts. Omitted fields use the English defaults.
  const VergateStrings({
    this.updateTitle = 'New version available',
    this.forceUpdateMessage =
        "We've made improvements to the app. Please update to continue "
        'using it.',
    this.softUpdateMessage =
        'Version {version} is now available. Update to get the latest '
        'features and fixes.',
    this.updateNow = 'Update Now',
    this.remindLater = 'Remind me later',
    this.skipVersion = 'Skip this version',
    this.whatsNew = "What's new",
    this.bannerTitle = 'New version available',
    this.bannerAction = 'Update',
    this.dismissLabel = 'Dismiss',
    this.maintenanceTitle = 'Under maintenance',
    this.maintenanceMessage =
        'The app is currently undergoing maintenance. Thank you for your '
        'patience. Please check later.',
    this.maintenanceCountdownLabel = 'Estimated time remaining',
    this.daysSuffix = 'd',
  });

  /// Title of the update card.
  final String updateTitle;

  /// Body of the update card when the update is mandatory.
  final String forceUpdateMessage;

  /// Body of the update card when the update is optional.
  final String softUpdateMessage;

  /// Label of the primary button that opens the store.
  final String updateNow;

  /// Label of the button that snoozes a soft update.
  final String remindLater;

  /// Label of the button that skips the offered version.
  final String skipVersion;

  /// Heading above the release notes list.
  final String whatsNew;

  /// Text of the soft update banner.
  final String bannerTitle;

  /// Action label on the soft update banner.
  final String bannerAction;

  /// Accessibility label of the banner's close button.
  final String dismissLabel;

  /// Title of the maintenance screen.
  final String maintenanceTitle;

  /// Default body of the maintenance screen, used when the remote config
  /// does not provide its own message.
  final String maintenanceMessage;

  /// Label shown above the maintenance countdown.
  final String maintenanceCountdownLabel;

  /// Short suffix for days in the countdown, for example `2d 03:15:00`.
  final String daysSuffix;

  /// Fills the `{version}` placeholder in [template].
  String format(String template, {String? version}) =>
      template.replaceAll('{version}', version ?? '');
}
