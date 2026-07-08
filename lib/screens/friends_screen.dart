import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/friend_service.dart';

/// Shows the public profile of another player.
class FriendProfileScreen extends StatefulWidget {
  final String uid;
  final String username;

  const FriendProfileScreen({
    Key? key,
    required this.uid,
    required this.username,
  }) : super(key: key);

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  FriendProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<FriendService>();
    final profile = await service.loadFriendProfile(widget.uid);
    if (mounted)
      setState(() {
        _profile = profile;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final isFriend =
        context.watch<FriendService>().friendUids.contains(widget.uid);
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151A26),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.username,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (isFriend)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              color: Colors.grey[850],
              onSelected: (v) async {
                if (v == 'remove') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Freundschaft beenden?',
                          style: TextStyle(color: Colors.white)),
                      content: Text(
                          '${widget.username} aus deiner Freundesliste entfernen?',
                          style: const TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Abbrechen')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Entfernen',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    await context
                        .read<FriendService>()
                        .removeFriend(widget.uid);
                    if (mounted) Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'remove',
                    child: Text('Freundschaft beenden',
                        style: TextStyle(color: Colors.redAccent))),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _profile == null
              ? const Center(
                  child: Text('Profil nicht verfügbar',
                      style: TextStyle(color: Colors.white54)))
              : _buildProfile(_profile!),
    );
  }

  Widget _buildProfile(FriendProfile p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber[700],
                boxShadow: [
                  BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2)
                ],
              ),
              child: const Icon(Icons.person, size: 48, color: Colors.black),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            p.username,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Level ${(p.totalPoints / 100).floor() + 1}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.amber, fontSize: 14),
          ),
          const SizedBox(height: 28),

          if (p.favoriteTokens.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF151A26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lieblings-Tokens',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: p.favoriteTokens.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final token = p.favoriteTokens[i];
                        return SizedBox(
                          width: 74,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: token.imageUrl.startsWith('http')
                                    ? Image.network(
                                        token.imageUrl,
                                        width: 54,
                                        height: 54,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _favoriteFallbackIcon(),
                                      )
                                    : token.imageUrl.isNotEmpty
                                        ? Image.asset(
                                            token.imageUrl,
                                            width: 54,
                                            height: 54,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _favoriteFallbackIcon(),
                                          )
                                        : _favoriteFallbackIcon(),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                token.landmarkName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Stats
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF151A26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statistiken',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 14),
                _statRow(Icons.star, 'Gesamtpunkte', p.totalPoints.toString(),
                    Colors.amber),
                const SizedBox(height: 10),
                _statRow(Icons.public, 'Weltwunder',
                    p.worldWonderTokens.toString(), Colors.tealAccent),
                const SizedBox(height: 10),
                _statRow(Icons.location_on, 'Besuchte Orte',
                    p.visitedLandmarks.toString(), Colors.lightBlueAccent),
                const SizedBox(height: 10),
                _statRow(Icons.collections, 'Gesammelte Tokens',
                    p.totalTokens.toString(), Colors.deepPurpleAccent),
                const SizedBox(height: 10),
                _statRow(Icons.bolt, 'Level', p.level.toString(),
                    Colors.greenAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _favoriteFallbackIcon() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.emoji_events,
        color: Colors.amber,
        size: 22,
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 14))),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

// ─── Friends List Screen ────────────────────────────────────────────────────

class FriendsScreen extends StatefulWidget {
  final bool embedded;

  const FriendsScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(AppUserSummary user) async {
    final error = await context
        .read<FriendService>()
        .sendRequest(user.uid, user.username);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Anfrage an ${user.username} gesendet ✓'),
      backgroundColor: error != null ? Colors.red[700] : Colors.green[700],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tabContent = Column(
      children: [
        Container(
          color: const Color(0xFF151A26),
          child: TabBar(
            controller: _tabs,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'Freunde'),
              Tab(text: 'Alle Spieler'),
              Tab(text: 'Anfragen'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _FriendsTab(onSendRequest: _sendRequest),
              _AllPlayersTab(onSendRequest: _sendRequest),
              _RequestsTab(
                onAccepted: () => _tabs.animateTo(0),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Container(
        color: const Color(0xFF0F111A),
        child: tabContent,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151A26),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Freunde',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: tabContent,
    );
  }
}

// ── Friends Tab ──────────────────────────────────────────────────────────────

class _FriendsTab extends StatefulWidget {
  final Future<void> Function(AppUserSummary) onSendRequest;
  const _FriendsTab({required this.onSendRequest});

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  final TextEditingController _ctrl = TextEditingController();
  List<AppUserSummary> _results = [];
  bool _searching = false;

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _results = [];
    });
    final r = await context.read<FriendService>().searchUsers(q);
    if (mounted)
      setState(() {
        _searching = false;
        _results = r;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendService>(
      builder: (ctx, fs, _) {
        final friendUids = fs.friendUids.toList();
        final pendingOutgoingUids = fs.outgoingRequests
            .where((r) => r.status == FriendRequestStatus.pending)
            .map((r) => r.toUid)
            .toSet();
        final pendingIncomingByUid = {
          for (final r in fs.incomingRequests
              .where((r) => r.status == FriendRequestStatus.pending))
            r.fromUid: r,
        };
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Spielername suchen...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E2333),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _search,
                  child: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.search),
                ),
              ]),
            ),

