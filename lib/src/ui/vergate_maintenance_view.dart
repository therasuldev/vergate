import 'dart:async';

import 'package:flutter/material.dart';

import '../models/maintenance.dart';
import 'vergate_strings.dart';
import 'vergate_theme.dart';

/// Full-screen page shown while the app is under maintenance.
///
/// If the maintenance has an end time, a live countdown is displayed and
/// [onCountdownFinished] is called once when it reaches zero, so the host
/// can re-check and let the user in automatically.
class VergateMaintenanceView extends StatelessWidget {
  /// Creates a maintenance page.
  const VergateMaintenanceView({
    super.key,
    required this.maintenance,
    this.onCountdownFinished,
    this.strings = const VergateStrings(),
    this.theme = const VergateTheme(),
  });

  /// The active maintenance settings.
  final VergateMaintenance maintenance;

  /// Called once when the countdown reaches zero.
  final VoidCallback? onCountdownFinished;

  /// Texts to display.
  final VergateStrings strings;

  /// Visual customization.
  final VergateTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme.resolve(context);
    final until = maintenance.until;

    return ColoredBox(
      color: t.backgroundColor,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: t.maxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.surfaceColor,
                  borderRadius: BorderRadius.circular(t.cornerRadius),
                ),
                child: Padding(
                  padding: t.cardPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: t.maintenanceIcon),
                      const SizedBox(height: 16),
                      Text(
                        strings.maintenanceTitle,
                        textAlign: TextAlign.center,
                        style: t.titleStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        maintenance.message ?? strings.maintenanceMessage,
                        textAlign: TextAlign.center,
                        style: t.messageStyle,
                      ),
                      if (until != null) ...[
                        const SizedBox(height: 24),
                        _Countdown(
                          until: until,
                          label: strings.maintenanceCountdownLabel,
                          daysSuffix: strings.daysSuffix,
                          labelStyle: t.messageStyle.copyWith(fontSize: 13),
                          timeStyle: t.titleStyle.copyWith(
                            fontSize: 28,
                            color: t.primaryColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          onFinished: onCountdownFinished,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A once-per-second countdown to [until].
class _Countdown extends StatefulWidget {
  const _Countdown({
    required this.until,
    required this.label,
    required this.daysSuffix,
    required this.labelStyle,
    required this.timeStyle,
    this.onFinished,
  });

  final DateTime until;
  final String label;
  final String daysSuffix;
  final TextStyle labelStyle;
  final TextStyle timeStyle;
  final VoidCallback? onFinished;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;
  late Duration _remaining;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(_Countdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.until != widget.until) {
      _finished = false;
      _start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _computeRemaining() {
    final left = widget.until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _start() {
    _timer?.cancel();
    _remaining = _computeRemaining();

    if (_remaining == Duration.zero) {
      _finish();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() => _remaining = _computeRemaining());
    if (_remaining == Duration.zero) {
      _timer?.cancel();
      _finish();
    }
  }

  /// Notifies the host once, after the current frame, because the callback
  /// may trigger a rebuild and must not run while widgets are building.
  void _finish() {
    if (_finished) return;
    _finished = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFinished?.call();
    });
  }

  /// Formats as `HH:MM:SS`, prefixed with days when longer than 24 hours.
  String _format(Duration duration) {
    // Round up so the display shows 00:00:01 until the very last moment.
    final total = (duration.inMilliseconds / 1000).ceil();
    final days = total ~/ 86400;
    final hours = (total % 86400) ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;

    String two(int value) => value.toString().padLeft(2, '0');
    final time = '${two(hours)}:${two(minutes)}:${two(seconds)}';
    return days > 0 ? '$days${widget.daysSuffix} $time' : time;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.label, style: widget.labelStyle),
        const SizedBox(height: 4),
        Text(_format(_remaining), style: widget.timeStyle),
      ],
    );
  }
}
