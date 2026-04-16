import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';

class MapScreenSafe extends StatelessWidget {
  const MapScreenSafe({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karte (Sichere Version)'),
      ),
      body: Consumer2<LandmarkService, LocationService>(
        builder: (context, landmarkService, locationService, child) {
          final position = locationService.currentPosition;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (position != null)
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.my_location, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Dein Standort',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Sehenswürdigkeiten',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...landmarkService.landmarks.map((landmark) {
                final distance = position != null
                    ? landmark.getDistance(position.latitude, position.longitude)
                    : null;
                
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: distance != null && distance <= 0.1
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(landmark.name),
                    subtitle: Text(
                      distance != null
                          ? '${(distance * 1000).toStringAsFixed(0)} m entfernt'
                          : 'Standort unbekannt',
                    ),
                    trailing: Text('${landmark.pointsReward} pts'),
                    onTap: () {
                      _showLandmarkDetails(context, landmark);
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showLandmarkDetails(BuildContext context, Landmark landmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(landmark.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(landmark.description),
            const SizedBox(height: 16),
            Text('Koordinaten:'),
            Text(
              '${landmark.latitude.toStringAsFixed(4)}, ${landmark.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
