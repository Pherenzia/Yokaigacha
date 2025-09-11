import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'pet.dart';

part 'game_data.g.dart';

@HiveType(typeId: 5)
@JsonSerializable()
class UserProgress {
  @HiveField(0)
  final String userId;
  
  @HiveField(1)
  final int coins;
  
  @HiveField(2)
  final int gems;
  
  @HiveField(3)
  final int level;
  
  @HiveField(4)
  final int experience;
  
  @HiveField(5)
  final List<String> unlockedPets;
  
  @HiveField(6)
  final List<String> unlockedVariants;
  
  @HiveField(7)
  final int battlesWon;
  
  @HiveField(8)
  final int battlesLost;
  
  @HiveField(9)
  final int currentStreak;
  
  @HiveField(10)
  final int bestStreak;
  
  @HiveField(11)
  final DateTime lastPlayDate;
  
  @HiveField(12)
  final Map<String, int> petUsageStats;
  
  @HiveField(13)
  final List<String> achievements;
  
  @HiveField(14)
  final int currentRound;
  
  @HiveField(15)
  final int spirit;

  const UserProgress({
    required this.userId,
    required this.coins,
    required this.gems,
    required this.level,
    required this.experience,
    required this.unlockedPets,
    required this.unlockedVariants,
    required this.battlesWon,
    required this.battlesLost,
    required this.currentStreak,
    required this.bestStreak,
    required this.lastPlayDate,
    required this.petUsageStats,
    required this.achievements,
    required this.currentRound,
    required this.spirit,
  });

  factory UserProgress.initial(String userId) {
    return UserProgress(
      userId: userId,
      coins: 50000, // Starting coins for testing
      gems: 10, // Starting gems
      level: 1,
      experience: 0,
      unlockedPets: ['cat', 'dog', 'bird'], // Starting pets
      unlockedVariants: [],
      battlesWon: 0,
      battlesLost: 0,
      currentStreak: 0,
      bestStreak: 0,
      lastPlayDate: DateTime.now(),
      petUsageStats: {},
      achievements: [],
      currentRound: 1,
      spirit: 12, // 11 + level (1) = 12 spirit
    );
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) => _$UserProgressFromJson(json);
  Map<String, dynamic> toJson() => _$UserProgressToJson(this);

  UserProgress copyWith({
    String? userId,
    int? coins,
    int? gems,
    int? level,
    int? experience,
    List<String>? unlockedPets,
    List<String>? unlockedVariants,
    int? battlesWon,
    int? battlesLost,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastPlayDate,
    Map<String, int>? petUsageStats,
    List<String>? achievements,
    int? currentRound,
    int? spirit,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      unlockedPets: unlockedPets ?? this.unlockedPets,
      unlockedVariants: unlockedVariants ?? this.unlockedVariants,
      battlesWon: battlesWon ?? this.battlesWon,
      battlesLost: battlesLost ?? this.battlesLost,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastPlayDate: lastPlayDate ?? this.lastPlayDate,
      petUsageStats: petUsageStats ?? this.petUsageStats,
      achievements: achievements ?? this.achievements,
      currentRound: currentRound ?? this.currentRound,
      spirit: spirit ?? this.spirit,
    );
  }
  
  // Calculate total spirit based on level (11 + level)
  int get totalSpirit => 11 + level;
}

@HiveType(typeId: 6)
@JsonSerializable()
class BattleTeam {
  @HiveField(0)
  final List<BattlePet> pets;
  
  @HiveField(1)
  final String teamName;
  
  @HiveField(2)
  final DateTime createdAt;

  const BattleTeam({
    required this.pets,
    required this.teamName,
    required this.createdAt,
  });

  factory BattleTeam.fromJson(Map<String, dynamic> json) => _$BattleTeamFromJson(json);
  Map<String, dynamic> toJson() => _$BattleTeamToJson(this);
}

@HiveType(typeId: 7)
@JsonSerializable()
class BattleResult {
  @HiveField(0)
  final String battleId;
  
  @HiveField(1)
  final bool isVictory;
  
  @HiveField(2)
  final int coinsEarned;
  
  @HiveField(3)
  final int experienceEarned;
  
  @HiveField(4)
  final List<String> petsUsed;
  
  @HiveField(5)
  final DateTime battleDate;
  
  @HiveField(6)
  final int turnsTaken;
  
  @HiveField(7)
  final Map<String, dynamic> battleLog;

  const BattleResult({
    required this.battleId,
    required this.isVictory,
    required this.coinsEarned,
    required this.experienceEarned,
    required this.petsUsed,
    required this.battleDate,
    required this.turnsTaken,
    required this.battleLog,
  });

  factory BattleResult.fromJson(Map<String, dynamic> json) => _$BattleResultFromJson(json);
  Map<String, dynamic> toJson() => _$BattleResultToJson(this);
}

@HiveType(typeId: 8)
@JsonSerializable()
class GachaResult {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final Pet pet;
  
  @HiveField(2)
  final PetRarity rarity;
  
  @HiveField(3)
  final bool isNewVariant;
  
  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final int cost;

  const GachaResult({
    required this.id,
    required this.pet,
    required this.rarity,
    required this.isNewVariant,
    required this.timestamp,
    required this.cost,
  });

  factory GachaResult.fromJson(Map<String, dynamic> json) => _$GachaResultFromJson(json);
  Map<String, dynamic> toJson() => _$GachaResultToJson(this);
}

@HiveType(typeId: 9)
@JsonSerializable()
class Achievement {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String iconPath;
  
  @HiveField(4)
  final int rewardCoins;
  
  @HiveField(5)
  final int rewardGems;
  
  @HiveField(6)
  final Map<String, dynamic> requirements;
  
  @HiveField(7)
  final bool isUnlocked;
  
  @HiveField(8)
  final DateTime? unlockDate;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.rewardCoins,
    required this.rewardGems,
    required this.requirements,
    required this.isUnlocked,
    this.unlockDate,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);
}

