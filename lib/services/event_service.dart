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
      id: 'kirchensegen_mai_2026',
      title: 'Kirchensegen-Sammler',
      description:
          'Sammle 5 Kirchensegen-Tokens bis 18. Juni 2026 '
          'und erhalte eine besondere Belohnung!',
      endDate: DateTime(2026, 6, 18, 23, 59, 59),
      requiredCount: 5,
      rewardCoins: 2500,
      rewardLootboxes: 5,
    ),
    GameEvent(
      id: 'parkbesucher_juli_2026',
      title: 'Park-Entdecker',
      description:
          'Sammle 10 Park-Tokens in Hamburgs schönen Grünanlagen bis 18. Juli 2026 '
          'und erhalte eine besondere Belohnung!',
      endDate: DateTime(2026, 7, 18, 23, 59, 59),
      requiredCount: 10,
      rewardCoins: 3000,
      rewardLootboxes: 7,
    ),
  ];

  // Im Dev-Modus laufen abgelaufene Events trotzdem weiter.
  bool _devMode = false;

  /// Ob Event-Pins auf der Karte angezeigt werden sollen (An/Aus-Filter).
  bool _showEventPins = true;
  bool get showEventPins => _showEventPins;

  void setShowEventPins(bool value) {
    if (_showEventPins == value) return;
    _showEventPins = value;
    _saveShowEventPins();
    notifyListeners();
  }

  Future<void> _saveShowEventPins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('event_show_pins', _showEventPins);
  }

  void setDevMode(bool value) {
    if (_devMode == value) return;
    _devMode = value;
    notifyListeners();
  }

  bool _isActive(GameEvent event) => _devMode || !event.isExpired;

  /// Ob das Kirchen-Event aktuell läuft.
  bool get isChurchEventActive =>
      allEvents.any((e) => e.id.startsWith('kirchensegen') && _isActive(e));

  /// Ob das Park-Event aktuell läuft.
  bool get isParkEventActive =>
      allEvents.any((e) => e.id.startsWith('parkbesucher') && _isActive(e));

  // Gesammelte Tokens pro Event.
  final Map<String, int> _collectedCounts = {};
  final Map<String, bool> _rewardClaimed = {};
  // Welche Landmark-IDs pro Event bereits gesammelt wurden (verhindert Doppelzählung).
  final Map<String, Set<String>> _collectedLandmarks = {};

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
      final landmarksKey = '${_prefPrefix}${event.id}_landmarks';
      _collectedLandmarks[event.id] =
          (prefs.getStringList(landmarksKey) ?? []).toSet();
    }
    _showEventPins = prefs.getBool('event_show_pins') ?? true;
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

  /// Ob dieses Landmark für das aktive Kirchen-Event bereits gezählt wurde.
  bool isCollectedForActiveChurchEvent(String landmarkId) {
    for (final event in allEvents) {
      if (!event.id.startsWith('kirchensegen')) continue;
      if (!_isActive(event)) continue;
      if (_collectedLandmarks[event.id]?.contains(landmarkId) == true) return true;
    }
    return false;
  }

  /// Ob dieses Landmark für das aktive Park-Event bereits gezählt wurde.
  bool isCollectedForActiveParkEvent(String landmarkId) {
    for (final event in allEvents) {
      if (!event.id.startsWith('parkbesucher')) continue;
      if (!_isActive(event)) continue;
      if (_collectedLandmarks[event.id]?.contains(landmarkId) == true) return true;
    }
    return false;
  }

  /// Wird aufgerufen wenn ein Kirchensegen gesammelt wurde.
  Future<bool> recordChurchCollected(String landmarkId) =>
      _recordForEventType('kirchensegen', landmarkId);

  /// Wird aufgerufen wenn ein Park besucht wurde.
  Future<bool> recordParkCollected(String landmarkId) =>
      _recordForEventType('parkbesucher', landmarkId);

  Future<bool> _recordForEventType(String prefix, String landmarkId) async {
    var changed = false;
    final prefs = await SharedPreferences.getInstance();

    for (final event in allEvents) {
      if (!event.id.startsWith(prefix)) continue;
      if (!_isActive(event)) continue;
      // Jedes Landmark darf pro Event nur einmal gezählt werden.
      _collectedLandmarks.putIfAbsent(event.id, () => {});
      if (_collectedLandmarks[event.id]!.contains(landmarkId)) continue;
      _collectedLandmarks[event.id]!.add(landmarkId);
      await prefs.setStringList(
        '${_prefPrefix}${event.id}_landmarks',
        _collectedLandmarks[event.id]!.toList(),
      );
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
      if (!_isActive(event)) continue;
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

  /// [DevMode] Setzt ein Event vollständig zurück (Fortschritt + Reward).
  Future<void> resetEvent(String eventId) async {
    _collectedCounts[eventId] = 0;
    _rewardClaimed[eventId] = false;
    _collectedLandmarks[eventId] = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefPrefix}${eventId}_count');
    await prefs.remove('${_prefPrefix}${eventId}_claimed');
    await prefs.remove('${_prefPrefix}${eventId}_landmarks');
    notifyListeners();
  }
}
