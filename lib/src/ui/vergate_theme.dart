import 'package:flutter/material.dart';

/// Visual customization for every Vergate widget.
///
/// Every color and style is optional. Missing values are derived from the
/// surrounding Material [Theme], so the defaults already follow your app
/// (including dark mode).
class VergateTheme {
  /// Creates a theme. All parameters are optional.
  const VergateTheme({
    this.primaryColor,
    this.onPrimaryColor,
    this.surfaceColor,
    this.backgroundColor,
    this.barrierColor,
    this.textColor,
    this.secondaryTextColor,
    this.bannerColor,
    this.titleStyle,
    this.messageStyle,
    this.buttonTextStyle,
    this.updateIcon,
    this.maintenanceIcon,
    this.cornerRadius = 24,
    this.buttonRadius = 100,
    this.maxWidth = 400,
    this.cardPadding = const EdgeInsets.all(24),
    this.animationDuration = const Duration(milliseconds: 250),
  });

  /// Main accent: primary button, links, default icons.
  final Color? primaryColor;

  /// Content color on top of [primaryColor] (button text).
  final Color? onPrimaryColor;

  /// Background of cards.
  final Color? surfaceColor;

  /// Full-screen background of the maintenance screen.
  final Color? backgroundColor;

  /// Dimming color behind the update dialog.
  final Color? barrierColor;

  /// Color of titles and primary text.
  final Color? textColor;

  /// Color of descriptions and secondary buttons.
  final Color? secondaryTextColor;

  /// Background of the soft update banner.
  final Color? bannerColor;

  /// Style of card titles.
  final TextStyle? titleStyle;

  /// Style of card descriptions.
  final TextStyle? messageStyle;

  /// Style of the primary button label.
  final TextStyle? buttonTextStyle;

  /// Icon on top of the update card. Replace it with your own logo.
  final Widget? updateIcon;

  /// Icon on top of the maintenance card.
  final Widget? maintenanceIcon;

  /// Corner radius of cards.
  final double cornerRadius;

  /// Corner radius of buttons. The default gives pill-shaped buttons.
  final double buttonRadius;

  /// Maximum width of cards, keeps them tidy on tablets.
  final double maxWidth;

  /// Inner padding of cards.
  final EdgeInsetsGeometry cardPadding;

  /// Duration of the fade animation when overlays appear or disappear.
  final Duration animationDuration;

  /// Fills every missing value using the Material theme found in [context].
  VergateResolvedTheme resolve(BuildContext context) {
    final material = Theme.of(context);
    final scheme = material.colorScheme;
    final textTheme = material.textTheme;

    final primary = primaryColor ?? scheme.primary;
    final surface = surfaceColor ?? scheme.surface;
    final onSurface = textColor ?? scheme.onSurface;
    final onSurfaceVariant = secondaryTextColor ?? scheme.onSurfaceVariant;

    return VergateResolvedTheme(
      primaryColor: primary,
      onPrimaryColor: onPrimaryColor ?? scheme.onPrimary,
      surfaceColor: surface,
      backgroundColor: backgroundColor ?? scheme.surfaceContainerLow,
      barrierColor: barrierColor ?? Colors.black54,
      textColor: onSurface,
      secondaryTextColor: onSurfaceVariant,
      bannerColor:
          bannerColor ?? Color.alphaBlend(primary.withAlpha(36), surface),
      titleStyle:
          titleStyle ??
          (textTheme.titleLarge ?? const TextStyle(fontSize: 22)).copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
      messageStyle:
          messageStyle ??
          (textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(
            color: onSurfaceVariant,
            height: 1.4,
          ),
      buttonTextStyle:
          buttonTextStyle ??
          (textTheme.labelLarge ?? const TextStyle()).copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
      updateIcon:
          updateIcon ??
          Icon(Icons.system_update_rounded, size: 48, color: primary),
      maintenanceIcon:
          maintenanceIcon ??
          Icon(Icons.construction_rounded, size: 48, color: primary),
      cornerRadius: cornerRadius,
      buttonRadius: buttonRadius,
      maxWidth: maxWidth,
      cardPadding: cardPadding,
      animationDuration: animationDuration,
    );
  }
}

/// A [VergateTheme] where every value is guaranteed to be set.
///
/// Obtain it with [VergateTheme.resolve]. Useful inside custom builders
/// when you want to reuse the same colors and styles.
class VergateResolvedTheme {
  /// Creates a fully resolved theme. Prefer [VergateTheme.resolve].
  const VergateResolvedTheme({
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.surfaceColor,
    required this.backgroundColor,
    required this.barrierColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.bannerColor,
    required this.titleStyle,
    required this.messageStyle,
    required this.buttonTextStyle,
    required this.updateIcon,
    required this.maintenanceIcon,
    required this.cornerRadius,
    required this.buttonRadius,
    required this.maxWidth,
    required this.cardPadding,
    required this.animationDuration,
  });

  /// See [VergateTheme.primaryColor].
  final Color primaryColor;

  /// See [VergateTheme.onPrimaryColor].
  final Color onPrimaryColor;

  /// See [VergateTheme.surfaceColor].
  final Color surfaceColor;

  /// See [VergateTheme.backgroundColor].
  final Color backgroundColor;

  /// See [VergateTheme.barrierColor].
  final Color barrierColor;

  /// See [VergateTheme.textColor].
  final Color textColor;

  /// See [VergateTheme.secondaryTextColor].
  final Color secondaryTextColor;

  /// See [VergateTheme.bannerColor].
  final Color bannerColor;

  /// See [VergateTheme.titleStyle].
  final TextStyle titleStyle;

  /// See [VergateTheme.messageStyle].
  final TextStyle messageStyle;

  /// See [VergateTheme.buttonTextStyle].
  final TextStyle buttonTextStyle;

  /// See [VergateTheme.updateIcon].
  final Widget updateIcon;

  /// See [VergateTheme.maintenanceIcon].
  final Widget maintenanceIcon;

  /// See [VergateTheme.cornerRadius].
  final double cornerRadius;

  /// See [VergateTheme.buttonRadius].
  final double buttonRadius;

  /// See [VergateTheme.maxWidth].
  final double maxWidth;

  /// See [VergateTheme.cardPadding].
  final EdgeInsetsGeometry cardPadding;

  /// See [VergateTheme.animationDuration].
  final Duration animationDuration;
}
