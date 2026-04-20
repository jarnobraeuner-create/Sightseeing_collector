import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';

class CooldownService extends ChangeNotifier {
  static const String _prefPrefix = 'cooldown_';
  final Map<String, DateTime> _lastCollected = {};

  CooldownService() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefPrefix));
    for (final key in keys) {
      final ms = prefs.getInt(key);
      if (ms != null) {
        final landmarkId = key.substring(_prefPrefix.length);
        _lastCollected[landmarkId] = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
    notifyListeners();
  }

  /// Returns the required cooldown for a given tier.
  /// null means one-time only (platinum).
  Duration? cooldownDuration(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:
        return const Duration(minutes: 10);
      case TokenTier.silver:
        return const Duration(hours: 2);
      case TokenTier.gold:
        return const Duration(hours: 24);
      case TokenTier.platinum:
        return null; // one-time only
    }
  }

  /// Returns true if the landmark can be collected right now.
  bool canCollect(String landmarkId, TokenTier tier) {
    final last = _lastCollected[landmarkId];
    if (last == null) return true; // never collected
    final cooldown = cooldownDuration(tier);
    if (cooldown == null) return false; // platinum: one-time only
    return DateTime.now().difference(last) >= cooldown;
  }

  /// Returns remaining cooldown duration, or null if available.
  Duration? remainingCooldown(String landmarkId, TokenTier tier) {
    if (canCollect(landmarkId, tier)) return null;
    final last = _lastCollected[landmarkId]!;
    final cooldown = cooldownDuration(tier);
    if (cooldown == null) return null; // will be shown as "einmalig"
    final elapsed = DateTime.now().difference(last);
    final remaining = cooldown - elapsed;
    return remaining.isNegative ? null : remaining;
  }

  /// Whether this landmark was ever collected (used for platinum check).
  bool wasEverCollected(String landmarkId) {
    return _lastCollected.containsKey(landmarkId);
  }

  /// Record a collection (called when token is collected OR quick-sold).
  Future<void> recordCollection(String landmarkId) async {
    _lastCollected[landmarkId] = DateTime.now();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_prefPrefix$landmarkId',
      _lastCollected[landmarkId]!.millisecondsSinceEpoch,
    );
  }

  /// Dev-only: Löscht alle Cooldowns (Token-Sammeln + Lootbox).
  Future<void> resetAllCooldowns() async {
    _lastCollected.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefPrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Formats a duration into a human-readable string.
  static String formatDuration(Duration d) {
    if (d.inSeconds < 60) {
      return '${d.inSeconds}s';
    } else if (d.inMinutes < 60) {
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      return s > 0 ? '${m}m ${s}s' : '${m}m';
    } else {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
  }
}
