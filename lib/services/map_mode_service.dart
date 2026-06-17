import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verwaltet den globalen Tag-/Nachtmodus der Karte
/// Unterstützt mehrere Modi für zukünftige Erweiterung (z.B. Event-, Winter-, Halloweenmodus)
class MapModeService extends ChangeNotifier {
  static const String _prefKey = 'map_mode_v1';
  static const String _modeDayValue = 'day';
  static const String _modeNightValue = 'night';

  String _currentMode = _modeNightValue;
  bool _isLoaded = false;

  String get currentMode => _currentMode;
  bool get isDayMode => _currentMode == _modeDayValue;
  bool get isNightMode => _currentMode == _modeNightValue;
  bool get isLoaded => _isLoaded;

  /// Alle verfügbaren Modi (für zukünftige Erweiterbarkeit)
  static const List<String> availableModes = [
    _modeDayValue,
    _modeNightValue,
    // Zukünftig: 'event', 'winter', 'halloween', etc.
  ];

  MapModeService() {
    _loadSavedMode();
  }

  /// Lade den gespeicherten Modus aus LocalStorage
  Future<void> _loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey) ?? _modeDayValue;
      _currentMode = saved;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading map mode: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Wechsle zu einem neuen Modus
  Future<void> setMode(String mode) async {
    if (!availableModes.contains(mode)) {
      debugPrint('Invalid map mode: $mode');
      return;
    }

    if (_currentMode == mode) return; // Kein Wechsel nötig

    _currentMode = mode;
    notifyListeners();

    // Persistente Speicherung
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode);
      debugPrint('Map mode changed to: $mode');
    } catch (e) {
      debugPrint('Error saving map mode: $e');
    }
  }

  /// Toggle zwischen Tag und Nacht
  Future<void> toggleMode() async {
    final newMode = isDayMode ? _modeNightValue : _modeDayValue;
    await setMode(newMode);
  }

  /// DevMode: Reset zu Tagesmodus
  Future<void> resetToDay() async {
    await setMode(_modeDayValue);
  }
}
