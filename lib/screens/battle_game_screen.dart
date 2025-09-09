import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/game_provider.dart';
import '../core/models/pet.dart';
import '../core/models/game_data.dart';
import '../core/services/battle_service.dart';
import '../core/data/pet_data.dart';

class BattleGameScreen extends StatefulWidget {
  const BattleGameScreen({super.key});

  @override
  State<BattleGameScreen> createState() => _BattleGameScreenState();
}

class _BattleGameScreenState extends State<BattleGameScreen>
    with TickerProviderStateMixin {
  List<BattlePet>? _playerTeam;
  List<BattlePet>? _enemyTeam;
  bool _isBattleActive = false;
  bool _isPlayerTurn = true;
  int _currentTurn = 0;
  String _battleLog = 'Battle starting...';
  late AnimationController _attackController;
  late Animation<double> _attackAnimation;

  @override
  void initState() {
    super.initState();
    _attackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _attackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _attackController, curve: Curves.easeInOut),
    );
    _initializeBattle();
  }

  @override
  void dispose() {
    _attackController.dispose();
    super.dispose();
  }

  void _initializeBattle() {
    // Create player team from starter pets
    final starterPets = PetData.getStarterPets();
    _playerTeam = starterPets.take(3).map((pet) => BattlePet(
      pet: pet,
      currentHealth: pet.currentHealth,
      currentAttack: pet.currentAttack,
      position: starterPets.indexOf(pet),
      activeEffects: [],
      isAlive: true,
    )).toList();

    // Create enemy team
    _enemyTeam = BattleService.generateEnemyTeam(1);
    
    setState(() {
      _isBattleActive = true;
      _isPlayerTurn = true;
      _currentTurn = 1;
      _battleLog = 'Battle begins! Your pets vs enemy pets!';
    });

    // Start the battle after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      _startBattleLoop();
    });
  }

  Future<void> _startBattleLoop() async {
    while (_isBattleActive && _playerTeam != null && _enemyTeam != null) {
      await _executeTurn();
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!_isBattleActive) break;
      
      _isPlayerTurn = !_isPlayerTurn;
      _currentTurn++;
    }
  }

  Future<void> _executeTurn() async {
    if (_playerTeam == null || _enemyTeam == null) return;

    final alivePlayerPets = _playerTeam!.where((pet) => pet.isAlive).toList();
    final aliveEnemyPets = _enemyTeam!.where((pet) => pet.isAlive).toList();

    if (alivePlayerPets.isEmpty || aliveEnemyPets.isEmpty) {
      _endBattle();
      return;
    }

    if (_isPlayerTurn) {
      await _playerAttack(alivePlayerPets.first, aliveEnemyPets.first);
    } else {
      await _enemyAttack(aliveEnemyPets.first, alivePlayerPets.first);
    }

    setState(() {});
  }

  Future<void> _playerAttack(BattlePet attacker, BattlePet target) async {
    _attackController.forward().then((_) {
      _attackController.reset();
    });

    final damage = _calculateDamage(attacker, target);
    target.currentHealth -= damage;
    
    if (target.currentHealth <= 0) {
      target.currentHealth = 0;
      target.isAlive = false;
    }

    setState(() {
      _battleLog = '${attacker.pet.name} attacks ${target.pet.name} for $damage damage!';
    });

    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _enemyAttack(BattlePet attacker, BattlePet target) async {
    _attackController.forward().then((_) {
      _attackController.reset();
    });

    final damage = _calculateDamage(attacker, target);
    target.currentHealth -= damage;
    
    if (target.currentHealth <= 0) {
      target.currentHealth = 0;
      target.isAlive = false;
    }

    setState(() {
      _battleLog = 'Enemy ${attacker.pet.name} attacks ${target.pet.name} for $damage damage!';
    });

    await Future.delayed(const Duration(milliseconds: 800));
  }

  int _calculateDamage(BattlePet attacker, BattlePet target) {
    // Simple damage calculation
    int damage = attacker.currentAttack;
    // Add some randomness
    final random = DateTime.now().millisecondsSinceEpoch % 3;
    damage += random - 1; // -1, 0, or +1
    return damage.clamp(1, damage);
  }

  void _endBattle() {
    if (_playerTeam == null || _enemyTeam == null) return;

    final alivePlayerPets = _playerTeam!.where((pet) => pet.isAlive).toList();
    final aliveEnemyPets = _enemyTeam!.where((pet) => pet.isAlive).toList();

    final playerWon = alivePlayerPets.isNotEmpty && aliveEnemyPets.isEmpty;
    
    setState(() {
      _isBattleActive = false;
      _battleLog = playerWon ? 'Victory! You won the battle!' : 'Defeat! Your pets were defeated!';
    });

    // Show results after a delay
    Future.delayed(const Duration(seconds: 2), () {
      _showBattleResults(playerWon);
    });
  }

  void _showBattleResults(bool playerWon) {
    final coinsEarned = playerWon ? 15 : 5;
    final experienceEarned = playerWon ? 25 : 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              playerWon ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              color: playerWon ? AppTheme.successColor : AppTheme.errorColor,
            ),
            const SizedBox(width: 8),
            Text(playerWon ? 'Victory!' : 'Defeat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Battle completed in $_currentTurn turns'),
            const SizedBox(height: 8),
            Text('Coins earned: $coinsEarned'),
            Text('Experience earned: $experienceEarned'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
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
      ),
      body: _playerTeam == null || _enemyTeam == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBattleLog(),
                Expanded(
                  child: _buildBattleField(),
                ),
                _buildTurnIndicator(),
              ],
            ),
    );
  }

  Widget _buildBattleLog() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Text(
        _battleLog,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBattleField() {
    return Row(
      children: [
        Expanded(
          child: _buildTeamSection('Your Team', _playerTeam!, true),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTeamSection('Enemy Team', _enemyTeam!, false),
        ),
      ],
    );
  }

  Widget _buildTeamSection(String title, List<BattlePet> pets, bool isPlayer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPlayer ? AppTheme.primaryColor : AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index];
                  return _buildPetCard(pet, isPlayer);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(BattlePet battlePet, bool isPlayer) {
    final pet = battlePet.pet;
    final isAlive = battlePet.isAlive;
    final healthPercentage = battlePet.currentHealth / pet.currentHealth;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAlive ? AppTheme.surfaceColor : AppTheme.dividerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAlive 
              ? (isPlayer ? AppTheme.primaryColor : AppTheme.errorColor)
              : AppTheme.secondaryTextColor,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getPetIcon(pet.type),
                size: 24,
                color: isAlive ? AppTheme.primaryTextColor : AppTheme.secondaryTextColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pet.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isAlive ? AppTheme.primaryTextColor : AppTheme.secondaryTextColor,
                  ),
                ),
              ),
              if (!isAlive)
                const Icon(
                  Icons.close,
                  color: AppTheme.errorColor,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite, size: 16, color: AppTheme.errorColor),
              const SizedBox(width: 4),
              Text('${battlePet.currentHealth}/${pet.currentHealth}'),
              const SizedBox(width: 16),
              Icon(Icons.flash_on, size: 16, color: AppTheme.warningColor),
              const SizedBox(width: 4),
              Text('${battlePet.currentAttack}'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: healthPercentage,
            backgroundColor: AppTheme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              healthPercentage > 0.5 
                  ? AppTheme.successColor 
                  : healthPercentage > 0.25 
                      ? AppTheme.warningColor 
                      : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isPlayerTurn ? AppTheme.primaryColor : AppTheme.errorColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _isPlayerTurn ? 'Your Turn' : 'Enemy Turn',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
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
}
