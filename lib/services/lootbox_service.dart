import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import 'notification_service.dart';

class LootboxService extends ChangeNotifier {
  static const _prefKey       = 'last_lootbox_date';
  static const _prefExtraKey  = 'extra_lootboxes';
  static const _prefMonumentKey = 'monument_lootboxes';

  bool _canOpen = false;
  bool get canOpen => _canOpen;

  int _extraLootboxes = 0;
  int get extraLootboxes => _extraLootboxes;

  int _monumentLootboxes = 0;
  int get monumentLootboxes => _monumentLootboxes;

  /// Total openable: daily free + bought extras
  bool get canOpenAny => _canOpen || _extraLootboxes > 0;

  LootboxService() {
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_prefKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    _canOpen = lastDate != todayStr;
    _extraLootboxes = prefs.getInt(_prefExtraKey) ?? 0;
    _monumentLootboxes = prefs.getInt(_prefMonumentKey) ?? 0;
    notifyListeners();
  }

  /// Adds [count] extra lootboxes to the inventory.
  Future<void> addExtraLootboxes(int count) async {
    final prefs = await SharedPreferences.getInstance();
    _extraLootboxes += count;
    await prefs.setInt(_prefExtraKey, _extraLootboxes);
    notifyListeners();
  }

  /// Adds [count] monument lootboxes to the inventory.
  Future<void> addMonumentLootboxes(int count) async {
    final prefs = await SharedPreferences.getInstance();
    _monumentLootboxes += count;
    await prefs.setInt(_prefMonumentKey, _monumentLootboxes);
    notifyListeners();
  }

  /// Returns the won tier. Probabilities:
  /// Platinum 1%, Gold 10%, Silver 20%, Bronze 69%
  Future<TokenTier> openLootbox() async {
    if (!canOpenAny) throw StateError('No lootboxes available');
    final prefs = await SharedPreferences.getInstance();

    if (_canOpen) {
      // Use the free daily lootbox
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      await prefs.setString(_prefKey, todayStr);
      _canOpen = false;
      NotificationService.instance.scheduleLootboxReady();
    } else {
      // Use an extra lootbox
      _extraLootboxes -= 1;
      await prefs.setInt(_prefExtraKey, _extraLootboxes);
    }
    notifyListeners();

    return _rollTier();
  }

  /// Opens a monument lootbox. Always returns Monumente tier.
  Future<TokenTier> openMonumentLootbox() async {
    if (_monumentLootboxes <= 0) {
      throw StateError('No monument lootboxes available');
    }
    final prefs = await SharedPreferences.getInstance();
    _monumentLootboxes -= 1;
    await prefs.setInt(_prefMonumentKey, _monumentLootboxes);
    notifyListeners();
    return TokenTier.monumente;
  }

  TokenTier _rollTier() {
    final rand = Random().nextDouble() * 100;
    if (rand < 1)  return TokenTier.platinum;
    if (rand < 11) return TokenTier.gold;
    if (rand < 31) return TokenTier.silver;
    return TokenTier.bronze;
  }

  /// Opens a lootbox with guaranteed Silver minimum (for daily reward day 7).
  /// Does NOT use or check any cooldown.
  TokenTier openGuaranteedSilverLootbox() {
    final rand = Random().nextDouble() * 100;
    if (rand < 1)  return TokenTier.platinum;
    if (rand < 11) return TokenTier.gold;
    return TokenTier.silver;
  }

  /// For testing: reset so lootbox can be opened again today
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _canOpen = true;
    notifyListeners();
  }
}
