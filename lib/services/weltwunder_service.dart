import '../models/token.dart';
import '../models/landmark.dart';

class WeltwunderService {
  static bool isWeltwunderLandmark(Landmark landmark) {
    return landmark.category == 'weltwunder';
  }

  static Weltwunder toWeltwunder(Landmark landmark) {
    return Weltwunder(
      id: landmark.id,
      name: landmark.name,
      description: landmark.description,
      imageUrl: landmark.imageUrl,
      latitude: landmark.latitude,
      longitude: landmark.longitude,
    );
  }
}
