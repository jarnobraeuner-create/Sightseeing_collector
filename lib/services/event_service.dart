import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventCheckpoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const EventCheckpoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

enum EventStatus { upcoming, active, finished }

class EventRotationConfig {
  final List<String> order;
  final DateTime anchorStart;
  final bool useCalendarMonth;
  final int durationDays;

  const EventRotationConfig({
    required this.order,
    required this.anchorStart,
    required this.useCalendarMonth,
    required this.durationDays,
  });
}

/// Beschreibt ein einzelnes Spiel-Event.
class GameEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int requiredCount;
  final int rewardCoins;
  final int rewardLootboxes;
  final List<String> landmarkIds;
  final List<EventCheckpoint> checkpoints;
  final String tokenImageUrl;
  final String markerImageUrl;

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
    this.checkpoints = const [],
    this.tokenImageUrl = 'assets/images/Kirche_default_token.png',
    this.markerImageUrl = 'assets/images/map_pin_gold.png',
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isNotStarted => DateTime.now().isBefore(startDate);
  bool get isActive => !isExpired && !isNotStarted;
}

/// Service der Events und deren Fortschritt verwaltet.
class EventService extends ChangeNotifier {
  static const _prefPrefix = 'event_';
  bool _devMode = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _rotationSub;
  Timer? _rotationTicker;

  EventRotationConfig _rotation = EventRotationConfig(
    order: const ['bruecken_august_2026', 'park_hunter_2026'],
    anchorStart: DateTime(2026, 8, 1),
    useCalendarMonth: true,
    durationDays: 30,
  );

  String? _activeEventId;
  String? _nextEventId;
  DateTime? _activeEventStart;
  DateTime? _activeEventEnd;

  String? get activeEventId => _activeEventId;
  String? get nextEventId => _nextEventId;
  DateTime? get activeEventStart => _activeEventStart;
  DateTime? get activeEventEnd => _activeEventEnd;

  Duration? get activeEventRemaining {
    final end = _activeEventEnd;
    if (end == null) return null;
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return Duration.zero;
    return diff;
  }

