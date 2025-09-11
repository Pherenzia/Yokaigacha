import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pet.g.dart';

@HiveType(typeId: 0)
enum PetRarity {
  @HiveField(0)
  common,
  @HiveField(1)
  rare,
  @HiveField(2)
  epic,
  @HiveField(3)
  legendary,
}

@HiveType(typeId: 1)
enum PetType {
  @HiveField(0)
  mammal,
  @HiveField(1)
  bird,
  @HiveField(2)
  reptile,
  @HiveField(3)
  fish,
  @HiveField(4)
  insect,
  @HiveField(5)
  mythical,
}

@HiveType(typeId: 2)
@JsonSerializable()
class PetAbility {
  @HiveField(0)
  final String name;
  
  @HiveField(1)
  final String description;
  
  @HiveField(2)
  final int triggerLevel;
  
  @HiveField(3)
  final String triggerCondition; // "start_of_battle", "end_of_turn", "hurt", etc.
  
  @HiveField(4)
  final Map<String, dynamic> parameters;

  const PetAbility({
    required this.name,
    required this.description,
    required this.triggerLevel,
    required this.triggerCondition,
    required this.parameters,
  });

  factory PetAbility.fromJson(Map<String, dynamic> json) => _$PetAbilityFromJson(json);
  Map<String, dynamic> toJson() => _$PetAbilityToJson(this);
}

@HiveType(typeId: 3)
@JsonSerializable()
class Pet {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final PetRarity rarity;
  
  @HiveField(4)
  final PetType type;
  
  @HiveField(5)
  final int baseAttack;
  
  @HiveField(6)
  final int baseHealth;
  
  @HiveField(7)
  final int level;
  
  @HiveField(8)
  final int experience;
  
  @HiveField(9)
  final List<PetAbility> abilities;
  
  @HiveField(10)
  final String imagePath;
  
  @HiveField(11)
  final String variantId; // For gacha variants
  
  @HiveField(12)
  final bool isUnlocked;
  
  @HiveField(13)
  final DateTime? unlockDate;
  
  @HiveField(14)
  final int starLevel; // 0-5 stars, starts at 0

  const Pet({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.type,
    required this.baseAttack,
    required this.baseHealth,
    required this.level,
    required this.experience,
    required this.abilities,
    required this.imagePath,
    required this.variantId,
    required this.isUnlocked,
    this.unlockDate,
    this.starLevel = 0,
  });

  // Computed properties
  int get currentAttack => baseAttack + (level - 1) * 2 + (starLevel * 3);
  int get currentHealth => baseHealth + (level - 1) * 2 + (starLevel * 5);
  int get experienceToNextLevel => level * 10;
  double get experienceProgress => experience / experienceToNextLevel;
  
  // Star level requirements
  int get copiesRequiredForNextStar {
    if (starLevel >= 5) return 0; // Max stars reached
    return 2 * (1 << starLevel); // 2, 4, 8, 16, 32 for levels 1-5
  }

  Pet copyWith({
    String? id,
    String? name,
    String? description,
    PetRarity? rarity,
    PetType? type,
    int? baseAttack,
    int? baseHealth,
    int? level,
    int? experience,
    List<PetAbility>? abilities,
    String? imagePath,
    String? variantId,
    bool? isUnlocked,
    DateTime? unlockDate,
    int? starLevel,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      type: type ?? this.type,
      baseAttack: baseAttack ?? this.baseAttack,
      baseHealth: baseHealth ?? this.baseHealth,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      abilities: abilities ?? this.abilities,
      imagePath: imagePath ?? this.imagePath,
      variantId: variantId ?? this.variantId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockDate: unlockDate ?? this.unlockDate,
      starLevel: starLevel ?? this.starLevel,
    );
  }

  factory Pet.fromJson(Map<String, dynamic> json) => _$PetFromJson(json);
  Map<String, dynamic> toJson() => _$PetToJson(this);
}

// Battle-specific pet instance
@HiveType(typeId: 4)
@JsonSerializable()
class BattlePet {
  @HiveField(0)
  final Pet pet;
  
  @HiveField(1)
  int currentHealth;
  
  @HiveField(2)
  int currentAttack;
  
  @HiveField(3)
  final int position; // 0-4 position in team
  
  @HiveField(4)
  final List<String> activeEffects;
  
  @HiveField(5)
  bool isAlive;

  BattlePet({
    required this.pet,
    required this.currentHealth,
    required this.currentAttack,
    required this.position,
    required this.activeEffects,
    required this.isAlive,
  });

  BattlePet copyWith({
    Pet? pet,
    int? currentHealth,
    int? currentAttack,
    int? position,
    List<String>? activeEffects,
    bool? isAlive,
  }) {
    return BattlePet(
      pet: pet ?? this.pet,
      currentHealth: currentHealth ?? this.currentHealth,
      currentAttack: currentAttack ?? this.currentAttack,
      position: position ?? this.position,
      activeEffects: activeEffects ?? this.activeEffects,
      isAlive: isAlive ?? this.isAlive,
    );
  }

  factory BattlePet.fromJson(Map<String, dynamic> json) => _$BattlePetFromJson(json);
  Map<String, dynamic> toJson() => _$BattlePetToJson(this);
}

