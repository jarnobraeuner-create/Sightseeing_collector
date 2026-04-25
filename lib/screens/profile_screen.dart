import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class _LoggedInProfile extends StatelessWidget {
  const _LoggedInProfile({Key? key}) : super(key: key);

  int _calculateLevel(int points) => (points / 100).floor() + 1;

  Future<void> _logout(BuildContext context, AuthService auth) async {
    try {
      await (auth as dynamic).signOut();
    } catch (_) {
      try {
        await (auth as dynamic).logout();
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abmelden ist aktuell nicht verfügbar.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final appUser = authService.appUser as dynamic;

    final String username = appUser?.username ?? 'Gast';
    final int totalPoints = 0;
    final int visitedLandmarks = 0;
    final int collectedTokens = 0;
    final int level = _calculateLevel(totalPoints);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            tooltip: 'Abmelden',
            onPressed: () => _logout(context, authService),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.amber[700],
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Level $level',
                style: const TextStyle(color: Colors.amber),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              Consumer<LootboxService>(
                builder: (context, lootboxService, _) {
                  final int lootboxCount =
                      lootboxService.extraLootboxes +
                      (lootboxService.canOpen ? 1 : 0);

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.card_giftcard,
                              label: 'Lootboxen\n$lootboxCount',
                              color: Colors.amber[700]!,
                              onTap: lootboxService.canOpenAny
                                  ? () => showDialog(
                                        context: context,
                                        builder: (_) => const LootboxDialog(),
                                      )
                                  : () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  );
                },
              ),

              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.collections,
                      label: 'Sammlung',
                      color: Colors.deepPurple,
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
                      label: 'Token-Upgrade',
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TokenUpgradeScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _DarkCard(
                title: 'Statistiken',
                children: [
                  _StatRow(
                    icon: Icons.star,
                    label: 'Gesamtpunkte',
                    value: totalPoints.toString(),
                    color: Colors.amber,
                  ),
                  _StatRow(
                    icon: Icons.location_on,
                    label: 'Besuchte Orte',
                    value: visitedLandmarks.toString(),
                    color: Colors.lightBlueAccent,
                  ),
                  _StatRow(
                    icon: Icons.collections,
                    label: 'Gesammelte Tokens',
                    value: collectedTokens.toString(),
                    color: Colors.deepPurpleAccent,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const _FeedbackCard(),
              const SizedBox(height: 18),

              Consumer<DevModeService>(
                builder: (context, devMode, _) {
                  if (!devMode.isAllowed(
                    username: authService.appUser?.username,
                    email: authService.appUser?.email,
                    uid: authService.appUser?.uid,
                  )) {
                    return const SizedBox.shrink();
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 24),
                      child: ElevatedButton.icon(
                        icon: Icon(
                          devMode.enabled
                              ? Icons.developer_mode
                              : Icons.developer_board,
                        ),
                        label: Text(
                          devMode.enabled
                              ? 'Entwicklermodus deaktivieren'
                              : 'Entwicklermodus aktivieren',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              devMode.enabled ? Colors.red[400] : Colors.amber[700],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => devMode.toggle(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
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
                  color: color.withOpacity(0.4),
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
          'Schicke Fehlerberichte oder Verbesserungsvorschläge direkt per E-Mail.',
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
          label: Text(
            _selectedImage == null ? 'Optional Bild hochladen' : 'Bild ändern',
          ),
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
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red[300],
                ),
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

  const _DarkCard({
    required this.title,
    required this.children,
  });

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
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
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