  static final List<EventCheckpoint> bridgeHunterCheckpoints = [
    const EventCheckpoint(
        id: 'bh_koehlbrandbruecke',
        name: 'Köhlbrandbrücke',
        latitude: 53.5308,
        longitude: 9.9668),
    const EventCheckpoint(
        id: 'bh_alte_harburger_elbbruecke',
        name: 'Alte Harburger Elbbrücke',
        latitude: 53.4639,
        longitude: 9.9928),
    const EventCheckpoint(
        id: 'bh_freihafenelbbruecke',
        name: 'Freihafenelbbrücke',
        latitude: 53.5357,
        longitude: 10.0215),
    const EventCheckpoint(
        id: 'bh_norderelbbruecke',
        name: 'Norderelbbrücke',
        latitude: 53.5457,
        longitude: 10.0288),
    const EventCheckpoint(
        id: 'bh_lombardsbruecke',
        name: 'Lombardsbrücke',
        latitude: 53.5610,
        longitude: 9.9925),
    const EventCheckpoint(
        id: 'bh_kennedybruecke',
        name: 'Kennedybrücke',
        latitude: 53.5651,
        longitude: 10.0004),
    const EventCheckpoint(
        id: 'bh_brooksbruecke',
        name: 'Brooksbrücke',
        latitude: 53.5477,
        longitude: 9.9955),
    const EventCheckpoint(
        id: 'bh_trostbruecke',
        name: 'Trostbrücke',
        latitude: 53.5489,
        longitude: 9.9919),
    const EventCheckpoint(
        id: 'bh_poggenmuehlenbruecke',
        name: 'Poggenmühlenbrücke',
        latitude: 53.5438,
        longitude: 9.9892),
    const EventCheckpoint(
        id: 'bh_wandrahmsteg',
        name: 'Wandrahmsteg',
        latitude: 53.5457,
        longitude: 10.0027),
    const EventCheckpoint(
        id: 'bh_kibbelstegbruecke',
        name: 'Kibbelstegbrücke',
        latitude: 53.5433,
        longitude: 10.0014),
    const EventCheckpoint(
        id: 'bh_oberhafenbruecke',
        name: 'Oberhafenbrücke',
        latitude: 53.5430,
        longitude: 10.0182),
    const EventCheckpoint(
        id: 'bh_baakenhafenbruecke',
        name: 'Baakenhafenbrücke',
        latitude: 53.5419,
        longitude: 10.0145),
    const EventCheckpoint(
        id: 'bh_ericusbruecke',
        name: 'Ericusbrücke',
        latitude: 53.5465,
        longitude: 10.0104),
    const EventCheckpoint(
        id: 'bh_rethebruecke',
        name: 'Rethebrücke',
        latitude: 53.5178,
        longitude: 9.9710),
    const EventCheckpoint(
        id: 'bh_kattwykbruecke',
        name: 'Kattwykbrücke',
        latitude: 53.4977,
        longitude: 10.0152),
    const EventCheckpoint(
        id: 'bh_krugkoppelbruecke',
        name: 'Krugkoppelbrücke',
        latitude: 53.5746,
        longitude: 10.0086),
    const EventCheckpoint(
        id: 'bh_leinpfadbruecke',
        name: 'Leinpfadbrücke',
        latitude: 53.5790,
        longitude: 9.9959),
    const EventCheckpoint(
        id: 'bh_feenteichbruecke',
        name: 'Feenteichbrücke',
        latitude: 53.5722,
        longitude: 10.0150),
    const EventCheckpoint(
        id: 'bh_brandshofer_bruecke',
        name: 'Brandshofer Brücke',
        latitude: 53.5412,
        longitude: 10.0256),
    const EventCheckpoint(
        id: 'bh_stubbenhukbruecke',
        name: 'Stubbenhukbrücke',
        latitude: 53.5405,
        longitude: 9.9755),
    const EventCheckpoint(
        id: 'bh_elbparkbruecke',
        name: 'Elbparkbrücke',
        latitude: 53.5452,
        longitude: 9.9661),
    const EventCheckpoint(
        id: 'bh_jungfernbruecke',
        name: 'Jungfernbrücke',
        latitude: 53.5498,
        longitude: 9.9914),
    const EventCheckpoint(
        id: 'bh_schleusenbruecke',
        name: 'Schleusenbrücke',
        latitude: 53.5501,
        longitude: 9.9933),
    const EventCheckpoint(
        id: 'bh_adolphsbruecke',
        name: 'Adolphsbrücke',
        latitude: 53.5497,
        longitude: 9.9918),
    const EventCheckpoint(
        id: 'bh_reesendammbruecke',
        name: 'Reesendammbrücke',
        latitude: 53.5512,
        longitude: 9.9946),
    const EventCheckpoint(
        id: 'bh_kersten_miles_bruecke',
        name: 'Kersten-Miles-Brücke',
        latitude: 53.5758,
        longitude: 9.9740),
    const EventCheckpoint(
        id: 'bh_fuhlsbuettler_bruecke',
        name: 'Fuhlsbüttler Brücke',
        latitude: 53.6348,
        longitude: 10.0081),
    const EventCheckpoint(
        id: 'bh_poppenbuetteler_bruecke',
        name: 'Poppenbütteler Brücke',
        latitude: 53.6530,
        longitude: 10.0850),
    const EventCheckpoint(
        id: 'bh_saseler_bruecke',
        name: 'Saseler Brücke',
        latitude: 53.6536,
        longitude: 10.1105),
    const EventCheckpoint(
        id: 'bh_volksdorfer_bruecke',
        name: 'Volksdorfer Brücke',
        latitude: 53.6490,
        longitude: 10.1630),
    const EventCheckpoint(
        id: 'bh_bergedorfer_bruecke',
        name: 'Bergedorfer Brücke',
        latitude: 53.4890,
        longitude: 10.2094),
    const EventCheckpoint(
        id: 'bh_biller_bruecke',
        name: 'Biller Brücke',
        latitude: 53.5386,
        longitude: 10.0717),
    const EventCheckpoint(
        id: 'bh_hammerbrookbruecke',
        name: 'Hammerbrookbrücke',
        latitude: 53.5484,
        longitude: 10.0265),
    const EventCheckpoint(
        id: 'bh_amsinckbruecke',
        name: 'Amsinckbrücke',
        latitude: 53.5491,
        longitude: 10.0181),
    const EventCheckpoint(
        id: 'bh_besenbinderhof_bruecke',
        name: 'Besenbinderhof Brücke',
        latitude: 53.5521,
        longitude: 10.0064),
    const EventCheckpoint(
        id: 'bh_hafencity_bruecke',
        name: 'HafenCity Brücke',
        latitude: 53.5418,
        longitude: 10.0024),
    const EventCheckpoint(
        id: 'bh_versmannbruecke',
        name: 'Versmannbrücke',
        latitude: 53.5388,
        longitude: 10.0166),
    const EventCheckpoint(
        id: 'bh_amerikabruecke',
        name: 'Amerikabrücke',
        latitude: 53.5332,
        longitude: 9.9588),
    const EventCheckpoint(
        id: 'bh_argentinienbruecke',
        name: 'Argentinienbrücke',
        latitude: 53.5320,
        longitude: 9.9568),
    const EventCheckpoint(
        id: 'bh_australiabruecke',
        name: 'Australiabrücke',
        latitude: 53.5311,
        longitude: 9.9547),
    const EventCheckpoint(
        id: 'bh_indiahafenbruecke',
        name: 'Indiahafenbrücke',
        latitude: 53.5297,
        longitude: 9.9515),
    const EventCheckpoint(
        id: 'bh_reiherstiegbruecke',
        name: 'Reiherstiegbrücke',
        latitude: 53.5145,
        longitude: 9.9813),
    const EventCheckpoint(
        id: 'bh_wilhelmsburger_bruecke',
        name: 'Wilhelmsburger Brücke',
        latitude: 53.5038,
        longitude: 10.0022),
    const EventCheckpoint(
        id: 'bh_mueggenburger_bruecke',
        name: 'Müggenburger Brücke',
        latitude: 53.5245,
        longitude: 10.0223),
    const EventCheckpoint(
        id: 'bh_peutestrassenbruecke',
        name: 'Peutestraßenbrücke',
        latitude: 53.5310,
        longitude: 10.0490),
    const EventCheckpoint(
        id: 'bh_billhorner_bruecke',
        name: 'Billhorner Brücke',
        latitude: 53.5395,
        longitude: 10.0355),
    const EventCheckpoint(
        id: 'bh_entenwerder_bruecke',
        name: 'Entenwerder Brücke',
        latitude: 53.5319,
        longitude: 10.0268),
    const EventCheckpoint(
        id: 'bh_kaltehofe_bruecke',
        name: 'Kaltehofe Brücke',
        latitude: 53.5289,
        longitude: 10.0583),
    const EventCheckpoint(
        id: 'bh_ochsenwerder_bruecke',
        name: 'Ochsenwerder Brücke',
        latitude: 53.4740,
        longitude: 10.0815),
  ];

