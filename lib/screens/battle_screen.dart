import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/game_provider.dart';
import '../widgets/currency_display.dart';
import 'team_builder_screen.dart';
import 'battle_game_screen.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle'),
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
      body: Consumer<GameProvider>(
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
                    onPressed: () => provider.initializeGame(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _buildBattleContent();
        },
      ),
    );
  }

  Widget _buildBattleContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildBattleInfo(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildBattleArea(),
          ),
          const SizedBox(height: 20),
          _buildBattleControls(),
        ],
      ),
    );
  }

  Widget _buildBattleInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Battle Arena',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Select your team and start battling!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleArea() {
    return Row(
      children: [
        Expanded(
          child: _buildTeamArea('Your Team', true),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildTeamArea('Enemy Team', false),
        ),
      ],
    );
  }

  Widget _buildTeamArea(String title, bool isPlayer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildPetSlots(isPlayer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetSlots(bool isPlayer) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return _buildPetSlot(index, isPlayer);
      },
    );
  }

  Widget _buildPetSlot(int index, bool isPlayer) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 32,
              color: AppTheme.secondaryTextColor,
            ),
            const SizedBox(height: 4),
            Text(
              'Slot ${index + 1}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TeamBuilderScreen()),
              );
            },
            icon: const Icon(Icons.group),
            label: const Text('Select Team'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BattleGameScreen()),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Quick Battle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
          ),
        ),
      ],
    );
  }
}

