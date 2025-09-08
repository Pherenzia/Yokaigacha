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

    // Calculate rewards
    final coinsEarned = playerWon ? 10 + (turnCount * 2) : 5;
    final experienceEarned = playerWon ? 20 + (turnCount * 3) : 10;

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

  /// Generate a random enemy team
  static List<BattlePet> generateEnemyTeam(int difficulty) {
    final allPets = PetData.getAllPets();
    final enemyPets = <BattlePet>[];
    
    // Select pets based on difficulty
    int teamSize = 3 + (difficulty ~/ 3); // 3-5 pets
    teamSize = teamSize.clamp(3, 5);
    
    for (int i = 0; i < teamSize; i++) {
      // Higher difficulty = better pets
      PetRarity rarity;
      if (difficulty < 3) {
        rarity = PetRarity.common;
      } else if (difficulty < 6) {
        rarity = _random.nextBool() ? PetRarity.common : PetRarity.rare;
      } else if (difficulty < 10) {
        final rand = _random.nextDouble();
        if (rand < 0.4) rarity = PetRarity.common;
        else if (rand < 0.8) rarity = PetRarity.rare;
        else rarity = PetRarity.epic;
      } else {
        final rand = _random.nextDouble();
        if (rand < 0.3) rarity = PetRarity.rare;
        else if (rand < 0.7) rarity = PetRarity.epic;
        else rarity = PetRarity.legendary;
      }
      
      final availablePets = allPets.where((pet) => pet.rarity == rarity).toList();
      if (availablePets.isNotEmpty) {
        final selectedPet = availablePets[_random.nextInt(availablePets.length)];
        
        enemyPets.add(BattlePet(
          pet: selectedPet,
          currentHealth: selectedPet.currentHealth,
          currentAttack: selectedPet.currentAttack,
          position: i,
          activeEffects: [],
          isAlive: true,
        ));
      }
    }
    
    return enemyPets;
  }
}