            // Search results
            if (_results.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Suchergebnisse',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12))),
              ),
              const SizedBox(height: 4),
              ..._results.map((u) {
                final alreadyFriend = fs.friendUids.contains(u.uid);
                final hasPendingOutgoing = pendingOutgoingUids.contains(u.uid);
                final pendingIncoming = pendingIncomingByUid[u.uid];
                return ListTile(
                  leading: CircleAvatar(
                      backgroundColor: Colors.amber[700],
                      child: Text(u.username[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold))),
                  title: Text(u.username,
                      style: const TextStyle(color: Colors.white)),
                  trailing: alreadyFriend
                      ? const Chip(
                          label: Text('Befreundet',
                              style: TextStyle(fontSize: 11)),
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(color: Colors.white))
                      : pendingIncoming != null
                          ? TextButton.icon(
                              onPressed: () =>
                                  fs.acceptRequest(pendingIncoming.id),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Annehmen'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.greenAccent),
                            )
                          : TextButton.icon(
                              onPressed: hasPendingOutgoing
                                  ? null
                                  : () => widget.onSendRequest(u),
                              icon: Icon(
                                hasPendingOutgoing
                                    ? Icons.hourglass_empty
                                    : Icons.person_add,
                                size: 16,
                              ),
                              label: Text(hasPendingOutgoing
                                  ? 'Ausstehend'
                                  : 'Anfrage'),
                              style: TextButton.styleFrom(
                                foregroundColor: hasPendingOutgoing
                                    ? Colors.orangeAccent
                                    : Colors.amber,
                                disabledForegroundColor:
                                    Colors.orangeAccent.withValues(alpha: 0.8),
                              ),
                            ),
                );
              }),
              const Divider(color: Colors.white12, height: 24),
            ],

            // Friends list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Meine Freunde (${friendUids.length})',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12))),
            ),
            if (friendUids.isEmpty)
              Expanded(
                  child: Center(
                      child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_outlined,
                      color: Colors.white24, size: 48),
                  const SizedBox(height: 12),
                  Text('Noch keine Freunde',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text('Suche nach Spielern um Anfragen zu senden',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                ],
              )))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: friendUids.length,
                  itemBuilder: (_, i) {
                    final uid = friendUids[i];
                    return _FriendListTile(uid: uid);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FriendListTile extends StatefulWidget {
  final String uid;
  const _FriendListTile({required this.uid});
  @override
  State<_FriendListTile> createState() => _FriendListTileState();
}

class _FriendListTileState extends State<_FriendListTile> {
  FriendProfile? _profile;
  @override
  void initState() {
    super.initState();
    context.read<FriendService>().loadFriendProfile(widget.uid).then((p) {
      if (mounted) setState(() => _profile = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.username ?? widget.uid;
    final photoUrl = _profile?.photoUrl;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple[700],
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? NetworkImage(photoUrl)
            : null,
        child: (photoUrl == null || photoUrl.isEmpty)
            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))
            : null,
      ),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      subtitle: _profile != null
          ? Text(
              'Lvl ${_profile!.level} · ${_profile!.totalPoints} Punkte · ${_profile!.totalTokens} Tokens',
              style: TextStyle(color: Colors.grey[500], fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FriendProfileScreen(uid: widget.uid, username: name),
          )),
    );
  }
}

// ── All Players Tab ──────────────────────────────────────────────────────────

class _AllPlayersTab extends StatefulWidget {
  final Future<void> Function(AppUserSummary) onSendRequest;
  const _AllPlayersTab({required this.onSendRequest});
  @override
  State<_AllPlayersTab> createState() => _AllPlayersTabState();
}

