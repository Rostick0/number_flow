import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// JSON key-value persistence on top of SharedPreferences.
///
/// Writes update the in-memory cache synchronously, so reads right after a
/// write always see the new value even before the disk write completes.
class StorageService {
  StorageService(this._prefs);

  static const profileKey = 'profile_v1';
  static const savedGameKey = 'saved_game_v1';
  static const adsStateKey = 'ads_state_v1';

  final SharedPreferences _prefs;

  static Future<StorageService> open() async =>
      StorageService(await SharedPreferences.getInstance());

  Map<String, dynamic>? readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException catch (e) {
      debugPrint('Corrupted "$key" ignored: $e');
    }
    return null;
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);
}

/// Overridden in `main()` with an opened instance.
final storageProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('storageProvider must be overridden'),
);
