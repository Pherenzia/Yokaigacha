import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/game_provider.dart';
import '../core/models/pet.dart';
import '../core/models/game_data.dart';
import '../core/services/battle_service.dart';
import '../core/services/storage_service.dart';
import '../core/data/pet_data.dart';

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
  List<String> _battleLog = [];
  
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
    
    // Use selected pets from shop if available, otherwise use default pets
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
    
    _enemyTeam = BattleService.generateEnemyTeam(1);
    _battleLog.add('Battle started with ${_playerTeam!.length} pets!');
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
        title: const Text('Battle'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
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
    final healthPercentage = battlePet.currentHealth / pet.currentHealth;
    
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
            '${battlePet.currentHealth}/${pet.currentHealth} HP',
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
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Home'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _startNewBattle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Battle Again'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isPlayerTurn ? _executePlayerTurn : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPlayerTurn ? AppTheme.primaryColor : AppTheme.dividerColor,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(
          _isPlayerTurn ? 'Attack!' : 'Enemy Turn...',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
    
    // Create battle result
    final battleResult = BattleResult(
      battleId: DateTime.now().millisecondsSinceEpoch.toString(),
      isVictory: isVictory,
      coinsEarned: isVictory ? 15 : 5,
      experienceEarned: isVictory ? 25 : 10,
      petsUsed: _playerTeam!.map((pet) => pet.pet.id).toList(),
      battleDate: DateTime.now(),
      turnsTaken: _currentTurn + 1,
      battleLog: {'log': _battleLog},
    );
    
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

  void _startNewBattle() {
    setState(() {
      _currentTurn = 0;
      _isPlayerTurn = true;
      _battleEnded = false;
      _battleResult = null;
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
}
