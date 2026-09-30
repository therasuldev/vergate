import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_version.dart';
import '../core/platform_detector.dart';
import '../core/vergate_evaluator.dart';
import '../models/vergate_config.dart';
import '../models/vergate_platform.dart';
import '../models/vergate_status.dart';
import '../sources/vergate_source.dart';
import '../storage/vergate_storage.dart';

/// Returns the version of the installed app.
typedef VergateVersionProvider = Future<AppVersion> Function();

/// Opens [url] and returns whether it succeeded.
typedef VergateUrlOpener = Future<bool> Function(Uri url);

/// Coordinates the whole version check flow:
///
/// 1. Loads the remote config from a [VergateSource].
/// 2. Evaluates it against the installed version.
/// 3. Applies the user's snooze / skip choices to soft updates.
/// 4. Re-checks automatically when the app returns to the foreground.
///
/// The controller has no UI. Listen to it and read [status]:
/// ```dart
/// final controller = VergateController(source: source);
/// await controller.start();
/// ```
class VergateController extends ChangeNotifier with WidgetsBindingObserver {
  /// Creates a controller.
  ///
  /// Only [_source] is required. Everything else has a sensible default
  /// and can be replaced, mainly to make testing easy.
  VergateController({
    required this._source,
    this.snoozeDuration = const Duration(hours: 24),
    this.resumeCheckInterval = const Duration(minutes: 15),
    this.onError,
    VergatePlatform? platform,
    VergateVersionProvider? versionProvider,
    VergateStorage? storage,
    VergateUrlOpener? urlOpener,
    DateTime Function()? clock,
  }) : _platform = platform ?? detectVergatePlatform(),
       _versionProvider = versionProvider ?? _defaultVersionProvider,
       _storage = storage ?? SharedPreferencesStorage(),
       _urlOpener = urlOpener ?? _defaultUrlOpener,
       _clock = clock ?? DateTime.now;

  static const String _snoozeKey = 'snoozed_until';
  static const String _skipKey = 'skipped_version';

  /// How long "Remind me later" hides a soft update by default.
  final Duration snoozeDuration;

  /// Minimum time between two network checks caused by app resume.
  ///
  /// While the status is blocking (force update or maintenance) this
  /// is ignored and every resume triggers a fresh check.
  final Duration resumeCheckInterval;

  /// Called when a check fails. Use it to log to Crashlytics or Sentry.
  /// The user is never blocked by such errors.
  final void Function(Object error, StackTrace stackTrace)? onError;

  final VergateSource _source;
  final VergatePlatform _platform;
  final VergateVersionProvider _versionProvider;
  final VergateStorage _storage;
  final VergateUrlOpener _urlOpener;
  final DateTime Function() _clock;

  VergateConfig? _config;
  AppVersion? _currentVersion;
  VergateStatus _rawStatus = const VergateUpToDate();
  VergateStatus? _debugOverride;
  DateTime? _lastFetchAt;
  Object? _lastError;
  bool _isChecking = false;
  bool _observing = false;
  bool _disposed = false;

  Future<void>? _inFlight;
  Future<void>? _choicesLoading;
  DateTime? _snoozedUntil;
  AppVersion? _skippedVersion;

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------

  /// The status the UI should react to.
  ///
  /// This is the evaluated status with the user's snooze / skip choices
  /// applied. Force updates and maintenance are never hidden.
  VergateStatus get status {
    final override = _debugOverride;
    if (override != null) return override;
    return _applyUserChoices(_rawStatus);
  }

  /// Whether a check is currently running.
  bool get isChecking => _isChecking;

  /// Whether at least one check has completed successfully.
  bool get hasChecked => _lastFetchAt != null;

  /// The error of the last failed check, or `null` if it succeeded.
  Object? get lastError => _lastError;

  /// The installed app version, available after the first check.
  AppVersion? get currentVersion => _currentVersion;

