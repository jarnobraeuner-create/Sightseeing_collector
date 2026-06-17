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
        ChangeNotifierProvider(create: (_) => CosmeticService()),
        ChangeNotifierProxyProvider<AuthService, FriendService>(
          create: (_) => FriendService(),
          update: (_, auth, service) {
            service!.setUser(
              auth.isLoggedIn ? auth.firebaseUser?.uid : null,
              auth.appUser?.username,
            );
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
