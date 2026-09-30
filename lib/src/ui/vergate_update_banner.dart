import 'package:flutter/material.dart';

import 'vergate_strings.dart';
import 'vergate_theme.dart';

/// A compact, non-blocking banner announcing an optional update.
///
/// Tapping the banner triggers [onUpdate]. The close button (shown only
/// when [onDismiss] is provided) is meant to snooze the update.
class VergateUpdateBanner extends StatelessWidget {
  /// Creates an update banner.
  const VergateUpdateBanner({
    super.key,
    required this.onUpdate,
    this.onDismiss,
    this.strings = const VergateStrings(),
    this.theme = const VergateTheme(),
  });

  /// Called when the banner or its action is tapped.
  final VoidCallback onUpdate;

  /// Called when the close button is tapped. Hides the button when `null`.
  final VoidCallback? onDismiss;

  /// Texts to display.
  final VergateStrings strings;

  /// Visual customization.
  final VergateTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme.resolve(context);
    final radius = BorderRadius.circular(t.cornerRadius * 0.6);
    final hasClose = onDismiss != null;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: t.bannerColor,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onUpdate,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              hasClose ? 4 : 14,
              hasClose ? 4 : 16,
              hasClose ? 4 : 14,
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: t.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.bannerTitle,
                    style: t.messageStyle.copyWith(
                      color: t.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  strings.bannerAction,
                  style: t.messageStyle.copyWith(
                    color: t.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hasClose)
                  // No tooltip on purpose: tooltips need an Overlay, which
                  // does not exist above the Navigator.
                  Semantics(
                    button: true,
                    label: strings.dismissLabel,
                    child: IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close, size: 20),
                      color: t.secondaryTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
