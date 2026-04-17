import 'package:flutter/foundation.dart';
import '../models/index.dart';

class LandmarkService extends ChangeNotifier {
  final List<Landmark> _landmarks = [];
  List<Landmark> _filteredLandmarks = [];
  String _selectedCategory = 'all'; // 'all', 'sightseeing', 'travel'
  bool _isLoaded = false;

  List<Landmark> get landmarks {
    _ensureLoaded();
    return _landmarks;
  }
  
  List<Landmark> get filteredLandmarks {
    _ensureLoaded();
    return _filteredLandmarks;
  }
  
  String get selectedCategory => _selectedCategory;

  LandmarkService() {
    // Nicht automatisch laden
    debugPrint('LandmarkService created (lazy loading)');
  }

  void _ensureLoaded() {
    if (!_isLoaded) {
      _isLoaded = true;
      _loadLandmarks();
      _applyFilter();
    }
  }

  void _loadLandmarks() {
    _landmarks.addAll([
      // Hamburg Landmarks
      Landmark(
        id: '1',
        name: 'Speicherstadt',
        description:
            'Historischer Hafen und Lagerhauskomplex in Hamburg. Der größte zusammenhängende Lagerhauskomplex der Welt und UNESCO-Weltkulturerbe.',
        latitude: 53.5438,
        longitude: 9.9989,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/Token_gold_speicherstadt.png',
        relatedSetIds: ['set_hamburg', 'set_monuments'],
        quests: [
          Quest(
            id: 'q1',
            title: 'Foto in der Speicherstadt',
            taskType: 'photo',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '2',
        name: 'Elbphilharmonie',
        description:
            'Die berühmte Konzerthalle an der Elbe mit ihrer markanten Glasfassade. Ein modernes Wahrzeichen Hamburgs.',
        latitude: 53.5410,
        longitude: 9.9849,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 120,
        imageUrl: 'assets/images/Token_Elbphilhamonie_Bronze.png',
        relatedSetIds: ['set_hamburg', 'set_monuments'],
        quests: [
          Quest(
            id: 'q2',
            title: 'Plaza-Besuch',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '3',
        name: 'Laeiszhalle',
        description:
            'Das traditionelle Konzerthaus von Hamburg, bekannt für exzellente Akustik und klassische Musik.',
        latitude: 53.5570,
        longitude: 9.9844,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 110,
        imageUrl: 'assets/images/Token_Leiszhalle_platin.png',
        relatedSetIds: ['set_hamburg'],
        quests: [
          Quest(
            id: 'q3',
            title: 'Konzertbesuch',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '4',
        name: 'Hamburger Michel',
        description:
            'Die bekannteste Kirche Hamburgs mit ihrem charakteristischen Turm. Ein Symbol der Stadt seit Jahrhunderten.',
        latitude: 53.5479,
        longitude: 9.9790,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/Token_Michel_silber.png',
        relatedSetIds: ['set_hamburg'],
        defaultTier: TokenTier.silver,
        quests: [
          Quest(
            id: 'q4',
            title: 'Turmbesteigung',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '5',
        name: 'Chilehaus',
        description:
            'Expressionistisches Kontorhaus im Hamburger Kontorhausviertel, UNESCO-Weltkulturerbe.',
        latitude: 53.5490,
        longitude: 10.0023,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 110,
        imageUrl: 'assets/images/Token_gold_chilehaus.png',
        relatedSetIds: ['set_hamburg'],
        quests: [
          Quest(
            id: 'q5',
            title: 'Architektur-Foto',
            taskType: 'photo',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '6',
        name: 'Volksparkstadion',
        description:
            'Großer Volkspark in Hamburg-Altona mit vielfältigen Freizeitmöglichkeiten.',
        latitude: 53.5889,
        longitude: 9.8872,
        category: 'travel',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/Token_gold_volksparkstadion.png',
        relatedSetIds: ['set_hamburg'],
        quests: [
          Quest(
            id: 'q6',
            title: 'Spaziergang im Park',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      // Dissen Landmarks
      Landmark(
        id: '7',
        name: 'Dissen Aussichtsturm',
        description:
            'Der markante Aussichtsturm von Dissen mit herrlichem Panoramablick über die Region.',
        latitude: 52.1167,
        longitude: 8.1833,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 80,
        imageUrl: 'assets/images/dissen aussichtsturm.png',
        relatedSetIds: ['set_dissen'],
        quests: [
          Quest(
            id: 'q7',
            title: 'Turmbesteigung',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '8',
        name: 'Dissen Bahnhof',
        description:
            'Der historische Bahnhof von Dissen, ein wichtiger Verkehrsknotenpunkt der Region.',
        latitude: 52.1200,
        longitude: 8.1900,
        category: 'travel',
        difficulty: 'easy',
        pointsReward: 70,
        imageUrl: 'assets/images/Dissen Bahnhof.png',
        relatedSetIds: ['set_dissen'],
        quests: [
          Quest(
            id: 'q8',
            title: 'Bahnhofs-Check-in',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '9',
        name: 'Dissen Rathaus',
        description:
            'Das historische Rathaus im Zentrum von Dissen, Sitz der Stadtverwaltung.',
        latitude: 52.1180,
        longitude: 8.1850,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 85,
        imageUrl: 'assets/images/Dissen Rathaus.png',
        relatedSetIds: ['set_dissen'],
        quests: [
          Quest(
            id: 'q9',
            title: 'Rathaus-Foto',
            taskType: 'photo',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '10',
        name: 'Dissen St. Mauritius Kirche',
        description:
            'Die ehrwürdige St. Mauritius Kirche, das spirituelle Zentrum von Dissen.',
        latitude: 52.1190,
        longitude: 8.1840,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 95,
        imageUrl: 'assets/images/dissen St. Mauritius Kirche.png',
        relatedSetIds: ['set_dissen'],
        quests: [
          Quest(
            id: 'q10',
            title: 'Kirchenbesuch',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '11',
        name: 'Dissen Wasserturm',
        description:
            'Der charakteristische Wasserturm von Dissen, ein technisches Denkmal.',
        latitude: 52.1150,
        longitude: 8.1820,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 75,
        imageUrl: 'assets/images/Dissen Wasserturm.png',
        relatedSetIds: ['set_dissen'],
        quests: [
          Quest(
            id: 'q11',
            title: 'Wasserturm-Foto',
            taskType: 'photo',
            completed: false,
          ),
        ],
      ),
      // Weitere Landmarks
      Landmark(
        id: '12',
        name: 'Rövekamp',
        description:
            'Historisches Gebäude und beliebter Treffpunkt in der Region.',
        latitude: 52.1220,
        longitude: 8.1950,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 100,
        imageUrl: 'assets/images/Rövekamp.png',
        relatedSetIds: ['set_dissen'],
        quests: [
          Quest(
            id: 'q12',
            title: 'Rövekamp-Besuch',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '13',
        name: 'Atlantic Hotel',
        description:
            'Elegantes Luxushotel mit langer Tradition und herausragendem Service.',
        latitude: 53.5572,
        longitude: 9.9900,
        category: 'travel',
        difficulty: 'medium',
        pointsReward: 110,
        imageUrl: 'assets/images/Token_Atlantic_Gold.png',
        relatedSetIds: ['set_hamburg'],
        quests: [
          Quest(
            id: 'q13',
            title: 'Hotel-Check-in',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '14',
        name: 'Hayns Park',
        description:
            'Wunderschöne Parkanlage mit historischen Elementen und reichhaltiger Flora.',
        latitude: 52.1210,
        longitude: 8.1880,
        category: 'travel',
        difficulty: 'easy',
        pointsReward: 85,
        imageUrl: 'assets/images/Token_HaynsPark_Gold.png',
        relatedSetIds: ['set_hamburg'],
        quests: [
          Quest(
            id: 'q14',
            title: 'Park-Spaziergang',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '15',
        name: 'Planten un Blomen',
        description:
            'Wunderschöne Parkanlage im Herzen Hamburgs mit botanischen Gärten, Wasserspielen und japanischem Garten.',
        latitude: 53.5607,
        longitude: 9.9820,
        category: 'travel',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/Token_P_u_B_Gold.png',
        relatedSetIds: ['set_hamburg'],
        quests: [
          Quest(
            id: 'q15',
            title: 'Parkbesuch',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '16',
        name: 'Die Tanzenden Türme',
        description:
            'Markante Türme mit architektonischer Bedeutung und historischem Wert.',
        latitude: 53.5500,
        longitude: 9.9950,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 105,
        imageUrl: 'assets/images/Token_gold_tueme.png',
        relatedSetIds: ['set_hamburg'],
        quests: [
          Quest(
            id: 'q16',
            title: 'Turm-Foto',
            taskType: 'photo',
            completed: false,
          ),
        ],
      ),
    ]);
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_selectedCategory == 'all') {
      _filteredLandmarks = List.from(_landmarks);
    } else {
      _filteredLandmarks =
          _landmarks.where((l) => l.category == _selectedCategory).toList();
    }
  }

  Landmark? getLandmarkById(String id) {
    try {
      return _landmarks.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Landmark> getNearby(double userLat, double userLon,
      {double radiusInKm = 0.1}) {
    return _landmarks
        .where((landmark) => landmark.getDistance(userLat, userLon) <= radiusInKm)
        .toList();
  }

  List<Landmark> searchLandmarks(String query) {
    final lowerQuery = query.toLowerCase();
    return _landmarks
        .where((l) =>
            l.name.toLowerCase().contains(lowerQuery) ||
            l.description.toLowerCase().contains(lowerQuery))
        .toList();
  }

  String getImageUrlForTier(String landmarkId, TokenTier tier) {
    final landmark = getLandmarkById(landmarkId);
    if (landmark == null) return 'assets/images/default_token.jpeg';

    // Elbphilharmonie immer mit Bronze-Token
    if (landmarkId == '2') {
      switch (tier) {
        case TokenTier.bronze:
          return 'assets/images/Token_Elbphilhamonie_Bronze.png';
        case TokenTier.silver:
          return 'assets/images/Token_Elbphilhamonie_Bronze.png';
        case TokenTier.gold:
          return 'assets/images/Token_Elbphilhamonie_Bronze.png';
        case TokenTier.platinum:
          return 'assets/images/Token_Elbphilhamonie_Bronze.png';
      }
    }

    // Spezielle Tier-Bilder für Laeiszhalle
    if (landmarkId == '3') {
      switch (tier) {
        case TokenTier.bronze:
          return 'assets/images/Token_gold_laeiszhalle.png';
        case TokenTier.silver:
          return 'assets/images/Token_gold_laeiszhalle.png';
        case TokenTier.gold:
          return 'assets/images/Token_gold_laeiszhalle.png';
        case TokenTier.platinum:
          return 'assets/images/Token_Leiszhalle_platin.png';
      }
    }

    // Spezielle Tier-Bilder für Michel
    if (landmarkId == '4') {
      switch (tier) {
        case TokenTier.bronze:
          return landmark.imageUrl; // Kein Bronze-Bild vorhanden
        case TokenTier.silver:
          return 'assets/images/Token_Michel_silber.png';
        case TokenTier.gold:
          return 'assets/images/Token_gold_Michel.png';
        case TokenTier.platinum:
          return landmark.imageUrl; // Fallback zum Standard
      }
    }

    // Für andere Landmarks: Verwende Standard-Bild
    return landmark.imageUrl;
  }

  String getMapPinForTier(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:
        return 'assets/images/Map_Pin_Bronze.png';
      case TokenTier.silver:
        return 'assets/images/Map_pin_silber.png';
      case TokenTier.gold:
        return 'assets/images/map_pin_gold.png';
      case TokenTier.platinum:
        return 'assets/images/Map_Pin_Bronze.png'; // Fallback
    }
  }
}
