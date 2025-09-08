import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/gacha_provider.dart';
import '../core/providers/user_progress_provider.dart';
import '../widgets/currency_display.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> with TickerProviderStateMixin {
  late AnimationController _pullAnimationController;
  late Animation<double> _pullAnimation;

  @override
  void initState() {
    super.initState();
    _pullAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pullAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pullAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pullAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gacha'),
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
      body: Consumer2<GachaProvider, UserProgressProvider>(
        builder: (context, gachaProvider, userProvider, child) {
          if (gachaProvider.isLoading || userProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (gachaProvider.error != null) {
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
                    'Error: ${gachaProvider.error}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => gachaProvider.initializeGacha(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _buildGachaContent(gachaProvider, userProvider);
        },
      ),
    );
  }

  Widget _buildGachaContent(GachaProvider gachaProvider, UserProgressProvider userProvider) {
    final userProgress = userProvider.userProgress;
    final canAffordSingle = (userProgress?.coins ?? 0) >= gachaProvider.singlePullCost;
    final canAffordTen = (userProgress?.coins ?? 0) >= gachaProvider.tenPullCost;
    final canAffordPremium = (userProgress?.gems ?? 0) >= gachaProvider.premiumPullCost;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildGachaInfo(),
          const SizedBox(height: 20),
          _buildPullButtons(
            gachaProvider,
            canAffordSingle,
            canAffordTen,
            canAffordPremium,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildGachaHistory(gachaProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildGachaInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Pet Gacha',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Pull for a chance to get rare pets!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildRarityRates(),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityRates() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildRarityRate('Common', '70%', AppTheme.petRarityCommon),
        _buildRarityRate('Rare', '20%', AppTheme.petRarityRare),
        _buildRarityRate('Epic', '8%', AppTheme.petRarityEpic),
        _buildRarityRate('Legendary', '2%', AppTheme.petRarityLegendary),
      ],
    );
  }

  Widget _buildRarityRate(String name, String rate, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          rate,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPullButtons(
    GachaProvider gachaProvider,
    bool canAffordSingle,
    bool canAffordTen,
    bool canAffordPremium,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildPullButton(
            title: 'Single Pull',
            subtitle: '${gachaProvider.singlePullCost} Coins',
            icon: Icons.card_giftcard,
            color: AppTheme.primaryColor,
            enabled: canAffordSingle,
            onTap: () => _performSinglePull(gachaProvider, false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPullButton(
            title: 'Ten Pull',
            subtitle: '${gachaProvider.tenPullCost} Coins',
            icon: Icons.ten_k,
            color: AppTheme.secondaryColor,
            enabled: canAffordTen,
            onTap: () => _performTenPull(gachaProvider),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPullButton(
            title: 'Premium',
            subtitle: '${gachaProvider.premiumPullCost} Gems',
            icon: Icons.diamond,
            color: AppTheme.accentColor,
            enabled: canAffordPremium,
            onTap: () => _performSinglePull(gachaProvider, true),
          ),
        ),
      ],
    );
  }

  Widget _buildPullButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 100,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : AppTheme.dividerColor,
          foregroundColor: enabled ? Colors.white : AppTheme.secondaryTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGachaHistory(GachaProvider gachaProvider) {
    final history = gachaProvider.gachaHistory;
    
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: AppTheme.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No pulls yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try your first pull to see results here!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Pulls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final result = history[index];
                  return _buildHistoryItem(result);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(dynamic result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRarityColor(result.rarity.toString()).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRarityColor(result.rarity.toString()).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.pets,
              color: _getRarityColor(result.rarity.toString()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.pet.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${result.rarity.toString().split('.').last.toUpperCase()} • ${result.cost} ${result.cost == 50 ? 'Gems' : 'Coins'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (result.isNewVariant)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'PetRarity.common':
        return AppTheme.petRarityCommon;
      case 'PetRarity.rare':
        return AppTheme.petRarityRare;
      case 'PetRarity.epic':
        return AppTheme.petRarityEpic;
      case 'PetRarity.legendary':
        return AppTheme.petRarityLegendary;
      default:
        return AppTheme.secondaryTextColor;
    }
  }

  Future<void> _performSinglePull(GachaProvider gachaProvider, bool useGems) async {
    _pullAnimationController.forward().then((_) {
      _pullAnimationController.reset();
    });
    
    final result = await gachaProvider.performSinglePull(useGems: useGems);
    
    if (result != null && mounted) {
      _showPullResult(result);
    }
  }

  Future<void> _performTenPull(GachaProvider gachaProvider) async {
    _pullAnimationController.forward().then((_) {
      _pullAnimationController.reset();
    });
    
    final results = await gachaProvider.performTenPull();
    
    if (results.isNotEmpty && mounted) {
      _showTenPullResults(results);
    }
  }

  void _showPullResult(dynamic result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('You got: ${result.pet.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getRarityColor(result.rarity.toString()).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.pets,
                size: 40,
                color: _getRarityColor(result.rarity.toString()),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.pet.description,
              textAlign: TextAlign.center,
            ),
            if (result.isNewVariant) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'NEW VARIANT!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTenPullResults(List<dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ten Pull Results'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return _buildHistoryItem(result);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

