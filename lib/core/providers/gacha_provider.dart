import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/game_data.dart';
import '../models/pet.dart';
import '../services/storage_service.dart';
import '../data/pet_data.dart';

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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

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
  Future<GachaResult?> performSinglePull({bool useGems = false, required UserProgress userProgress}) async {
    if (_isLoading) return null;
    
    _setLoading(true);
    try {
      final result = await _performPull(useGems: useGems, userProgress: userProgress);
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
  Future<List<GachaResult>> performTenPull({bool useGems = false, required UserProgress userProgress}) async {
    if (_isLoading) return [];
    
    _setLoading(true);
    try {
      // Check if user can afford ten pulls
      final totalCost = useGems ? (_premiumPullCost * 10) : _tenPullCost;
      final hasEnoughCurrency = useGems 
          ? (userProgress.gems >= totalCost)
          : (userProgress.coins >= totalCost);
      
      if (!hasEnoughCurrency) {
        _error = useGems 
            ? 'Not enough gems! Need $totalCost gems for ten pulls.'
            : 'Not enough coins! Need $totalCost coins for ten pulls.';
        notifyListeners();
        return [];
      }
      
      final results = <GachaResult>[];
      
      // Perform 9 regular pulls
      for (int i = 0; i < 9; i++) {
        final result = await _performPull(useGems: useGems, userProgress: userProgress);
        if (result != null) {
          results.add(result);
        }
      }
      
      // 10th pull is guaranteed rare or better
      final guaranteedResult = await _performGuaranteedPull(useGems: useGems, userProgress: userProgress);
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
  Future<GachaResult?> _performPull({bool useGems = false, required UserProgress userProgress}) async {
    final cost = useGems ? _premiumPullCost : _singlePullCost;
    final hasEnoughCurrency = useGems 
        ? (userProgress.gems >= cost)
        : (userProgress.coins >= cost);
    
    if (!hasEnoughCurrency) {
      _error = useGems 
          ? 'Not enough gems! Need $cost gems.'
          : 'Not enough coins! Need $cost coins.';
      notifyListeners();
      return null;
    }
    
    // Deduct currency by updating user progress
    final updatedProgress = userProgress.copyWith(
      coins: useGems ? userProgress.coins : userProgress.coins - cost,
      gems: useGems ? userProgress.gems - cost : userProgress.gems,
    );
    await StorageService.saveUserProgress(updatedProgress);
    
    final rarity = _determineRarity();
    final pet = await _generatePet(rarity);
    
    if (pet == null) return null;
    
    final isNewVariant = !StorageService.getUnlockedPets().any((p) => p.variantId == pet.variantId);
    
    // Save the pet to storage so user can use it in battles
    await StorageService.savePet(pet);
    
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
      cost: cost,
    );
  }

  // Perform a guaranteed rare or better pull
  Future<GachaResult?> _performGuaranteedPull({bool useGems = false, required UserProgress userProgress}) async {
    final cost = useGems ? _premiumPullCost : _singlePullCost;
    final hasEnoughCurrency = useGems 
        ? (userProgress.gems >= cost)
        : (userProgress.coins >= cost);
    
    if (!hasEnoughCurrency) {
      _error = useGems 
          ? 'Not enough gems! Need $cost gems.'
          : 'Not enough coins! Need $cost coins.';
      notifyListeners();
      return null;
    }
    
    // Deduct currency by updating user progress
    final updatedProgress = userProgress.copyWith(
      coins: useGems ? userProgress.coins : userProgress.coins - cost,
      gems: useGems ? userProgress.gems - cost : userProgress.gems,
    );
    await StorageService.saveUserProgress(updatedProgress);
    
    // Guaranteed rare or better
    final guaranteedRarities = [PetRarity.rare, PetRarity.epic, PetRarity.legendary];
    final rarity = guaranteedRarities[_random.nextInt(guaranteedRarities.length)];
    
    final pet = await _generatePet(rarity);
    if (pet == null) return null;
    
    final isNewVariant = !StorageService.getUnlockedPets().any((p) => p.variantId == pet.variantId);
    
    // Save the pet to storage so user can use it in battles
    await StorageService.savePet(pet);
    
    if (isNewVariant) {
      await StorageService.unlockPet(pet.id);
    }
    
    return GachaResult(
      id: _uuid.v4(),
      pet: pet,
      rarity: rarity,
      isNewVariant: isNewVariant,
      timestamp: DateTime.now(),
      cost: cost,
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
    // Get all pets of the specified rarity from our pet data
    final availablePets = PetData.getPetsByRarity(rarity);
    
    if (availablePets.isEmpty) {
      return null;
    }
    
    // Select a random pet from the available pets
    final selectedPet = availablePets[_random.nextInt(availablePets.length)];
    
    // Create a copy with a unique ID and mark as unlocked
    return Pet(
      id: _uuid.v4(),
      name: selectedPet.name,
      description: selectedPet.description,
      rarity: selectedPet.rarity,
      type: selectedPet.type,
      baseAttack: selectedPet.baseAttack,
      baseHealth: selectedPet.baseHealth,
      level: 1,
      experience: 0,
      abilities: selectedPet.abilities,
      imagePath: selectedPet.imagePath,
      variantId: selectedPet.variantId,
      isUnlocked: true,
      unlockDate: DateTime.now(),
    );
  }


  // Utility Methods
  void _setLoading(bool loading) {
    _isLoading = loading;
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

