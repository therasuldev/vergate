import 'package:flutter/material.dart';

import '../controller/vergate_controller.dart';
import '../models/vergate_status.dart';
import 'vergate_maintenance_view.dart';
import 'vergate_strings.dart';
import 'vergate_theme.dart';
import 'vergate_update_banner.dart';
import 'vergate_update_card.dart';

/// How an optional (soft) update is presented.
enum VergateSoftUpdateStyle {
  /// A floating banner. The app stays fully usable. This is the default.
  banner,

  /// A dialog with "update", "remind me later" and "skip" actions.
  dialog,

  /// Nothing is shown. Listen to the controller and build your own UI.
  none,
}

/// Builds a custom screen for a given [status].
///
/// The returned widget is laid out to fill the whole screen, so a
/// `Scaffold` or a `Center` works well. Use [controller] to trigger
/// actions such as `controller.openStore()` or `controller.snooze()`.
typedef VergateStatusBuilder<T extends VergateStatus> = Widget Function(
  BuildContext context,
  T status,
  VergateController controller,
);

/// Builds the texts of the built-in UI from a [BuildContext].
///
/// Use it to connect your own localization system.
typedef VergateStringsBuilder = VergateStrings Function(BuildContext context);

/// Guards the whole app behind the version rules of a [VergateController].
///
/// Place it in `MaterialApp.builder` so it covers every route:
/// ```dart
/// MaterialApp(
///   builder: (context, child) => VergateGate(
///     controller: controller,
///     child: child!,
///   ),
///   home: const HomePage(),
/// );
/// ```
///
/// The gate does not use `showDialog` and needs no `Navigator` or
/// `Overlay`. It draws overlays itself, so it works above the Navigator
/// and never disturbs the state of your routes.
///
/// The gate does not start the controller. Call `controller.start()`
/// yourself, typically in `main()`.
class VergateGate extends StatelessWidget {
  /// Creates a gate around [child].
  ///
  /// Provide either [strings] (fixed texts) or [stringsBuilder]
  /// (context-aware texts), not both. With neither, English is used.
  const VergateGate({
    super.key,
    required this.controller,
    required this.child,
    this.theme = const VergateTheme(),
    this.strings,
    this.stringsBuilder,
    this.softUpdateStyle = VergateSoftUpdateStyle.banner,
    this.bannerAlignment = Alignment.topCenter,
    this.forceUpdateBuilder,
    this.softUpdateBuilder,
    this.maintenanceBuilder,
    this.onUpdateTap,
    this.onLaterTap,
    this.onSkipTap,
  }) : assert(
         strings == null || stringsBuilder == null,
         'Provide either strings or stringsBuilder, not both.',
       );

  /// The controller whose [VergateController.status] drives the gate.
  final VergateController controller;

  /// Your app.
  final Widget child;

  /// Visual customization of the built-in UI.
  final VergateTheme theme;

  /// Fixed texts of the built-in UI. Mutually exclusive with
  /// [stringsBuilder].
  final VergateStrings? strings;

  /// Builds the texts from the current context, for localized apps.
  /// Mutually exclusive with [strings].
  ///
  /// The context sits inside `MaterialApp`, so `AppLocalizations.of`,
  /// `Localizations.localeOf` and `context.tr()` style APIs work.
  final VergateStringsBuilder? stringsBuilder;

  /// How soft updates are presented.
  final VergateSoftUpdateStyle softUpdateStyle;

  /// Where the soft update banner floats.
  final AlignmentGeometry bannerAlignment;

  /// Replaces the built-in force update dialog.
  final VergateStatusBuilder<VergateForceUpdate>? forceUpdateBuilder;

  /// Replaces the built-in soft update banner or dialog.
  final VergateStatusBuilder<VergateSoftUpdate>? softUpdateBuilder;

  /// Replaces the built-in maintenance screen.
  final VergateStatusBuilder<VergateUnderMaintenance>? maintenanceBuilder;

  /// Called when the user taps the update button (for analytics).
  final ValueChanged<VergateUpdateStatus>? onUpdateTap;

  /// Called when the user snoozes a soft update.
  final ValueChanged<VergateSoftUpdate>? onLaterTap;

  /// Called when the user skips a soft update version.
  final ValueChanged<VergateSoftUpdate>? onSkipTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final status = controller.status;
        final resolved = theme.resolve(context);
        final texts =
            strings ?? stringsBuilder?.call(context) ?? const VergateStrings();
        final overlay = _buildOverlay(context, resolved, texts, status);
        final blocking =
            status is VergateForceUpdate || status is VergateUnderMaintenance;

