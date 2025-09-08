// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_data.dart';

// Import the enum map from pet.g.dart
const _$PetRarityEnumMap = {
  PetRarity.common: 'common',
  PetRarity.rare: 'rare',
  PetRarity.epic: 'epic',
  PetRarity.legendary: 'legendary',
};

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) => UserProgress(
      userId: json['userId'] as String,
      coins: json['coins'] as int,
      gems: json['gems'] as int,
      level: json['level'] as int,
      experience: json['experience'] as int,
      unlockedPets: (json['unlockedPets'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      unlockedVariants: (json['unlockedVariants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      battlesWon: json['battlesWon'] as int,
      battlesLost: json['battlesLost'] as int,
      currentStreak: json['currentStreak'] as int,
      bestStreak: json['bestStreak'] as int,
      lastPlayDate: DateTime.parse(json['lastPlayDate'] as String),
      petUsageStats: Map<String, int>.from(json['petUsageStats'] as Map),
      achievements: (json['achievements'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UserProgressToJson(UserProgress instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'coins': instance.coins,
      'gems': instance.gems,
      'level': instance.level,
      'experience': instance.experience,
      'unlockedPets': instance.unlockedPets,
      'unlockedVariants': instance.unlockedVariants,
      'battlesWon': instance.battlesWon,
      'battlesLost': instance.battlesLost,
      'currentStreak': instance.currentStreak,
      'bestStreak': instance.bestStreak,
      'lastPlayDate': instance.lastPlayDate.toIso8601String(),
      'petUsageStats': instance.petUsageStats,
      'achievements': instance.achievements,
    };

BattleTeam _$BattleTeamFromJson(Map<String, dynamic> json) => BattleTeam(
      pets: (json['pets'] as List<dynamic>)
          .map((e) => BattlePet.fromJson(e as Map<String, dynamic>))
          .toList(),
      teamName: json['teamName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BattleTeamToJson(BattleTeam instance) =>
    <String, dynamic>{
      'pets': instance.pets,
      'teamName': instance.teamName,
      'createdAt': instance.createdAt.toIso8601String(),
    };

BattleResult _$BattleResultFromJson(Map<String, dynamic> json) => BattleResult(
      battleId: json['battleId'] as String,
      isVictory: json['isVictory'] as bool,
      coinsEarned: json['coinsEarned'] as int,
      experienceEarned: json['experienceEarned'] as int,
      petsUsed: (json['petsUsed'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      battleDate: DateTime.parse(json['battleDate'] as String),
      turnsTaken: json['turnsTaken'] as int,
      battleLog: Map<String, dynamic>.from(json['battleLog'] as Map),
    );

Map<String, dynamic> _$BattleResultToJson(BattleResult instance) =>
    <String, dynamic>{
      'battleId': instance.battleId,
      'isVictory': instance.isVictory,
      'coinsEarned': instance.coinsEarned,
      'experienceEarned': instance.experienceEarned,
      'petsUsed': instance.petsUsed,
      'battleDate': instance.battleDate.toIso8601String(),
      'turnsTaken': instance.turnsTaken,
      'battleLog': instance.battleLog,
    };

GachaResult _$GachaResultFromJson(Map<String, dynamic> json) => GachaResult(
      id: json['id'] as String,
      pet: Pet.fromJson(json['pet'] as Map<String, dynamic>),
      rarity: $enumDecode(_$PetRarityEnumMap, json['rarity']),
      isNewVariant: json['isNewVariant'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      cost: json['cost'] as int,
    );

Map<String, dynamic> _$GachaResultToJson(GachaResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pet': instance.pet,
      'rarity': _$PetRarityEnumMap[instance.rarity]!,
      'isNewVariant': instance.isNewVariant,
      'timestamp': instance.timestamp.toIso8601String(),
      'cost': instance.cost,
    };

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconPath: json['iconPath'] as String,
      rewardCoins: json['rewardCoins'] as int,
      rewardGems: json['rewardGems'] as int,
      requirements: Map<String, dynamic>.from(json['requirements'] as Map),
      isUnlocked: json['isUnlocked'] as bool,
      unlockDate: json['unlockDate'] == null
          ? null
          : DateTime.parse(json['unlockDate'] as String),
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'iconPath': instance.iconPath,
      'rewardCoins': instance.rewardCoins,
      'rewardGems': instance.rewardGems,
      'requirements': instance.requirements,
      'isUnlocked': instance.isUnlocked,
      'unlockDate': instance.unlockDate?.toIso8601String(),
    };

