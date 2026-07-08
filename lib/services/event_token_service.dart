import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/event_token.dart';
import '../models/landmark.dart';
import 'event_service.dart';
import 'event_token_repository.dart';

class EventTokenService extends ChangeNotifier {
  EventTokenService({EventTokenRepository? repository})
      : _repository = repository ?? EventTokenRepository();

  final EventTokenRepository _repository;

  String? _uid;
  String? _username;
  String? _activeEventId;

  final List<EventToken> _activeEventTokens = [];
  List<EventToken> get activeEventTokens => List.unmodifiable(_activeEventTokens);

  Set<String> _collectedEventTokenIds = {};
  Set<String> get collectedEventTokenIds => Set.unmodifiable(_collectedEventTokenIds);

  StreamSubscription<List<EventToken>>? _activeSub;
  StreamSubscription<Set<String>>? _collectedSub;

  bool isCollected(String eventTokenId) => _collectedEventTokenIds.contains(eventTokenId);

  void setUser(String? uid, String? username) {
    if (_uid == uid && _username == username) return;
    _uid = uid;
    _username = username;
    _collectedEventTokenIds = {};
    _collectedSub?.cancel();

    if (uid != null) {
      _collectedSub = _repository.streamCollectedEventTokenIds(uid).listen((ids) {
        _collectedEventTokenIds = ids;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void configureFromLocalEvents({
    required List<GameEvent> events,
    required List<Landmark> landmarks,
    required String? activeEventId,
    required String? nextEventId,
    DateTime? activeWindowStart,
    DateTime? activeWindowEnd,
  }) {
    final previousActiveEventId = _activeEventId;
    _activeEventId = activeEventId;

    if (activeEventId == null) {
      _activeEventTokens
        ..clear();
      notifyListeners();
      return;
    }

    final all = <EventToken>[];
    for (final event in events) {
      if (event.id != activeEventId) {
        continue;
      }

      final checkpointBased = event.checkpoints.isNotEmpty;
      final landmarkIds = checkpointBased
          ? event.checkpoints.map((cp) => cp.id).toList(growable: false)
          : event.landmarkIds;
      if (landmarkIds.isEmpty) continue;

      for (final landmarkId in landmarkIds) {
        final checkpoint = checkpointBased
            ? event.checkpoints.firstWhere((cp) => cp.id == landmarkId)
            : null;
        final landmark = checkpoint == null
            ? landmarks.firstWhere(
                (l) => l.id == landmarkId,
                orElse: () => Landmark(
                  id: landmarkId,
                  name: landmarkId,
                  description: '',
                  latitude: 0,
                  longitude: 0,
                  category: 'event',
                  difficulty: 'easy',
                  pointsReward: 0,
                  imageUrl: event.tokenImageUrl,
                ),
              )
            : Landmark(
                id: checkpoint.id,
                name: checkpoint.name,
                description: event.description,
                latitude: checkpoint.latitude,
                longitude: checkpoint.longitude,
                category: 'event',
                difficulty: 'easy',
                pointsReward: event.requiredCount == 0
                    ? event.rewardCoins
                    : (event.rewardCoins ~/ event.requiredCount),
                imageUrl: event.tokenImageUrl,
              );

        all.add(EventToken(
          id: '${event.id}_${landmark.id}',
          eventId: event.id,
          eventName: event.title,
          eventDescription: event.description,
          startDate: event.id == activeEventId && activeWindowStart != null
            ? activeWindowStart
            : event.startDate,
          endDate: event.id == activeEventId && activeWindowEnd != null
            ? activeWindowEnd
            : event.endDate,
          landmarkId: landmark.id,
          landmarkName: landmark.name,
          tokenImageUrl: event.tokenImageUrl,
            markerImageUrl: event.markerImageUrl,
            eventStatus: event.id == activeEventId
              ? 'active'
              : (event.id == nextEventId ? 'upcoming' : 'finished'),
          latitude: landmark.latitude,
          longitude: landmark.longitude,
          points: event.requiredCount == 0
              ? event.rewardCoins
              : (event.rewardCoins ~/ event.requiredCount),
          rewardCoins: event.rewardCoins,
          rewardLootboxes: event.rewardLootboxes,
        ));
      }
    }

    final now = DateTime.now();
    _activeEventTokens
      ..clear()
      ..addAll(all.where((e) => !now.isBefore(e.startDate) && !now.isAfter(e.endDate)));

    notifyListeners();

    _activeSub?.cancel();
    _activeSub = _repository
        .streamActiveEventTokens(activeEventId: activeEventId)
        .listen((remoteTokens) {
      // Prefer Firestore tokens when available; fallback to local set if empty.
      if (remoteTokens.isNotEmpty) {
        _activeEventTokens
          ..clear()
          ..addAll(remoteTokens);
        notifyListeners();
      }
    });

    if (previousActiveEventId != _activeEventId) {
      notifyListeners();
    }
  }

  EventToken? activeTokenForLandmark(String landmarkId) {
    try {
      return _activeEventTokens.firstWhere((t) => t.landmarkId == landmarkId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> collectToken(EventToken token) async {
    final uid = _uid;
    if (uid == null) return false;
    if (!token.isActive) return false;
    if (isCollected(token.id)) return false;

    await _repository.collectEventToken(
      uid: uid,
      username: _username ?? uid,
      token: token,
    );
    return true;
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    _collectedSub?.cancel();
    super.dispose();
  }
}
