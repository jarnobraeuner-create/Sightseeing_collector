import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isServiceEnabled = false;
  bool _isLocationAccessGranted = false;
  bool _isInitialized = false;

  Position? get currentPosition => _currentPosition;
  bool get isServiceEnabled => _isServiceEnabled;
  bool get isLocationAccessGranted => _isLocationAccessGranted;

  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50, // Update every 50 meters (Performance optimiert)
        ),
      );

  LocationService() {
    // Initialisierung nicht automatisch starten
    debugPrint('LocationService created (not initialized)');
  }

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    try {
      await _checkPermissions();
      if (_isLocationAccessGranted && _isServiceEnabled) {
        await refreshLocation();
        
        // Listen to position stream
        positionStream.listen(
          (Position position) {
            _currentPosition = position;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error in position stream: $error');
          },
        );
      }
    } catch (e) {
      debugPrint('Error initializing LocationService: $e');
    }
  }

  Future<void> _checkPermissions() async {
    // Check if location service is enabled
    _isServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!_isServiceEnabled) {
      notifyListeners();
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _isLocationAccessGranted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    try {
      await ensureInitialized();
      
      if (!_isServiceEnabled || !_isLocationAccessGranted) {
        await _checkPermissions();
      }

      if (_isServiceEnabled && _isLocationAccessGranted) {
        try {
          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 5));
          notifyListeners();
        } catch (e) {
          debugPrint('Error getting location: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in refreshLocation: $e');
    }
  }

  double? calculateDistance(double targetLat, double targetLon) {
    if (_currentPosition == null) return null;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLon,
    ) / 1000; // Convert to km
  }

  bool isNearby(double targetLat, double targetLon, {double radiusInKm = 0.1}) {
    final distance = calculateDistance(targetLat, targetLon);
    return distance != null && distance <= radiusInKm;
  }
}
