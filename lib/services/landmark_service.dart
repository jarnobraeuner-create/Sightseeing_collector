import 'package:flutter/foundation.dart';
import '../models/index.dart';
import 'notification_service.dart';

class LandmarkService extends ChangeNotifier {
  final List<Landmark> _landmarks = [];
  List<Landmark> _filteredLandmarks = [];
  String _selectedCategory = 'all'; // 'all', 'sightseeing', 'travel'
  bool _isLoaded = false;

  // Landmarks die einen Monument-Token haben können (nur diese 3)
  static const Set<String> monumentLandmarkIds = {'1', '2', '4'};

  bool hasMonumentTier(String landmarkId) =>
      monumentLandmarkIds.contains(landmarkId);

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
      // Prüfen ob neue Landmarks hinzugekommen sind
      NotificationService.instance
          .checkAndNotifyMapUpdated(_landmarks.length);
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
        latitude: 53.544889,
        longitude: 9.997472,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/Token_gold_speicherstadt.png',
        relatedSetIds: ['set_hamburg'],
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
        relatedSetIds: ['set_hamburg'],
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
        latitude: 53.555694,
        longitude: 9.980500,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 110,
        imageUrl: 'assets/images/Token_Leiszhalle_platin.png',
        relatedSetIds: ['set_hamburg'],
        defaultTier: TokenTier.platinum,
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
        isChurch: true,
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
        latitude: 53.548306,
        longitude: 10.003306,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 110,
        imageUrl: 'assets/images/Token_gold_chilehaus.png',
        relatedSetIds: ['set_hamburg'],
        defaultTier: TokenTier.gold,
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
      Landmark(
        id: '13',
        name: 'Atlantic Hotel',
        description:
            'Elegantes Luxushotel mit langer Tradition und herausragendem Service.',
        latitude: 53.557194,
        longitude: 10.004167,
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
        latitude: 53.549917,
        longitude: 9.968194,
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
      Landmark(
        id: '17',
        name: 'HCU Hamburg',
        description:
            'Die HafenCity Universität Hamburg – Hochschule für Baukunst und Metropolenentwicklung in der HafenCity.',
        latitude: 53.540667,
        longitude: 10.005056,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/Token_HCU.png',
        relatedSetIds: ['set_hamburg'],
        defaultTier: TokenTier.gold,
        quests: [
          Quest(
            id: 'q17',
            title: 'Campus-Besuch',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '18',
        name: 'Landungsbrücken',
        description:
            'Die berühmten Hamburger Landungsbrücken am Hafen – Tor zur Welt und Treffpunkt der Stadt.',
        latitude: 53.545639,
        longitude: 9.970028,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 110,
        imageUrl: 'assets/images/Token_Landungsbrücken_Gold.png',
        relatedSetIds: ['set_hamburg'],
        defaultTier: TokenTier.gold,
        quests: [
          Quest(
            id: 'q18',
            title: 'Hafenrundfahrt',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '19',
        name: 'Marco Polo Tower',
        description:
            'Markantes Wohnhochhaus in der HafenCity mit spektakulärer Architektur und Blick auf die Elbe.',
        latitude: 53.539750,
        longitude: 9.992806,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 105,
        imageUrl: 'assets/images/Token_MarcoPolo.png',
        relatedSetIds: ['set_hamburg'],
        defaultTier: TokenTier.gold,
        quests: [
          Quest(
            id: 'q19',
            title: 'Architektur-Foto',
            taskType: 'photo',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '20',
        name: 'Hamburger Rathaus',
        description:
            'Das prachtvolle neugotische Rathaus am Rathausmarkt – Herz der Hansestadt und Sitz der Bürgerschaft.',
        latitude: 53.550583,
        longitude: 9.992750,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 115,
        imageUrl: 'assets/images/Token_Rathaus_Gold.png',
        relatedSetIds: ['set_hamburg'],
        defaultTier: TokenTier.gold,
        quests: [
          Quest(
            id: 'q20',
            title: 'Rathausmarkt-Besuch',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '21',
        name: 'Westfield Hamburg-Überseequartier',
        description:
            'Modernes Einkaufs- und Entertainmentzentrum im Herzen der HafenCity.',
        latitude: 53.539500,
        longitude: 9.999861,
        category: 'travel',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/Token_Westfield.png',
        relatedSetIds: ['set_hamburg'],
        defaultTier: TokenTier.gold,
        quests: [
          Quest(
            id: 'q21',
            title: 'Shopping-Besuch',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      // ─── Neue Hamburg Sights ───────────────────────────────────
      Landmark(
        id: '24',
        name: 'Rickmer Rickmers',
        description: 'Historisches Dreimaster-Museumsschiff am Hamburger Hafen – eines der bekanntesten Wahrzeichen der Hansestadt.',
        latitude: 53.544611,
        longitude: 9.972806,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q24', title: 'Rickmer Rickmers besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '25',
        name: 'Cap San Diego',
        description: 'Das weltgrößte fahrtüchtige Frachtmotorschiff der Nachkriegszeit liegt als Museumsschiff im Hamburger Hafen.',
        latitude: 53.543222,
        longitude: 9.976111,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q25', title: 'Cap San Diego erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '26',
        name: 'Alter Elbtunnel',
        description: 'Der historische Elbtunnel aus dem Jahr 1911 verbindet St. Pauli mit Steinwerder – ein technisches Denkmal der Kaiserzeit.',
        latitude: 53.545889,
        longitude: 9.966694,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q26', title: 'Durch den Tunnel spazieren', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '27',
        name: 'Alter Schwede',
        description: 'Der „Alte Schwede" – ein über 217 Tonnen schwerer Findling im Hamburger Stadtgebiet, eines der schwersten Gesteinsbrocken Norddeutschlands.',
        latitude: 53.544750,
        longitude: 9.895667,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q27', title: 'Den Alten Schweden finden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '28',
        name: 'St. Nikolai Kirche',
        description: 'Die Mahnmalkirche St. Nikolai erinnert an die Zerstörung Hamburgs im Zweiten Weltkrieg – der Turm ist ein Symbol des Friedens.',
        latitude: 53.547389,
        longitude: 9.990500,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        isChurch: true,
        quests: [Quest(id: 'q28', title: 'St. Nikolai besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '29',
        name: 'Miniatur Wunderland',
        description: 'Die weltgrößte Modelleisenbahn-Ausstellung mit über 1.500 Zügen und beeindruckenden Dioramen aus aller Welt.',
        latitude: 53.543944,
        longitude: 9.989056,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 120,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q29', title: 'Miniatur Wunderland erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '30',
        name: 'Kunsthalle Hamburg',
        description: 'Eines der bedeutendsten deutschen Kunstmuseen mit Werken vom Mittelalter bis zur Gegenwart.',
        latitude: 53.554417,
        longitude: 10.004278,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q30', title: 'Kunsthalle besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '31',
        name: 'Museum für Kunst und Gewerbe',
        description: 'Das Museum für Kunst und Gewerbe Hamburg vereint Kunsthandwerk und Design aus Jahrtausenden und Kulturen.',
        latitude: 53.554417,
        longitude: 10.007417,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q31', title: 'MKG entdecken', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '32',
        name: 'Maritimes Museum',
        description: 'Das Internationale Maritime Museum Hamburg beherbergt eine der weltgrößten privatem Sammlungen zur Seefahrtsgeschichte.',
        latitude: 53.543111,
        longitude: 9.999694,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q32', title: 'Maritimes Museum erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '33',
        name: 'Staatsoper Hamburg',
        description: 'Die Hamburgische Staatsoper ist eines der renommiertesten Opernhäuser der Welt mit einer jahrhundertealten Tradition.',
        latitude: 53.556861,
        longitude: 9.988444,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q33', title: 'Staatsoper besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '34',
        name: 'Dockland',
        description: 'Das markante schräge Bürogebäude Dockland liegt direkt an der Elbe in Altona mit spektakulärem Ausblick auf den Hafen.',
        latitude: 53.543361,
        longitude: 9.934333,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q34', title: 'Dockland Aussichtspunkt', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '35',
        name: 'Planetarium Hamburg',
        description: 'Das Hamburger Planetarium im Stadtpark – eines der ältesten und größten Planetarien Deutschlands in einem historischen Wasserturm.',
        latitude: 53.596528,
        longitude: 10.010000,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q35', title: 'Sterne beobachten', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '36',
        name: 'Altonaer Balkon',
        description: 'Der Altonaer Balkon ist eine erhöhte Promenade mit herrlichem Panoramablick über die Elbe und den Hamburger Hafen.',
        latitude: 53.545361,
        longitude: 9.935361,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q36', title: 'Aussicht genießen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '37',
        name: 'Große Freiheit',
        description: 'Die Große Freiheit auf St. Pauli ist Hamburgs bekannteste Ausgehmeile und Heimat legendärer Musikclubs.',
        latitude: 53.550889,
        longitude: 9.957694,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q37', title: 'Große Freiheit erleben', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '38',
        name: 'Beatles-Platz',
        description: 'Der Beatles-Platz auf der Reeperbahn erinnert an die frühen Jahre der Fab Four in Hamburg, wo sie ihre Karriere starteten.',
        latitude: 53.549917,
        longitude: 9.957361,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q38', title: 'Beatles-Platz besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '39',
        name: 'Hans-Albers-Platz',
        description: 'Der Hans-Albers-Platz im Hamburger Stadtteil St. Pauli ist nach dem legendären Hamburger Schauspieler und Sänger benannt.',
        latitude: 53.548667,
        longitude: 9.960861,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q39', title: 'Hans-Albers-Platz erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '40',
        name: 'Millerntor-Stadion',
        description: 'Das Millerntor-Stadion ist die Heimspielstätte des FC St. Pauli – eines der kultigsten Fußballvereine der Welt.',
        latitude: 53.554361,
        longitude: 9.967722,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q40', title: 'Millerntor erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '41',
        name: 'St. Petri Kirche',
        description: 'Die St. Petri Kirche ist eine der ältesten Kirchen Hamburgs und ein wichtiges Wahrzeichen in der Hamburger Innenstadt.',
        latitude: 53.5501,
        longitude: 9.9988,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        isChurch: true,
        quests: [Quest(id: 'q41', title: 'St. Petri besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '42',
        name: 'Museumshafen Övelgönne',
        description: 'Der Museumshafen Neumühlen/Övelgönne beherbergt historische Schiffe und bietet einen malerischen Blick auf die Elbe.',
        latitude: 53.543556,
        longitude: 9.914472,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q42', title: 'Museumshafen erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '43',
        name: 'Treppenviertel Blankenese',
        description: 'Das Treppenviertel in Blankenese mit seinen verwinkelt Gassen und Treppen gilt als eines der schönsten Wohnviertel Hamburgs.',
        latitude: 53.557417,
        longitude: 9.807611,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q43', title: 'Durch das Treppenviertel wandern', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '44',
        name: 'Ohlsdorfer Friedhof',
        description: 'Der Ohlsdorfer Friedhof ist der größte Parkfriedhof der Welt und gilt als grüne Oase der Ruhe in der Großstadt.',
        latitude: 53.6196,
        longitude: 10.0337,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q44', title: 'Friedhof erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '45',
        name: 'Sternwarte Bergedorf',
        description: 'Die historische Sternwarte Bergedorf ist eine der am besten erhaltenen Observatorien Deutschlands aus dem frühen 20. Jahrhundert.',
        latitude: 53.479750,
        longitude: 10.240000,
        category: 'sightseeing',
        difficulty: 'hard',
        pointsReward: 130,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q45', title: 'Sternwarte besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '46',
        name: 'Fischauktionshalle',
        description: 'Die historische Fischauktionshalle in Altona ist ein Jugendstil-Baudenkmal und heute Veranstaltungsort und Fischmarkt-Attraktion.',
        latitude: 53.544694,
        longitude: 9.951806,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q46', title: 'Fischauktionshalle erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '47',
        name: 'Hagenbecks Tierpark',
        description: 'Der weltweit erste Tierpark ohne Gitterstäbe – Hagenbecks Tierpark ist ein Hamburger Familienklassiker mit über 100-jähriger Geschichte.',
        latitude: 53.593472,
        longitude: 9.942944,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q47', title: 'Hagenbeck besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '48',
        name: 'Bismarck-Denkmal',
        description: 'Das imposante Bismarck-Denkmal im Alten Elbpark ist die größte freistehende Bismarck-Statue der Welt.',
        latitude: 53.548667,
        longitude: 9.971778,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q48', title: 'Bismarck entdecken', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '49',
        name: 'Alsterarkaden',
        description: 'Die Alsterarkaden sind eine elegante Bogenarkade am Hamburger Alsterfleet – ein beliebter Flanier- und Shoppingbereich.',
        latitude: 53.547389,
        longitude: 9.990500,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q49', title: 'Alsterarkaden schlendern', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '50',
        name: 'Hanseviertel',
        description: 'Das Hanseviertel ist ein elegantes Einkaufs- und Geschäftsviertel in der Hamburger Innenstadt mit historischen Passagen.',
        latitude: 53.553194,
        longitude: 9.989833,
        category: 'travel',
        difficulty: 'easy',
        pointsReward: 80,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q50', title: 'Hanseviertel erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '51',
        name: 'Auswanderermuseum BallinStadt',
        description: 'Das BallinStadt Auswanderermuseum in Hamburg-Veddel erinnert an die Millionen Europäer, die von Hamburg in die Neue Welt aufbrachen.',
        latitude: 53.5143,
        longitude: 10.0214,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q51', title: 'BallinStadt besuchen', taskType: 'checkin', completed: false)],
      ),

      // ─── Leipzig Sights ───────────────────────────────────────
      Landmark(
        id: '52',
        name: 'Gewandhaus Leipzig',
        description: 'Das weltberühmte Gewandhausorchester hat hier seine Heimat – eines der bedeutendsten Konzerthäuser Deutschlands.',
        latitude: 51.3397,
        longitude: 12.3804,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q52', title: 'Gewandhaus besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '53',
        name: 'Panoramatower Leipzig',
        description: 'Der Panoramatower auf dem Universitätshochhaus bietet einen spektakulären 360°-Blick über Leipzig.',
        latitude: 51.3397,
        longitude: 12.3799,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q53', title: 'Aussicht genießen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '54',
        name: 'Völkerschlachtdenkmal',
        description: 'Das mächtige Völkerschlachtdenkmal erinnert an die Völkerschlacht bei Leipzig 1813 – eines der größten Denkmäler Europas.',
        latitude: 51.3124,
        longitude: 12.4131,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 130,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q54', title: 'Denkmal erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '55',
        name: 'Bundesverwaltungsgericht',
        description: 'Das Bundesverwaltungsgericht in Leipzig residiert im historischen Reichsgerichtsgebäude – ein beeindruckendes Gründerzeitbauwerk.',
        latitude: 51.3381,
        longitude: 12.3718,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q55', title: 'Reichsgericht besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '56',
        name: 'Neues Rathaus Leipzig',
        description: 'Das Neue Rathaus Leipzig gilt als eines der größten deutschen Rathäuser – ein monumentaler Historismusbau am Burgplatz.',
        latitude: 51.3364,
        longitude: 12.3797,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q56', title: 'Neues Rathaus erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '57',
        name: 'Altes Rathaus Leipzig',
        description: 'Das Alte Rathaus am Marktplatz ist eines der schönsten Renaissancegebäude Deutschlands und beherbergt das Stadtgeschichtliche Museum.',
        latitude: 51.3406,
        longitude: 12.3746,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q57', title: 'Altes Rathaus besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '58',
        name: 'Marktplatz Leipzig',
        description: 'Der Marktplatz ist das Herz Leipzigs – umgeben von historischen Bauten und Schauplatz vieler Veranstaltungen.',
        latitude: 51.3406,
        longitude: 12.3748,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q58', title: 'Marktplatz erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '59',
        name: 'Red Bull Arena Leipzig',
        description: 'Die Red Bull Arena ist die Heimstätte von RB Leipzig – eines der modernsten Fußballstadien Deutschlands.',
        latitude: 51.3457,
        longitude: 12.3483,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q59', title: 'Arena besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '60',
        name: 'Grassi Museum',
        description: 'Das Grassi Museum beherbergt drei bedeutende Museen unter einem Dach: Völkerkunde, Musikinstrumente und angewandte Kunst.',
        latitude: 51.3356,
        longitude: 12.3896,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q60', title: 'Grassi erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '61',
        name: 'Neue Messe Leipzig',
        description: 'Die Neue Messe Leipzig mit ihrer imposanten Glashalle ist eines der modernsten Messezentren Europas.',
        latitude: 51.3978,
        longitude: 12.3924,
        category: 'travel',
        difficulty: 'medium',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q61', title: 'Messe erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '62',
        name: 'Südfriedhof Leipzig',
        description: 'Der Südfriedhof Leipzig ist einer der größten und schönsten Parkfriedhöfe Deutschlands mit beeindruckender Kapellenanlage.',
        latitude: 51.3098,
        longitude: 12.3751,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q62', title: 'Südfriedhof erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '63',
        name: 'Universität Leipzig',
        description: 'Die Universität Leipzig wurde 1409 gegründet und ist eine der ältesten Universitäten Deutschlands mit einem modernen Campus.',
        latitude: 51.3394,
        longitude: 12.3802,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q63', title: 'Campus besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '64',
        name: 'Zoo Leipzig',
        description: 'Der Zoo Leipzig gehört zu den besten Zoos Europas und ist bekannt für seine naturnahen Erlebnisbereiche wie die Gondwanaland-Tropenhalle.',
        latitude: 51.3528,
        longitude: 12.3690,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 120,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q64', title: 'Zoo besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '65',
        name: 'Clara-Zetkin-Park',
        description: 'Der Clara-Zetkin-Park ist die grüne Lunge Leipzigs – ein weitläufiger Stadtpark mit Seen, Wegen und dem bekannten Palmengarten.',
        latitude: 51.3302,
        longitude: 12.3542,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 80,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q65', title: 'Park erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '66',
        name: 'Haus Auensee',
        description: 'Das Haus Auensee ist eine traditionsreiche Veranstaltungshalle direkt am Auensee im Westen Leipzigs.',
        latitude: 51.3667,
        longitude: 12.3167,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q66', title: 'Auensee besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '67',
        name: 'Mädlerpassage',
        description: 'Die Mädlerpassage ist eine der schönsten Jugendstilpassagen Deutschlands – Heimat von Auerbachs Keller, Goethes Fauststätte.',
        latitude: 51.3404,
        longitude: 12.3762,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q67', title: 'Passage durchqueren', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '68',
        name: 'Oper Leipzig',
        description: 'Die Oper Leipzig ist eines der führenden Musiktheater Deutschlands mit einer über 300-jährigen Geschichte.',
        latitude: 51.3454,
        longitude: 12.3709,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 110,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_leipzig'],
        quests: [Quest(id: 'q68', title: 'Oper besuchen', taskType: 'checkin', completed: false)],
      ),

      // ─── Weitere Hamburg Sights ────────────────────────────────
      Landmark(
        id: '69',
        name: 'Niendorfer Gehege',
        description: 'Das Niendorfer Gehege ist ein rund 200 Hektar großes Waldgebiet im Hamburger Norden – ideal zum Spazieren, Joggen und Naturerleben.',
        latitude: 53.593472,
        longitude: 9.942944,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 90,
        imageUrl: 'assets/images/default_token.jpeg',
        checkInRadiusKm: 0.6,
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q69', title: 'Niendorfer Gehege erkunden', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '70',
        name: 'Airbus Aussichtsplattform',
        description: 'Von der öffentlichen Aussichtsplattform am Airbus-Werk in Finkenwerder können Besucher die riesigen Flugzeuge hautnah beim Start und Landeanflug beobachten.',
        latitude: 53.530778,
        longitude: 9.830722,
        category: 'sightseeing',
        difficulty: 'medium',
        pointsReward: 120,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q70', title: 'Flugzeug beobachten', taskType: 'photo', completed: false)],
      ),
      Landmark(
        id: '71',
        name: 'Boberger Dünen',
        description: 'Die Boberger Dünen sind ein einzigartiges Naturschutzgebiet im Hamburger Osten – die einzigen Binnendünen der Stadt mit seltener Tier- und Pflanzenwelt.',
        latitude: 53.510056,
        longitude: 10.157972,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q71', title: 'Dünen fotografieren', taskType: 'photo', completed: false)],
      ),
      Landmark(
        id: '72',
        name: 'Fischauktionshalle',
        description: 'Die historische Fischauktionshalle in Altona stammt aus dem Jahr 1896 und ist heute ein Veranstaltungsort sowie Wahrzeichen des Hamburger Fischmarkts.',
        latitude: 53.544694,
        longitude: 9.951806,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [Quest(id: 'q72', title: 'Fischauktionshalle besuchen', taskType: 'checkin', completed: false)],
      ),
      Landmark(
        id: '73',
        name: 'Museum der Arbeit',
        description:
            'Das Museum der Arbeit in Barmbek zeigt die Arbeits- und Alltagsgeschichte Hamburgs von der Industrialisierung bis heute.',
        latitude: 53.5797,
        longitude: 10.0417,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [
          Quest(
            id: 'q73',
            title: 'Museum der Arbeit besuchen',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '74',
        name: 'Museum für Hamburgische Geschichte',
        description:
            'Das Museum für Hamburgische Geschichte erzählt die Entwicklung der Stadt von den Anfängen bis in die Gegenwart.',
        latitude: 53.5516,
        longitude: 9.9746,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [
          Quest(
            id: 'q74',
            title: 'Hamburg-Museum erkunden',
            taskType: 'checkin',
            completed: false,
          ),
        ],
      ),
      Landmark(
        id: '75',
        name: 'Völkerkundemuseum Hamburg',
        description:
            'Das Völkerkundemuseum (MARKK) zeigt Kulturen der Welt mit umfangreichen Sammlungen aus allen Kontinenten.',
        latitude: 53.5675,
        longitude: 9.9870,
        category: 'sightseeing',
        difficulty: 'easy',
        pointsReward: 100,
        imageUrl: 'assets/images/default_token.jpeg',
        relatedSetIds: ['set_hamburg'],
        quests: [
          Quest(
            id: 'q75',
            title: 'Völkerkundemuseum besuchen',
            taskType: 'checkin',
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

    // Spezielle Tier-Bilder für Speicherstadt
    if (landmarkId == '1') {
      switch (tier) {
        case TokenTier.bronze:
          return 'assets/images/Speicherstadt_bronze.jpeg';
        case TokenTier.silver:
          return 'assets/images/Speicherstadt_silber.jpeg';
        case TokenTier.gold:
          return 'assets/images/Speicherstadt_gold_neu.jpeg';
        case TokenTier.platinum:
          return 'assets/images/Speicherstadt_platin.png';
        case TokenTier.monumente:
          return 'assets/images/Speicherstandt-monumente_token.png';
      }
    }

    // Spezielle Tier-Bilder für Elbphilharmonie
    if (landmarkId == '2') {
      switch (tier) {
        case TokenTier.bronze:
          return 'assets/images/Token_Elbphilhamonie_Bronze.png';
        case TokenTier.silver:
          return 'assets/images/Token_Elbphilhamonie_silber.png';
        case TokenTier.gold:
          return 'assets/images/Token_Elbphilhamonie_silber.png';
        case TokenTier.platinum:
          return 'assets/images/Token_Elbphilhamonie_silber.png';
        case TokenTier.monumente:
          return 'assets/images/monument_token.png';
      }
    }

    // Spezielle Tier-Bilder für Laeiszhalle
    if (landmarkId == '3') {
      switch (tier) {
        case TokenTier.bronze:
          return 'assets/images/Leiszhalle_bronze.png';
        case TokenTier.silver:
          return 'assets/images/Leiszhalle_silber.png';
        case TokenTier.gold:
          return 'assets/images/Token_gold_laeiszhalle.png';
        case TokenTier.platinum:
          return 'assets/images/Token_Leiszhalle_platin.png';
        case TokenTier.monumente:
          return 'assets/images/Token_Leiszhalle_platin.png';
      }
    }

    // Spezielle Tier-Bilder für Michel
    if (landmarkId == '4') {
      switch (tier) {
        case TokenTier.bronze:
          return 'assets/images/Michel_Bronze.jpeg';
        case TokenTier.silver:
          return 'assets/images/Token_Michel_silber.png';
        case TokenTier.gold:
          return 'assets/images/Token_gold_Michel.png';
        case TokenTier.platinum:
          return 'assets/images/Michel_platin.png';
        case TokenTier.monumente:
          return 'assets/images/Michel_monumente_token.png';
      }
    }

    // Spezielle Tier-Bilder für Volksparkstadion
    if (landmarkId == '6') {
      switch (tier) {
        case TokenTier.bronze:
          return 'assets/images/Volksparkstadion_bronze.jpeg';
        case TokenTier.silver:
          return 'assets/images/Volksparkstadion_silber .jpeg';
        case TokenTier.gold:
          return 'assets/images/Token_gold_volksparkstadion.png';
        case TokenTier.platinum:
          return 'assets/images/Token_gold_volksparkstadion.png'; // Fallback
        case TokenTier.monumente:
          return 'assets/images/Token_gold_volksparkstadion.png';
      }
    }

    // Spezielle Tier-Bilder für Atlantic Hotel
    if (landmarkId == '13') {
      switch (tier) {
        case TokenTier.bronze:
          return 'assets/images/Atlantichotel_bronze.jpeg';
        case TokenTier.silver:
          return 'assets/images/Atlantichotel_silber.jpeg';
        case TokenTier.gold:
          return 'assets/images/Token_Atlantic_Gold.png';
        case TokenTier.platinum:
          return 'assets/images/Atlantichotel_platin.png';
        case TokenTier.monumente:
          return 'assets/images/Token_Atlantic_Gold.png';
      }
    }

    // Spezielle Tier-Bilder für Landungsbrücken
    if (landmarkId == '18') {
      switch (tier) {
        case TokenTier.bronze:
          return 'assets/images/Landungsbrücken_bronze.jpeg';
        case TokenTier.silver:
          return 'assets/images/Landungsbrücken_silber.jpeg';
        case TokenTier.gold:
          return 'assets/images/Token_Landungsbrücken_Gold.png';
        case TokenTier.platinum:
          return 'assets/images/Landungsbrücken_platin.png';
        case TokenTier.monumente:
          return 'assets/images/Token_Landungsbrücken_Gold.png';
      }
    }

    // Spezielle Tier-Bilder für Hamburger Rathaus
    if (landmarkId == '20') {
      switch (tier) {
        case TokenTier.bronze:
          return 'assets/images/Rathhaus_bronze.jpeg';
        case TokenTier.silver:
          return 'assets/images/Rathhaus_silber.jpeg';
        case TokenTier.gold:
          return 'assets/images/Token_Rathaus_Gold.png';
        case TokenTier.platinum:
          return 'assets/images/Rathaus_platin.png';
        case TokenTier.monumente:
          return 'assets/images/Token_Rathaus_Gold.png';
      }
    }

    // Für andere Landmarks: Verwende Standard-Bild
    return landmark.imageUrl;
  }

  String getMapPinForTier(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:
        return 'assets/images/default_token.jpeg';
      case TokenTier.silver:
        return 'assets/images/Map_pin_silber.png';
      case TokenTier.gold:
        return 'assets/images/map_pin_gold.png';
      case TokenTier.platinum:
        return 'assets/images/default_token.jpeg'; // Fallback
      case TokenTier.monumente:
        return 'assets/images/default_token.jpeg';
    }
  }
}
