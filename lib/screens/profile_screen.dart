import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/index.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer2<CollectionService, LocationService>(
        builder: (context, collectionService, locationService, child) {
          final stats = collectionService.getStatistics();
          final position = locationService.currentPosition;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar & Name
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    'Level ${_calculateLevel(stats['totalPoints'] ?? 0)}',
                  ),
                  backgroundColor: Colors.amber[100],
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    'Level ${_calculateLevel(stats['totalPoints'] ?? 0)}',
                  ),
                  backgroundColor: Colors.amber[100],
                ),
                const SizedBox(height: 24),
                // Statistics Cards
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistics',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          context,
                          Icons.emoji_events,
                          'Total Points',
                          '${stats['totalPoints']}',
                          Colors.amber,
                        ),
                        const Divider(),
                        _buildStatRow(
                          context,
                          Icons.collections,
                          'Tokens Collected',
                          '${stats['totalTokens']}',
                          Colors.blue,
                        ),
                        const Divider(),
                        _buildStatRow(
                          context,
                          Icons.camera_alt,
                          'Sightseeing Tokens',
                          '${stats['sightseeingTokens']}',
                          Colors.purple,
                        ),
                        const Divider(),
                        _buildStatRow(
                          context,
                          Icons.flight,
                          'Travel Tokens',
                          '${stats['travelTokens']}',
                          Colors.green,
                        ),
                        const Divider(),
                        _buildStatRow(
                          context,
                          Icons.folder_special,
                          'Sets Completed',
                          '${stats['completedSets']}/${stats['totalSets']}',
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Location Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.red[400],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (position != null) ...[
                                    Text(
                                      'Latitude: ${position.latitude.toStringAsFixed(4)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    Text(
                                      'Longitude: ${position.longitude.toStringAsFixed(4)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ] else
                                    Text(
                                      'Location unavailable',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              locationService.isServiceEnabled
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: locationService.isServiceEnabled
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'GPS ${locationService.isServiceEnabled ? "Enabled" : "Disabled"}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  int _calculateLevel(int points) {
    return (points / 100).floor() + 1;
  }
}
