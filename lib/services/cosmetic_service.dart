import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/token.dart';

// ─── Profile Frame Definition ────────────────────────────────────────────────

class ProfileFrame {
  final String id;
  final String name;
  final String description;
  final int price;
  final Color primaryColor;
  final Color secondaryColor;
  final String emoji;
  /// Minimum token tier the player must own at least one of.
  final TokenTier requiredTier;

  const ProfileFrame({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.primaryColor,
    required this.secondaryColor,
    required this.emoji,
    required this.requiredTier,
  });

  List<Color> get gradientColors => [primaryColor, secondaryColor];
}

// ─── CosmeticService ─────────────────────────────────────────────────────────

class CosmeticService extends ChangeNotifier {
  static const _ownedKey = 'cosmetic_owned_frames_v1';
  static const _selectedKey = 'cosmetic_selected_frame_v1';
  static const _profileImageKey = 'cosmetic_profile_image_v1';

  // ── Available Frames ──────────────────────────────────────────────────────
  static const List<ProfileFrame> availableFrames = [
    ProfileFrame(
      id: 'bronze',
      name: 'Bronze Rahmen',
      description: 'Ein solider bronzener Rahmen für Einsteiger.',
      price: 500,
      primaryColor: Color(0xFFCD7F32),
      secondaryColor: Color(0xFF8B4513),
      emoji: '🥉',
      requiredTier: TokenTier.bronze,
    ),
    ProfileFrame(
      id: 'silver',
      name: 'Silber Rahmen',
      description: 'Schimmerndes Silber für erfahrene Sammler.',
      price: 1500,
      primaryColor: Color(0xFFE8E8E8),
      secondaryColor: Color(0xFF808080),
      emoji: '🥈',
      requiredTier: TokenTier.silver,
    ),
    ProfileFrame(
      id: 'gold',
      name: 'Gold Rahmen',
      description: 'Goldglänzender Rahmen für wahre Experten.',
      price: 3000,
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFFFF8C00),
      emoji: '🥇',
      requiredTier: TokenTier.gold,
    ),
    ProfileFrame(
      id: 'platinum',
      name: 'Platin Rahmen',
      description: 'Eisblauer Rahmen für die Elite der Sammler.',
      price: 6000,
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF0088FF),
      emoji: '💎',
      requiredTier: TokenTier.platinum,
    ),
    ProfileFrame(
      id: 'monumente',
      name: 'Monumente Rahmen',
      description: 'Mystischer lila Rahmen für Denkmal-Meister.',
      price: 10000,
      primaryColor: Color(0xFF9C27B0),
      secondaryColor: Color(0xFF4A0080),
      emoji: '🏛️',
      requiredTier: TokenTier.monumente,
    ),
    ProfileFrame(
      id: 'weltwunder',
      name: 'Weltwunder Rahmen',
      description: 'Exklusiver Rahmen für Weltreisende.',
      price: 20000,
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF00FF88),
      emoji: '🌍',
      requiredTier: TokenTier.weltwunder,
    ),
  ];

  List<String> _ownedFrameIds = [];
  String? _selectedFrameId;
  String? _profileImagePath;

  CosmeticService() {
    _loadFromPrefs();
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  List<String> get ownedFrameIds => _ownedFrameIds;
  String? get selectedFrameId => _selectedFrameId;
  String? get profileImagePath => _profileImagePath;

  ProfileFrame? get selectedFrame => _selectedFrameId == null
      ? null
      : availableFrames.where((f) => f.id == _selectedFrameId).firstOrNull;

  bool hasFrame(String id) => _ownedFrameIds.contains(id);

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> purchaseFrame(String frameId) async {
    if (_ownedFrameIds.contains(frameId)) return;
    _ownedFrameIds.add(frameId);
    notifyListeners();
    await _persist();
  }

  Future<void> selectFrame(String? frameId) async {
    _selectedFrameId = frameId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (frameId != null) {
      await prefs.setString(_selectedKey, frameId);
    } else {
      await prefs.remove(_selectedKey);
    }
  }

  Future<void> setProfileImagePath(String? path) async {
    _profileImagePath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_profileImageKey, path);
    } else {
      await prefs.remove(_profileImageKey);
    }
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ownedKey);
    if (raw != null) {
      _ownedFrameIds = List<String>.from(jsonDecode(raw) as List);
    }
    _selectedFrameId = prefs.getString(_selectedKey);
    _profileImagePath = prefs.getString(_profileImageKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ownedKey, jsonEncode(_ownedFrameIds));
  }

  /// Full reset: removes owned frames, selected frame and profile image.
  Future<void> resetAll() async {
    _ownedFrameIds = [];
    _selectedFrameId = null;
    _profileImagePath = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ownedKey);
    await prefs.remove(_selectedKey);
    await prefs.remove(_profileImageKey);
  }
}
