import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/game_provider.dart';
import '../core/models/pet.dart';
import '../core/models/game_data.dart';
import '../core/services/battle_service.dart';
import '../core/services/storage_service.dart';
import '../core/data/pet_data.dart';
import 'home_screen.dart';

class BattleGameScreen extends StatefulWidget {
  final List<Pet>? selectedPets;
  
  const BattleGameScreen({super.key, this.selectedPets});

  @override
  State<BattleGameScreen> createState() => _BattleGameScreenState();
}

class _BattleGameScreenState extends State<BattleGameScreen>
    with TickerProviderStateMixin {
  List<BattlePet>? _playerTeam;
  List<BattlePet>? _enemyTeam;
  int _currentTurn = 0;
  bool _isPlayerTurn = true;
  bool _battleEnded = false;
  String? _battleResult;
  BattleResult? _battleResultData;
  List<String> _battleLog = [];
  bool _isBattleAnimating = false;
  
  // Store original scaled health values for retries
  Map<String, int> _originalEnemyHealth = {};
  Map<String, int> _originalPlayerHealth = {};
  
  late AnimationController _attackController;
  late AnimationController _damageController;
  late Animation<double> _attackAnimation;
  late Animation<double> _damageAnimation;

  @override
  void initState() {
    super.initState();
    _initializeBattle();
    _setupAnimations();
  }

  void _setupAnimations() {
    _attackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _damageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _attackAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _attackController,
      curve: Curves.easeInOut,
    ));
    
    _damageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _damageController,
      curve: Curves.easeOut,
    ));
  }

  void _initializeBattle() {
    List<Pet> petsToUse;
    
    // Use selected pets from team builder if available, otherwise use default pets
    if (widget.selectedPets != null && widget.selectedPets!.isNotEmpty) {
      petsToUse = widget.selectedPets!;
    } else {
      // Get user's unlocked pets from storage
      final userPets = StorageService.getAllPets().where((pet) => pet.isUnlocked).toList();
      
      // If user has pets, use them; otherwise use starter pets
      petsToUse = userPets.isNotEmpty ? userPets : PetData.getStarterPets();
    }
    
    _playerTeam = petsToUse.take(5).map((pet) => BattlePet(
      pet: pet,
      currentHealth: pet.currentHealth,
      currentAttack: pet.currentAttack,
      position: petsToUse.indexOf(pet),
      activeEffects: [],
      isAlive: true,
    )).toList();
    
    // Store original player health values
    _originalPlayerHealth.clear();
    for (final pet in _playerTeam!) {
      _originalPlayerHealth[pet.pet.id] = pet.currentHealth;
    }
    
    // Get current round from user progress
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentRound = gameProvider.userProgress?.currentRound ?? 1;
    
    _enemyTeam = BattleService.generateEnemyTeam(currentRound);
    
    // Store original enemy health values (scaled)
    _originalEnemyHealth.clear();
    for (final pet in _enemyTeam!) {
      _originalEnemyHealth[pet.pet.id] = pet.currentHealth;
      if (kDebugMode) {
        print('Storing original enemy health: ${pet.pet.name} (${pet.pet.id}) = ${pet.currentHealth}');
      }
    }
    
    // Check if this is a boss round
    final isBossRound = currentRound % 10 == 0;
    if (isBossRound) {
      _battleLog.add('🔥 BOSS BATTLE - Round $currentRound! 🔥');
      _battleLog.add('A powerful boss Yokai has appeared!');
    } else {
      _battleLog.add('Round $currentRound - Battle started with ${_playerTeam!.length} pets!');
    }
  }

  void _initializeBattleForRetry() {
    // Reset player team health to original values
    if (_playerTeam != null) {
      for (final pet in _playerTeam!) {
        pet.currentHealth = _originalPlayerHealth[pet.pet.id] ?? pet.pet.currentHealth;
        pet.isAlive = true;
        pet.activeEffects.clear();
      }
    }
    
    // Reset enemy team health to original scaled values
    if (_enemyTeam != null) {
      for (final pet in _enemyTeam!) {
        // Reset to the original scaled health that was generated
        final originalHealth = _originalEnemyHealth[pet.pet.id] ?? pet.currentHealth;
        pet.currentHealth = originalHealth;
        pet.isAlive = true;
        pet.activeEffects.clear();
        if (kDebugMode) {
          print('Retry: Restoring enemy health: ${pet.pet.name} (${pet.pet.id}) = $originalHealth');
        }
      }
    }
    
    // Get current round from user progress
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentRound = gameProvider.userProgress?.currentRound ?? 1;
    
    // Check if this is a boss round
    final isBossRound = currentRound % 10 == 0;
    if (isBossRound) {
      _battleLog.add('🔥 BOSS BATTLE - Round $currentRound! 🔥');
      _battleLog.add('A powerful boss Yokai has appeared!');
    } else {
      _battleLog.add('Round $currentRound - Battle started with ${_playerTeam!.length} pets!');
    }
  }

  @override
  void dispose() {
    _attackController.dispose();
    _damageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            final currentRound = gameProvider.userProgress?.currentRound ?? 1;
            final isBossRound = currentRound % 10 == 0;
            return Row(
              children: [
                if (isBossRound) ...[
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                ],
                Text('Round $currentRound${isBossRound ? ' - BOSS!' : ''}'),
              ],
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.surfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildBattleHeader(),
              Expanded(
                child: _buildBattleArea(),
              ),
              _buildBattleControls(),
              _buildBattleLog(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBattleHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Turn ${_currentTurn + 1}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_battleResult != null)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _battleResult == 'Victory!' 
                        ? AppTheme.successColor 
                        : AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _battleResult!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_battleResultData != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: AppTheme.warningColor,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${_battleResultData!.coinsEarned}',
                              style: TextStyle(
                                color: AppTheme.warningColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Coins',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              Icons.star,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${_battleResultData!.experienceEarned}',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'XP',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBattleArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Enemy Team
          _buildTeamArea('Enemy Team', _enemyTeam ?? [], true),
          const SizedBox(height: 20),
          // Battle Status
          _buildBattleStatus(),
          const SizedBox(height: 20),
          // Player Team
          _buildTeamArea('Your Team', _playerTeam ?? [], false),
        ],
      ),
    );
  }

  Widget _buildTeamArea(String title, List<BattlePet> team, bool isEnemy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: team.map((pet) => _buildPetCard(pet, isEnemy)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(BattlePet battlePet, bool isEnemy) {
    final pet = battlePet.pet;
    final originalMaxHealth = isEnemy 
        ? (_originalEnemyHealth[pet.id] ?? pet.baseHealth)
        : (_originalPlayerHealth[pet.id] ?? pet.baseHealth);
    final healthPercentage = battlePet.currentHealth / originalMaxHealth;
    
    return Container(
      width: 100,
      child: Column(
        children: [
          // Pet Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: battlePet.isAlive 
                  ? _getRarityColor(pet.rarity).withOpacity(0.1)
                  : AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: battlePet.isAlive 
                    ? _getRarityColor(pet.rarity)
                    : AppTheme.secondaryTextColor,
                width: 2,
              ),
            ),
            child: Icon(
              _getPetIcon(pet.type),
              size: 32,
              color: battlePet.isAlive 
                  ? _getRarityColor(pet.rarity)
                  : AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          // Pet Name
          Text(
            pet.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Health Bar
          Container(
            width: 80,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: healthPercentage,
              child: Container(
                decoration: BoxDecoration(
                  color: healthPercentage > 0.5 
                      ? AppTheme.successColor
                      : healthPercentage > 0.25
                          ? AppTheme.warningColor
                          : AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Stats
          Text(
            '${battlePet.currentHealth}/$originalMaxHealth HP',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
            ),
          ),
          Text(
            '${battlePet.currentAttack} ATK',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusItem('VS', Icons.sports_mma, AppTheme.primaryColor),
          if (_isPlayerTurn)
            _buildStatusItem('Your Turn', Icons.play_arrow, AppTheme.successColor)
          else
            _buildStatusItem('Enemy Turn', Icons.pause, AppTheme.warningColor),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBattleControls() {
    if (_battleEnded) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final currentRound = gameProvider.userProgress?.currentRound ?? 1;
      final isVictory = _battleResult == 'Victory!';
      final nextRound = currentRound + 1;
      final isBossRound = nextRound % 10 == 0;
      
      return Container(
        padding: const EdgeInsets.all(16),
        child: isVictory 
          ? Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    ),
                    child: const Text('Back to Home'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startNextRound,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: Text(isBossRound 
                      ? 'Next Round (BOSS!)' 
                      : 'Next Round ($nextRound)'),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        ),
                        child: const Text('Back to Home'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _startNewBattle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _restartFromRound1,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Restart from Round 1'),
                  ),
                ),
              ],
            ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_isPlayerTurn && !_isBattleAnimating) ? _playFullBattle : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isPlayerTurn && !_isBattleAnimating) ? AppTheme.primaryColor : AppTheme.dividerColor,
                minimumSize: const Size(0, 50),
              ),
              child: Text(
                _isBattleAnimating ? 'Battle in Progress...' : (_isPlayerTurn ? 'Auto Battle' : 'Enemy Turn...'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: (_isPlayerTurn && !_isBattleAnimating) ? _quickPlayBattle : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isPlayerTurn && !_isBattleAnimating) ? AppTheme.secondaryColor : AppTheme.dividerColor,
                minimumSize: const Size(0, 50),
              ),
              child: const Text(
                'Quick Play',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleLog() {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Battle Log',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _battleLog.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _battleLog[index],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _executePlayerTurn() async {
    if (_playerTeam == null || _enemyTeam == null) return;
    
    final alivePlayerPets = _playerTeam!.where((pet) => pet.isAlive).toList();
    final aliveEnemyPets = _enemyTeam!.where((pet) => pet.isAlive).toList();
    
    if (alivePlayerPets.isEmpty || aliveEnemyPets.isEmpty) {
      _endBattle();
      return;
    }
    
    // Player attacks
    final attacker = alivePlayerPets.first;
    final target = aliveEnemyPets.first;
    
    _battleLog.add('${attacker.pet.name} attacks ${target.pet.name}!');
    
    // Animate attack
    _attackController.forward().then((_) {
      _attackController.reset();
    });
    
    // Calculate damage
    final damage = attacker.currentAttack;
    target.currentHealth -= damage;
    
    _battleLog.add('${target.pet.name} takes $damage damage!');
    
    if (target.currentHealth <= 0) {
      target.currentHealth = 0;
      target.isAlive = false;
      _battleLog.add('${target.pet.name} is defeated!');
    }
    
    // Animate damage
    _damageController.forward().then((_) {
      _damageController.reset();
    });
    
    setState(() {});
    
    // Wait a bit then enemy turn
    await Future.delayed(const Duration(milliseconds: 1500));
    _executeEnemyTurn();
  }

  void _executeEnemyTurn() async {
    if (_playerTeam == null || _enemyTeam == null) return;
    
    final alivePlayerPets = _playerTeam!.where((pet) => pet.isAlive).toList();
    final aliveEnemyPets = _enemyTeam!.where((pet) => pet.isAlive).toList();
    
    if (alivePlayerPets.isEmpty || aliveEnemyPets.isEmpty) {
      _endBattle();
      return;
    }
    
    // Enemy attacks
    final attacker = aliveEnemyPets.first;
    final target = alivePlayerPets.first;
    
    _battleLog.add('${attacker.pet.name} attacks ${target.pet.name}!');
    
    // Animate attack
    _attackController.forward().then((_) {
      _attackController.reset();
    });
    
    // Calculate damage
    final damage = attacker.currentAttack;
    target.currentHealth -= damage;
    
    _battleLog.add('${target.pet.name} takes $damage damage!');
    
    if (target.currentHealth <= 0) {
      target.currentHealth = 0;
      target.isAlive = false;
      _battleLog.add('${target.pet.name} is defeated!');
    }
    
    // Animate damage
    _damageController.forward().then((_) {
      _damageController.reset();
    });
    
    setState(() {
      _isPlayerTurn = true;
      _currentTurn++;
    });
    
    // Check if battle should continue
    await Future.delayed(const Duration(milliseconds: 1500));
    if (_playerTeam!.any((pet) => pet.isAlive) && _enemyTeam!.any((pet) => pet.isAlive)) {
      // Continue battle
    } else {
      _endBattle();
    }
  }

  void _endBattle() {
    final playerAlive = _playerTeam!.any((pet) => pet.isAlive);
    final enemyAlive = _enemyTeam!.any((pet) => pet.isAlive);
    
    if (playerAlive && !enemyAlive) {
      _battleResult = 'Victory!';
      _battleLog.add('You won the battle!');
    } else if (!playerAlive && enemyAlive) {
      _battleResult = 'Defeat!';
      _battleLog.add('You lost the battle!');
    } else {
      _battleResult = 'Draw!';
      _battleLog.add('The battle ended in a draw!');
    }
    
    setState(() {
      _battleEnded = true;
      _isPlayerTurn = false;
    });
    
    // Save battle result
    _saveBattleResult();
  }

  void _saveBattleResult() async {
    if (_playerTeam == null || _enemyTeam == null) return;
    
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final isVictory = _battleResult == 'Victory!';
    
    // If we already have battle result data from the battle service, use it
    if (_battleResultData != null) {
      // Update user progress with the battle result from the service
      await gameProvider.updateUserProgress(
        gameProvider.userProgress!.copyWith(
          coins: gameProvider.userProgress!.coins + _battleResultData!.coinsEarned,
          experience: gameProvider.userProgress!.experience + _battleResultData!.experienceEarned,
          battlesWon: isVictory ? gameProvider.userProgress!.battlesWon + 1 : gameProvider.userProgress!.battlesWon,
          battlesLost: !isVictory ? gameProvider.userProgress!.battlesLost + 1 : gameProvider.userProgress!.battlesLost,
        ),
      );
    } else {
      // Fallback for manual battles (auto battle mode)
      final currentRound = gameProvider.userProgress?.currentRound ?? 1;
      
      // Calculate rewards based on round level
      int coinsEarned = 0;
      int experienceEarned = 0;
      
      if (isVictory) {
        // Base rewards: +2 coins per round level, +1 XP per round level
        coinsEarned = currentRound * 2;
        experienceEarned = currentRound;
        
        // Bonus for every 5th round: +5 coins and +2 XP
        if (currentRound % 5 == 0) {
          coinsEarned += 5;
          experienceEarned += 2;
        }
      } else {
        // Reduced rewards for defeat: half the base rewards
        coinsEarned = (currentRound * 2) ~/ 2;
        experienceEarned = currentRound ~/ 2;
        
        // Still get bonus for 5th rounds, but reduced
        if (currentRound % 5 == 0) {
          coinsEarned += 2;
          experienceEarned += 1;
        }
      }
      
      // Create battle result for manual battles
      final battleResult = BattleResult(
        battleId: DateTime.now().millisecondsSinceEpoch.toString(),
        isVictory: isVictory,
        coinsEarned: coinsEarned,
        experienceEarned: experienceEarned,
        petsUsed: _playerTeam!.map((pet) => pet.pet.id).toList(),
        battleDate: DateTime.now(),
        turnsTaken: _currentTurn + 1,
        battleLog: {'log': _battleLog},
      );
      
      // Store battle result data for display
      setState(() {
        _battleResultData = battleResult;
      });
      
      // Update user progress
      await gameProvider.updateUserProgress(
        gameProvider.userProgress!.copyWith(
          coins: gameProvider.userProgress!.coins + battleResult.coinsEarned,
          experience: gameProvider.userProgress!.experience + battleResult.experienceEarned,
          battlesWon: isVictory ? gameProvider.userProgress!.battlesWon + 1 : gameProvider.userProgress!.battlesWon,
          battlesLost: !isVictory ? gameProvider.userProgress!.battlesLost + 1 : gameProvider.userProgress!.battlesLost,
        ),
      );
    }
  }

  void _startNewBattle() {
    setState(() {
      _currentTurn = 0;
      _isPlayerTurn = true;
      _battleEnded = false;
      _battleResult = null;
      _battleResultData = null;
      _battleLog.clear();
      _isBattleAnimating = false;
    });
    _initializeBattleForRetry();
  }

  void _startNextRound() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    // Advance to next round on victory
    if (_battleResult == 'Victory!') {
      final currentRound = gameProvider.userProgress?.currentRound ?? 1;
      final nextRound = currentRound + 1;
      
      await gameProvider.updateUserProgress(
        gameProvider.userProgress!.copyWith(
          currentRound: nextRound,
        ),
      );
    }
    
    setState(() {
      _currentTurn = 0;
      _isPlayerTurn = true;
      _battleEnded = false;
      _battleResult = null;
      _battleResultData = null;
      _battleLog.clear();
    });
    _initializeBattle();
  }

  Color _getRarityColor(PetRarity rarity) {
    switch (rarity) {
      case PetRarity.common:
        return AppTheme.petRarityCommon;
      case PetRarity.rare:
        return AppTheme.petRarityRare;
      case PetRarity.epic:
        return AppTheme.petRarityEpic;
      case PetRarity.legendary:
        return AppTheme.petRarityLegendary;
    }
  }

  IconData _getPetIcon(PetType type) {
    switch (type) {
      case PetType.mammal:
        return Icons.pets;
      case PetType.bird:
        return Icons.flight;
      case PetType.reptile:
        return Icons.eco;
      case PetType.fish:
        return Icons.water;
      case PetType.insect:
        return Icons.bug_report;
      case PetType.mythical:
        return Icons.auto_awesome;
    }
  }

  void _restartFromRound1() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    // Reset to round 1
    await gameProvider.updateUserProgress(
      gameProvider.userProgress!.copyWith(
        currentRound: 1,
      ),
    );
    
    // Reset battle state and start fresh
    setState(() {
      _currentTurn = 0;
      _isPlayerTurn = true;
      _battleEnded = false;
      _battleResult = null;
      _battleResultData = null;
      _battleLog.clear();
      _playerTeam = null;
      _enemyTeam = null;
      _isBattleAnimating = false;
    });
    
    // Initialize battle with round 1 difficulty (this will regenerate teams with proper scaling)
    _initializeBattle();
  }

  void _playFullBattle() async {
    if (_isBattleAnimating || _battleEnded) return;
    
    setState(() {
      _isBattleAnimating = true;
    });
    
    // Use the proper battle service for consistent results
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentRound = gameProvider.userProgress?.currentRound ?? 1;
    
    try {
      final battleResult = BattleService.simulateBattle(
        playerTeam: _playerTeam!,
        enemyTeam: _enemyTeam!,
        battleId: DateTime.now().millisecondsSinceEpoch.toString(),
        currentRound: currentRound,
      );
      
      // Simulate the battle with visual feedback
      await _simulateBattleWithAnimation(battleResult);
      
      // Update the battle pets' health to match the battle result
      _updateBattlePetsHealth(battleResult);
      
      // Update the battle state based on the result
      setState(() {
        _battleResult = battleResult.isVictory ? 'Victory!' : 'Defeat!';
        _battleResultData = battleResult;
        _battleEnded = true;
        _isPlayerTurn = false;
        _isBattleAnimating = false;
      });
      
      // Add result to battle log
      _battleLog.add(battleResult.isVictory ? 'You won the battle!' : 'You lost the battle!');
      
      // Save battle result and update user progress
      _saveBattleResult();
      
    } catch (e) {
      print('Error in auto battle: $e');
      setState(() {
        _isBattleAnimating = false;
      });
    }
  }

  void _updateBattlePetsHealth(BattleResult battleResult) {
    // Update player team health based on battle result
    final battleLog = battleResult.battleLog;
    if (battleLog != null && battleLog['playerTeam'] != null) {
      final playerTeamData = battleLog['playerTeam'] as List<dynamic>;
      
      // Create a map of pet ID to health data for efficient lookup
      final playerHealthMap = <String, Map<String, dynamic>>{};
      for (final petData in playerTeamData) {
        final petJson = petData as Map<String, dynamic>;
        // The 'pet' field is now a Map (from toJson()), so we can access id directly
        final petMap = petJson['pet'] as Map<String, dynamic>;
        final petId = petMap['id'] as String;
        playerHealthMap[petId] = petJson;
      }
      
      // Update player team health by matching pet IDs
      for (final playerPet in _playerTeam!) {
        final petId = playerPet.pet.id;
        if (playerHealthMap.containsKey(petId)) {
          final petData = playerHealthMap[petId]!;
          final newHealth = petData['currentHealth'] as int;
          playerPet.currentHealth = newHealth;
          playerPet.isAlive = newHealth > 0;
          
          // Debug logging
          if (kDebugMode) {
            print('Player ${playerPet.pet.name} (${petId}): Health = $newHealth, Alive = ${playerPet.isAlive}');
          }
        }
      }
    }
    
    // Update enemy team health based on battle result
    if (battleLog != null && battleLog['enemyTeam'] != null) {
      final enemyTeamData = battleLog['enemyTeam'] as List<dynamic>;
      
      // Create a map of pet ID to health data for efficient lookup
      final enemyHealthMap = <String, Map<String, dynamic>>{};
      for (final petData in enemyTeamData) {
        final petJson = petData as Map<String, dynamic>;
        // The 'pet' field is now a Map (from toJson()), so we can access id directly
        final petMap = petJson['pet'] as Map<String, dynamic>;
        final petId = petMap['id'] as String;
        enemyHealthMap[petId] = petJson;
      }
      
      // Update enemy team health by matching pet IDs
      for (final enemyPet in _enemyTeam!) {
        final petId = enemyPet.pet.id;
        if (enemyHealthMap.containsKey(petId)) {
          final petData = enemyHealthMap[petId]!;
          final newHealth = petData['currentHealth'] as int;
          enemyPet.currentHealth = newHealth;
          enemyPet.isAlive = newHealth > 0;
          
          // Debug logging
          if (kDebugMode) {
            print('Enemy ${enemyPet.pet.name} (${petId}): Health = $newHealth, Alive = ${enemyPet.isAlive}');
          }
        }
      }
    }
  }

  Future<void> _simulateBattleWithAnimation(BattleResult battleResult) async {
    // Extract battle turns from the battle result
    final battleLog = battleResult.battleLog;
    if (battleLog != null && battleLog['turns'] != null) {
      final turns = battleLog['turns'] as List<dynamic>;
      
      for (final turn in turns) {
        final turnData = turn as Map<String, dynamic>;
        final turnNumber = turnData['turn'] as int;
        
        // Add turn header to battle log
        _battleLog.add('--- Turn $turnNumber ---');
        
        // Process player attacks
        final playerAttacks = turnData['playerAttacks'] as List<dynamic>;
        for (final attack in playerAttacks) {
          final attackData = attack as Map<String, dynamic>;
          final attacker = attackData['attacker'] as String;
          final target = attackData['target'] as String;
          final targetId = attackData['targetId'] as String;
          final damage = attackData['damage'] as int;
          final targetHealth = attackData['targetHealth'] as int;
          
          _battleLog.add('$attacker attacks $target for $damage damage!');
          
          // Update enemy pet health in real-time using unique ID
          final enemyPet = _enemyTeam!.firstWhere(
            (pet) => pet.pet.id == targetId,
            orElse: () => _enemyTeam!.first,
          );
          enemyPet.currentHealth = targetHealth;
          enemyPet.isAlive = targetHealth > 0;
          
          if (targetHealth <= 0) {
            _battleLog.add('$target is defeated!');
          }
          
          // Update the UI to show health changes
          setState(() {});
          
          // Wait for visual feedback
          await Future.delayed(const Duration(milliseconds: 400));
        }
        
        // Process enemy attacks
        final enemyAttacks = turnData['enemyAttacks'] as List<dynamic>;
        for (final attack in enemyAttacks) {
          final attackData = attack as Map<String, dynamic>;
          final attacker = attackData['attacker'] as String;
          final target = attackData['target'] as String;
          final targetId = attackData['targetId'] as String;
          final damage = attackData['damage'] as int;
          final targetHealth = attackData['targetHealth'] as int;
          
          _battleLog.add('$attacker attacks $target for $damage damage!');
          
          // Update player pet health in real-time using unique ID
          final playerPet = _playerTeam!.firstWhere(
            (pet) => pet.pet.id == targetId,
            orElse: () => _playerTeam!.first,
          );
          playerPet.currentHealth = targetHealth;
          playerPet.isAlive = targetHealth > 0;
          
          if (targetHealth <= 0) {
            _battleLog.add('$target is defeated!');
          }
          
          // Update the UI to show health changes
          setState(() {});
          
          // Wait for visual feedback
          await Future.delayed(const Duration(milliseconds: 400));
        }
        
        // Wait between turns
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  void _quickPlayBattle() async {
    if (_isBattleAnimating || _battleEnded) return;
    
    setState(() {
      _isBattleAnimating = true;
    });
    
    // Use the proper battle service for consistent results
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentRound = gameProvider.userProgress?.currentRound ?? 1;
    
    try {
      final battleResult = BattleService.simulateBattle(
        playerTeam: _playerTeam!,
        enemyTeam: _enemyTeam!,
        battleId: DateTime.now().millisecondsSinceEpoch.toString(),
        currentRound: currentRound,
      );
      
      // Update the battle pets' health to match the battle result
      _updateBattlePetsHealth(battleResult);
      
      // Update the battle state based on the result
      setState(() {
        _battleResult = battleResult.isVictory ? 'Victory!' : 'Defeat!';
        _battleResultData = battleResult;
        _battleEnded = true;
        _isPlayerTurn = false;
        _isBattleAnimating = false;
      });
      
      // Add result to battle log
      _battleLog.add(battleResult.isVictory ? 'You won the battle!' : 'You lost the battle!');
      
      // Save battle result and update user progress
      _saveBattleResult();
      
    } catch (e) {
      print('Error in quick play battle: $e');
      setState(() {
        _isBattleAnimating = false;
      });
    }
  }
}
