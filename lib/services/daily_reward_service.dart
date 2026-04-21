import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DailyRewardType {
  lootbox,
  coins100,
  coins200,
  coins300,
  cooldownSkip,
  lootboxSilverPlus,
}

class DailyReward {
  final int weekday; // 1 = Mo, 7 = So
  final String label;
  final DailyRewardType type;
  final String emoji;
  final String description;

  const DailyReward({
    required this.weekday,
    required this.label,
    required this.type,
    required this.emoji,
    required this.description,
  });
}

class DailyRewardService extends ChangeNotifier {
  static const _prefKey = 'last_daily_reward_date';

  static const List<DailyReward> rewards = [
    DailyReward(weekday: 1, label: 'Mo', type: DailyRewardType.lootbox,         emoji: '🎁', description: '1 Lootbox'),
    DailyReward(weekday: 2, label: 'Di', type: DailyRewardType.coins100,        emoji: '🪙', description: '100 Coins'),
    DailyReward(weekday: 3, label: 'Mi', type: DailyRewardType.lootbox,         emoji: '🎁', description: '1 Lootbox'),
    DailyReward(weekday: 4, label: 'Do', type: DailyRewardType.coins200,        emoji: '🪙', description: '200 Coins'),
    DailyReward(weekday: 5, label: 'Fr', type: DailyRewardType.cooldownSkip,    emoji: '⏭️', description: 'Cooldown Skip'),
    DailyReward(weekday: 6, label: 'Sa', type: DailyRewardType.coins300,        emoji: '🪙', description: '300 Coins'),
    DailyReward(weekday: 7, label: 'So', type: DailyRewardType.lootboxSilverPlus, emoji: '✨', description: 'Lootbox (min. Silber)'),
  ];

  bool _claimedToday = false;
  bool get claimedToday => _claimedToday;

  /// True if the popup should be shown (first open of the day, not yet claimed).
  bool _shouldShowPopup = false;
  bool get shouldShowPopup => _shouldShowPopup;

  DailyRewardService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_prefKey);
    final todayStr = _todayStr();
    _claimedToday = lastDate == todayStr;
    _shouldShowPopup = !_claimedToday;
    notifyListeners();
  }

  DailyReward get todaysReward {
    final weekday = DateTime.now().weekday; // 1=Mo ... 7=So
    return rewards.firstWhere((r) => r.weekday == weekday);
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Call after the player has received the reward.
  Future<void> markClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _todayStr());
    _claimedToday = true;
    _shouldShowPopup = false;
    notifyListeners();
  }

  /// Dismisses popup without claiming (e.g. user closes dialog without tapping).
  void dismissPopup() {
    _shouldShowPopup = false;
    notifyListeners();
  }

  /// Dev: reset so popup shows again.
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _claimedToday = false;
    _shouldShowPopup = true;
    notifyListeners();
  }
}
