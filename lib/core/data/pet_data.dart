import '../models/pet.dart';

class PetData {
  static List<Pet> getStarterPets() {
    return [
      Pet(
        id: 'cat_001',
        name: 'Cat',
        description: 'A friendly cat with sharp claws.',
        rarity: PetRarity.common,
        type: PetType.mammal,
        baseAttack: 2,
        baseHealth: 3,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Scratch',
            description: 'Deals 1 damage to the enemy.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 1},
          ),
        ],
        imagePath: 'assets/images/pets/cat.png',
        variantId: 'normal',
        isUnlocked: true,
        unlockDate: DateTime.now(),
      ),
      Pet(
        id: 'dog_001',
        name: 'Dog',
        description: 'A loyal dog with strong bite.',
        rarity: PetRarity.common,
        type: PetType.mammal,
        baseAttack: 3,
        baseHealth: 2,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Bite',
            description: 'Deals 1 damage to the enemy.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 1},
          ),
        ],
        imagePath: 'assets/images/pets/dog.png',
        variantId: 'normal',
        isUnlocked: true,
        unlockDate: DateTime.now(),
      ),
      Pet(
        id: 'bird_001',
        name: 'Bird',
        description: 'A swift bird that can fly.',
        rarity: PetRarity.common,
        type: PetType.bird,
        baseAttack: 1,
        baseHealth: 4,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Peck',
            description: 'Deals 1 damage to the enemy.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 1},
          ),
        ],
        imagePath: 'assets/images/pets/bird.png',
        variantId: 'normal',
        isUnlocked: true,
        unlockDate: DateTime.now(),
      ),
    ];
  }

  static List<Pet> getAllPets() {
    return [
      ...getStarterPets(),
      Pet(
        id: 'lion_001',
        name: 'Lion',
        description: 'The king of the jungle.',
        rarity: PetRarity.rare,
        type: PetType.mammal,
        baseAttack: 4,
        baseHealth: 3,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Roar',
            description: 'Deals 2 damage to the enemy.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 2},
          ),
        ],
        imagePath: 'assets/images/pets/lion.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      Pet(
        id: 'eagle_001',
        name: 'Eagle',
        description: 'A majestic bird of prey.',
        rarity: PetRarity.rare,
        type: PetType.bird,
        baseAttack: 3,
        baseHealth: 4,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Dive',
            description: 'Deals 2 damage to the enemy.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 2},
          ),
        ],
        imagePath: 'assets/images/pets/eagle.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      Pet(
        id: 'dragon_001',
        name: 'Dragon',
        description: 'A legendary fire-breathing dragon.',
        rarity: PetRarity.legendary,
        type: PetType.mythical,
        baseAttack: 6,
        baseHealth: 5,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Fire Breath',
            description: 'Deals 3 damage to the enemy.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 3},
          ),
        ],
        imagePath: 'assets/images/pets/dragon.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
    ];
  }

  static Pet? getPetById(String id) {
    return getAllPets().firstWhere(
      (pet) => pet.id == id,
      orElse: () => throw Exception('Pet with id $id not found'),
    );
  }

  static List<Pet> getPetsByRarity(PetRarity rarity) {
    return getAllPets().where((pet) => pet.rarity == rarity).toList();
  }
}
