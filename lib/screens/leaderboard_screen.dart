import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/collection_service.dart';
import '../services/friend_service.dart';
import 'friends_screen.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const LeaderboardPanel(embedded: false);
  }
}

class LeaderboardPanel extends StatefulWidget {
  final bool embedded;

  const LeaderboardPanel({Key? key, required this.embedded}) : super(key: key);

  @override
  State<LeaderboardPanel> createState() => _LeaderboardPanelState();
}

class _LeaderboardPanelState extends State<LeaderboardPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final ScrollController _globalScroll;
  late final ScrollController _friendsScroll;

  int _globalLimit = 30;
  int _friendsLimit = 30;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _globalScroll = ScrollController()..addListener(_onGlobalScroll);
    _friendsScroll = ScrollController()..addListener(_onFriendsScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _publishStats();
    });
  }

  void _onGlobalScroll() {
    if (!_globalScroll.hasClients) return;
    if (_globalScroll.position.pixels >=
        _globalScroll.position.maxScrollExtent - 140) {
      setState(() => _globalLimit += 20);
    }
  }

  void _onFriendsScroll() {
    if (!_friendsScroll.hasClients) return;
    if (_friendsScroll.position.pixels >=
        _friendsScroll.position.maxScrollExtent - 140) {
      setState(() => _friendsLimit += 20);
    }
  }

  Future<void> _publishStats() async {
    final collection = context.read<CollectionService>();

    if (!collection.isLoaded) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return false;
        return !context.read<CollectionService>().isLoaded;
      });
      if (!mounted) return;
    }

    final stats = collection.getStatistics();
    await context.read<FriendService>().publishMyStats(
          totalPoints: stats['totalPoints'] ?? 0,
          totalTokens: stats['totalTokens'] ?? 0,
          visitedLandmarks: stats['visitedLandmarks'] ?? 0,
          leaderboardScore: stats['leaderboardScore'] ?? 0,
          worldWonderTokens: stats['worldWonderTokens'] ?? 0,
          level: stats['level'] ?? 1,
        );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _globalScroll.dispose();
    _friendsScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Container(
          color: const Color(0xFF151A26),
          child: TabBar(
            controller: _tabs,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'Global'),
              Tab(text: 'Freunde'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _RealtimeLeaderboardList(
                stream: context
                    .read<FriendService>()
                    .streamGlobalLeaderboard(limit: _globalLimit),
                scrollController: _globalScroll,
                emptyMessage:
                    'Noch keine Spieler-Daten verfügbar.\nSpiele und sammle Tokens um zu erscheinen!',
              ),
              _RealtimeLeaderboardList(
                stream: context
                    .read<FriendService>()
                    .streamFriendsLeaderboard(limit: _friendsLimit),
                scrollController: _friendsScroll,
                emptyMessage:
                    'Noch keine Freunde.\nFüge Freunde hinzu um sie hier zu sehen!',
                onAddFriends: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FriendsScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Container(color: const Color(0xFF0F111A), child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151A26),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Rangliste',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _publishStats,
          ),
        ],
      ),
      body: content,
    );
  }
}

class _RealtimeLeaderboardList extends StatelessWidget {
  final Stream<List<LeaderboardEntry>> stream;
  final ScrollController scrollController;
  final String emptyMessage;
  final VoidCallback? onAddFriends;

  const _RealtimeLeaderboardList({
    required this.stream,
    required this.scrollController,
    required this.emptyMessage,
    this.onAddFriends,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        final entries = snapshot.data ?? const <LeaderboardEntry>[];
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.white24,
                  size: 52,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (onAddFriends != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onAddFriends,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Freunde hinzufügen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: entries.length,
          itemBuilder: (ctx, i) {
            final e = entries[i];
            final rank = i + 1;
            return _LeaderboardTile(
              entry: e,
              rank: rank,
              onTap: e.isMe
                  ? null
                  : () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) =>
                              FriendProfileScreen(uid: e.uid, username: e.username),
                        ),
                      ),
            );
          },
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final VoidCallback? onTap;

  const _LeaderboardTile({required this.entry, required this.rank, this.onTap});

  Color _rankColor() {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.white24;
  }

  String _rankEmoji() {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = entry.isMe;
    final avatar = entry.photoUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.amber.withValues(alpha: 0.12)
              : const Color(0xFF151A26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted
                ? Colors.amber.withValues(alpha: 0.5)
                : entry.isFriend
                    ? Colors.deepPurple.withValues(alpha: 0.5)
                    : Colors.white12,
            width: isHighlighted || entry.isFriend ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: rank <= 3
                  ? Text(
                      _rankEmoji(),
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      '#$rank',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _rankColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 20,
              backgroundColor: isHighlighted
                  ? Colors.amber[700]
                  : entry.isFriend
                      ? Colors.deepPurple[700]
                      : Colors.grey[700],
              backgroundImage: avatar != null && avatar.startsWith('http')
                  ? NetworkImage(avatar)
                  : null,
              child: avatar == null || !avatar.startsWith('http')
                  ? Text(
                      entry.username.isNotEmpty
                          ? entry.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.username,
                        style: TextStyle(
                          color: isHighlighted ? Colors.amber : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (entry.isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Du',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (entry.isFriend && !entry.isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[700],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Freund',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${entry.totalTokens} Tokens',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      Text(
                        '${entry.worldWonderTokens} Weltwunder',
                        style: TextStyle(
                          color: Colors.tealAccent[100],
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Lvl ${entry.level}',
                        style: TextStyle(
                          color: Colors.lightBlueAccent[100],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${entry.totalPoints}',
              style: TextStyle(
                color: isHighlighted ? Colors.amber : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              'Pkt',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
