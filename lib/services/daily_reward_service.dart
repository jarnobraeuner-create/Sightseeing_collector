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
  final int day; // 1–7 (Streak-Tag)
  final String label;
  final DailyRewardType type;
  final String emoji;
  final String description;

  const DailyReward({
    required this.day,
    required this.label,
    required this.type,
    required this.emoji,
    required this.description,
  });
}

class DailyRewardService extends ChangeNotifier {
  static const _prefKeyDate = 'last_daily_reward_date';
  static const _prefKeyDay  = 'daily_reward_streak_day';

  static const List<DailyReward> rewards = [
    DailyReward(day: 1, label: 'Tag 1', type: DailyRewardType.lootbox,            emoji: '🎁', description: '1 Lootbox'),
    DailyReward(day: 2, label: 'Tag 2', type: DailyRewardType.coins100,           emoji: '🪙', description: '100 Coins'),
    DailyReward(day: 3, label: 'Tag 3', type: DailyRewardType.lootbox,            emoji: '🎁', description: '1 Lootbox'),
    DailyReward(day: 4, label: 'Tag 4', type: DailyRewardType.coins200,           emoji: '🪙', description: '200 Coins'),
    DailyReward(day: 5, label: 'Tag 5', type: DailyRewardType.cooldownSkip,       emoji: '⏭️', description: 'Cooldown Skip'),
    DailyReward(day: 6, label: 'Tag 6', type: DailyRewardType.coins300,           emoji: '🪙', description: '300 Coins'),
    DailyReward(day: 7, label: 'Tag 7', type: DailyRewardType.lootboxSilverPlus,  emoji: '✨', description: 'Lootbox (min. Silber)'),
  ];

  bool _claimedToday = false;
  bool get claimedToday => _claimedToday;

  int _currentDay = 1; // 1–7
  int get currentDay => _currentDay;

  /// True if the popup should be shown (first open of the day, not yet claimed).
  bool _shouldShowPopup = false;
  bool get shouldShowPopup => _shouldShowPopup;

  DailyRewardService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_prefKeyDate);
    final todayStr = _todayStr();
    _currentDay  = prefs.getInt(_prefKeyDay) ?? 1;
    _claimedToday = lastDate == todayStr;
    _shouldShowPopup = !_claimedToday;
    notifyListeners();
  }

  DailyReward get todaysReward =>
      rewards.firstWhere((r) => r.day == _currentDay);

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Call after the player has received the reward.
  /// Advances the streak day (wraps 7 → 1).
  Future<void> markClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyDate, _todayStr());
    final nextDay = (_currentDay % 7) + 1;
    await prefs.setInt(_prefKeyDay, nextDay);
    _claimedToday = true;
    _shouldShowPopup = false;
    notifyListeners();
  }

  /// Dismisses popup without claiming (e.g. user closes dialog without tapping).
  void dismissPopup() {
    _shouldShowPopup = false;
    notifyListeners();
  }

  /// Dev: reset so popup shows again from day 1.
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyDate);
    await prefs.remove(_prefKeyDay);
    _currentDay = 1;
    _claimedToday = false;
    _shouldShowPopup = true;
    notifyListeners();
  }
}
