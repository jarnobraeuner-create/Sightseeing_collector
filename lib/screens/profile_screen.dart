import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/index.dart';
import '../widgets/lootbox_dialog.dart';
import 'collection_screen.dart';
import 'token_upgrade_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _LoggedInProfile();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Eingeloggtes Profil
// ══════════════════════════════════════════════════════════════════════════════

class _LoggedInProfile extends StatelessWidget {
  const _LoggedInProfile();

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
                if (confirm == true) await auth.logout();
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
                      child: _ActionButton(
                        icon: Icons.upgrade,
                        label: 'Token Fusion',
                        color: Colors.purple[700]!,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TokenUpgradeScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<LootboxService>(
                        builder: (context, lootboxService, _) {
                          final canOpen = lootboxService.canOpenAny;
                          final extra = lootboxService.extraLootboxes;
                          String label;
                          if (lootboxService.canOpen && extra > 0) {
                            label = 'Lootbox 🎁 (+$extra)';
                          } else if (lootboxService.canOpen) {
                            label = 'Lootbox! 🎁';
                          } else if (extra > 0) {
                            label = 'Lootbox 🎁 ×$extra';
                          } else {
                            label = 'Morgen wieder';
                          }
                          return _ActionButton(
                            icon: Icons.card_giftcard,
                            label: label,
                            color: canOpen ? Colors.orange[700]! : Colors.grey[700]!,
                            badge: canOpen,
                            onTap: canOpen
                                ? () => showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const LootboxDialog(),
                                  )
                                : () => ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Du hast heute schon eine Lootbox geöffnet. Kaufe mehr im Shop! 🎁'),
                                      backgroundColor: Colors.grey,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Consumer<LootboxService>(
                  builder: (context, lootboxService, _) {
                    final monumentCount = lootboxService.monumentLootboxes;
                    final canOpenMonument = monumentCount > 0;
                    return _ActionButton(
                      icon: Icons.account_balance,
                      label: canOpenMonument
                          ? 'Monumente-Lootbox 🏛️ ×$monumentCount'
                          : 'Monumente-Lootboxen im Shop kaufen',
                      color: canOpenMonument
                          ? Colors.deepPurple[700]!
                          : Colors.grey[700]!,
                      badge: canOpenMonument,
                      onTap: canOpenMonument
                          ? () => showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const LootboxDialog(
                                  mode: LootboxDialogMode.monument,
                                ),
                              )
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Keine Monumente-Lootbox verfügbar. Kaufe sie im Shop! 🏛️',
                                  ),
                                  backgroundColor: Colors.grey,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              ),
                    );
                  },
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
                // ── Abmelden Button ──────────────────────────────────────
                Consumer<AuthService>(
                  builder: (_, auth, __) => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[400],
                        side: BorderSide(color: Colors.red[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Abmelden',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.grey[850],
                            title: const Text('Abmelden?',
                                style: TextStyle(color: Colors.white)),
                            content: const Text(
                                'Möchtest du dich wirklich abmelden?',
                                style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Abbrechen'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text('Abmelden',
                                    style: TextStyle(color: Colors.red[400])),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) await auth.logout();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _FeedbackCard(),
                const SizedBox(height: 16),
                Consumer<DevModeService>(
                  builder: (context, devMode, _) => _DarkCard(
                    title: '🛠 Developer Mode',
                    children: [
                      // ── Dev-Mode Toggle ──────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: devMode.enabled
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: devMode.enabled ? Colors.green : Colors.grey[700]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              devMode.enabled ? Icons.developer_mode : Icons.developer_mode_outlined,
                              color: devMode.enabled ? Colors.greenAccent : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    devMode.enabled ? 'Dev-Mode aktiv' : 'Dev-Mode inaktiv',
                                    style: TextStyle(
                                      color: devMode.enabled ? Colors.greenAccent : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    devMode.enabled
                                        ? 'Standort- & Coin-Beschränkungen aufgehoben'
                                        : 'Normale Spielbeschränkungen aktiv',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: devMode.enabled,
                              onChanged: (_) => devMode.toggle(),
                              activeColor: Colors.greenAccent,
                              inactiveTrackColor: Colors.grey[800],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // ── Cooldowns zurücksetzen ───────────────────
                      Consumer2<CooldownService, LootboxService>(
                        builder: (context, cooldownService, lootboxService, _) =>
                            SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.greenAccent,
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Alle Cooldowns zurücksetzen'),
                            onPressed: () async {
                              await cooldownService.resetAllCooldowns();
                              await lootboxService.resetForTesting();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Alle Cooldowns zurückgesetzt'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 32),
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

class _FeedbackCard extends StatefulWidget {
  const _FeedbackCard();

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final FeedbackService _feedbackService = FeedbackService();

  XFile? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted || pickedImage == null) return;

    setState(() {
      _selectedImage = pickedImage;
    });
  }

  Future<void> _submitFeedback() async {
    final message = _messageController.text;
    if (message.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte beschreibe dein Feedback im Textfeld.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await _feedbackService.sendFeedbackEmail(
      message: message,
      username: auth.appUser?.username,
      userEmail: auth.appUser?.email,
      imagePath: _selectedImage?.path,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kein Mail-Client verfügbar. Bitte später erneut versuchen.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _messageController.clear();
    setState(() {
      _selectedImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback wurde an den Mail-Client übergeben.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      title: '✉️ Feedback',
      children: [
        Text(
          'Schicke Fehlerberichte oder Verbesserungsvorschläge direkt per E-Mail. Die Empfängeradresse ist aktuell noch ein Platzhalter.',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageController,
          minLines: 5,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Beschreibe hier dein Problem oder Feedback...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.amber[700]!),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : _pickImage,
          icon: const Icon(Icons.image_outlined),
          label: Text(_selectedImage == null ? 'Optional Bild hochladen' : 'Bild ändern'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber[300],
            side: BorderSide(color: Colors.amber[700]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(
                    _selectedImage!.path,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(_selectedImage!.path),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedImage!.name,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Entfernen'),
                style: TextButton.styleFrom(foregroundColor: Colors.red[300]),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitFeedback,
            icon: Icon(_isSubmitting ? Icons.hourglass_top : Icons.send),
            label: Text(_isSubmitting ? 'Wird vorbereitet...' : 'Per E-Mail senden'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
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
