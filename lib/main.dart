import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/index.dart';
import 'screens/index.dart';

void main() {
  runApp(const SightseeingCollectorApp());
}

class SightseeingCollectorApp extends StatelessWidget {
  const SightseeingCollectorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => LandmarkService()),
        ChangeNotifierProvider(create: (_) => CollectionService()),
        ChangeNotifierProvider(create: (_) => AuctionService()),
      ],
      child: MaterialApp(
        title: 'Sightseeing Collector',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
