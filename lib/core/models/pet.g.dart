// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PetAbility _$PetAbilityFromJson(Map<String, dynamic> json) => PetAbility(
      name: json['name'] as String,
      description: json['description'] as String,
      triggerLevel: json['triggerLevel'] as int,
      triggerCondition: json['triggerCondition'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
    );

Map<String, dynamic> _$PetAbilityToJson(PetAbility instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'triggerLevel': instance.triggerLevel,
      'triggerCondition': instance.triggerCondition,
      'parameters': instance.parameters,
    };

Pet _$PetFromJson(Map<String, dynamic> json) => Pet(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rarity: $enumDecode(_$PetRarityEnumMap, json['rarity']),
      type: $enumDecode(_$PetTypeEnumMap, json['type']),
      baseAttack: json['baseAttack'] as int,
      baseHealth: json['baseHealth'] as int,
      level: json['level'] as int,
      experience: json['experience'] as int,
      abilities: (json['abilities'] as List<dynamic>)
          .map((e) => PetAbility.fromJson(e as Map<String, dynamic>))
          .toList(),
      imagePath: json['imagePath'] as String,
      variantId: json['variantId'] as String,
      isUnlocked: json['isUnlocked'] as bool,
      unlockDate: json['unlockDate'] == null
          ? null
          : DateTime.parse(json['unlockDate'] as String),
    );

Map<String, dynamic> _$PetToJson(Pet instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'rarity': _$PetRarityEnumMap[instance.rarity]!,
      'type': _$PetTypeEnumMap[instance.type]!,
      'baseAttack': instance.baseAttack,
      'baseHealth': instance.baseHealth,
      'level': instance.level,
      'experience': instance.experience,
      'abilities': instance.abilities,
      'imagePath': instance.imagePath,
      'variantId': instance.variantId,
      'isUnlocked': instance.isUnlocked,
      'unlockDate': instance.unlockDate?.toIso8601String(),
    };

const _$PetRarityEnumMap = {
  PetRarity.common: 'common',
  PetRarity.rare: 'rare',
  PetRarity.epic: 'epic',
  PetRarity.legendary: 'legendary',
};

const _$PetTypeEnumMap = {
  PetType.mammal: 'mammal',
  PetType.bird: 'bird',
  PetType.reptile: 'reptile',
  PetType.fish: 'fish',
  PetType.insect: 'insect',
  PetType.mythical: 'mythical',
};

BattlePet _$BattlePetFromJson(Map<String, dynamic> json) => BattlePet(
      pet: Pet.fromJson(json['pet'] as Map<String, dynamic>),
      currentHealth: json['currentHealth'] as int,
      currentAttack: json['currentAttack'] as int,
      position: json['position'] as int,
      activeEffects: (json['activeEffects'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isAlive: json['isAlive'] as bool,
    );

Map<String, dynamic> _$BattlePetToJson(BattlePet instance) => <String, dynamic>{
      'pet': instance.pet,
      'currentHealth': instance.currentHealth,
      'currentAttack': instance.currentAttack,
      'position': instance.position,
      'activeEffects': instance.activeEffects,
      'isAlive': instance.isAlive,
    };

