import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/index.dart';
import 'screens/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.initialize();
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
