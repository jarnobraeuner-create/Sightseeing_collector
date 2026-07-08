import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/index.dart';
import 'screens/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // App startet trotzdem - offline-Mode
  }
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
  }
  runApp(const SightseeingCollectorApp());
}

class SightseeingCollectorApp extends StatelessWidget {
  const SightseeingCollectorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => LandmarkService()),
        ChangeNotifierProvider(create: (_) => MapModeService()),
        // CollectionService bekommt die userId vom AuthService
        ChangeNotifierProxyProvider<AuthService, CollectionService>(
          create: (_) => CollectionService(),
          update: (_, auth, service) {
            service!.setUserId(
              auth.isLoggedIn ? auth.firebaseUser?.uid : null,
            );
            return service;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, AuctionService>(
          create: (_) => AuctionService(),
          update: (_, auth, service) {
            service!.setCurrentUserId(
              auth.isLoggedIn ? auth.firebaseUser?.uid : null,
            );
            return service;
          },
        ),
        ChangeNotifierProvider(create: (_) => LootboxService()),
        ChangeNotifierProvider(create: (_) => CooldownService()),
        ChangeNotifierProvider(create: (_) => DailyRewardService()),
        ChangeNotifierProvider(create: (_) => NightTokenService()),
        ChangeNotifierProxyProvider<AuthService, DevModeService>(
          create: (_) => DevModeService(),
          update: (_, auth, service) {
            service!.syncAuthorization(
              username: auth.appUser?.username,
              email: auth.appUser?.email,
              uid: auth.firebaseUser?.uid,
            );
            return service;
          },
        ),
        ChangeNotifierProxyProvider<DevModeService, EventService>(
          create: (_) => EventService(),
          update: (_, devMode, event) {
            event!.setDevMode(devMode.enabled);
            return event;
          },
        ),
        ChangeNotifierProxyProvider3<AuthService, EventService, LandmarkService,
            EventTokenService>(
          create: (_) => EventTokenService(),
          update: (_, auth, events, landmarks, service) {
            service!
              ..setUser(
                auth.isLoggedIn ? auth.firebaseUser?.uid : null,
                auth.appUser?.username,
              )
              ..configureFromLocalEvents(
                events: EventService.allEvents,
                landmarks: landmarks.landmarks,
                activeEventId: events.activeEventId,
                nextEventId: events.nextEventId,
                activeWindowStart: events.activeEventStart,
                activeWindowEnd: events.activeEventEnd,
              );
            return service;
          },
        ),
        ChangeNotifierProvider(create: (_) => CosmeticService()),
        ChangeNotifierProxyProvider2<AuthService, CollectionService, FriendService>(
          create: (_) => FriendService(),
          update: (_, auth, collection, service) {
            service!.setUser(
              auth.isLoggedIn ? auth.firebaseUser?.uid : null,
              auth.appUser?.username,
            );
            if (auth.isLoggedIn && collection.isLoaded) {
              final stats = collection.getStatistics();
              service.syncLiveStatsFromCollection(
                stats.map((key, value) => MapEntry(key, value.toInt())),
              );
            }
            return service;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Sightseeing Collector',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
