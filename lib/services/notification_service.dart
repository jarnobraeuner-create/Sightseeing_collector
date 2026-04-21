import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'sightseeing_main';
  static const _channelName = 'Sightseeing Collector';
  static const _channelDesc = 'Auktions- und Spielbenachrichtigungen';

  static const int _idBidReceived = 1;
  static const int _idAuctionExpired = 2;
  static const int _idBidAccepted = 3;
  static const int _idLootboxReady = 4;
  static const int _idMapUpdated = 5;

  static const _prefLandmarkCount = 'notif_landmark_count';

  /// Initialisiert den Plugin-Kern (ohne Permission-Dialog).
  /// Muss vor dem ersten show()-Aufruf laufen, kann in main() aufgerufen werden.
  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Fragt den User nach Notification-Erlaubnis.
  /// MUSS nach runApp() aufgerufen werden (Activity muss bereit sein).
  Future<void> requestPermissions() async {
    if (!_initialized) return;

    // Android 13+ (API 33)
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    // Exakte Alarme für Lootbox-Scheduled-Notif
    await android?.requestExactAlarmsPermission();

    // iOS
    final iOS = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iOS?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails get _details => NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      );

  // ── 1. Neues Gebot auf eigene Auktion ─────────────────────────
  Future<void> showBidReceived(String auctionTitle, int amount) async {
    if (!_initialized) return;
    await _plugin.show(
      _idBidReceived,
      '💰 Neues Gebot erhalten!',
      'Deine Auktion "$auctionTitle" hat ein Gebot von $amount Coins bekommen.',
      _details,
    );
  }

  // ── 2. Eigene Auktion abgelaufen ──────────────────────────────
  Future<void> showAuctionExpired(String auctionTitle) async {
    if (!_initialized) return;
    await _plugin.show(
      _idAuctionExpired,
      '⏰ Auktion abgelaufen',
      'Deine Auktion "$auctionTitle" ist abgelaufen.',
      _details,
    );
  }

  // ── 3. Gebot auf Token wurde angenommen ───────────────────────
  Future<void> showBidAccepted(String tokenName) async {
    if (!_initialized) return;
    await _plugin.show(
      _idBidAccepted,
      '🎉 Gebot angenommen!',
      'Dein Gebot auf "$tokenName" wurde angenommen. Der Token ist jetzt in deiner Sammlung.',
      _details,
    );
  }

  // ── 4. Lootbox-Cooldown abgelaufen (geplante Notif in 24h) ───
  Future<void> scheduleLootboxReady() async {
    if (!_initialized) return;
    await _plugin.cancel(_idLootboxReady);
    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));
    await _plugin.zonedSchedule(
      _idLootboxReady,
      '🎁 Lootbox bereit!',
      'Dein Cooldown ist abgelaufen – hol dir jetzt deinen täglichen Token!',
      scheduledDate,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── 5. Karte aktualisiert (nur wenn neue Landmarks) ──────────
  Future<void> checkAndNotifyMapUpdated(int currentCount) async {
    if (!_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final prevCount = prefs.getInt(_prefLandmarkCount) ?? -1;
    await prefs.setInt(_prefLandmarkCount, currentCount);
    if (prevCount > 0 && currentCount > prevCount) {
      final newOnes = currentCount - prevCount;
      await _plugin.show(
        _idMapUpdated,
        '🗺️ Karte aktualisiert!',
        '$newOnes neue Sehenswürdigkeit${newOnes == 1 ? '' : 'en'} wurden zur Karte hinzugefügt.',
        _details,
      );
    }
  }
}
