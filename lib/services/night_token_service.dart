import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/night_token.dart';
import '../models/landmark.dart';
import 'night_token_repository.dart';

class NightTokenService extends ChangeNotifier {
  NightTokenService({NightTokenRepository? repository})
      : _repository = repository ?? NightTokenRepository();

  final NightTokenRepository _repository;

  String? _uid;
  String? _username;

  final List<NightToken> _nightTokens = [];
  List<NightToken> get nightTokens => List.unmodifiable(_nightTokens);

  Set<String> _collectedNightTokenIds = {};
  Set<String> get collectedNightTokenIds =>
      Set.unmodifiable(_collectedNightTokenIds);

  StreamSubscription<List<NightToken>>? _tokensSub;
  StreamSubscription<Set<String>>? _collectedSub;

  bool get isComingSoon => true;
  bool get canCollectTokens => false;

  void setUser(String? uid, String? username) {
    if (_uid == uid && _username == username) return;

    _uid = uid;
    _username = username;
    _collectedNightTokenIds = {};
    _collectedSub?.cancel();

    if (uid != null) {
      _collectedSub = _repository.streamCollectedNightTokenIds(uid).listen((ids) {
        _collectedNightTokenIds = ids;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  void configureFutureNightContent({required List<Landmark> landmarks}) {
    final placeholderNightTokens = landmarks
        .where((landmark) => landmark.mode == 'night')
        .map(
          (landmark) => NightToken(
            id: landmark.id,
            locationId: landmark.id,
            title: landmark.name,
            description: landmark.description,
            category: landmark.category,
            latitude: landmark.latitude,
            longitude: landmark.longitude,
            tokenImageUrl: landmark.imageUrl,
            markerImageUrl: 'assets/images/map_pin_gold.png',
            updatedAt: DateTime.now(),
          ),
        )
        .toList(growable: false);

    _nightTokens
      ..clear()
      ..addAll(placeholderNightTokens);
    notifyListeners();

    _tokensSub?.cancel();
    _tokensSub = _repository.streamNightTokens().listen((remoteTokens) {
      if (remoteTokens.isNotEmpty) {
        _nightTokens
          ..clear()
          ..addAll(remoteTokens);
        notifyListeners();
      }
    });
  }

  bool isCollected(String nightTokenId) =>
      _collectedNightTokenIds.contains(nightTokenId);

  Future<bool> collectNightToken(NightToken token) async {
    debugPrint('Night Mode is WIP. Collection is disabled for ${token.id}.');
    return false;
  }

  Future<Map<String, dynamic>?> readProgress() async {
    final uid = _uid;
    if (uid == null) return null;
    return _repository.readNightProgress(uid);
  }

  Future<Map<String, dynamic>?> readStats() async {
    final uid = _uid;
    if (uid == null) return null;
    return _repository.readNightStats(uid);
  }

  @override
  void dispose() {
    _tokensSub?.cancel();
    _collectedSub?.cancel();
    super.dispose();
  }
}