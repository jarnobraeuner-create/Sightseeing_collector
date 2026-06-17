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
  final List<String> landmarkIds;
  final String tokenImageUrl;
  final DateTime startDate;

  const GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.requiredCount,
    required this.rewardCoins,
    required this.rewardLootboxes,
    this.landmarkIds = const [],
    this.tokenImageUrl = 'assets/images/Kirche_default_token.png',
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isNotStarted => DateTime.now().isBefore(startDate);
  bool get isActive => !isExpired && !isNotStarted;
}

/// Service der Events und deren Fortschritt verwaltet.
class EventService extends ChangeNotifier {
  static const _prefPrefix = 'event_';

  /// Alle definierten Events (unveränderlich)
  static final List<GameEvent> allEvents = [
    GameEvent(
      id: 'seen_juni_2026',
      title: 'Seeblick-Sammler',
      description:
          'Besuche 3 Seen und Gewässer bis Ende Juni 2026 '
          'und erhalte eine besondere Belohnung!',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30, 23, 59, 59),
      requiredCount: 3,
      rewardCoins: 2000,
      rewardLootboxes: 3,
      landmarkIds: [],
    ),
    GameEvent(
      id: 'parks_juli_2026',
      title: 'Parkläufer',
      description:
          'Besuche 4 Parks und Grünanlagen bis Ende Juli 2026 '
          'und erhalte eine besondere Belohnung!',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31, 23, 59, 59),
      requiredCount: 4,
      rewardCoins: 2500,
      rewardLootboxes: 4,
      landmarkIds: ['14', '15'],
    ),
    GameEvent(
      id: 'bruecken_august_2026',
      title: 'Brückenbauer',
      description:
          'Besuche 3 Brücken bis Ende August 2026 '
          'und erhalte eine besondere Belohnung!',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31, 23, 59, 59),
      requiredCount: 3,
      rewardCoins: 2000,
      rewardLootboxes: 3,
      landmarkIds: [],
    ),
  ];

  // Gesammelte Token-Counts pro Event.
  final Map<String, int> _collectedCounts = {};
  final Map<String, bool> _rewardClaimed = {};
  // Besuchte Landmark-IDs pro Event (einmalige Zählung pro Standort).
  final Map<String, Set<String>> _visitedLandmarks = {};

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
      _visitedLandmarks[event.id] =
          (prefs.getStringList('${_prefPrefix}${event.id}_visited') ?? []).toSet();
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
      if (!event.isActive) continue;
      // Neue Events (mit landmarkIds) werden über recordEventLandmarkCollected gezählt
      if (event.landmarkIds.isNotEmpty) continue;
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

  /// Prüft ob ein Landmark bereits für ein Event besucht wurde.
  bool hasLandmarkBeenVisited(String eventId, String landmarkId) {
    return _visitedLandmarks[eventId]?.contains(landmarkId) ?? false;
  }

  /// Zählt den Besuch eines Standorts für ein Event.
  /// Jeder Standort wird nur einmal pro Event gezählt.
  Future<bool> recordEventLandmarkCollected(
      String eventId, String landmarkId) async {
    final eventIndex = allEvents.indexWhere((e) => e.id == eventId);
    if (eventIndex < 0) return false;
    final event = allEvents[eventIndex];
    if (!event.isActive) return false;

    final visited = _visitedLandmarks[eventId] ?? <String>{};
    if (visited.contains(landmarkId)) return false;

    visited.add(landmarkId);
    _visitedLandmarks[eventId] = visited;
    final nextCount = (_collectedCounts[eventId] ?? 0) + 1;
    _collectedCounts[eventId] = nextCount;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_prefPrefix}${eventId}_count', nextCount);
    await prefs.setStringList(
        '${_prefPrefix}${eventId}_visited', visited.toList());
    notifyListeners();
    return true;
  }
}
