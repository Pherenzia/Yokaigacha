import 'package:flutter/foundation.dart';
import '../models/pet.dart';
import 'storage_service.dart';

class StarService {
  /// Calculate how many copies are needed to reach the next star level
  static int getCopiesRequiredForNextStar(int currentStarLevel) {
    if (currentStarLevel >= 5) return 0; // Max stars reached
    return 2 * (1 << currentStarLevel); // 2, 4, 8, 16, 32 for levels 1-5
  }

  /// Get all pets grouped by their unique characteristics (name + rarity + variant)
  static Map<String, List<Pet>> getGroupedPets() {
    final allPets = StorageService.getAllPets();
    
    // Filter out removed pets (those with '_removed' in their ID)
    final pets = allPets.where((pet) => !pet.id.contains('_removed')).toList();
    
    final Map<String, List<Pet>> groupedPets = {};
    
    for (final pet in pets) {
      // Create a unique key based on name, rarity, and variant
      final uniqueKey = '${pet.name}_${pet.rarity.name}_${pet.variantId}';
      
      if (!groupedPets.containsKey(uniqueKey)) {
        groupedPets[uniqueKey] = [];
      }
      groupedPets[uniqueKey]!.add(pet);
    }
    
    return groupedPets;
  }

  /// Get the highest star level pet from a group
  static Pet? getHighestStarPet(List<Pet> pets) {
    if (pets.isEmpty) return null;
    
    // Sort by star level (highest first), then by unlock date (newest first)
    pets.sort((a, b) {
      if (a.starLevel != b.starLevel) {
        return b.starLevel.compareTo(a.starLevel);
      }
      if (a.unlockDate != null && b.unlockDate != null) {
        return b.unlockDate!.compareTo(a.unlockDate!);
      }
      return 0;
    });
    
    return pets.first;
  }

  /// Check if a pet can be starred up
  static bool canStarUp(Pet pet) {
    if (pet.starLevel >= 5) return false; // Max stars reached
    
    final groupedPets = getGroupedPets();
    final uniqueKey = '${pet.name}_${pet.rarity.name}_${pet.variantId}';
    final petGroup = groupedPets[uniqueKey] ?? [];
    
    // Need at least the required number of copies (including the main pet)
    final requiredCopies = getCopiesRequiredForNextStar(pet.starLevel);
    return petGroup.length >= requiredCopies;
  }

  /// Get the number of available copies for starring up
  static int getAvailableCopiesForStarUp(Pet pet) {
    final groupedPets = getGroupedPets();
    final uniqueKey = '${pet.name}_${pet.rarity.name}_${pet.variantId}';
    final petGroup = groupedPets[uniqueKey] ?? [];
    
    // Return total copies available for starring up
    return petGroup.length;
  }

  /// Star up a pet by consuming the required copies
  static Future<bool> starUpPet(Pet pet) async {
    if (!canStarUp(pet)) return false;
    
    final groupedPets = getGroupedPets();
    final uniqueKey = '${pet.name}_${pet.rarity.name}_${pet.variantId}';
    final petGroup = groupedPets[uniqueKey] ?? [];
    
    final requiredCopies = getCopiesRequiredForNextStar(pet.starLevel);
    
    // Sort pets by star level (lowest first) and unlock date (oldest first) for consumption
    final sortedPets = List<Pet>.from(petGroup);
    sortedPets.sort((a, b) {
      if (a.starLevel != b.starLevel) {
        return a.starLevel.compareTo(b.starLevel);
      }
      if (a.unlockDate != null && b.unlockDate != null) {
        return a.unlockDate!.compareTo(b.unlockDate!);
      }
      return 0;
    });
    
    // Find the main pet (highest star level)
    final mainPet = getHighestStarPet(petGroup);
    if (mainPet == null) return false;
    
    // Remove the required number of copies (including the main pet)
    final petsToRemove = <Pet>[];
    int copiesToRemove = requiredCopies;
    
    for (final p in sortedPets) {
      if (copiesToRemove > 0) {
        petsToRemove.add(p);
        copiesToRemove--;
      }
    }
    
    // Remove the consumed pets from storage
    for (final petToRemove in petsToRemove) {
      await StorageService.savePet(petToRemove.copyWith(id: '${petToRemove.id}_removed'));
    }
    
    // Create a new starred pet with the next star level
    final newStarLevel = mainPet.starLevel + 1;
    final newStarredPet = mainPet.copyWith(
      id: '${mainPet.name.toLowerCase()}_${mainPet.rarity.name}_${mainPet.variantId}_star${newStarLevel}_${DateTime.now().millisecondsSinceEpoch}',
      starLevel: newStarLevel,
      unlockDate: DateTime.now(),
    );
    
    
    // Save the new starred pet
    await StorageService.savePet(newStarredPet);
    
    return true;
  }

  /// Get star level display string
  static String getStarDisplay(int starLevel) {
    if (starLevel == 0) return '';
    return '★' * starLevel;
  }

  /// Get star level color
  static String getStarColor(int starLevel) {
    switch (starLevel) {
      case 0:
        return '#9E9E9E'; // Grey
      case 1:
        return '#4CAF50'; // Green
      case 2:
        return '#2196F3'; // Blue
      case 3:
        return '#9C27B0'; // Purple
      case 4:
        return '#FF9800'; // Orange
      case 5:
        return '#F44336'; // Red
      default:
        return '#9E9E9E';
    }
  }
}
