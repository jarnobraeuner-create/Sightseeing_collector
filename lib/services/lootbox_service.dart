import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import 'notification_service.dart';

class LootboxService extends ChangeNotifier {
  static const _prefKey = 'last_lootbox_date';

  bool _canOpen = false;
  bool get canOpen => _canOpen;

  LootboxService() {
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_prefKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    _canOpen = lastDate != todayStr;
    notifyListeners();
  }

  /// Returns the won tier. Probabilities:
  /// Platinum 1%, Gold 10%, Silver 20%, Bronze 69%
  Future<TokenTier> openLootbox() async {
    if (!_canOpen) throw StateError('Lootbox already opened today');
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString(_prefKey, todayStr);
    _canOpen = false;
    notifyListeners();

    // Benachrichtigung in 24h planen
    NotificationService.instance.scheduleLootboxReady();

    final rand = Random().nextDouble() * 100;
    if (rand < 1) return TokenTier.platinum;
    if (rand < 11) return TokenTier.gold;
    if (rand < 31) return TokenTier.silver;
    return TokenTier.bronze;
  }

  /// For testing: reset so lootbox can be opened again today
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _canOpen = true;
    notifyListeners();
  }
}
