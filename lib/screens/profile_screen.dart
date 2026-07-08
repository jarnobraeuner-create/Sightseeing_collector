import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../widgets/lootbox_dialog.dart';
import 'collection_screen.dart';
import 'friends_screen.dart';
import 'leaderboard_screen.dart';
import 'trading_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _LoggedInProfile();
  }
}

class _LoggedInProfile extends StatefulWidget {
  const _LoggedInProfile();

  @override
  State<_LoggedInProfile> createState() => _LoggedInProfileState();
}

class _LoggedInProfileState extends State<_LoggedInProfile> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  bool _isSavingFavorites = false;
  bool _hasLocalFavoriteEdits = false;

  String? _activeUid;
  List<String> _favoriteTokenIds = const <String>[];

  int _calculateLevel(int points) => (points ~/ 100) + 1;

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _pickAndUploadProfileImage(String uid) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );
    if (!mounted || picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('profile')
          .child('avatar.jpg');

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        await storageRef.putFile(
          File(picked.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final url = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilbild aktualisiert.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profilbild konnte nicht gespeichert werden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  String _tokenImagePath(Token token, LandmarkService landmarkService) {
    if (token.tier != null) {
      return landmarkService.getImageUrlForTier(token.landmarkId, token.tier!);
    }
    return token.weltwunder?.imageUrl ?? 'assets/images/default_token.jpeg';
  }

  Map<String, dynamic> _tokenToFavoriteMap(
    Token token,
    LandmarkService landmarkService,
  ) {
    return {
      'tokenId': token.id,
      'landmarkId': token.landmarkId,
      'landmarkName': token.landmarkName,
      'tier': token.tier?.name,
      'points': token.points,
      'category': token.category,
      'imageUrl': _tokenImagePath(token, landmarkService),
      'worldWonderId': token.worldWonderId,
    };
  }

  Future<void> _persistFavoriteTokens({
    required String uid,
    required Map<String, Token> tokensById,
    required LandmarkService landmarkService,
  }) async {
    final clamped = _favoriteTokenIds
        .where(tokensById.containsKey)
        .take(5)
        .toList(growable: false);

    setState(() => _isSavingFavorites = true);

    try {
      final payload = clamped
          .map((id) => _tokenToFavoriteMap(tokensById[id]!, landmarkService))
          .toList(growable: false);

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'favoriteTokens': payload,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _favoriteTokenIds = clamped;
        _hasLocalFavoriteEdits = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingFavorites = false);
      }
    }
  }

  Future<void> _showAddFavoriteTokenSheet({
    required String uid,
    required List<Token> ownedTokens,
    required LandmarkService landmarkService,
  }) async {
    final alreadySelected = _favoriteTokenIds.toSet();
    final available = ownedTokens
        .where((t) => !alreadySelected.contains(t.id))
        .toList(growable: false);

    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine weiteren besessenen Tokens verfügbar.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<Token>(
      context: context,
      backgroundColor: const Color(0xFF151A26),
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: available.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (_, i) {
              final token = available[i];
              final imagePath = _tokenImagePath(token, landmarkService);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.pop(context, token),
                leading: _TokenThumbnail(imagePath: imagePath, size: 48),
                title: Text(
                  token.landmarkName,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${token.tier?.displayName ?? 'Weltwunder'} · ${token.points} Punkte',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                trailing:
                    const Icon(Icons.add_circle_outline, color: Colors.amber),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    if (_favoriteTokenIds.length >= 5) return;

    setState(() {
      _favoriteTokenIds = [..._favoriteTokenIds, selected.id];
      _hasLocalFavoriteEdits = true;
    });

    final tokensById = {for (final token in ownedTokens) token.id: token};
    await _persistFavoriteTokens(
      uid: uid,
      tokensById: tokensById,
      landmarkService: landmarkService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<CollectionService, AuthService, LandmarkService,
        DevModeService>(
      builder: (context, collectionService, authService, landmarkService,
          devModeService, _) {
        final uid = authService.firebaseUser?.uid;
        if (uid == null) {
          return const Scaffold(
            body: Center(child: Text('Nicht angemeldet')),
          );
        }

        final points = collectionService.totalPoints;
        final level = _calculateLevel(points);
        final ownedTokens = collectionService.tokens;
        final tokensById = {for (final token in ownedTokens) token.id: token};
        final canUseDevMode = devModeService.isAllowed(
          username: authService.appUser?.username,
          email: authService.appUser?.email,
          uid: authService.firebaseUser?.uid,
        );

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() ?? const <String, dynamic>{};
            final username = userData['username'] as String? ??
                authService.appUser?.username ??
                'Explorer';
            final photoUrl = userData['photoUrl'] as String?;

            final remoteFavoriteMaps =
                (userData['favoriteTokens'] as List<dynamic>? ?? const [])
                    .whereType<Map>()
                    .map((e) => e.map((k, v) => MapEntry('$k', v)))
                    .toList(growable: false);

            final remoteFavoriteIds = remoteFavoriteMaps
                .map((e) => e['tokenId'] as String? ?? '')
                .where((id) => id.isNotEmpty && tokensById.containsKey(id))
                .take(5)
                .toList(growable: false);

            if (_activeUid != uid) {
              _activeUid = uid;
              _favoriteTokenIds = remoteFavoriteIds;
              _hasLocalFavoriteEdits = false;
            } else if (!_hasLocalFavoriteEdits &&
                !_listEquals(_favoriteTokenIds, remoteFavoriteIds)) {
              _favoriteTokenIds = remoteFavoriteIds;
            }

            final favoriteTokens = _favoriteTokenIds
                .where(tokensById.containsKey)
                .map((id) => tokensById[id]!)
                .take(5)
                .toList(growable: false);

            return Scaffold(
              backgroundColor: const Color(0xFF0F111A),
              appBar: AppBar(
                backgroundColor: const Color(0xFF151A26),
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
                title: const Text(
                  'Profil',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    tooltip: 'Abmelden',
                    onPressed: () => authService.logout(),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              _OrbitingFavoriteTokens(
                                imagePaths: favoriteTokens
                                    .map((token) =>
                                        _tokenImagePath(token, landmarkService))
                                    .toList(growable: false),
                                size: 190,
                                radius: 76,
                                tokenSize: 29,
                                showFallbackText: false,
                              ),
                              SizedBox(
                                width: 112,
                                height: 112,
                                child: CircleAvatar(
                                  radius: 54,
                                  backgroundColor: Colors.amber[700],
                                  backgroundImage:
                                      (photoUrl != null && photoUrl.isNotEmpty)
                                          ? NetworkImage(photoUrl)
                                          : null,
                                  child: (photoUrl == null || photoUrl.isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          size: 52,
                                          color: Colors.black,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.amber[700],
                                    foregroundColor: Colors.black,
                                  ),
                                  onPressed: _isUploadingImage
                                      ? null
                                      : () => _pickAndUploadProfileImage(uid),
                                  icon: _isUploadingImage
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black,
                                          ),
                                        )
                                      : const Icon(Icons.photo_camera_outlined),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Level $level · $points Punkte · ${collectionService.getCompletedSets().length}/${collectionService.sets.length} Sets · ${collectionService.getStatistics()['worldWonderTokens'] ?? 0} Weltwunder',
                            style: TextStyle(
                                color: Colors.grey[300], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FavoriteShowcaseCard(
                      isSaving: _isSavingFavorites,
                      favoriteTokens: favoriteTokens,
                      landmarkService: landmarkService,
                      onAdd: favoriteTokens.length >= 5
                          ? null
                          : () => _showAddFavoriteTokenSheet(
                                uid: uid,
                                ownedTokens: ownedTokens,
                                landmarkService: landmarkService,
                              ),
                      onRemove: (tokenId) async {
                        setState(() {
                          _favoriteTokenIds = _favoriteTokenIds
                              .where((id) => id != tokenId)
                              .toList(growable: false);
                          _hasLocalFavoriteEdits = true;
                        });
                        await _persistFavoriteTokens(
                          uid: uid,
                          tokensById: tokensById,
                          landmarkService: landmarkService,
                        );
                      },
                      onReorder: (oldIndex, newIndex) async {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final updated = [..._favoriteTokenIds];
                        final moved = updated.removeAt(oldIndex);
                        updated.insert(newIndex, moved);
                        setState(() {
                          _favoriteTokenIds = updated;
                          _hasLocalFavoriteEdits = true;
                        });
                        await _persistFavoriteTokens(
                          uid: uid,
                          tokensById: tokensById,
                          landmarkService: landmarkService,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: const Color(0xFF1D2434),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.storefront),
                            label: const Text(
                              'Marketplace',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TradingScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: const Color(0xFF1D2434),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.collections),
                            label: const Text(
                              'Collection',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CollectionScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _LargeActionCard(
                      title: 'Freunde',
                      subtitle: 'Freundesliste, Anfragen und Profile',
                      icon: Icons.group,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FriendsScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LargeActionCard(
                      title: 'Leaderboard',
                      subtitle: 'Globale und Freundes-Rangliste',
                      icon: Icons.emoji_events,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<LootboxService>(
                      builder: (context, lootboxService, _) {
                        return _LargeActionCard(
                          title: 'Lootboxen',
                          subtitle:
                              '${lootboxService.extraLootboxes + (lootboxService.canOpen ? 1 : 0)} verfügbar',
                          icon: Icons.card_giftcard,
                          onTap: lootboxService.canOpenAny
                              ? () => showDialog(
                                    context: context,
                                    builder: (_) => const LootboxDialog(),
                                  )
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _SetProgressCard(sets: collectionService.sets),
                    if (canUseDevMode) ...[
                      const SizedBox(height: 12),
                      _DevModeCard(
                        enabled: devModeService.enabled,
                        onChanged: (_) => devModeService.toggle(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const _FeedbackCard(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DevModeCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _DevModeCard({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151A26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled
              ? Colors.tealAccent.withValues(alpha: 0.55)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.tealAccent.withValues(alpha: 0.15)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              enabled ? Icons.developer_mode : Icons.developer_mode_outlined,
              color: enabled ? Colors.tealAccent : Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dev Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Erweitere Testfunktionen aktivieren',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: Colors.tealAccent,
            activeTrackColor: Colors.tealAccent.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}

class _FavoriteShowcaseCard extends StatelessWidget {
  final bool isSaving;
  final List<Token> favoriteTokens;
  final LandmarkService landmarkService;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;
  final Future<void> Function(String tokenId) onRemove;
  final VoidCallback? onAdd;

  const _FavoriteShowcaseCard({
    required this.isSaving,
    required this.favoriteTokens,
    required this.landmarkService,
    required this.onReorder,
    required this.onRemove,
    required this.onAdd,
  });

  String _tokenImage(Token token) {
    if (token.tier != null) {
      return landmarkService.getImageUrlForTier(token.landmarkId, token.tier!);
    }
    return token.weltwunder?.imageUrl ?? 'assets/images/default_token.jpeg';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151A26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium,
                  color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lieblings-Tokens',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${favoriteTokens.length}/5',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.amber,
                tooltip: 'Token hinzufügen',
              ),
            ],
          ),
          if (isSaving)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (favoriteTokens.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Wähle bis zu 5 Tokens aus deiner Sammlung aus.',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 102,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                itemCount: favoriteTokens.length,
                onReorder: onReorder,
                itemBuilder: (_, index) {
                  final token = favoriteTokens[index];
                  return Container(
                    key: ValueKey(token.id),
                    width: 82,
                    margin: const EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: _TokenThumbnail(
                                imagePath: _tokenImage(token),
                                size: 58,
                              ),
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => onRemove(token.id),
                                icon: const Icon(Icons.close, size: 16),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.redAccent,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          token.landmarkName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _OrbitingFavoriteTokens extends StatefulWidget {
  final List<String> imagePaths;
  final double size;
  final double radius;
  final double tokenSize;
  final bool showFallbackText;

  const _OrbitingFavoriteTokens({
    required this.imagePaths,
    this.size = 150,
    this.radius = 58,
    this.tokenSize = 14,
    this.showFallbackText = true,
  });

  @override
  State<_OrbitingFavoriteTokens> createState() =>
      _OrbitingFavoriteTokensState();
}

class _OrbitingFavoriteTokensState extends State<_OrbitingFavoriteTokens>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _orbitController.repeat();
    } else {
      _orbitController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Opacity(
                opacity: widget.imagePaths.isEmpty ? 0.22 : 0.45,
                child: Lottie.asset(
                  'assets/lottie/loading_pulse.json',
                  width: widget.size * 0.9,
                  height: widget.size * 0.9,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
            if (widget.imagePaths.isEmpty && widget.showFallbackText)
              Text(
                'Keine Lieblings-Tokens ausgewählt',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              )
            else
              AnimatedBuilder(
                animation: _orbitController,
                builder: (_, __) {
                  final n = widget.imagePaths.length;
                  final angleBase = _orbitController.value * 2 * math.pi;
                  final center = widget.size / 2;

                  return Stack(
                    children: List.generate(n, (i) {
                      final angle = angleBase + ((2 * math.pi * i) / n);
                      final x = widget.radius * math.cos(angle);
                      final y = widget.radius * math.sin(angle);
                      return Positioned(
                        left: center + x - widget.tokenSize / 2,
                        top: center + y - widget.tokenSize / 2,
                        child: _TokenThumbnail(
                          imagePath: widget.imagePaths[i],
                          size: widget.tokenSize,
                          borderRadius: 5,
                        ),
                      );
                    }),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SetProgressCard extends StatelessWidget {
  final List<CollectionSet> sets;

  const _SetProgressCard({required this.sets});

  @override
  Widget build(BuildContext context) {
    final totalSets = sets.length;
    final completedSets = sets.where((s) => s.completed).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151A26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.collections_bookmark,
                  color: Colors.lightBlueAccent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Set-Fortschritt',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '$completedSets/$totalSets',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (sets.isEmpty)
            Text(
              'Keine Sets verfügbar',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            )
          else
            ...sets.map((set) {
              final total = set.requiredTokenIds.length;
              final progress = set.collectedTokenIds.length;
              final pct = total > 0 ? progress / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            set.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$progress/$total',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 7,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          set.completed
                              ? Colors.tealAccent
                              : Colors.lightBlueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _LargeActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _LargeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF151A26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _TokenThumbnail extends StatelessWidget {
  final String imagePath;
  final double size;
  final double borderRadius;

  const _TokenThumbnail({
    required this.imagePath,
    required this.size,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(Icons.emoji_events, color: Colors.amber, size: size * 0.5),
    );

    if (imagePath.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    if (imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    return fallback;
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

    final error = await _feedbackService.sendFeedback(
      message: message,
      username: auth.appUser?.username,
      userEmail: auth.appUser?.email,
      imagePath: _selectedImage?.path,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
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
        content: Text('Feedback erfolgreich gesendet. Danke!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feedback',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Schicke Fehlerberichte oder Verbesserungsvorschläge direkt an das Entwicklerteam.',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            minLines: 4,
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
              _selectedImage == null
                  ? 'Optional Bild hochladen'
                  : 'Bild ändern',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber[300],
              side: BorderSide(color: Colors.amber[700]!),
            ),
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(
                      _selectedImage!.path,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(_selectedImage!.path),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitFeedback,
              icon: Icon(_isSubmitting ? Icons.hourglass_top : Icons.send),
              label: Text(_isSubmitting ? 'Wird vorbereitet...' : 'Senden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
