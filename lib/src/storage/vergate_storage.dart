import 'package:shared_preferences/shared_preferences.dart';

/// A minimal key-value store used to remember the user's choices
/// (snooze and skip) between app launches.
///
/// Implement this if you prefer another persistence layer such as
/// Hive, Isar or secure storage.
abstract interface class VergateStorage {
  /// Reads the value stored under [key], or `null` if there is none.
  Future<String?> read(String key);

  /// Stores [value] under [key]. A `null` [value] removes the key.
  Future<void> write(String key, String? value);
}

/// The default storage, backed by `shared_preferences`.
class SharedPreferencesStorage implements VergateStorage {
  /// Creates a storage that prefixes every key with [keyPrefix]
  /// to avoid clashes with the host app's own keys.
  SharedPreferencesStorage({this.keyPrefix = 'vergate.'});

  /// Prefix added to every key.
  final String keyPrefix;

  Future<SharedPreferences>? _instance;

  // Created lazily so that constructing the storage never does I/O.
  Future<SharedPreferences> get _prefs =>
      _instance ??= SharedPreferences.getInstance();

  @override
  Future<String?> read(String key) async {
    final prefs = await _prefs;
    return prefs.getString('$keyPrefix$key');
  }

  @override
  Future<void> write(String key, String? value) async {
    final prefs = await _prefs;
    if (value == null) {
      await prefs.remove('$keyPrefix$key');
    } else {
      await prefs.setString('$keyPrefix$key', value);
    }
  }
}

/// A non-persistent storage. Useful for tests or if you do not want
/// snooze and skip to survive an app restart.
class MemoryStorage implements VergateStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }
}
