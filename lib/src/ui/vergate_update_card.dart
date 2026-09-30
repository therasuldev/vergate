import 'package:flutter/material.dart';

import '../models/vergate_status.dart';
import 'vergate_strings.dart';
import 'vergate_theme.dart';

/// The card that announces an available update.
///
/// Used by the gate for both force and soft updates, and public so you
/// can embed it in your own layouts. The secondary buttons appear only
/// when [onLater] / [onSkip] are provided, which is how a force update
/// ends up without any way to dismiss it.
class VergateUpdateCard extends StatelessWidget {
  /// Creates an update card for [status].
  const VergateUpdateCard({
    super.key,
    required this.status,
    required this.onUpdate,
    this.onLater,
    this.onSkip,
    this.strings = const VergateStrings(),
    this.theme = const VergateTheme(),
    this.maxReleaseNotes = 5,
  });

  /// The update this card describes.
  final VergateUpdateStatus status;

  /// Called when the primary button is tapped.
  final VoidCallback onUpdate;

  /// Shows a "remind me later" button when not `null`.
  final VoidCallback? onLater;

  /// Shows a "skip this version" button when not `null`.
  final VoidCallback? onSkip;

  /// Texts to display.
  final VergateStrings strings;

  /// Visual customization.
  final VergateTheme theme;

  /// Maximum number of release notes to show.
  final int maxReleaseNotes;

  @override
  Widget build(BuildContext context) {
    final t = theme.resolve(context);
    final template = status is VergateForceUpdate
        ? strings.forceUpdateMessage
        : strings.softUpdateMessage;
    final message = strings.format(
      template,
      version: status.latestVersion?.toString(),
    );
    final notes = status.releaseNotes.take(maxReleaseNotes).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceColor,
        borderRadius: BorderRadius.circular(t.cornerRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: t.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: t.updateIcon),
            const SizedBox(height: 16),
            Text(
              strings.updateTitle,
              textAlign: TextAlign.center,
              style: t.titleStyle,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: t.messageStyle),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ReleaseNotes(heading: strings.whatsNew, notes: notes, theme: t),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onUpdate,
              style: FilledButton.styleFrom(
                backgroundColor: t.primaryColor,
                foregroundColor: t.onPrimaryColor,
                minimumSize: const Size.fromHeight(52),
                textStyle: t.buttonTextStyle,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(t.buttonRadius),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.updateNow),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
            if (onLater != null)
              _SecondaryButton(
                label: strings.remindLater,
                onPressed: onLater!,
                color: t.secondaryTextColor,
              ),
            if (onSkip != null)
              _SecondaryButton(
                label: strings.skipVersion,
                onPressed: onSkip!,
                color: t.secondaryTextColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: color),
        child: Text(label),
      ),
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes({
    required this.heading,
    required this.notes,
    required this.theme,
  });

  final String heading;
  final List<String> notes;
  final VergateResolvedTheme theme;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = theme.messageStyle.copyWith(fontSize: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: bodyStyle.copyWith(
            color: theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: bodyStyle),
                Expanded(child: Text(note, style: bodyStyle)),
              ],
            ),
          ),
      ],
    );
  }
}
