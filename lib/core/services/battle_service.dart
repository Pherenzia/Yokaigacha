import 'dart:math';
import '../models/pet.dart';
import '../models/game_data.dart';
import '../data/pet_data.dart';

class BattleService {
  static final Random _random = Random();

  /// Simulate a battle between two teams
  static BattleResult simulateBattle({
    required List<BattlePet> playerTeam,
    required List<BattlePet> enemyTeam,
    required String battleId,
    int currentRound = 1,
  }) {
    final battleLog = <String, dynamic>{};
    final turns = <Map<String, dynamic>>[];
    
    // Create copies of teams for battle
    List<BattlePet> playerPets = playerTeam.map((pet) => BattlePet(
      pet: pet.pet,
      currentHealth: pet.pet.currentHealth,
      currentAttack: pet.pet.currentAttack,
      position: pet.position,
      activeEffects: [],
      isAlive: true,
    )).toList();
    
    List<BattlePet> enemyPets = enemyTeam.map((pet) => BattlePet(
      pet: pet.pet,
      currentHealth: pet.pet.currentHealth,
      currentAttack: pet.pet.currentAttack,
      position: pet.position,
      activeEffects: [],
      isAlive: true,
    )).toList();

    int turnCount = 0;
    bool playerWon = false;

    // Battle loop
    while (turnCount < 50) { // Max 50 turns to prevent infinite loops
      turnCount++;
      
      // Check if battle is over
      final playerAlive = playerPets.where((pet) => pet.isAlive).toList();
      final enemyAlive = enemyPets.where((pet) => pet.isAlive).toList();
      
      if (playerAlive.isEmpty) {
        playerWon = false;
        break;
      }
      
      if (enemyAlive.isEmpty) {
        playerWon = true;
        break;
      }

      // Simple battle logic: each pet attacks the first alive enemy
      final turn = <String, dynamic>{
        'turn': turnCount,
        'playerAttacks': <Map<String, dynamic>>[],
        'enemyAttacks': <Map<String, dynamic>>[],
      };

      // Player pets attack
      for (final playerPet in playerAlive) {
        final target = enemyAlive.first;
        final damage = _calculateDamage(playerPet, target);
        
        target.currentHealth -= damage;
        if (target.currentHealth <= 0) {
          target.currentHealth = 0;
          target.isAlive = false;
        }

        turn['playerAttacks'].add({
          'attacker': playerPet.pet.name,
          'target': target.pet.name,
          'damage': damage,
          'targetHealth': target.currentHealth,
        });
      }

      // Enemy pets attack
      for (final enemyPet in enemyAlive) {
        final target = playerAlive.first;
        final damage = _calculateDamage(enemyPet, target);
        
        target.currentHealth -= damage;
        if (target.currentHealth <= 0) {
          target.currentHealth = 0;
          target.isAlive = false;
        }

        turn['enemyAttacks'].add({
          'attacker': enemyPet.pet.name,
          'target': target.pet.name,
          'damage': damage,
          'targetHealth': target.currentHealth,
        });
      }

      turns.add(turn);
    }

    // Calculate rewards based on round level
    int coinsEarned = 0;
    int experienceEarned = 0;
    
    if (playerWon) {
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

    battleLog['turns'] = turns;
    battleLog['playerTeam'] = playerPets.map((pet) => pet.toJson()).toList();
    battleLog['enemyTeam'] = enemyPets.map((pet) => pet.toJson()).toList();
    battleLog['finalResult'] = playerWon ? 'victory' : 'defeat';

    return BattleResult(
      battleId: battleId,
      isVictory: playerWon,
      coinsEarned: coinsEarned,
      experienceEarned: experienceEarned,
      petsUsed: playerTeam.map((pet) => pet.pet.id).toList(),
      battleDate: DateTime.now(),
      turnsTaken: turnCount,
      battleLog: battleLog,
    );
  }

  /// Calculate damage between two pets
  static int _calculateDamage(BattlePet attacker, BattlePet defender) {
    // Base damage is attacker's attack power
    int damage = attacker.currentAttack;
    
    // Add some randomness (±20%)
    final randomFactor = 0.8 + (_random.nextDouble() * 0.4);
    damage = (damage * randomFactor).round();
    
    // Minimum 1 damage
    return damage.clamp(1, damage);
  }

  /// Generate a random enemy team with progressive difficulty
  static List<BattlePet> generateEnemyTeam(int currentRound) {
    final allPets = PetData.getAllPets();
    final enemyPets = <BattlePet>[];
    
    // Check if this is a boss round (every 10th round)
    if (currentRound % 10 == 0) {
      return _generateBossTeam(currentRound);
    }
    
    // Calculate team size: 3 base + 1 every 5 rounds
    int teamSize = 3 + (currentRound ~/ 5);
    teamSize = teamSize.clamp(3, 8); // Cap at 8 enemies
    
    for (int i = 0; i < teamSize; i++) {
      // Higher rounds = better pets
      PetRarity rarity;
      if (currentRound < 3) {
        rarity = PetRarity.common;
      } else if (currentRound < 6) {
        rarity = _random.nextBool() ? PetRarity.common : PetRarity.rare;
      } else if (currentRound < 10) {
        final rand = _random.nextDouble();
        if (rand < 0.4) rarity = PetRarity.common;
        else if (rand < 0.8) rarity = PetRarity.rare;
        else rarity = PetRarity.epic;
      } else {
        final rand = _random.nextDouble();
        if (rand < 0.2) rarity = PetRarity.common;
        else if (rand < 0.5) rarity = PetRarity.rare;
        else if (rand < 0.8) rarity = PetRarity.epic;
        else rarity = PetRarity.legendary;
      }
      
      final availablePets = allPets.where((pet) => pet.rarity == rarity).toList();
      if (availablePets.isNotEmpty) {
        final selectedPet = availablePets[_random.nextInt(availablePets.length)];
        
        // Apply stat scaling based on round
        final scaledHealth = _scaleStat(selectedPet.baseHealth, currentRound, 'health');
        final scaledAttack = _scaleStat(selectedPet.baseAttack, currentRound, 'attack');
        
        enemyPets.add(BattlePet(
          pet: selectedPet,
          currentHealth: scaledHealth,
          currentAttack: scaledAttack,
          position: i,
          activeEffects: [],
          isAlive: true,
        ));
      }
    }
    
    return enemyPets;
  }

  /// Generate a boss team for special rounds
  static List<BattlePet> _generateBossTeam(int currentRound) {
    final bossPets = PetData.getBossYokai();
    final selectedBoss = bossPets[_random.nextInt(bossPets.length)];
    
    // Boss gets significant stat scaling
    final bossHealth = _scaleStat(selectedBoss.baseHealth, currentRound, 'health', isBoss: true);
    final bossAttack = _scaleStat(selectedBoss.baseAttack, currentRound, 'attack', isBoss: true);
    
    return [
      BattlePet(
        pet: selectedBoss,
        currentHealth: bossHealth,
        currentAttack: bossAttack,
        position: 0,
        activeEffects: [],
        isAlive: true,
      ),
    ];
  }

  /// Scale stats based on current round
  static int _scaleStat(int baseStat, int currentRound, String statType, {bool isBoss = false}) {
    // Each round increases stats by 1 point
    int scaling = currentRound - 1;
    
    // Boss rounds get additional scaling
    if (isBoss) {
      scaling += (currentRound ~/ 10) * 3; // Extra scaling for boss rounds
    }
    
    // Apply scaling to the stat
    if (statType == 'health') {
      return baseStat + scaling;
    } else if (statType == 'attack') {
      return baseStat + scaling;
    }
    
    return baseStat;
  }
}
