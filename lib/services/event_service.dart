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
          'Sammle 5 verschiedene Kirchensegen-Tokens bis Ende April 2026 '
          'und erhalte eine besondere Belohnung!',
      endDate: DateTime(2026, 4, 30, 23, 59, 59),
      requiredCount: 5,
      rewardCoins: 2500,
      rewardLootboxes: 5,
    ),
  ];

  // landmarkId-Set der gesammelten Kirchensegen-IDs (z.B. '4', '10', …)
  // Wir speichern die Landmark-ID ohne '_church'-Suffix.
  final Map<String, Set<String>> _collectedIds = {};
  final Map<String, bool> _rewardClaimed = {};

  EventService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final event in allEvents) {
      final raw = prefs.getStringList('${_prefPrefix}${event.id}_collected') ?? [];
      _collectedIds[event.id] = raw.toSet();
      _rewardClaimed[event.id] =
          prefs.getBool('${_prefPrefix}${event.id}_claimed') ?? false;
    }
    notifyListeners();
  }

  /// Anzahl gesammelter eindeutiger Church-Tokens für ein Event.
  int collectedCount(String eventId) =>
      (_collectedIds[eventId] ?? {}).length;

  /// Ob das Event bereits abgeschlossen und der Reward abgeholt wurde.
  bool rewardClaimed(String eventId) => _rewardClaimed[eventId] ?? false;

  /// Ob ein bestimmter Kirchensegen für dieses Event bereits gezählt wurde.
  bool hasCollectedChurch(String eventId, String landmarkId) =>
      (_collectedIds[eventId] ?? {}).contains(landmarkId);

  /// Wird aufgerufen wenn ein Kirchensegen-Token gesammelt wurde.
  /// Gibt `true` zurück wenn das Token neu ist (also zum ersten Mal gesammelt).
  Future<bool> recordChurchCollected(String landmarkId) async {
    bool anyNew = false;
    for (final event in allEvents) {
      if (event.isExpired) continue;
      final set = _collectedIds.putIfAbsent(event.id, () => {});
      if (!set.contains(landmarkId)) {
        set.add(landmarkId);
        anyNew = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          '${_prefPrefix}${event.id}_collected',
          set.toList(),
        );
      }
    }
    if (anyNew) notifyListeners();
    return anyNew;
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
