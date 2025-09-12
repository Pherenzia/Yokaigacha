import 'dart:math';
import '../models/cavern_run.dart';
import '../models/pet.dart';
import '../data/pet_data.dart';
import 'storage_service.dart';

class CavernService {
  static const int _maxTeamSize = 5;
  static const int _startingLives = 5;
  static const int _startingSpirit = 10;
  static const int _shopSize = 10;
  static const int _livesRecoveryInterval = 5;

  // Rarity distribution for shop generation
  static const Map<PetRarity, double> _rarityDistribution = {
    PetRarity.common: 0.60,    // 60%
    PetRarity.rare: 0.25,      // 25%
    PetRarity.epic: 0.12,      // 12%
    PetRarity.legendary: 0.03, // 3%
  };

  // Spirit costs by rarity
  static const Map<PetRarity, int> _spiritCosts = {
    PetRarity.common: 2,
    PetRarity.rare: 3,
    PetRarity.epic: 4,
    PetRarity.legendary: 5,
  };

  /// Create a new Cavern run
  static Future<CavernRun> startNewRun(String userId) async {
    final run = CavernRun.newRun(userId);
    await StorageService.saveCavernRun(run);
    return run;
  }

  /// Get active run for user
  static Future<CavernRun?> getActiveRun(String userId) async {
    final runs = await StorageService.getAllCavernRuns();
    return runs
        .where((run) => run.userId == userId && run.status == CavernRunStatus.active)
        .firstOrNull;
  }

