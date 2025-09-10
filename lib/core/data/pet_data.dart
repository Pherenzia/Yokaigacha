import '../models/pet.dart';

class PetData {
  static List<Pet> getStarterPets() {
    return [
      Pet(
        id: 'tanuki_001',
        name: 'Tanuki',
        description: 'A mischievous raccoon dog with shape-shifting powers.',
        rarity: PetRarity.common,
        type: PetType.mammal,
        baseAttack: 3,
        baseHealth: 4,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Trickster Strike',
            description: 'Deals 3 damage and confuses the enemy.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 3, 'confusion': true},
          ),
        ],
        imagePath: 'assets/images/pets/tanuki.png',
        variantId: 'normal',
        isUnlocked: true,
        unlockDate: DateTime.now(),
      ),
      Pet(
        id: 'kitsune_001',
        name: 'Kitsune',
        description: 'A wise fox spirit with nine tails and magical abilities.',
        rarity: PetRarity.common,
        type: PetType.mammal,
        baseAttack: 4,
        baseHealth: 3,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Fox Fire',
            description: 'Deals 4 damage with mystical flames.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 4, 'fire': true},
          ),
        ],
        imagePath: 'assets/images/pets/kitsune.png',
        variantId: 'normal',
        isUnlocked: true,
        unlockDate: DateTime.now(),
      ),
      Pet(
        id: 'tengu_001',
        name: 'Tengu',
        description: 'A crow-like mountain spirit with wind powers.',
        rarity: PetRarity.common,
        type: PetType.bird,
        baseAttack: 2,
        baseHealth: 5,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Wind Slash',
            description: 'Deals 2 damage with razor-sharp wind.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 2, 'wind': true},
          ),
        ],
        imagePath: 'assets/images/pets/tengu.png',
        variantId: 'normal',
        isUnlocked: true,
        unlockDate: DateTime.now(),
      ),
    ];
  }

  static List<Pet> getAllPets() {
    return [
      ...getStarterPets(),
      // Common Yokai
      Pet(
        id: 'kodama_001',
        name: 'Kodama',
        description: 'A tree spirit that protects ancient forests.',
        rarity: PetRarity.common,
        type: PetType.mythical,
        baseAttack: 2,
        baseHealth: 3,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Nature\'s Wrath',
            description: 'Deals 2 damage with thorny vines.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 2, 'nature': true},
          ),
        ],
        imagePath: 'assets/images/pets/kodama.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      Pet(
        id: 'kappa_001',
        name: 'Kappa',
        description: 'A water demon with a bowl on its head.',
        rarity: PetRarity.common,
        type: PetType.mythical,
        baseAttack: 1,
        baseHealth: 4,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Water Blast',
            description: 'Deals 1 damage with pressurized water.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 1, 'water': true},
          ),
        ],
        imagePath: 'assets/images/pets/kappa.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      // Rare Yokai
      Pet(
        id: 'bakeneko_001',
        name: 'Bakeneko',
        description: 'A cat demon with supernatural powers.',
        rarity: PetRarity.rare,
        type: PetType.mammal,
        baseAttack: 4,
        baseHealth: 4,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Shadow Claw',
            description: 'Deals 4 damage with ethereal claws.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 4, 'shadow': true},
          ),
        ],
        imagePath: 'assets/images/pets/bakeneko.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      Pet(
        id: 'yuki_onna_001',
        name: 'Yuki-onna',
        description: 'A snow woman spirit with ice powers.',
        rarity: PetRarity.rare,
        type: PetType.mythical,
        baseAttack: 3,
        baseHealth: 5,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Frozen Breath',
            description: 'Deals 3 damage and freezes the enemy.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 3, 'ice': true},
          ),
        ],
        imagePath: 'assets/images/pets/yuki_onna.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      Pet(
        id: 'oni_001',
        name: 'Oni',
        description: 'A powerful demon with incredible strength.',
        rarity: PetRarity.rare,
        type: PetType.mythical,
        baseAttack: 5,
        baseHealth: 3,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Demon Strike',
            description: 'Deals 5 damage with demonic force.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 5, 'demon': true},
          ),
        ],
        imagePath: 'assets/images/pets/oni.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      // Epic Yokai
      Pet(
        id: 'ryu_001',
        name: 'Ryu',
        description: 'A powerful dragon spirit of the sky.',
        rarity: PetRarity.epic,
        type: PetType.mythical,
        baseAttack: 6,
        baseHealth: 5,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Dragon Breath',
            description: 'Deals 6 damage with elemental fury.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 6, 'elemental': true},
          ),
        ],
        imagePath: 'assets/images/pets/ryu.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      Pet(
        id: 'shuten_doji_001',
        name: 'Shuten-doji',
        description: 'A legendary oni king with immense power.',
        rarity: PetRarity.epic,
        type: PetType.mythical,
        baseAttack: 7,
        baseHealth: 4,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Oni King\'s Wrath',
            description: 'Deals 7 damage with demonic energy.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 7, 'demon_king': true},
          ),
        ],
        imagePath: 'assets/images/pets/shuten_doji.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      Pet(
        id: 'nue_001',
        name: 'Nue',
        description: 'A chimera-like creature with multiple animal parts.',
        rarity: PetRarity.epic,
        type: PetType.mythical,
        baseAttack: 5,
        baseHealth: 6,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Chaos Strike',
            description: 'Deals 5 damage with chaotic energy.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 5, 'chaos': true},
          ),
        ],
        imagePath: 'assets/images/pets/nue.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      // Legendary Yokai
      Pet(
        id: 'susanoo_001',
        name: 'Susanoo',
        description: 'The storm god with control over wind and lightning.',
        rarity: PetRarity.legendary,
        type: PetType.mythical,
        baseAttack: 8,
        baseHealth: 8,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Divine Storm',
            description: 'Deals 8 damage with godly thunder.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 8, 'divine': true},
          ),
        ],
        imagePath: 'assets/images/pets/susanoo.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      Pet(
        id: 'amaterasu_001',
        name: 'Amaterasu',
        description: 'The sun goddess with radiant power.',
        rarity: PetRarity.legendary,
        type: PetType.mythical,
        baseAttack: 7,
        baseHealth: 9,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Solar Flare',
            description: 'Deals 7 damage with blinding light.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 7, 'solar': true},
          ),
        ],
        imagePath: 'assets/images/pets/amaterasu.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
      Pet(
        id: 'tsukuyomi_001',
        name: 'Tsukuyomi',
        description: 'The moon god with mysterious lunar powers.',
        rarity: PetRarity.legendary,
        type: PetType.mythical,
        baseAttack: 6,
        baseHealth: 10,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Lunar Eclipse',
            description: 'Deals 6 damage with shadow magic.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 6, 'lunar': true},
          ),
        ],
        imagePath: 'assets/images/pets/tsukuyomi.png',
        variantId: 'normal',
        isUnlocked: false,
      ),
    ];
  }

  /// Get boss Yokai for special battles (every 10th round)
  static List<Pet> getBossYokai() {
    return [
      // Ancient Dragon Boss
      Pet(
        id: 'boss_ancient_dragon_001',
        name: 'Ancient Dragon',
        description: 'An ancient dragon that has lived for millennia, wielding immense power.',
        rarity: PetRarity.legendary,
        type: PetType.mythical,
        baseAttack: 12,
        baseHealth: 15,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Dragon\'s Wrath',
            description: 'Deals 12 damage with ancient dragon power.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 12, 'ancient': true},
          ),
        ],
        imagePath: 'assets/images/pets/boss_ancient_dragon.png',
        variantId: 'boss',
        isUnlocked: false,
      ),
      // Demon King Boss
      Pet(
        id: 'boss_demon_king_001',
        name: 'Demon King',
        description: 'The ruler of all demons, commanding dark forces beyond imagination.',
        rarity: PetRarity.legendary,
        type: PetType.mythical,
        baseAttack: 15,
        baseHealth: 12,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Hellfire Blast',
            description: 'Deals 15 damage with demonic hellfire.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 15, 'hellfire': true},
          ),
        ],
        imagePath: 'assets/images/pets/boss_demon_king.png',
        variantId: 'boss',
        isUnlocked: false,
      ),
      // Celestial Phoenix Boss
      Pet(
        id: 'boss_celestial_phoenix_001',
        name: 'Celestial Phoenix',
        description: 'A divine phoenix that controls the cycle of life and death.',
        rarity: PetRarity.legendary,
        type: PetType.mythical,
        baseAttack: 10,
        baseHealth: 18,
        level: 1,
        experience: 0,
        abilities: [
          PetAbility(
            name: 'Phoenix Rebirth',
            description: 'Deals 10 damage and can resurrect once per battle.',
            triggerLevel: 1,
            triggerCondition: 'start_of_battle',
            parameters: {'damage': 10, 'rebirth': true},
          ),
        ],
        imagePath: 'assets/images/pets/boss_celestial_phoenix.png',
        variantId: 'boss',
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
