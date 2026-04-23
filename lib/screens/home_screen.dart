import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../widgets/index.dart';
import '../widgets/daily_reward_dialog.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'trading_screen.dart';
import 'token_upgrade_screen.dart';
import 'sets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Page order: Trading(0) | Karte(1) | Sets(2) | Profil(3)
  static const int _initialPage = 1;
  static const Map<String, String> _taskRewardLandmarkIds = {
    'task_michel': '4', // Hamburger Michel
    'task_elbphi': '2', // Elbphilharmonie
    'task_speicherstadt': '1', // Speicherstadt
  };
  static const Map<String, String> _taskRewardTitles = {
    'task_michel': '🏛️ Michel-Belohnung',
    'task_elbphi': '🏛️ Elbphi-Belohnung',
    'task_speicherstadt': '🏛️ Speicherstadt-Belohnung',
  };
  late final PageController _pageController;
  int _currentPage = _initialPage;
  bool _isProcessingMonumentRewards = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybeShowTutorial();
      _maybeShowDailyReward();
      // Listener für Set-Abschluss Banner
      context.read<CollectionService>().addListener(_onCollectionChanged);
      _maybeGrantMonumentTaskRewards();
    });
  }

  Future<void> _maybeShowTutorial() async {
    final show = await shouldShowTutorial();
    if (!mounted || !show) return;
    final completed = await showTutorial(
      context,
      onStepChanged: (stepIndex) {
        if (!mounted) return;
        // Seite 4 => Sets, Seite 5 => Marktplatz, Seite 6 => Profil
        if (stepIndex == 3) {
          _pageController.jumpToPage(2);
          setState(() => _currentPage = 2);
        } else if (stepIndex == 4) {
          _pageController.jumpToPage(0);
          setState(() => _currentPage = 0);
        } else if (stepIndex == 5) {
          _pageController.jumpToPage(3);
          setState(() => _currentPage = 3);
        }
      },
    );
    if (!mounted || !completed) return;

    final lootboxService = context.read<LootboxService>();
    await lootboxService.addExtraLootboxes(1);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LootboxDialog(),
    );
  }

  void _onCollectionChanged() async {
    final service = context.read<CollectionService>();
    final completed = service.lastCompletedSet;
    if (completed != null) {
      service.clearLastCompletedSet();
      if (!mounted) return;
      _showSetCompletedBanner(completed);
    }
    await _maybeGrantMonumentTaskRewards();
  }

  bool _hasMonumentTokenForLandmark(
    CollectionService collectionService,
    String landmarkId,
  ) {
    return collectionService.tokens.any(
      (t) => t.landmarkId == landmarkId && t.tier == TokenTier.monumente,
    );
  }

  Future<void> _maybeGrantMonumentTaskRewards() async {
    if (!mounted || _isProcessingMonumentRewards) return;

    final collectionService = context.read<CollectionService>();
    final landmarkService = context.read<LandmarkService>();

    final status = MonumentUnlockService.getHamburgMonumentStatus(
      collectionService,
      landmarkService,
    );

    if (!status.challengeUnlocked) return;

    _isProcessingMonumentRewards = true;
    try {
      for (final task in status.tasks) {
        if (!task.completed) continue;

        final rewardLandmarkId = _taskRewardLandmarkIds[task.id];
        if (rewardLandmarkId == null) continue;
        if (_hasMonumentTokenForLandmark(collectionService, rewardLandmarkId)) {
          continue;
        }

        Landmark? rewardLandmark;
        try {
          rewardLandmark =
              landmarkService.landmarks.firstWhere((l) => l.id == rewardLandmarkId);
        } catch (_) {
          continue;
        }

        collectionService.collectTokenAllowDuplicate(
          rewardLandmark.id,
          rewardLandmark.name,
          rewardLandmark.category,
          TokenTier.monumente.pointValue,
          rewardLandmark.relatedSetIds,
          tier: TokenTier.monumente,
        );

        if (!mounted) return;
        await _showMonumentRewardSequence(
          rewardLandmark,
          _taskRewardTitles[task.id] ?? '🏛️ Monument-Belohnung',
        );
      }
    } finally {
      _isProcessingMonumentRewards = false;
    }
  }

  Future<void> _showMonumentRewardSequence(
    Landmark rewardLandmark,
    String title,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LootboxDialog(
        forcedTier: TokenTier.monumente,
        forcedLandmarkId: rewardLandmark.id,
        displayOnlyReward: true,
        customTitle: title,
      ),
    );
  }

  void _showSetCompletedBanner(CollectionSet set) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SetCompletedBanner(
        set: set,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _maybeShowDailyReward() {
    final rewardService = context.read<DailyRewardService>();
    if (rewardService.shouldShowPopup) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DailyRewardDialog(),
      );
    }
  }

  Future<void> _showLootboxRewardPopup({
    required String title,
    required String message,
    required Color accent,
    required String emoji,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: accent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // ignore if service no longer available
    try {
      context.read<CollectionService>().removeListener(_onCollectionChanged);
    } catch (_) {}
    _pageController.dispose();
    super.dispose();
  }

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.swap_horiz, label: 'Trading'),
    _NavItem(icon: Icons.map, label: 'Karte'),
    _NavItem(icon: Icons.collections, label: 'Sets'),
    _NavItem(icon: Icons.person, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: const [
              _KeepAlivePage(child: TradingScreen()),
              _KeepAlivePage(child: MapScreen()),
              _KeepAlivePage(child: SetsScreen()),
              _KeepAlivePage(child: ProfileScreen()),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: (i) {
          _pageController.jumpToPage(i);
          setState(() => _currentPage = i);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: _navItems
            .map((n) => BottomNavigationBarItem(icon: Icon(n.icon), label: n.label))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

/// Keeps a page alive in the PageView so state is not lost when swiping away.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class ExploreTab extends StatefulWidget {
  const ExploreTab({Key? key}) : super(key: key);

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  @override
  void initState() {
    super.initState();
    // Initialisiere Location Service nach einem Delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final locationService = Provider.of<LocationService>(context, listen: false);
        locationService.ensureInitialized();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Landmarks'),
        actions: [
          Consumer<CollectionService>(
            builder: (context, collectionService, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Chip(
                    label: Text(
                      '${collectionService.totalPoints} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.amber[100],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Consumer<LandmarkService>(
            builder: (context, landmarkService, child) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _buildCategoryChip(
                        context,
                        'All',
                        'all',
                        landmarkService.selectedCategory == 'all',
                        () => landmarkService.setCategory('all'),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        context,
                        'Sightseeing',
                        'sightseeing',
                        landmarkService.selectedCategory == 'sightseeing',
                        () => landmarkService.setCategory('sightseeing'),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        context,
                        'Travel',
                        'travel',
                        landmarkService.selectedCategory == 'travel',
                        () => landmarkService.setCategory('travel'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Landmarks List
          Expanded(
            child: Consumer<LandmarkService>(
              builder: (context, landmarkService, child) {
                if (landmarkService.filteredLandmarks.isEmpty) {
                  return const Center(
                    child: Text('No landmarks found'),
                  );
                }

                return ListView.builder(
                  itemCount: landmarkService.filteredLandmarks.length,
                  itemBuilder: (context, index) {
                    final landmark =
                        landmarkService.filteredLandmarks[index];
                    return LandmarkCard(
                      landmark: landmark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LandmarkDetailScreen(landmark: landmark),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<LocationService>(
        builder: (context, locationService, child) {
          return FloatingActionButton(
            onPressed: () {
              locationService.refreshLocation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Icon(Icons.my_location),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    String value,
    bool selected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class LandmarkDetailScreen extends StatelessWidget {
  final Landmark landmark;

  const LandmarkDetailScreen({
    Key? key,
    required this.landmark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(landmark.name),
      ),
      body: Consumer3<LocationService, CollectionService, AuthService>(
        builder: (context, locationService, collectionService, authService, child) {
          final position = locationService.currentPosition;
          final distance = position != null
              ? landmark.getDistance(position.latitude, position.longitude)
              : null;
          final isNearby = distance != null && distance <= landmark.checkInRadiusKm;
          final isCollected = collectionService.hasCollectedToken(landmark.id);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Landmark Image
                Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Image.asset(
                    landmark.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.location_on,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Category
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              landmark.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Chip(
                            label: Text(landmark.category),
                            backgroundColor: landmark.category == 'sightseeing'
                                ? Colors.purple[100]
                                : Colors.green[100],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Distance and Points
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: isNearby ? Colors.green : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance != null
                                ? '${distance.toStringAsFixed(2)} km away'
                                : 'Location unavailable',
                            style: TextStyle(
                              color: isNearby ? Colors.green : Colors.grey[600],
                              fontWeight:
                                  isNearby ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.emoji_events,
                            size: 20,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${landmark.pointsReward} points',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        landmark.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      // Difficulty
                      Row(
                        children: [
                          Text(
                            'Difficulty: ',
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Chip(
                            label: Text(
                              landmark.difficulty.toUpperCase(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _getDifficultyColor(landmark.difficulty),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Quests
                      if (landmark.quests.isNotEmpty) ...[
                        Text(
                          'Quests',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        ...landmark.quests.map((quest) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(_getQuestIcon(quest.taskType)),
                                title: Text(quest.title),
                                subtitle: Text(quest.taskType),
                                trailing: quest.completed
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : null,
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],
                      // Collect Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isCollected
                              ? null
                              : (isNearby
                                  ? () {
                                      if (!authService.isLoggedIn) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Bitte melde dich an, um Tokens zu sammeln. Gehe zum Profil-Tab.',
                                            ),
                                            backgroundColor: Colors.orange,
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                        return;
                                      }
                                      collectionService.collectToken(
                                        landmark.id,
                                        landmark.name,
                                        landmark.category,
                                        landmark.pointsReward,
                                        landmark.relatedSetIds,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Token collected! +${landmark.pointsReward} points',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  : null),
                          icon: Icon(
                            isCollected
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                          ),
                          label: Text(
                            isCollected
                                ? 'Already Collected'
                                : (isNearby
                                    ? 'Collect Token'
                                    : 'Get closer to collect'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCollected
                                ? Colors.grey
                                : (isNearby ? Colors.green : null),
                          ),
                        ),
                      ),
                      if (!isNearby && !isCollected)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'You need to be within 100m to collect this token',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange[700],
                                  fontStyle: FontStyle.italic,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return Colors.green[300]!;
      case 'medium': return Colors.orange[300]!;
      case 'hard': return Colors.red[300]!;
      default: return Colors.grey[300]!;
    }
  }

  IconData _getQuestIcon(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'photo': return Icons.camera_alt;
      case 'visit': return Icons.location_on;
      case 'quiz': return Icons.quiz;
      case 'collect': return Icons.token;
      default: return Icons.task_alt;
    }
  }
}

// ── In-App Set-Abschluss Banner ────────────────────────────────────────────

class _SetCompletedBanner extends StatefulWidget {
  final CollectionSet set;
  final VoidCallback onDismiss;

  const _SetCompletedBanner({required this.set, required this.onDismiss});

  @override
  State<_SetCompletedBanner> createState() => _SetCompletedBannerState();
}

class _SetCompletedBannerState extends State<_SetCompletedBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
    // Auto-dismiss nach 5 Sekunden
    Future.delayed(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _ctrl.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Positioned(
      top: mediaQuery.padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF2A2A4E)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const AppLottie(
                    type: AppLottieType.success,
                    size: 46,
                    repeat: false,
                  ),
                  const SizedBox(width: 8),
                  // Wappen-Bild oder Trophäen-Icon
                  if (widget.set.rewardImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        widget.set.rewardImageUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                      ),
                    )
                  else
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🏆 Set abgeschlossen!',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.set.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '+${widget.set.bonusPoints} Bonus-Coins erhalten!',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green[100]!;
      case 'medium':
        return Colors.orange[100]!;
      case 'hard':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  IconData _getQuestIcon(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'photo':
        return Icons.camera_alt;
      case 'checkin':
        return Icons.check_circle_outline;
      case 'puzzle':
        return Icons.extension;
      default:
        return Icons.task;
    }
  }
}
