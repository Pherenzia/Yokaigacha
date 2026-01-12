import 'package:flutter/material.dart';
import '../core/models/cavern_run.dart';
import '../core/models/pet.dart';
import '../core/services/cavern_service.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/currency_display.dart';
import 'battle_game_screen.dart';
import 'yokai_detail_screen.dart';

class CavernScreen extends StatefulWidget {
  const CavernScreen({super.key});

  @override
  State<CavernScreen> createState() => _CavernScreenState();
}

class _CavernScreenState extends State<CavernScreen> {
  CavernRun? _currentRun;
  CavernShop? _currentShop;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentRun();
  }

  Future<void> _loadCurrentRun() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProgress = StorageService.getUserProgress();
      if (userProgress == null) {
        setState(() {
          _errorMessage = 'User progress not found';
          _isLoading = false;
        });
        return;
      }

      // Get or create active run
      _currentRun = await CavernService.getActiveRun(userProgress.userId);
      
      if (_currentRun == null) {
        // Start new run
        _currentRun = await CavernService.startNewRun(userProgress.userId);
      }

      // Generate shop for current floor
      _currentShop = CavernService.generateShop(
        _currentRun!.currentFloor,
        _currentRun!.isBossFloor,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cavern run: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectYokai(Pet yokai) async {
    if (_currentRun == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final updatedRun = await CavernService.selectYokaiFromShop(_currentRun!, yokai);
      if (updatedRun != null) {
        setState(() {
          _currentRun = updatedRun;
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${yokai.name} added to team!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select yokai: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeYokaiFromTeam(Pet yokai) async {
    if (_currentRun == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final updatedRun = await CavernService.removeYokaiFromTeam(_currentRun!, yokai);
      if (updatedRun != null) {
        setState(() {
          _currentRun = updatedRun;
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${yokai.name} removed from team!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove yokai: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startBattle() async {
    if (_currentRun == null || _currentRun!.team.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least one yokai to start battle!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Generate enemy team
      final enemyTeam = CavernService.generateEnemyTeam(
        _currentRun!.currentSpirit,
        _currentRun!.isBossFloor,
      );

      // Navigate to battle
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BattleGameScreen(
            playerTeam: _currentRun!.team,
            enemyTeam: enemyTeam,
            isCavernMode: true,
            cavernRun: _currentRun!,
          ),
        ),
      );

      if (result == true) {
        // Battle won
        await _completeFloor(true, 0);
      } else if (result == false) {
        // Battle lost
        await _completeFloor(false, 1);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Battle failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeFloor(bool wasVictory, int livesLost) async {
    if (_currentRun == null) return;

    try {
      final updatedRun = await CavernService.completeFloor(_currentRun!, wasVictory, livesLost);
      if (updatedRun != null) {
        setState(() {
          _currentRun = updatedRun;
        });

        // Generate new shop for next floor
        _currentShop = CavernService.generateShop(
          _currentRun!.currentFloor,
          _currentRun!.isBossFloor,
        );

        // Show result message
        if (wasVictory) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Floor ${_currentRun!.currentFloor - 1} completed!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Floor ${_currentRun!.currentFloor - 1} failed! Lives: ${_currentRun!.lives}'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Check if run is over
        if (_currentRun!.status != CavernRunStatus.active) {
          _showRunCompleteDialog();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete floor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _lockTeam() async {
    if (_currentRun == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active run found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_currentRun!.canLock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot lock team: Floor ${_currentRun!.currentFloor}, Lives: ${_currentRun!.lives}, Team size: ${_currentRun!.team.length}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      print('Attempting to lock team: Floor ${_currentRun!.currentFloor}, Spirit: ${_currentRun!.currentSpirit}, Team: ${_currentRun!.team.length}');
      
      final lockedTeam = await CavernService.lockTeam(_currentRun!);
      if (lockedTeam != null) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team locked for competitive play!'),
            backgroundColor: Colors.blue,
          ),
        );

        // Return to home or show locked team screen
        Navigator.pop(context);
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to lock team: Unknown error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('Error locking team: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to lock team: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRunCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_currentRun!.status == CavernRunStatus.locked 
            ? 'Run Locked!' 
            : 'Run Failed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Floor Reached: ${_currentRun!.highestFloorReached}'),
            Text('Total Spirit Spent: ${_currentRun!.totalSpiritSpent}'),
            if (_currentRun!.status == CavernRunStatus.locked)
              const Text('Your team is now available for competitive play!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to home
            },
            child: const Text('Return Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('The Cavern'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCurrentRun,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentRun == null) {
      return const Scaffold(
        body: Center(
          child: Text('No active run found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Cavern'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          const CurrencyDisplay(),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildRunStatus(),
          _buildTeamDisplay(),
          Expanded(
            child: _currentShop != null 
                ? _buildShopDisplay()
                : const Center(child: Text('Generating shop...')),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildRunStatus() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Floor ${_currentRun!.currentFloor}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_currentRun!.isBossFloor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'BOSS FLOOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatDisplay('Spirit', '${_currentRun!.currentSpirit}'),
              _buildStatDisplay('Lives', '${_currentRun!.lives}'),
              _buildStatDisplay('Team', '${_currentRun!.team.length}/5'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDisplay(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTeamDisplay() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'Current Team',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                if (index < _currentRun!.team.length) {
                  return _buildTeamYokaiCard(_currentRun!.team[index]);
                } else {
                  return _buildEmptyTeamSlot();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamYokaiCard(Pet yokai) {
    final rarityColor = _getRarityColor(yokai.rarity);
    
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getPetIcon(yokai.type),
                  size: 30,
                  color: rarityColor,
                ),
                const SizedBox(height: 4),
                Text(
                  yokai.name,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (yokai.starLevel > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getStarColor(yokai.starLevel),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '★${yokai.starLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            // Remove button in top-right corner
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => _removeYokaiFromTeam(yokai),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTeamSlot() {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        color: Colors.grey[100],
        child: const Center(
          child: Icon(
            Icons.add,
            color: Colors.grey,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildShopDisplay() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Draft Shop - Choose 1 Yokai',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_currentShop!.isBossReward)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'BOSS REWARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _currentShop!.availableYokai.length,
            itemBuilder: (context, index) {
              final yokai = _currentShop!.availableYokai[index];
              return _buildShopYokaiCard(yokai);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShopYokaiCard(Pet yokai) {
    final rarityColor = _getRarityColor(yokai.rarity);
    final spiritCost = CavernService.getSpiritCost(yokai);
    final canAfford = _currentRun!.currentSpirit >= spiritCost;
    final canAdd = CavernService.canAddYokaiToTeam(_currentRun!, yokai);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YokaiDetailScreen(yokai: yokai),
          ),
        );
      },
      child: Card(
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canAfford && canAdd 
                  ? rarityColor 
                  : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Header with name and rarity
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      yokai.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: rarityColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rarityColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        yokai.rarity.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Yokai icon
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: rarityColor.withOpacity(0.05),
                  ),
                  child: Center(
                    child: Icon(
                      _getPetIcon(yokai.type),
                      size: 40,
                      color: rarityColor,
                    ),
                  ),
                ),
              ),
              
              // Stats and cost
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          '${yokai.currentAttack}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          '${yokai.currentHealth}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: canAfford ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$spiritCost Spirit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!canAfford)
                      const Text(
                        'Not enough spirit',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 8,
                        ),
                      ),
                    if (!canAdd && canAfford)
                      const Text(
                        'Duplicate yokai',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 8,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Add/Remove button
                    if (canAfford && canAdd)
                      ElevatedButton(
                        onPressed: () => _selectYokai(yokai),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rarityColor,
                          minimumSize: const Size(60, 24),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (!canAfford)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'No Spirit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Duplicate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _currentRun!.team.isNotEmpty ? _startBattle : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Start Battle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (_currentRun!.canLock)
            Expanded(
              child: ElevatedButton(
                onPressed: _lockTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Lock Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRarityColor(PetRarity rarity) {
    switch (rarity) {
      case PetRarity.common:
        return Colors.grey;
      case PetRarity.rare:
        return Colors.blue;
      case PetRarity.epic:
        return Colors.purple;
      case PetRarity.legendary:
        return Colors.orange;
    }
  }

  IconData _getPetIcon(PetType type) {
    switch (type) {
      case PetType.mammal:
        return Icons.pets;
      case PetType.bird:
        return Icons.flight;
      case PetType.reptile:
        return Icons.cruelty_free;
      case PetType.fish:
        return Icons.water;
      case PetType.insect:
        return Icons.bug_report;
      case PetType.mythical:
        return Icons.auto_awesome;
    }
  }

  Color _getStarColor(int starLevel) {
    switch (starLevel) {
      case 1:
        return const Color(0xFF4CAF50); // Green
      case 2:
        return const Color(0xFF2196F3); // Blue
      case 3:
        return const Color(0xFF9C27B0); // Purple
      case 4:
        return const Color(0xFFFF9800); // Orange
      case 5:
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}
