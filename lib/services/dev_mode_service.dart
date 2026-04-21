import 'package:flutter/foundation.dart';

/// Einfacher Toggle-Service für den Developer-Mode.
/// Dev-Mode schaltet Standort- und Coin-Beschränkungen ab.
class DevModeService extends ChangeNotifier {
  bool _enabled = false;

  bool get enabled => _enabled;

  void toggle() {
    _enabled = !_enabled;
    debugPrint('DevMode: $_enabled');
    notifyListeners();
  }

  void disable() {
    if (_enabled) {
      _enabled = false;
      notifyListeners();
    }
  }
}