  static final List<EventCheckpoint> parkHunterCheckpoints = [
    const EventCheckpoint(
        id: 'ph_planten_un_blomen',
        name: 'Planten un Blomen',
        latitude: 53.5602,
        longitude: 9.9786),
    const EventCheckpoint(
        id: 'ph_stadtpark_hamburg',
        name: 'Stadtpark Hamburg',
        latitude: 53.5935,
        longitude: 10.0150),
    const EventCheckpoint(
        id: 'ph_jenischpark',
        name: 'Jenischpark',
        latitude: 53.5487,
        longitude: 9.8475),
    const EventCheckpoint(
        id: 'ph_altonaer_volkspark',
        name: 'Altonaer Volkspark',
        latitude: 53.5781,
        longitude: 9.8982),
    const EventCheckpoint(
        id: 'ph_wilhelmsburger_inselpark',
        name: 'Wilhelmsburger Inselpark',
        latitude: 53.4987,
        longitude: 9.9872),
    const EventCheckpoint(
        id: 'ph_oejendorfer_park',
        name: 'Öjendorfer Park',
        latitude: 53.5532,
        longitude: 10.1370),
    const EventCheckpoint(
        id: 'ph_hammer_park',
        name: 'Hammer Park',
        latitude: 53.5558,
        longitude: 10.0614),
    const EventCheckpoint(
        id: 'ph_hayns_park',
        name: 'Hayns Park',
        latitude: 53.5826,
        longitude: 9.9894),
    const EventCheckpoint(
        id: 'ph_eppendorfer_park',
        name: 'Eppendorfer Park',
        latitude: 53.5904,
        longitude: 9.9804),
    const EventCheckpoint(
        id: 'ph_hirschpark',
        name: 'Hirschpark',
        latitude: 53.5505,
        longitude: 9.8218),
    const EventCheckpoint(
        id: 'ph_loki_schmidt_garten',
        name: 'Loki-Schmidt-Garten',
        latitude: 53.5198,
        longitude: 9.8550),
    const EventCheckpoint(
        id: 'ph_baurs_park',
        name: 'Baurs Park',
        latitude: 53.5586,
        longitude: 9.8108),
    const EventCheckpoint(
        id: 'ph_wohlers_park',
        name: 'Wohlers Park',
        latitude: 53.5613,
        longitude: 9.9475),
    const EventCheckpoint(
        id: 'ph_schanzenpark',
        name: 'Schanzenpark',
        latitude: 53.5625,
        longitude: 9.9675),
    const EventCheckpoint(
        id: 'ph_innocentiapark',
        name: 'Innocentiapark',
        latitude: 53.5824,
        longitude: 9.9838),
    const EventCheckpoint(
        id: 'ph_jacobipark',
        name: 'Jacobipark',
        latitude: 53.5759,
        longitude: 10.0667),
    const EventCheckpoint(
        id: 'ph_horner_park',
        name: 'Horner Park',
        latitude: 53.5537,
        longitude: 10.0881),
    const EventCheckpoint(
        id: 'ph_goethepark',
        name: 'Goethepark',
        latitude: 53.5715,
        longitude: 9.8764),
    const EventCheckpoint(
        id: 'ph_fischers_park',
        name: 'Fischers Park',
        latitude: 53.5516,
        longitude: 9.9148),
    const EventCheckpoint(
        id: 'ph_boeverstpark',
        name: 'Böverstpark',
        latitude: 53.6313,
        longitude: 10.1430),
    const EventCheckpoint(
        id: 'ph_hohenbuchenpark',
        name: 'Hohenbuchenpark',
        latitude: 53.6339,
        longitude: 10.1274),
    const EventCheckpoint(
        id: 'ph_kupferteichpark',
        name: 'Kupferteichpark',
        latitude: 53.6400,
        longitude: 10.1185),
    const EventCheckpoint(
        id: 'ph_skulpturenpark_hamburg',
        name: 'Skulpturenpark Hamburg',
        latitude: 53.5482,
        longitude: 9.9900),
    const EventCheckpoint(
        id: 'ph_alsterpark',
        name: 'Alsterpark',
        latitude: 53.5727,
        longitude: 9.9985),
    const EventCheckpoint(
        id: 'ph_rosengarten_altona',
        name: 'Rosengarten Altona',
        latitude: 53.5448,
        longitude: 9.9366),
    const EventCheckpoint(
        id: 'ph_bergedorfer_schlosspark',
        name: 'Bergedorfer Schlosspark',
        latitude: 53.4849,
        longitude: 10.2114),
    const EventCheckpoint(
        id: 'ph_wandsbeker_geholz',
        name: 'Wandsbeker Gehölz',
        latitude: 53.5732,
        longitude: 10.0798),
    const EventCheckpoint(
        id: 'ph_volksdorfer_teichwiesen',
        name: 'Volksdorfer Teichwiesen',
        latitude: 53.6486,
        longitude: 10.1656),
    const EventCheckpoint(
        id: 'ph_hegenwald',
        name: 'Hegenwald',
        latitude: 53.6477,
        longitude: 10.1550),
    const EventCheckpoint(
        id: 'ph_rissener_kiesgrube',
        name: 'Rissener Kiesgrube',
        latitude: 53.5782,
        longitude: 9.7598),
    const EventCheckpoint(
        id: 'ph_duvenstedter_brook',
        name: 'Duvenstedter Brook',
        latitude: 53.7067,
        longitude: 10.1546),
    const EventCheckpoint(
        id: 'ph_hainesch_iland',
        name: 'Hainesch-Iland',
        latitude: 53.6740,
        longitude: 10.0460),
    const EventCheckpoint(
        id: 'ph_parkanlage_bondenwald',
        name: 'Parkanlage Bondenwald',
        latitude: 53.6147,
        longitude: 9.9450),
    const EventCheckpoint(
        id: 'ph_mellingburger_schleuse_park',
        name: 'Mellingburger Schleuse Park',
        latitude: 53.6870,
        longitude: 10.0900),
    const EventCheckpoint(
        id: 'ph_alstervorland_park',
        name: 'Alstervorland Park',
        latitude: 53.5685,
        longitude: 10.0011),
    const EventCheckpoint(
        id: 'ph_baakenpark',
        name: 'Baakenpark',
        latitude: 53.5408,
        longitude: 10.0200),
    const EventCheckpoint(
        id: 'ph_lohsepark',
        name: 'Lohsepark',
        latitude: 53.5425,
        longitude: 10.0078),
    const EventCheckpoint(
        id: 'ph_grasbrookpark',
        name: 'Grasbrookpark',
        latitude: 53.5388,
        longitude: 10.0118),
    const EventCheckpoint(
        id: 'ph_elbpark_entenwerder',
        name: 'Elbpark Entenwerder',
        latitude: 53.5316,
        longitude: 10.0270),
    const EventCheckpoint(
        id: 'ph_burgerpark_wandsbek',
        name: 'Bürgerpark Wandsbek',
        latitude: 53.5764,
        longitude: 10.0738),
    const EventCheckpoint(
        id: 'ph_tarpenbek_park',
        name: 'Tarpenbek Park',
        latitude: 53.6073,
        longitude: 9.9892),
    const EventCheckpoint(
        id: 'ph_rodenbeker_quellental',
        name: 'Rodenbeker Quellental',
        latitude: 53.6771,
        longitude: 10.0930),
    const EventCheckpoint(
        id: 'ph_hummelsee_park',
        name: 'Hummelsee Park',
        latitude: 53.6088,
        longitude: 10.1801),
    const EventCheckpoint(
        id: 'ph_eichtalpark',
        name: 'Eichtalpark',
        latitude: 53.5750,
        longitude: 10.0875),
    const EventCheckpoint(
        id: 'ph_wasserpark_dove_elbe',
        name: 'Wasserpark Dove Elbe',
        latitude: 53.4860,
        longitude: 10.1105),
    const EventCheckpoint(
        id: 'ph_karlshohe_naturpark',
        name: 'Karlshöhe Naturpark',
        latitude: 53.6384,
        longitude: 10.0817),
    const EventCheckpoint(
        id: 'ph_niendorfer_gehege',
        name: 'Niendorfer Gehege',
        latitude: 53.6225,
        longitude: 9.9448),
    const EventCheckpoint(
        id: 'ph_ovelgonner_park',
        name: 'Övelgönner Park',
        latitude: 53.5475,
        longitude: 9.8857),
    const EventCheckpoint(
        id: 'ph_elbuferpark_neumuehlen',
        name: 'Elbuferpark Neumühlen',
        latitude: 53.5450,
        longitude: 9.9275),
    const EventCheckpoint(
        id: 'ph_dockland_parkanlage',
        name: 'Dockland Parkanlage',
        latitude: 53.5444,
        longitude: 9.9350),
  ];

