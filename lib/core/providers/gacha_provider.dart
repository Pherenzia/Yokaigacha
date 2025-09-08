import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/game_data.dart';
import '../models/pet.dart';
import '../services/storage_service.dart';

class GachaProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final _random = Random();
  
  List<GachaResult> _gachaHistory = [];
  bool _isLoading = false;
  String? _error;

  // Gacha rates (percentages)
  static const Map<PetRarity, double> _gachaRates = {
    PetRarity.common: 70.0,
    PetRarity.rare: 20.0,
    PetRarity.epic: 8.0,
    PetRarity.legendary: 2.0,
  };

  // Gacha costs
  static const int _singlePullCost = 100; // coins
  static const int _tenPullCost = 900; // coins (10% discount)
  static const int _premiumPullCost = 50; // gems

  // Getters
  List<GachaResult> get gachaHistory => _gachaHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get singlePullCost => _singlePullCost;
  int get tenPullCost => _tenPullCost;
  int get premiumPullCost => _premiumPullCost;

  // Initialize gacha system
  Future<void> initializeGacha() async {
    _setLoading(true);
    try {
      _gachaHistory = StorageService.getGachaHistory();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize gacha system: $e';
      if (kDebugMode) {
        print('Gacha initialization error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Single pull
  Future<GachaResult?> performSinglePull({bool useGems = false}) async {
    if (_isLoading) return null;
    
    _setLoading(true);
    try {
      final result = await _performPull(useGems: useGems);
      if (result != null) {
        await StorageService.saveGachaResult(result);
        _gachaHistory.insert(0, result);
        notifyListeners();
      }
      return result;
    } catch (e) {
      _error = 'Failed to perform gacha pull: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Ten pull (guaranteed rare or better)
  Future<List<GachaResult>> performTenPull({bool useGems = false}) async {
    if (_isLoading) return [];
    
    _setLoading(true);
    try {
      final results = <GachaResult>[];
      
      // Perform 9 regular pulls
      for (int i = 0; i < 9; i++) {
        final result = await _performPull(useGems: useGems);
        if (result != null) {
          results.add(result);
        }
      }
      
      // 10th pull is guaranteed rare or better
      final guaranteedResult = await _performGuaranteedPull(useGems: useGems);
      if (guaranteedResult != null) {
        results.add(guaranteedResult);
      }
      
      // Save all results
      for (final result in results) {
        await StorageService.saveGachaResult(result);
        _gachaHistory.insert(0, result);
      }
      
      notifyListeners();
      return results;
    } catch (e) {
      _error = 'Failed to perform ten pull: $e';
      notifyListeners();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Perform a single pull
  Future<GachaResult?> _performPull({bool useGems = false}) async {
    final rarity = _determineRarity();
    final pet = await _generatePet(rarity);
    
    if (pet == null) return null;
    
    final isNewVariant = !StorageService.getUnlockedPets().any((p) => p.variantId == pet.variantId);
    
    // Unlock the pet if it's new
    if (isNewVariant) {
      await StorageService.unlockPet(pet.id);
    }
    
    return GachaResult(
      id: _uuid.v4(),
      pet: pet,
      rarity: rarity,
      isNewVariant: isNewVariant,
      timestamp: DateTime.now(),
      cost: useGems ? _premiumPullCost : _singlePullCost,
    );
  }

  // Perform a guaranteed rare or better pull
  Future<GachaResult?> _performGuaranteedPull({bool useGems = false}) async {
    // Guaranteed rare or better
    final guaranteedRarities = [PetRarity.rare, PetRarity.epic, PetRarity.legendary];
    final rarity = guaranteedRarities[_random.nextInt(guaranteedRarities.length)];
    
    final pet = await _generatePet(rarity);
    if (pet == null) return null;
    
    final isNewVariant = !StorageService.getUnlockedPets().any((p) => p.variantId == pet.variantId);
    
    if (isNewVariant) {
      await StorageService.unlockPet(pet.id);
    }
    
    return GachaResult(
      id: _uuid.v4(),
      pet: pet,
      rarity: rarity,
      isNewVariant: isNewVariant,
      timestamp: DateTime.now(),
      cost: useGems ? _premiumPullCost : _singlePullCost,
    );
  }

  // Determine rarity based on rates
  PetRarity _determineRarity() {
    final roll = _random.nextDouble() * 100;
    double cumulative = 0;
    
    for (final entry in _gachaRates.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) {
        return entry.key;
      }
    }
    
    return PetRarity.common; // Fallback
  }

  // Generate a pet of the specified rarity
  Future<Pet?> _generatePet(PetRarity rarity) async {
    // This would typically load from a database or configuration
    // For now, we'll create placeholder pets
    
    final petTypes = PetType.values;
    final petType = petTypes[_random.nextInt(petTypes.length)];
    
    final baseStats = _getBaseStatsForRarity(rarity);
    final variantId = _generateVariantId();
    
    return Pet(
      id: _uuid.v4(),
      name: _generatePetName(petType, rarity),
      description: _generatePetDescription(petType, rarity),
      rarity: rarity,
      type: petType,
      baseAttack: baseStats['attack']!,
      baseHealth: baseStats['health']!,
      level: 1,
      experience: 0,
      abilities: _generateAbilities(rarity),
      imagePath: 'assets/images/pets/${petType.name}_${rarity.name}.png',
      variantId: variantId,
      isUnlocked: false,
    );
  }

  // Get base stats based on rarity
  Map<String, int> _getBaseStatsForRarity(PetRarity rarity) {
    switch (rarity) {
      case PetRarity.common:
        return {'attack': 2, 'health': 3};
      case PetRarity.rare:
        return {'attack': 3, 'health': 4};
      case PetRarity.epic:
        return {'attack': 4, 'health': 5};
      case PetRarity.legendary:
        return {'attack': 5, 'health': 6};
    }
  }

  // Generate variant ID
  String _generateVariantId() {
    final variants = ['normal', 'shiny', 'golden', 'rainbow', 'shadow'];
    return variants[_random.nextInt(variants.length)];
  }

  // Generate pet name
  String _generatePetName(PetType type, PetRarity rarity) {
    final baseNames = {
      PetType.mammal: ['Cat', 'Dog', 'Bear', 'Wolf', 'Lion'],
      PetType.bird: ['Eagle', 'Owl', 'Parrot', 'Falcon', 'Raven'],
      PetType.reptile: ['Snake', 'Lizard', 'Turtle', 'Dragon', 'Gecko'],
      PetType.fish: ['Goldfish', 'Shark', 'Dolphin', 'Whale', 'Octopus'],
      PetType.insect: ['Bee', 'Butterfly', 'Spider', 'Ant', 'Beetle'],
      PetType.mythical: ['Phoenix', 'Unicorn', 'Griffin', 'Pegasus', 'Dragon'],
    };
    
    final names = baseNames[type] ?? ['Creature'];
    final baseName = names[_random.nextInt(names.length)];
    
    if (rarity == PetRarity.legendary) {
      return 'Legendary $baseName';
    } else if (rarity == PetRarity.epic) {
      return 'Epic $baseName';
    } else if (rarity == PetRarity.rare) {
      return 'Rare $baseName';
    } else {
      return baseName;
    }
  }

  // Generate pet description
  String _generatePetDescription(PetType type, PetRarity rarity) {
    final descriptions = {
      PetRarity.common: 'A common but reliable companion.',
      PetRarity.rare: 'A rare find with special abilities.',
      PetRarity.epic: 'An epic creature with powerful skills.',
      PetRarity.legendary: 'A legendary being of immense power.',
    };
    
    return descriptions[rarity] ?? 'A mysterious creature.';
  }

  // Generate abilities based on rarity
  List<PetAbility> _generateAbilities(PetRarity rarity) {
    final abilities = <PetAbility>[];
    
    // All pets get a basic ability
    abilities.add(PetAbility(
      name: 'Basic Attack',
      description: 'Deals damage to the enemy.',
      triggerLevel: 1,
      triggerCondition: 'start_of_battle',
      parameters: {'damage': 1},
    ));
    
    // Higher rarity pets get additional abilities
    if (rarity.index >= PetRarity.rare.index) {
      abilities.add(PetAbility(
        name: 'Special Ability',
        description: 'A special ability unique to this pet.',
        triggerLevel: 2,
        triggerCondition: 'end_of_turn',
        parameters: {'effect': 'heal', 'amount': 1},
      ));
    }
    
    if (rarity.index >= PetRarity.epic.index) {
      abilities.add(PetAbility(
        name: 'Ultimate Ability',
        description: 'A powerful ultimate ability.',
        triggerLevel: 3,
        triggerCondition: 'hurt',
        parameters: {'effect': 'counter_attack', 'damage': 2},
      ));
    }
    
    return abilities;
  }

  // Utility Methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get gacha statistics
  Map<String, dynamic> getGachaStats() {
    final totalPulls = _gachaHistory.length;
    final rarityCounts = <PetRarity, int>{};
    final newVariants = _gachaHistory.where((result) => result.isNewVariant).length;
    
    for (final result in _gachaHistory) {
      rarityCounts[result.rarity] = (rarityCounts[result.rarity] ?? 0) + 1;
    }
    
    return {
      'totalPulls': totalPulls,
      'newVariants': newVariants,
      'rarityCounts': rarityCounts,
      'lastPull': _gachaHistory.isNotEmpty ? _gachaHistory.first.timestamp : null,
    };
  }
}

