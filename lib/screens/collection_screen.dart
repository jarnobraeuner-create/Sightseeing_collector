import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/index.dart';
import '../widgets/index.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Reset Collection (Test)',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Collection?'),
                  content: const Text('Alle gesammelten Tokens werden gelöscht. Dies kann nicht rückgängig gemacht werden.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                    TextButton(
                      onPressed: () {
                        Provider.of<CollectionService>(context, listen: false).resetCollection();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Collection zurückgesetzt'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: const Text('Reset', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tokens'),
            Tab(text: 'Sets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTokensTab(),
          _buildSetsTab(),
        ],
      ),
    );
  }

  Widget _buildTokensTab() {
    return Consumer<CollectionService>(
      builder: (context, collectionService, child) {
        if (collectionService.tokens.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.collections,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tokens collected yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Visit landmarks to start collecting!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: collectionService.tokens.length,
          itemBuilder: (context, index) {
            return TokenCard(token: collectionService.tokens[index]);
          },
        );
      },
    );
  }

  Widget _buildSetsTab() {
    return Consumer<CollectionService>(
      builder: (context, collectionService, child) {
        if (collectionService.sets.isEmpty) {
          return const Center(
            child: Text('No sets available'),
          );
        }

        return ListView.builder(
          itemCount: collectionService.sets.length,
          itemBuilder: (context, index) {
            return SetCard(set: collectionService.sets[index]);
          },
        );
      },
    );
  }
}
