import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/index.dart';
import '../widgets/lootbox_dialog.dart';
import 'collection_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text('Profil', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<AuthService>(
            builder: (_, auth, __) => IconButton(
              icon: const Icon(Icons.logout, color: Colors.grey),
              tooltip: 'Abmelden',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.grey[850],
                    title: const Text('Abmelden?',
                        style: TextStyle(color: Colors.white)),
                    content: const Text('Möchtest du dich wirklich abmelden?',
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Abbrechen'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Abmelden',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) auth.logout();
              },
            ),
          ),
        ],
      ),
      body: Consumer3<CollectionService, LocationService, AuthService>(
        builder: (context, collectionService, locationService, authService, child) {
          final stats = collectionService.getStatistics();
          final position = locationService.currentPosition;
          final level = _calculateLevel(stats['totalPoints'] ?? 0);
          final username = authService.appUser?.username ?? 'Explorer';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.amber[700]!, Colors.orange[800]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authService.appUser?.email ?? '',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[800]!, Colors.amber[500]!],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Level $level',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.collections,
                        label: 'Meine Sammlung',
                        color: Colors.blue[700]!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CollectionScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<LootboxService>(
                        builder: (context, lootboxService, _) {
                          final canOpen = lootboxService.canOpen;
                          return _ActionButton(
                            icon: Icons.card_giftcard,
                            label: canOpen ? 'Lootbox! 🎁' : 'Lootbox',
                            color: canOpen ? Colors.orange[700]! : Colors.grey[700]!,
                            badge: canOpen,
                            onTap: () => showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const LootboxDialog(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[900]!, Colors.orange[800]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deine Coins',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            '${stats['totalPoints']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DarkCard(
                  title: 'Statistiken',
                  children: [
                    _StatRow(
                      icon: Icons.collections,
                      label: 'Tokens gesammelt',
                      value: '${stats['totalTokens']}',
                      color: Colors.blue[400]!,
                    ),
                    _StatRow(
                      icon: Icons.camera_alt,
                      label: 'Sightseeing Tokens',
                      value: '${stats['sightseeingTokens']}',
                      color: Colors.purple[400]!,
                    ),
                    _StatRow(
                      icon: Icons.flight,
                      label: 'Travel Tokens',
                      value: '${stats['travelTokens']}',
                      color: Colors.green[400]!,
                    ),
                    _StatRow(
                      icon: Icons.folder_special,
                      label: 'Sets abgeschlossen',
                      value: '${stats['completedSets']}/${stats['totalSets']}',
                      color: Colors.orange[400]!,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DarkCard(
                  title: 'Standort',
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red[400], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: position != null
                              ? Text(
                                  '${position.latitude.toStringAsFixed(4)}° N, '
                                  '${position.longitude.toStringAsFixed(4)}° E',
                                  style: const TextStyle(color: Colors.white70),
                                )
                              : const Text(
                                  'Kein Standort verfügbar',
                                  style: TextStyle(color: Colors.grey),
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
                              ? Colors.green[400]
                              : Colors.red[400],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'GPS ${locationService.isServiceEnabled ? "aktiv" : "deaktiviert"}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  int _calculateLevel(int points) => (points / 100).floor() + 1;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool badge;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (badge)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DarkCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
