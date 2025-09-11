import 'dart:math';
import 'package:flutter/foundation.dart';
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
      currentHealth: pet.currentHealth, // Use the scaled health
      currentAttack: pet.currentAttack, // Use the scaled attack
      position: pet.position,
      activeEffects: [],
      isAlive: true,
    )).toList();
    
    List<BattlePet> enemyPets = enemyTeam.map((pet) => BattlePet(
      pet: pet.pet,
      currentHealth: pet.currentHealth, // Use the scaled health
      currentAttack: pet.currentAttack, // Use the scaled attack
      position: pet.position,
      activeEffects: [],
      isAlive: true,
    )).toList();

    int turnCount = 0;
    bool playerWon = false;

    // Track current attacking pets for each team
    int playerAttackerIndex = 0;
    int enemyAttackerIndex = 0;
    bool isPlayerTurn = true; // Start with player turn

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

      // New battle logic: Each turn alternates between player and enemy
      final turn = <String, dynamic>{
        'turn': turnCount,
        'playerAttacks': <Map<String, dynamic>>[],
        'enemyAttacks': <Map<String, dynamic>>[],
      };

      // Debug: Print turn info
      if (kDebugMode) {
        print('Turn $turnCount (${isPlayerTurn ? 'Player' : 'Enemy'} turn):');
        print('  Player alive: ${playerAlive.map((p) => '${p.pet.name}(${p.currentHealth}HP)').join(', ')}');
        print('  Enemy alive: ${enemyAlive.map((p) => '${p.pet.name}(${p.currentHealth}HP)').join(', ')}');
      }

      if (isPlayerTurn) {
        // Player turn: Find next alive player pet
        BattlePet? playerAttacker;
        while (playerAttackerIndex < playerPets.length) {
          if (playerPets[playerAttackerIndex].isAlive) {
            playerAttacker = playerPets[playerAttackerIndex];
            break;
          }
          playerAttackerIndex++;
        }

        // Player attacks first alive enemy
        if (playerAttacker != null && enemyAlive.isNotEmpty) {
          final target = enemyAlive.first;
          final damage = _calculateDamage(playerAttacker, target);
          
          target.currentHealth -= damage;
          if (target.currentHealth <= 0) {
            target.currentHealth = 0;
            target.isAlive = false;
          }

          final attackData = {
            'attacker': playerAttacker.pet.name,
            'attackerId': playerAttacker.pet.id,
            'target': target.pet.name,
            'targetId': target.pet.id,
            'damage': damage,
            'targetHealth': target.currentHealth,
          };
          
          turn['playerAttacks'].add(attackData);
          
          if (kDebugMode) {
            print('  Player ${playerAttacker.pet.name} attacks Enemy ${target.pet.name} for $damage damage (${target.currentHealth} HP remaining)');
          }
        }
      } else {
        // Enemy turn: Find next alive enemy pet
        BattlePet? enemyAttacker;
        while (enemyAttackerIndex < enemyPets.length) {
          if (enemyPets[enemyAttackerIndex].isAlive) {
            enemyAttacker = enemyPets[enemyAttackerIndex];
            break;
          }
          enemyAttackerIndex++;
        }

        // Enemy attacks first alive player
        if (enemyAttacker != null && playerAlive.isNotEmpty) {
          final target = playerAlive.first;
          final damage = _calculateDamage(enemyAttacker, target);
          
          target.currentHealth -= damage;
          if (target.currentHealth <= 0) {
            target.currentHealth = 0;
            target.isAlive = false;
          }

          final attackData = {
            'attacker': enemyAttacker.pet.name,
            'attackerId': enemyAttacker.pet.id,
            'target': target.pet.name,
            'targetId': target.pet.id,
            'damage': damage,
            'targetHealth': target.currentHealth,
          };
          
          turn['enemyAttacks'].add(attackData);
          
          if (kDebugMode) {
            print('  Enemy ${enemyAttacker.pet.name} attacks Player ${target.pet.name} for $damage damage (${target.currentHealth} HP remaining)');
          }
        }
      }

      // Check if battle is over after the attack
      final finalPlayerAlive = playerPets.where((pet) => pet.isAlive).toList();
      final finalEnemyAlive = enemyPets.where((pet) => pet.isAlive).toList();
      
      if (finalPlayerAlive.isEmpty) {
        playerWon = false;
        turns.add(turn);
        break;
      }
      
      if (finalEnemyAlive.isEmpty) {
        playerWon = true;
        turns.add(turn);
        break;
      }

      // Switch turns for next round
      isPlayerTurn = !isPlayerTurn;
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

  /// Generate a predetermined enemy team with progressive difficulty
  static List<BattlePet> generateEnemyTeam(int currentRound) {
    // Check if this is a boss round (every 10th round)
    if (currentRound % 10 == 0) {
      return _generateBossTeam(currentRound);
    }
    
    // Use predetermined teams for rounds 1-15
    if (currentRound <= 15) {
      return _getPredeterminedEnemyTeam(currentRound);
    }
    
    // For rounds 16+, fall back to random generation
    return _generateRandomEnemyTeam(currentRound);
  }

  /// Get predetermined enemy team for rounds 1-15
  static List<BattlePet> _getPredeterminedEnemyTeam(int currentRound) {
    final allPets = PetData.getAllPets();
    final enemyPets = <BattlePet>[];
    
    // Define predetermined enemy compositions for each round
    final enemyCompositions = _getEnemyCompositions();
    final composition = enemyCompositions[currentRound] ?? enemyCompositions[15]!;
    
    for (int i = 0; i < composition.length; i++) {
      final enemyData = composition[i];
      final pet = allPets.firstWhere(
        (p) => p.id == enemyData['petId'],
        orElse: () => allPets.first,
      );
      
      // Apply scaling based on current round
      final scaledAttack = _scaleStat(pet.baseAttack, currentRound, 'attack');
      final scaledHealth = _scaleStat(pet.baseHealth, currentRound, 'health');
      
      // Create battle pet with scaled stats
      final battlePet = BattlePet(
        pet: pet,
        currentHealth: scaledHealth,
        currentAttack: scaledAttack,
        position: i,
        activeEffects: [],
        isAlive: true,
      );
      
      enemyPets.add(battlePet);
    }
    
    return enemyPets;
  }

  /// Define predetermined enemy compositions for rounds 1-15
  static Map<int, List<Map<String, dynamic>>> _getEnemyCompositions() {
    return {
      1: [
        {'petId': 'tanuki_starter_001'},
        {'petId': 'kitsune_starter_001'},
        {'petId': 'tengu_starter_001'},
      ],
      2: [
        {'petId': 'tanuki_starter_001'},
        {'petId': 'kitsune_starter_001'},
        {'petId': 'tengu_starter_001'},
        {'petId': 'oni_common_001'},
      ],
      3: [
        {'petId': 'tanuki_starter_001'},
        {'petId': 'kitsune_starter_001'},
        {'petId': 'tengu_starter_001'},
        {'petId': 'oni_common_001'},
        {'petId': 'kitsune_common_001'},
      ],
      4: [
        {'petId': 'kitsune_common_001'},
        {'petId': 'oni_common_001'},
        {'petId': 'tanuki_common_001'},
        {'petId': 'tengu_common_001'},
      ],
      5: [
        {'petId': 'kitsune_common_001'},
        {'petId': 'oni_common_001'},
        {'petId': 'tanuki_common_001'},
        {'petId': 'tengu_common_001'},
        {'petId': 'susanoo_common_001'},
      ],
      6: [
        {'petId': 'kitsune_rare_001'},
        {'petId': 'oni_common_001'},
        {'petId': 'tanuki_common_001'},
        {'petId': 'tengu_common_001'},
        {'petId': 'susanoo_common_001'},
      ],
      7: [
        {'petId': 'kitsune_rare_001'},
        {'petId': 'oni_rare_001'},
        {'petId': 'tanuki_common_001'},
        {'petId': 'tengu_common_001'},
        {'petId': 'susanoo_common_001'},
        {'petId': 'kitsune_common_001'},
      ],
      8: [
        {'petId': 'kitsune_rare_001'},
        {'petId': 'oni_rare_001'},
        {'petId': 'tanuki_rare_001'},
        {'petId': 'tengu_common_001'},
        {'petId': 'susanoo_common_001'},
        {'petId': 'kitsune_common_001'},
      ],
      9: [
        {'petId': 'kitsune_rare_001'},
        {'petId': 'oni_rare_001'},
        {'petId': 'tanuki_rare_001'},
        {'petId': 'tengu_rare_001'},
        {'petId': 'susanoo_common_001'},
        {'petId': 'kitsune_common_001'},
        {'petId': 'oni_common_001'},
      ],
      11: [
        {'petId': 'kitsune_epic_001'},
        {'petId': 'oni_rare_001'},
        {'petId': 'tanuki_rare_001'},
        {'petId': 'tengu_rare_001'},
        {'petId': 'susanoo_rare_001'},
        {'petId': 'kitsune_common_001'},
        {'petId': 'oni_common_001'},
      ],
      12: [
        {'petId': 'kitsune_epic_001'},
        {'petId': 'oni_epic_001'},
        {'petId': 'tanuki_rare_001'},
        {'petId': 'tengu_rare_001'},
        {'petId': 'susanoo_rare_001'},
        {'petId': 'kitsune_common_001'},
        {'petId': 'oni_common_001'},
        {'petId': 'tanuki_common_001'},
      ],
      13: [
        {'petId': 'kitsune_epic_001'},
        {'petId': 'oni_epic_001'},
        {'petId': 'tanuki_epic_001'},
        {'petId': 'tengu_rare_001'},
        {'petId': 'susanoo_rare_001'},
        {'petId': 'kitsune_common_001'},
        {'petId': 'oni_common_001'},
        {'petId': 'tanuki_common_001'},
      ],
      14: [
        {'petId': 'kitsune_epic_001'},
        {'petId': 'oni_epic_001'},
        {'petId': 'tanuki_epic_001'},
        {'petId': 'tengu_epic_001'},
        {'petId': 'susanoo_rare_001'},
        {'petId': 'kitsune_common_001'},
        {'petId': 'oni_common_001'},
        {'petId': 'tanuki_common_001'},
        {'petId': 'tengu_common_001'},
      ],
      15: [
        {'petId': 'kitsune_epic_001'},
        {'petId': 'oni_epic_001'},
        {'petId': 'tanuki_epic_001'},
        {'petId': 'tengu_epic_001'},
        {'petId': 'susanoo_epic_001'},
        {'petId': 'kitsune_common_001'},
        {'petId': 'oni_common_001'},
        {'petId': 'tanuki_common_001'},
        {'petId': 'tengu_common_001'},
        {'petId': 'susanoo_common_001'},
      ],
    };
  }

  /// Generate random enemy team for rounds 16+
  static List<BattlePet> _generateRandomEnemyTeam(int currentRound) {
    final allPets = PetData.getAllPets();
    final enemyPets = <BattlePet>[];
    
    // Calculate team size: 3 base + 1 every 3 rounds, with faster scaling
    int teamSize = 3 + (currentRound ~/ 3); // More frequent enemy additions
    teamSize = teamSize.clamp(3, 10); // Cap at 10 enemies for more challenge
    
    for (int i = 0; i < teamSize; i++) {
      // Higher rounds = better pets with more aggressive scaling
      PetRarity rarity;
      if (currentRound < 20) {
        final rand = _random.nextDouble();
        if (rand < 0.1) rarity = PetRarity.rare;
        else if (rand < 0.6) rarity = PetRarity.epic;
        else rarity = PetRarity.legendary;
      } else {
        // Very high rounds: mostly epic and legendary
        final rand = _random.nextDouble();
        if (rand < 0.1) rarity = PetRarity.rare;
        else if (rand < 0.6) rarity = PetRarity.epic;
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
    // Base scaling: each round increases stats
    int scaling = currentRound - 1;
    
    // Additional scaling for higher rounds
    if (currentRound > 5) {
      scaling += (currentRound - 5) * 2; // Extra scaling after round 5
    }
    
    if (currentRound > 10) {
      scaling += (currentRound - 10) * 3; // Even more scaling after round 10
    }
    
    // Boss rounds get significant additional scaling
    if (isBoss) {
      scaling += (currentRound ~/ 10) * 5; // Extra scaling for boss rounds
    }
    
    // Apply scaling to the stat
    if (statType == 'health') {
      // Health gets more scaling than attack for tankiness
      return baseStat + (scaling * 1.5).round();
    } else if (statType == 'attack') {
      return baseStat + scaling;
    }
    
    return baseStat;
  }
}