  /// Generate shop for current floor
  static CavernShop generateShop(int floorNumber, bool isBossReward) {
    final random = Random();
    final availableYokai = <Pet>[];
    
    // Get all unlocked yokai from collection
    final allPets = StorageService.getAllPets()
        .where((pet) => pet.isUnlocked && !pet.id.contains('_removed'))
        .toList();

    if (allPets.isEmpty) {
      // Fallback to default pets if no unlocked pets
      allPets.addAll(PetData.getAllPets());
    }

    // Generate shop based on rarity distribution
    for (int i = 0; i < _shopSize; i++) {
      PetRarity selectedRarity = _selectRarityByDistribution(random);
      
      // Filter pets by rarity
      final petsOfRarity = allPets.where((pet) => pet.rarity == selectedRarity).toList();
      
      if (petsOfRarity.isNotEmpty) {
        final selectedPet = petsOfRarity[random.nextInt(petsOfRarity.length)];
        
        // Create a copy with unique ID for the shop
        final shopPet = selectedPet.copyWith(
          id: '${selectedPet.id}_shop_${DateTime.now().millisecondsSinceEpoch}_$i',
        );
        
        availableYokai.add(shopPet);
      }
    }

    // Boss reward: guarantee at least one rare+ yokai
    if (isBossReward && availableYokai.every((pet) => pet.rarity == PetRarity.common)) {
      final rarePets = allPets.where((pet) => pet.rarity != PetRarity.common).toList();
      if (rarePets.isNotEmpty) {
        final bossReward = rarePets[random.nextInt(rarePets.length)];
        availableYokai[0] = bossReward.copyWith(
          id: '${bossReward.id}_boss_reward_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    }

    return CavernShop(
      floorNumber: floorNumber,
      availableYokai: availableYokai,
      generatedAt: DateTime.now(),
      isBossReward: isBossReward,
    );
  }

  /// Select yokai from shop
  static Future<CavernRun?> selectYokaiFromShop(
    CavernRun run,
    Pet selectedYokai,
  ) async {
    if (run.team.length >= _maxTeamSize) {
      throw Exception('Team is full');
    }

    final spiritCost = _spiritCosts[selectedYokai.rarity] ?? 0;
    if (run.currentSpirit < spiritCost) {
      throw Exception('Not enough spirit');
    }

    // Check uniqueness rules
    if (_hasDuplicateYokai(run.team, selectedYokai)) {
      throw Exception('Cannot have duplicate yokai of same name and rarity');
    }

    // Add yokai to team
    final newTeam = List<Pet>.from(run.team);
    newTeam.add(selectedYokai);

    // Update run
    final updatedRun = run.copyWith(
      team: newTeam,
      currentSpirit: run.currentSpirit - spiritCost,
      totalSpiritSpent: run.totalSpiritSpent + spiritCost,
    );

    await StorageService.saveCavernRun(updatedRun);
    return updatedRun;
  }

  /// Generate enemy team for floor
  static List<Pet> generateEnemyTeam(int spiritValue, bool isBossFloor) {
    final random = Random();
    final enemyTeam = <Pet>[];
    var remainingSpirit = spiritValue;

    // Boss floors get +2 spirit advantage
    if (isBossFloor) {
      remainingSpirit += 2;
    }

    // Get all available pets for enemy generation
    final allPets = PetData.getAllPets();

    // Generate team within spirit budget
    while (enemyTeam.length < _maxTeamSize && remainingSpirit > 0) {
      // Determine available rarities based on remaining spirit
      final availableRarities = <PetRarity>[];
      for (final entry in _spiritCosts.entries) {
        if (entry.value <= remainingSpirit) {
          availableRarities.add(entry.key);
        }
      }

      if (availableRarities.isEmpty) break;

      // Select rarity (boss floors prefer higher rarities)
      PetRarity selectedRarity;
      if (isBossFloor && availableRarities.contains(PetRarity.legendary)) {
        selectedRarity = PetRarity.legendary;
      } else if (isBossFloor && availableRarities.contains(PetRarity.epic)) {
        selectedRarity = PetRarity.epic;
      } else {
        selectedRarity = availableRarities[random.nextInt(availableRarities.length)];
      }

      // Find pets of selected rarity
      final petsOfRarity = allPets.where((pet) => pet.rarity == selectedRarity).toList();
      if (petsOfRarity.isNotEmpty) {
        final selectedPet = petsOfRarity[random.nextInt(petsOfRarity.length)];
        enemyTeam.add(selectedPet);
        remainingSpirit -= _spiritCosts[selectedRarity]!;
      } else {
        break;
      }
    }

    return enemyTeam;
  }

  /// Complete a floor
  static Future<CavernRun?> completeFloor(
    CavernRun run,
    bool wasVictory,
    int livesLost,
  ) async {
    if (run.status != CavernRunStatus.active) {
      throw Exception('Run is not active');
    }

    // Create floor record
    final floor = CavernFloor(
      floorNumber: run.currentFloor,
      spiritValue: run.currentSpirit,
      enemyTeam: generateEnemyTeam(run.currentSpirit, run.isBossFloor),
      isBossFloor: run.isBossFloor,
      completedAt: DateTime.now(),
      wasVictory: wasVictory,
      livesLost: livesLost,
      shopYokai: [], // Will be populated when shop is generated
    );

    // Update run
    final newLives = run.lives - livesLost;
    final newFloor = run.currentFloor + 1;
    final newSpirit = run.currentSpirit + 1; // +1 spirit per floor

    // Check for life recovery every 5 floors
    var finalLives = newLives;
    if (newFloor % _livesRecoveryInterval == 0 && finalLives < _startingLives) {
      finalLives = min(_startingLives, finalLives + 1);
    }

    // Check for run failure
    final newStatus = finalLives <= 0 ? CavernRunStatus.failed : run.status;

    final completedFloors = List<CavernFloor>.from(run.completedFloors);
    completedFloors.add(floor);

    final updatedRun = run.copyWith(
      currentFloor: newFloor,
      currentSpirit: newSpirit,
      lives: finalLives,
      status: newStatus,
      completedFloors: completedFloors,
      highestFloorReached: max(run.highestFloorReached, newFloor),
      endTime: newStatus != CavernRunStatus.active ? DateTime.now() : null,
    );

    await StorageService.saveCavernRun(updatedRun);
    return updatedRun;
  }

  /// Lock team for competitive play
  static Future<LockedTeam?> lockTeam(CavernRun run) async {
    if (!run.canLock) {
      throw Exception('Cannot lock team at this floor');
    }

    if (run.team.length != _maxTeamSize) {
      throw Exception('Team must have 5 yokai to lock');
    }

    // Create locked team
    final lockedTeam = LockedTeam.fromCavernRun(run);

    // Update run status
    final updatedRun = run.copyWith(
      status: CavernRunStatus.locked,
      isLocked: true,
      lockedAt: DateTime.now(),
      lockedFloor: run.currentFloor,
      lockedSpirit: run.currentSpirit,
      endTime: DateTime.now(),
    );

    await StorageService.saveCavernRun(updatedRun);
    await StorageService.saveLockedTeam(lockedTeam);

    return lockedTeam;
  }

  /// Get spirit cost for yokai
  static int getSpiritCost(Pet yokai) {
    return _spiritCosts[yokai.rarity] ?? 0;
  }

  /// Check if yokai can be added to team
  static bool canAddYokaiToTeam(CavernRun run, Pet yokai) {
    if (run.team.length >= _maxTeamSize) return false;
    if (run.currentSpirit < getSpiritCost(yokai)) return false;
    if (_hasDuplicateYokai(run.team, yokai)) return false;
    return true;
  }

  /// Check for duplicate yokai (same name and rarity)
  static bool _hasDuplicateYokai(List<Pet> team, Pet newYokai) {
    return team.any((pet) => 
        pet.name == newYokai.name && pet.rarity == newYokai.rarity);
  }

  /// Select rarity based on distribution
  static PetRarity _selectRarityByDistribution(Random random) {
    final roll = random.nextDouble();
    double cumulative = 0.0;

    for (final entry in _rarityDistribution.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) {
        return entry.key;
      }
    }

    return PetRarity.common; // Fallback
  }

  /// Get all locked teams for competitive play
  static Future<List<LockedTeam>> getLockedTeams() async {
    return await StorageService.getAllLockedTeams();
  }

  /// Get locked teams in spirit bracket
  static Future<List<LockedTeam>> getLockedTeamsInBracket(int spiritValue) async {
    final allTeams = await getLockedTeams();
    return allTeams.where((team) => 
        (team.spiritValue - spiritValue).abs() <= 2).toList();
  }

  /// Update locked team stats after battle
  static Future<void> updateLockedTeamStats(String teamId, bool won) async {
    final team = await StorageService.getLockedTeam(teamId);
    if (team == null) return;

    final newWins = team.wins + (won ? 1 : 0);
    final newLosses = team.losses + (won ? 0 : 1);
    final newWinRate = newWins / (newWins + newLosses);

    final updatedTeam = team.copyWith(
      wins: newWins,
      losses: newLosses,
      winRate: newWinRate,
    );

    await StorageService.saveLockedTeam(updatedTeam);
  }

  /// Get user's cavern statistics
  static Future<Map<String, dynamic>> getUserCavernStats(String userId) async {
    final runs = await StorageService.getAllCavernRuns();
    final userRuns = runs.where((run) => run.userId == userId).toList();

    if (userRuns.isEmpty) {
      return {
        'totalRuns': 0,
        'totalFloors': 0,
        'highestFloor': 0,
        'winRate': 0.0,
        'lockedTeams': 0,
        'averageRunLength': 0.0,
      };
    }

    final completedRuns = userRuns.where((run) => run.status != CavernRunStatus.active).toList();
    final totalFloors = userRuns.fold(0, (sum, run) => sum + run.highestFloorReached);
    final highestFloor = userRuns.fold(0, (max, run) => run.highestFloorReached > max ? run.highestFloorReached : max);
    final lockedTeams = userRuns.where((run) => run.isLocked).length;
    final averageRunLength = completedRuns.isNotEmpty ? totalFloors / completedRuns.length : 0.0;

    return {
      'totalRuns': userRuns.length,
      'totalFloors': totalFloors,
      'highestFloor': highestFloor,
      'winRate': completedRuns.isNotEmpty ? completedRuns.where((run) => run.status == CavernRunStatus.locked).length / completedRuns.length : 0.0,
      'lockedTeams': lockedTeams,
      'averageRunLength': averageRunLength,
    };
  }
}
