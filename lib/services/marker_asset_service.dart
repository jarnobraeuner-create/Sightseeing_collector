import '../models/event_token.dart';
import '../models/landmark.dart';

class MarkerAssetService {
  static const String normalTokenMarker = 'assets/images/map_pin_gold.png';
  static const String worldWonderMarker = 'assets/images/weltwunder_mappin.png';
  static const String bridgeEventMarker = 'assets/images/Brücke_mappin.png';
  static const String parkEventMarker = 'assets/images/Park_mappin.png';
  static const String nightModeMarker = 'assets/images/Nightmode_mappin.png';

  static String markerForLandmark(Landmark landmark) {
    if (landmark.category == 'weltwunder') {
      return worldWonderMarker;
    }
    if (landmark.mode == 'night') {
      return nightModeMarker;
    }
    return normalTokenMarker;
  }

  static String markerForEventToken(EventToken token) {
    if (token.markerImageUrl.isNotEmpty) {
      return token.markerImageUrl;
    }
    switch (token.eventId) {
      case 'park_hunter_2026':
        return parkEventMarker;
      case 'bruecken_august_2026':
        return bridgeEventMarker;
      default:
        return normalTokenMarker;
    }
  }
}