  /// The last successfully loaded remote configuration.
  VergateConfig? get config => _config;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Runs the first check and starts observing app lifecycle changes.
  ///
  /// Safe to call more than once.
  Future<void> start() {
    if (!_observing) {
      _observing = true;
      WidgetsFlutterBinding.ensureInitialized();
      WidgetsBinding.instance.addObserver(this);
    }
    return check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final lastFetch = _lastFetchAt;
    final isStale =
        lastFetch == null ||
        _now().difference(lastFetch) >= resumeCheckInterval;

    if (isStale || _isBlocking(_rawStatus)) {
      unawaited(check());
    } else {
      // No network needed: time-based rules (maintenance window,
      // snooze expiry) may have changed, so just re-evaluate.
      _reevaluate();
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Checking
  // ---------------------------------------------------------------------------

  /// Fetches the remote config and updates [status].
  ///
  /// Calls made while a check is running share the same request.
  /// This method never throws; failures are reported through [onError]
  /// and [lastError], and the user is not blocked.
  Future<void> check() {
    return _inFlight ??= _runCheck().whenComplete(() => _inFlight = null);
  }

  Future<void> _runCheck() async {
    _isChecking = true;
    _notify();

    try {
      await _loadUserChoices();

      final config = await _source.fetch();
      _currentVersion ??= await _versionProvider();

      _config = config;
      _lastFetchAt = _now();
      _lastError = null;
      _reevaluate();
    } catch (error, stackTrace) {
      // Fail-open: keep the previous config (if any) and never block
      // the user because of a network or parsing problem.
      _lastError = error;
      onError?.call(error, stackTrace);
    } finally {
      _isChecking = false;
      _notify();
    }
  }

  /// Recomputes [_rawStatus] from the cached config without any I/O.
  void _reevaluate() {
    final config = _config;
    final version = _currentVersion;
    if (config == null || version == null) return;

    _rawStatus = VergateEvaluator.evaluate(
      config: config,
      currentVersion: version,
      platform: _platform,
      now: _now(),
    );
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  /// Hides the soft update for [duration] (defaults to [snoozeDuration]).
  ///
  /// Has no effect on force updates or maintenance.
  Future<void> snooze([Duration? duration]) async {
    await _loadUserChoices();

    final until = _now().add(duration ?? snoozeDuration);
    _snoozedUntil = until;
    _notify();

    await _write(_snoozeKey, until.toUtc().millisecondsSinceEpoch.toString());
  }

  /// Hides the currently offered soft update until a newer version appears.
  ///
  /// Does nothing if there is no soft update to skip.
  Future<void> skipVersion() async {
    final current = _rawStatus;
    if (current is! VergateSoftUpdate || current.latestVersion == null) return;
    await _loadUserChoices();

    final version = current.latestVersion!;
    _skippedVersion = version;
    _notify();

    await _write(_skipKey, version.toString());
  }

  /// Clears any saved snooze and skip choices.
  Future<void> resetUserChoices() async {
    await _loadUserChoices();

    _snoozedUntil = null;
    _skippedVersion = null;
    _notify();

    await _write(_snoozeKey, null);
    await _write(_skipKey, null);
  }

  /// Opens the store page of the current update status.
  ///
  /// Returns `false` if there is no store URL or it could not be opened.
  Future<bool> openStore() async {
    final status = _debugOverride ?? _rawStatus;
    if (status is! VergateUpdateStatus) return false;

    final url = status.storeUrl == null ? null : Uri.tryParse(status.storeUrl!);
    if (url == null) return false;

    try {
      return await _urlOpener(url);
    } catch (_) {
      return false;
    }
  }

  /// Forces [status] to a given value to preview your UI.
  ///
  /// Works in debug mode only and is ignored in release builds.
  /// Pass `null` to remove the override.
  void debugOverrideStatus(VergateStatus? status) {
    if (!kDebugMode) return;
    _debugOverride = status;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DateTime _now() => _clock();

  bool _isBlocking(VergateStatus status) =>
      status is VergateForceUpdate || status is VergateUnderMaintenance;

  /// Hides soft updates that the user snoozed or skipped.
  VergateStatus _applyUserChoices(VergateStatus raw) {
    if (raw is! VergateSoftUpdate) return raw;

    final snoozedUntil = _snoozedUntil;
    if (snoozedUntil != null && _now().isBefore(snoozedUntil)) {
      return const VergateUpToDate();
    }

    final skipped = _skippedVersion;
    final latest = raw.latestVersion;
    if (skipped != null && latest != null && latest <= skipped) {
      return const VergateUpToDate();
    }

    return raw;
  }

  /// Loads saved choices once. The future is memoized so that concurrent
  /// callers wait for the same read.
  Future<void> _loadUserChoices() => _choicesLoading ??= _readUserChoices();

  Future<void> _readUserChoices() async {
    final snoozeMillis = int.tryParse(await _read(_snoozeKey) ?? '');
    _snoozedUntil = snoozeMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(snoozeMillis, isUtc: true);
    _skippedVersion = AppVersion.tryParse(await _read(_skipKey));
  }

  // Storage problems must never crash the host app.
  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, String? value) async {
    try {
      await _storage.write(key, value);
    } catch (_) {
      // Ignored on purpose: the choice still applies for this session.
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static Future<AppVersion> _defaultVersionProvider() async {
    final info = await PackageInfo.fromPlatform();
    final version = AppVersion.parse(info.version);
    final build = int.tryParse(info.buildNumber) ?? 0;
    return AppVersion(version.major, version.minor, version.patch, build);
  }

  static Future<bool> _defaultUrlOpener(Uri url) {
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