        // The app is always the first Stack child, so its state survives
        // overlays appearing and disappearing.
        return Stack(
          children: [
            Positioned.fill(
              child: TickerMode(
                enabled: !blocking,
                child: ExcludeFocus(
                  excluding: blocking,
                  child: ExcludeSemantics(excluding: blocking, child: child),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: overlay == null,
                child: AnimatedSwitcher(
                  duration: resolved.animationDuration,
                  child:
                      overlay ?? const SizedBox.shrink(key: ValueKey('none')),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Overlays
  // ---------------------------------------------------------------------------

  Widget? _buildOverlay(
    BuildContext context,
    VergateResolvedTheme resolved,
    VergateStrings texts,
    VergateStatus status,
  ) {
    switch (status) {
      case VergateUpToDate():
        return null;
      case VergateForceUpdate s:
        return _forceOverlay(context, resolved, texts, s);
      case VergateSoftUpdate s:
        return _softOverlay(context, resolved, texts, s);
      case VergateUnderMaintenance s:
        return _maintenanceOverlay(context, texts, s);
    }
  }

  Widget _forceOverlay(
    BuildContext context,
    VergateResolvedTheme resolved,
    VergateStrings texts,
    VergateForceUpdate status,
  ) {
    final custom = forceUpdateBuilder;
    if (custom != null) {
      return _layer('force', custom(context, status, controller));
    }

    // No "later" or "skip": a forced update cannot be dismissed.
    return _layer(
      'force',
      _ModalLayer(
        barrierColor: resolved.barrierColor,
        maxWidth: resolved.maxWidth,
        child: VergateUpdateCard(
          status: status,
          strings: texts,
          theme: theme,
          onUpdate: () => _update(status),
        ),
      ),
    );
  }

  Widget? _softOverlay(
    BuildContext context,
    VergateResolvedTheme resolved,
    VergateStrings texts,
    VergateSoftUpdate status,
  ) {
    final custom = softUpdateBuilder;
    if (custom != null) {
      return _layer('soft', custom(context, status, controller));
    }

    switch (softUpdateStyle) {
      case VergateSoftUpdateStyle.none:
        return null;

      case VergateSoftUpdateStyle.banner:
        return _layer(
          'banner',
          SafeArea(
            child: Align(
              alignment: bannerAlignment,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: resolved.maxWidth + 48),
                child: VergateUpdateBanner(
                  strings: texts,
                  theme: theme,
                  onUpdate: () => _update(status),
                  onDismiss: () => _later(status),
                ),
              ),
            ),
          ),
        );

      case VergateSoftUpdateStyle.dialog:
        return _layer(
          'soft',
          _ModalLayer(
            barrierColor: resolved.barrierColor,
            maxWidth: resolved.maxWidth,
            onBarrierTap: () => _later(status),
            child: VergateUpdateCard(
              status: status,
              strings: texts,
              theme: theme,
              onUpdate: () => _update(status),
              onLater: () => _later(status),
              onSkip: status.latestVersion == null ? null : () => _skip(status),
            ),
          ),
        );
    }
  }

  Widget _maintenanceOverlay(
    BuildContext context,
    VergateStrings texts,
    VergateUnderMaintenance status,
  ) {
    final custom = maintenanceBuilder;
    if (custom != null) {
      return _layer('maintenance', custom(context, status, controller));
    }

    return _layer(
      'maintenance',
      VergateMaintenanceView(
        maintenance: status.maintenance,
        strings: texts,
        theme: theme,
        // When the window ends, re-check so the user is let in
        // without restarting the app.
        onCountdownFinished: controller.check,
      ),
    );
  }

  /// Gives an overlay a stable identity, a Material ancestor (needed by
  /// buttons and ink effects) and the full screen as its constraints.
  Widget _layer(String id, Widget content) {
    return KeyedSubtree(
      key: ValueKey(id),
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox.expand(child: content),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _update(VergateUpdateStatus status) async {
    onUpdateTap?.call(status);
    await controller.openStore();
  }

  Future<void> _later(VergateSoftUpdate status) async {
    onLaterTap?.call(status);
    await controller.snooze();
  }

  Future<void> _skip(VergateSoftUpdate status) async {
    onSkipTap?.call(status);
    await controller.skipVersion();
  }
}

/// A dimmed barrier with a centered, scrollable card.
class _ModalLayer extends StatelessWidget {
  const _ModalLayer({
    required this.barrierColor,
    required this.maxWidth,
    required this.child,
    this.onBarrierTap,
  });

  final Color barrierColor;
  final double maxWidth;
  final Widget child;

  /// When `null`, the barrier cannot be dismissed (force update).
  final VoidCallback? onBarrierTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ModalBarrier(
            color: barrierColor,
            dismissible: onBarrierTap != null,
            onDismiss: onBarrierTap,
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