class _AllPlayersTabState extends State<_AllPlayersTab> {
  List<AppUserSummary> _all = [];
  List<AppUserSummary> _filtered = [];
  bool _loading = true;
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _ctrl.addListener(_filter);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_filter);
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final players = await context.read<FriendService>().loadAllPlayers();
    if (mounted)
      setState(() {
        _all = players;
        _filtered = players;
        _loading = false;
      });
  }

  void _filter() {
    final q = _ctrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((p) => p.username.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendService>(builder: (ctx, fs, _) {
      final pendingOutgoingUids = fs.outgoingRequests
          .where((r) => r.status == FriendRequestStatus.pending)
          .map((r) => r.toUid)
          .toSet();
      final pendingIncomingByUid = {
        for (final r in fs.incomingRequests
            .where((r) => r.status == FriendRequestStatus.pending))
          r.fromUid: r,
      };
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Spieler filtern...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: () {
                        _ctrl.clear();
                      })
                  : null,
              filled: true,
              fillColor: const Color(0xFF1E2333),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              Text('${_filtered.length} Spieler registriert',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const Spacer(),
              IconButton(
                icon:
                    const Icon(Icons.refresh, color: Colors.white38, size: 18),
                onPressed: _load,
                tooltip: 'Aktualisieren',
              ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(
              child:
                  Center(child: CircularProgressIndicator(color: Colors.amber)))
        else if (_filtered.isEmpty)
          Expanded(
              child: Center(
                  child: Text('Keine Spieler gefunden',
                      style: TextStyle(color: Colors.grey[600]))))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final p = _filtered[i];
                final isFriend = fs.friendUids.contains(p.uid);
                final hasPendingOutgoing = pendingOutgoingUids.contains(p.uid);
                final pendingIncoming = pendingIncomingByUid[p.uid];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isFriend ? Colors.teal[700] : Colors.grey[700],
                    backgroundImage:
                        (p.photoUrl != null && p.photoUrl!.isNotEmpty)
                            ? NetworkImage(p.photoUrl!)
                            : null,
                    child: (p.photoUrl == null || p.photoUrl!.isEmpty)
                        ? Text(
                            p.username.isNotEmpty
                                ? p.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Text(p.username,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: isFriend
                      ? Text('Befreundet',
                          style:
                              TextStyle(color: Colors.teal[300], fontSize: 12))
                      : null,
                  trailing: isFriend
                      ? const Icon(Icons.check_circle, color: Colors.teal)
                      : pendingIncoming != null
                          ? TextButton.icon(
                              onPressed: () =>
                                  fs.acceptRequest(pendingIncoming.id),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Annehmen'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.greenAccent),
                            )
                          : TextButton.icon(
                              onPressed: hasPendingOutgoing
                                  ? null
                                  : () => widget.onSendRequest(p),
                              icon: Icon(
                                hasPendingOutgoing
                                    ? Icons.hourglass_empty
                                    : Icons.person_add,
                                size: 16,
                              ),
                              label: Text(hasPendingOutgoing
                                  ? 'Ausstehend'
                                  : 'Anfrage'),
                              style: TextButton.styleFrom(
                                foregroundColor: hasPendingOutgoing
                                    ? Colors.orangeAccent
                                    : Colors.amber,
                                disabledForegroundColor:
                                    Colors.orangeAccent.withValues(alpha: 0.8),
                              ),
                            ),
                  onTap: isFriend
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => FriendProfileScreen(
                                  uid: p.uid, username: p.username)))
                      : null,
                );
              },
            ),
          ),
      ]);
    });
  }
}

// ── Requests Tab ──────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  final VoidCallback? onAccepted;

  const _RequestsTab({this.onAccepted});

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendService>(
      builder: (ctx, fs, _) {
        final incoming = fs.incomingRequests;
        final outgoing = fs.outgoingRequests;
        if (incoming.isEmpty && outgoing.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.mail_outline, color: Colors.white24, size: 48),
              const SizedBox(height: 12),
              Text('Keine offenen Anfragen',
                  style: TextStyle(color: Colors.grey[600])),
            ]),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (incoming.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Eingehend',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),
              ...incoming.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151A26),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: Colors.amber[800],
                        child: Text(
                            r.fromUsername.isNotEmpty
                                ? r.fromUsername[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.fromUsername,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text('möchte dein Freund sein',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12)),
                        ],
                      )),
                      IconButton(
                        onPressed: () async {
                          await fs.acceptRequest(r.id);
                          onAccepted?.call();
                        },
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Annehmen',
                      ),
                      IconButton(
                        onPressed: () => fs.rejectRequest(r.id),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Ablehnen',
                      ),
                    ]),
                  )),
              const SizedBox(height: 12),
            ],
            if (outgoing.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Gesendet',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),
              ...outgoing.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151A26),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.deepPurple.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple[700],
                        child: Text(
                            r.toUsername.isNotEmpty
                                ? r.toUsername[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.toUsername,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text('Anfrage gesendet',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12)),
                        ],
                      )),
                      IconButton(
                        onPressed: () => fs.withdrawRequest(r.id),
                        icon: const Icon(Icons.undo, color: Colors.orange),
                        tooltip: 'Zurückziehen',
                      ),
                    ]),
                  )),
            ],
          ],
        );
      },
    );
  }
}