  /// Alle definierten Events (unveränderlich als Eventkatalog)
  static final List<GameEvent> allEvents = [
    GameEvent(
      id: 'seen_juni_2026',
      title: 'Seeblick-Sammler',
      description: 'Besuche 3 Seen und Gewässer bis Ende Juni 2026 '
          'und erhalte eine besondere Belohnung!',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30, 23, 59, 59),
      requiredCount: 3,
      rewardCoins: 2000,
      rewardLootboxes: 3,
      landmarkIds: const [],
    ),
    GameEvent(
      id: 'parks_juli_2026',
      title: 'Parkläufer',
      description: 'Besuche 4 Parks und Grünanlagen bis Ende Juli 2026 '
          'und erhalte eine besondere Belohnung!',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31, 23, 59, 59),
      requiredCount: 4,
      rewardCoins: 2500,
      rewardLootboxes: 4,
      // Planten un Blomen wurde als Eventhauptpunkt entfernt.
      landmarkIds: const ['14'],
      markerImageUrl: 'assets/images/Park_mappin.png',
      tokenImageUrl: 'assets/images/Park_token.png',
    ),
    GameEvent(
      id: 'bruecken_august_2026',
      title: 'Bridge Hunter',
      description:
          'Besuche 10 von 50 Hamburger Brücken bis Ende des Event-Monats '
          'und erhalte eine besondere Belohnung!',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31, 23, 59, 59),
      requiredCount: 10,
      rewardCoins: 2000,
      rewardLootboxes: 3,
      landmarkIds: bridgeHunterCheckpoints.map((cp) => cp.id).toList(),
      checkpoints: bridgeHunterCheckpoints,
      tokenImageUrl: 'assets/images/Token_Landungsbrücken_Gold.png',
      markerImageUrl: 'assets/images/map_pin_gold.png',
    ),
    GameEvent(
      id: 'park_hunter_2026',
      title: 'Park Hunter',
      description:
          'Besuche 10 von 50 Hamburger Parks bis Ende des Event-Monats '
          'und sichere dir die Event-Belohnung!',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 30, 23, 59, 59),
      requiredCount: 10,
      rewardCoins: 2000,
      rewardLootboxes: 3,
      landmarkIds: parkHunterCheckpoints.map((cp) => cp.id).toList(),
      checkpoints: parkHunterCheckpoints,
      tokenImageUrl: 'assets/images/Park_token.png',
      markerImageUrl: 'assets/images/Park_mappin.png',
    ),
  ];

  final Map<String, int> _collectedCounts = {};
  final Map<String, bool> _rewardClaimed = {};
  final Map<String, Set<String>> _visitedLandmarks = {};

  EventService() {
    _recomputeSchedule(DateTime.now());
    _load();
    _listenRotationConfig();
    _rotationTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      final oldActive = _activeEventId;
      _recomputeSchedule(DateTime.now());
      if (oldActive != _activeEventId) {
        notifyListeners();
      }
    });
  }

  List<GameEvent> get allConfiguredEvents => allEvents;

  GameEvent? get activeEvent {
    if (_activeEventId == null) return null;
    return _eventById(_activeEventId!);
  }

  GameEvent? get nextEvent {
    if (_nextEventId == null) return null;
    return _eventById(_nextEventId!);
  }

  List<GameEvent> get visibleEvents {
    final active = this.activeEvent;
    final upcoming = nextEvent;
    final result = <GameEvent>[];
    if (active != null) result.add(active);
    if (upcoming != null && upcoming.id != active?.id) result.add(upcoming);
    return result;
  }

  EventStatus statusOf(String eventId) {
    if (eventId == _activeEventId) return EventStatus.active;
    if (eventId == _nextEventId) return EventStatus.upcoming;
    return EventStatus.finished;
  }

  bool _isEventActive(GameEvent event) =>
      _devMode || statusOf(event.id) == EventStatus.active;

  bool isEventCollectible(String eventId) {
    final event = _eventById(eventId);
    if (event == null) return false;
    return _isEventActive(event);
  }

  DocumentReference<Map<String, dynamic>> _eventProgressDoc(
    String uid,
    String eventId,
  ) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('event_progress')
        .doc(eventId);
  }

  Future<void> _saveEventProgressToFirestore({
    required String eventId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _eventProgressDoc(uid, eventId).set({
      'eventId': eventId,
      'count': _collectedCounts[eventId] ?? 0,
      'claimed': _rewardClaimed[eventId] ?? false,
      'visited': (_visitedLandmarks[eventId] ?? <String>{}).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _loadEventProgressFromFirestoreAndMerge() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('event_progress')
        .get();
    if (snap.docs.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    for (final doc in snap.docs) {
      final eventId = doc.id;
      if (_eventById(eventId) == null) continue;

      final data = doc.data();
      final remoteVisited =
          (data['visited'] as List?)?.map((e) => e.toString()).toSet() ??
              <String>{};
      final localVisited = _visitedLandmarks[eventId] ?? <String>{};
      final mergedVisited = <String>{...localVisited, ...remoteVisited};

      final remoteCount = (data['count'] as num?)?.toInt() ?? 0;
      final mergedCount = [
        _collectedCounts[eventId] ?? 0,
        remoteCount,
        mergedVisited.length,
      ].reduce((a, b) => a > b ? a : b);

      final remoteClaimed = data['claimed'] == true;
      final mergedClaimed = (_rewardClaimed[eventId] ?? false) || remoteClaimed;

      _visitedLandmarks[eventId] = mergedVisited;
      _collectedCounts[eventId] = mergedCount;
      _rewardClaimed[eventId] = mergedClaimed;

      await prefs.setInt('${_prefPrefix}${eventId}_count', mergedCount);
      await prefs.setBool('${_prefPrefix}${eventId}_claimed', mergedClaimed);
      await prefs.setStringList(
        '${_prefPrefix}${eventId}_visited',
        mergedVisited.toList(),
      );
    }
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
        final legacyRaw = prefs.getStringList(legacyCollectedKey) ?? [];
        _collectedCounts[event.id] = legacyRaw.toSet().length;
      }
      _rewardClaimed[event.id] =
          prefs.getBool('${_prefPrefix}${event.id}_claimed') ?? false;
      _visitedLandmarks[event.id] =
          (prefs.getStringList('${_prefPrefix}${event.id}_visited') ?? [])
              .toSet();
    }

    try {
      await _loadEventProgressFromFirestoreAndMerge();
    } catch (e) {
      debugPrint('Event progress merge failed, continuing with local data: $e');
    }

    _recomputeSchedule(DateTime.now());
    notifyListeners();
  }

  void _listenRotationConfig() {
    _rotationSub?.cancel();
    _rotationSub = _db
        .collection('event_rotation')
        .doc('config')
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return;

      final orderRaw = (data['eventOrder'] as List?)
              ?.map((e) => e.toString())
              .where((id) => _eventById(id) != null)
              .toList(growable: false) ??
          const <String>[];

      final anchorTs = data['anchorStart'] as Timestamp?;
      final mode = (data['durationMode'] as String?) ?? 'calendar_month';
      final durationDays = (data['durationDays'] as num?)?.toInt() ?? 30;

      final fallbackOrder = _resolvedRotationOrder();
      final nextOrder = orderRaw.isEmpty ? fallbackOrder : orderRaw;
      final nextAnchor = anchorTs?.toDate() ?? DateTime.now();

      _rotation = EventRotationConfig(
        order: nextOrder,
        anchorStart: nextAnchor,
        useCalendarMonth: mode == 'calendar_month',
        durationDays: durationDays,
      );

      _recomputeSchedule(DateTime.now());
      notifyListeners();
    });
  }

  List<String> _resolvedRotationOrder() {
    final fromRotation = _rotation.order
        .where((id) => _eventById(id) != null)
        .toList(growable: false);
    if (fromRotation.isNotEmpty) return fromRotation;

    final fromCatalog = allEvents.map((e) => e.id).toList(growable: false);
    if (fromCatalog.isNotEmpty) return fromCatalog;

    return const <String>[];
  }

  void _fallbackToFirstEvent(List<String> order, DateTime now) {
    _activeEventId = order.first;
    _nextEventId = order.length > 1 ? order[1] : order.first;
    if (_rotation.useCalendarMonth) {
      _activeEventStart = DateTime(now.year, now.month, 1);
      _activeEventEnd = DateTime(now.year, now.month + 1, 1);
    } else {
      final safeDuration =
          _rotation.durationDays <= 0 ? 30 : _rotation.durationDays;
      _activeEventStart = now;
      _activeEventEnd = now.add(Duration(days: safeDuration));
    }
  }

  void _recomputeSchedule(DateTime now) {
    final order = _resolvedRotationOrder();
    if (order.isEmpty) {
      _activeEventId = null;
      _nextEventId = null;
      _activeEventStart = null;
      _activeEventEnd = null;
      return;
    }

    try {
      var slotStart = _rotation.anchorStart;
      var slotIndex = 0;

      if (_rotation.useCalendarMonth) {
        while (now.isBefore(slotStart)) {
          slotStart = _addMonths(slotStart, -1);
          slotIndex--;
        }
        while (!now.isBefore(_addMonths(slotStart, 1))) {
          slotStart = _addMonths(slotStart, 1);
          slotIndex++;
        }
        _activeEventStart = slotStart;
        _activeEventEnd = _addMonths(slotStart, 1);
      } else {
        final diffDays = now.difference(_rotation.anchorStart).inDays;
        final safeDuration =
            _rotation.durationDays <= 0 ? 30 : _rotation.durationDays;
        slotIndex = diffDays >= 0
            ? diffDays ~/ safeDuration
            : -(((-diffDays - 1) ~/ safeDuration) + 1);
        slotStart =
            _rotation.anchorStart.add(Duration(days: slotIndex * safeDuration));
        _activeEventStart = slotStart;
        _activeEventEnd = slotStart.add(Duration(days: safeDuration));
      }

      final activeIdx =
          ((slotIndex % order.length) + order.length) % order.length;
      final candidate = order[activeIdx];
      if (_eventById(candidate) == null) {
        _fallbackToFirstEvent(order, now);
        return;
      }
      _activeEventId = candidate;
      _nextEventId = order[(activeIdx + 1) % order.length];
    } catch (e) {
      debugPrint('Event schedule recompute failed, using fallback: $e');
      _fallbackToFirstEvent(order, now);
    }

    // Hard guarantee: exactly one active event ID must exist.
    if (_activeEventId == null || _eventById(_activeEventId!) == null) {
      _fallbackToFirstEvent(order, now);
    }
  }

  DateTime _addMonths(DateTime dt, int months) {
    final y = dt.year + ((dt.month - 1 + months) ~/ 12);
    final m = ((dt.month - 1 + months) % 12) + 1;
    final endOfMonth = DateTime(y, m + 1, 0).day;
    final d = dt.day > endOfMonth ? endOfMonth : dt.day;
    return DateTime(y, m, d, dt.hour, dt.minute, dt.second);
  }

  GameEvent? _eventById(String id) {
    try {
      return allEvents.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  int collectedCount(String eventId) => _collectedCounts[eventId] ?? 0;

  bool rewardClaimed(String eventId) => _rewardClaimed[eventId] ?? false;

  bool hasCollectedChurch(String eventId, String landmarkId) =>
      collectedCount(eventId) > 0;

  void setDevMode(bool value) {
    if (_devMode == value) return;
    _devMode = value;
    notifyListeners();
  }

  Future<bool> recordChurchCollected(String landmarkId) async {
    var changed = false;
    final prefs = await SharedPreferences.getInstance();

    for (final event in allEvents) {
      if (!_isEventActive(event)) continue;
      if (event.landmarkIds.isNotEmpty || event.checkpoints.isNotEmpty)
        continue;
      final nextCount = (_collectedCounts[event.id] ?? 0) + 1;
      _collectedCounts[event.id] = nextCount;
      await prefs.setInt('${_prefPrefix}${event.id}_count', nextCount);
      await _saveEventProgressToFirestore(eventId: event.id);
      changed = true;
    }

    if (changed) notifyListeners();
    return changed;
  }

  GameEvent? pendingReward() {
    final active = this.activeEvent;
    if (active == null) return null;
    if (rewardClaimed(active.id)) return null;
    if (collectedCount(active.id) >= active.requiredCount) return active;
    return null;
  }

  Future<void> claimReward(String eventId) async {
    _rewardClaimed[eventId] = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefPrefix}${eventId}_claimed', true);
    await _saveEventProgressToFirestore(eventId: eventId);
    notifyListeners();
  }

  bool hasLandmarkBeenVisited(String eventId, String landmarkId) {
    return _visitedLandmarks[eventId]?.contains(landmarkId) ?? false;
  }

  Future<bool> recordEventLandmarkCollected(
      String eventId, String landmarkId) async {
    final event = _eventById(eventId);
    if (event == null) return false;
    if (!_isEventActive(event)) return false;

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
    await _saveEventProgressToFirestore(eventId: eventId);
    notifyListeners();
    return true;
  }

  Future<void> resetEvent(String eventId) async {
    _collectedCounts.remove(eventId);
    _rewardClaimed[eventId] = false;
    _visitedLandmarks.remove(eventId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefPrefix}${eventId}_count');
    await prefs.remove('${_prefPrefix}${eventId}_claimed');
    await prefs.remove('${_prefPrefix}${eventId}_visited');
    await prefs.remove('${_prefPrefix}${eventId}_collected');

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _eventProgressDoc(uid, eventId).delete();
    }
    notifyListeners();
  }

  List<GameEvent> completedEventsForProfile() {
    final completed = <GameEvent>[];
    for (final event in allEvents) {
      final reachedGoal = collectedCount(event.id) >= event.requiredCount;
      if (rewardClaimed(event.id) || reachedGoal) {
        completed.add(event);
      }
    }
    return completed;
  }

  @override
  void dispose() {
    _rotationTicker?.cancel();
    _rotationSub?.cancel();
    super.dispose();
  }
}
