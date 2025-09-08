import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/user_progress_provider.dart';
import '../widgets/currency_display.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CurrencyDisplay(),
          ),
        ],
      ),
      body: Consumer<UserProgressProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.initializeUserProgress(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _buildCollectionContent(provider);
        },
      ),
    );
  }

  Widget _buildCollectionContent(UserProgressProvider provider) {
    final stats = provider.getProgressStats();
    final unlockedPets = stats['unlockedPets'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCollectionStats(unlockedPets),
          const SizedBox(height: 20),
          Expanded(
            child: _buildPetGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionStats(int unlockedPets) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Unlocked',
              unlockedPets.toString(),
              Icons.pets,
              AppTheme.primaryColor,
            ),
            _buildStatItem(
              'Total',
              '50', // Placeholder total
              Icons.collections,
              AppTheme.secondaryColor,
            ),
            _buildStatItem(
              'Completion',
              '${(unlockedPets / 50 * 100).round()}%',
              Icons.percent,
              AppTheme.successColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPetGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 20, // Placeholder count
      itemBuilder: (context, index) {
        return _buildPetCard(index);
      },
    );
  }

  Widget _buildPetCard(int index) {
    // Simulate some unlocked pets
    final isUnlocked = index < 5;
    final rarity = _getRarityForIndex(index);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getRarityColor(rarity).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? _getRarityColor(rarity).withOpacity(0.1)
                      : AppTheme.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: isUnlocked
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pets,
                            size: 48,
                            color: _getRarityColor(rarity),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRarityColor(rarity),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rarity.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Icon(
                        Icons.lock,
                        size: 32,
                        color: AppTheme.secondaryTextColor,
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isUnlocked ? 'Pet ${index + 1}' : '???',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked 
                            ? AppTheme.primaryTextColor 
                            : AppTheme.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked ? 'Level 1' : 'Locked',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRarityForIndex(int index) {
    if (index < 2) return 'common';
    if (index < 4) return 'rare';
    if (index < 5) return 'epic';
    return 'legendary';
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return AppTheme.petRarityCommon;
      case 'rare':
        return AppTheme.petRarityRare;
      case 'epic':
        return AppTheme.petRarityEpic;
      case 'legendary':
        return AppTheme.petRarityLegendary;
      default:
        return AppTheme.secondaryTextColor;
    }
  }
}

