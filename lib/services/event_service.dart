import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Beschreibt ein einzelnes Spiel-Event.
class GameEvent {
  final String id;
  final String title;
  final String description;
  final DateTime endDate;
  final int requiredCount;
  final int rewardCoins;
  final int rewardLootboxes;

  const GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.endDate,
    required this.requiredCount,
    required this.rewardCoins,
    required this.rewardLootboxes,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
}

/// Service der Events und deren Fortschritt verwaltet.
class EventService extends ChangeNotifier {
  static const _prefPrefix = 'event_';

  /// Alle definierten Events (unveränderlich)
  static final List<GameEvent> allEvents = [
    GameEvent(
      id: 'kirchensegen_april_2026',
      title: 'Kirchensegen-Sammler',
      description:
          'Sammle 5 Kirchensegen-Tokens bis Ende April 2026 '
          'und erhalte eine besondere Belohnung!',
      endDate: DateTime(2026, 4, 30, 23, 59, 59),
      requiredCount: 5,
      rewardCoins: 2500,
      rewardLootboxes: 5,
    ),
  ];

  // Gesammelte Kirchensegen-Tokens pro Event (global, kirchenunabhängig).
  final Map<String, int> _collectedCounts = {};
  final Map<String, bool> _rewardClaimed = {};

  EventService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final event in allEvents) {
      final countKey = '${_prefPrefix}${event.id}_count';
      final legacyCollectedKey = '${_prefPrefix}${event.id}_collected';

      final storedCount = prefs.getInt(countKey);
      if (storedCount != null) {
        _collectedCounts[event.id] = storedCount;
      } else {
        // Migration: Alte Speicherung war eine Liste einzigartiger Landmark-IDs.
        final legacyRaw = prefs.getStringList(legacyCollectedKey) ?? [];
        _collectedCounts[event.id] = legacyRaw.toSet().length;
      }
      _rewardClaimed[event.id] =
          prefs.getBool('${_prefPrefix}${event.id}_claimed') ?? false;
    }
    notifyListeners();
  }

  /// Anzahl gesammelter Church-Tokens für ein Event.
  int collectedCount(String eventId) => _collectedCounts[eventId] ?? 0;

  /// Ob das Event bereits abgeschlossen und der Reward abgeholt wurde.
  bool rewardClaimed(String eventId) => _rewardClaimed[eventId] ?? false;

  /// Kompatibilitätsmethode: gibt zurück, ob bereits mindestens ein
  /// Kirchensegen für dieses Event gesammelt wurde.
  bool hasCollectedChurch(String eventId, String landmarkId) =>
      collectedCount(eventId) > 0;

  /// Wird aufgerufen wenn ein Kirchensegen-Token gesammelt wurde.
  /// Jeder Kirchensegen zählt, unabhängig davon bei welcher Kirche er gesammelt wurde.
  Future<bool> recordChurchCollected(String landmarkId) async {
    var changed = false;
    final prefs = await SharedPreferences.getInstance();

    for (final event in allEvents) {
      if (event.isExpired) continue;
      final nextCount = (_collectedCounts[event.id] ?? 0) + 1;
      _collectedCounts[event.id] = nextCount;
      await prefs.setInt('${_prefPrefix}${event.id}_count', nextCount);
      changed = true;
    }

    if (changed) notifyListeners();
    return changed;
  }

  /// Prüft ob ein Event abgeschlossen ist (Fortschritt erreicht) aber der
  /// Reward noch nicht abgeholt wurde. Gibt Event zurück oder null.
  GameEvent? pendingReward() {
    for (final event in allEvents) {
      if (event.isExpired) continue;
      if (rewardClaimed(event.id)) continue;
      if (collectedCount(event.id) >= event.requiredCount) return event;
    }
    return null;
  }

  /// Markiert den Reward eines Events als abgeholt.
  Future<void> claimReward(String eventId) async {
    _rewardClaimed[eventId] = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefPrefix}${eventId}_claimed', true);
    notifyListeners();
  }
}
