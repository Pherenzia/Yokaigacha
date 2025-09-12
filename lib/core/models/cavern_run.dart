import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'pet.dart';

part 'cavern_run.g.dart';

@HiveType(typeId: 10)
enum CavernRunStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  locked,
  @HiveField(2)
  failed,
  @HiveField(3)
  abandoned,
}

@HiveType(typeId: 11)
@JsonSerializable()
class CavernRun {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final DateTime startTime;
  
  @HiveField(3)
  final DateTime? endTime;
  
  @HiveField(4)
  final CavernRunStatus status;
  
  @HiveField(5)
  final int currentFloor;
  
  @HiveField(6)
  final int currentSpirit;
  
  @HiveField(7)
  final int lives;
  
  @HiveField(8)
  final List<Pet> team;
  
  @HiveField(9)
  final List<CavernFloor> completedFloors;
  
  @HiveField(10)
  final int totalSpiritSpent;
  
  @HiveField(11)
  final int highestFloorReached;
  
  @HiveField(12)
  final bool isLocked;
  
  @HiveField(13)
  final DateTime? lockedAt;
  
  @HiveField(14)
  final int lockedFloor;
  
  @HiveField(15)
  final int lockedSpirit;

  const CavernRun({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.currentFloor,
    required this.currentSpirit,
    required this.lives,
    required this.team,
    required this.completedFloors,
    required this.totalSpiritSpent,
    required this.highestFloorReached,
    required this.isLocked,
    this.lockedAt,
    required this.lockedFloor,
    required this.lockedSpirit,
  });

  factory CavernRun.newRun(String userId) {
    final now = DateTime.now();
    return CavernRun(
      id: 'cavern_run_${now.millisecondsSinceEpoch}',
      userId: userId,
      startTime: now,
      status: CavernRunStatus.active,
      currentFloor: 1,
      currentSpirit: 10, // Starting spirit
      lives: 5, // Starting lives
      team: [],
      completedFloors: [],
      totalSpiritSpent: 0,
      highestFloorReached: 1,
      isLocked: false,
      lockedFloor: 0,
      lockedSpirit: 0,
    );
  }

  CavernRun copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    CavernRunStatus? status,
    int? currentFloor,
    int? currentSpirit,
    int? lives,
    List<Pet>? team,
    List<CavernFloor>? completedFloors,
    int? totalSpiritSpent,
    int? highestFloorReached,
    bool? isLocked,
    DateTime? lockedAt,
    int? lockedFloor,
    int? lockedSpirit,
  }) {
    return CavernRun(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      currentFloor: currentFloor ?? this.currentFloor,
      currentSpirit: currentSpirit ?? this.currentSpirit,
      lives: lives ?? this.lives,
      team: team ?? this.team,
      completedFloors: completedFloors ?? this.completedFloors,
      totalSpiritSpent: totalSpiritSpent ?? this.totalSpiritSpent,
      highestFloorReached: highestFloorReached ?? this.highestFloorReached,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: lockedAt ?? this.lockedAt,
      lockedFloor: lockedFloor ?? this.lockedFloor,
      lockedSpirit: lockedSpirit ?? this.lockedSpirit,
    );
  }

  // Computed properties
  bool get canLock => currentFloor % 10 == 0 && lives > 0 && team.length == 5;
  bool get isBossFloor => currentFloor % 10 == 0;
  int get spiritValue => currentSpirit;
  bool get isAlive => lives > 0;
  bool get isComplete => status != CavernRunStatus.active;
  
  // Life recovery every 5 floors
  int get livesToRecover {
    if (lives >= 5) return 0;
    return (currentFloor / 5).floor() - (5 - lives);
  }

  factory CavernRun.fromJson(Map<String, dynamic> json) => _$CavernRunFromJson(json);
  Map<String, dynamic> toJson() => _$CavernRunToJson(this);
}

@HiveType(typeId: 12)
@JsonSerializable()
class CavernFloor {
  @HiveField(0)
  final int floorNumber;
  
  @HiveField(1)
  final int spiritValue;
  
  @HiveField(2)
  final List<Pet> enemyTeam;
  
  @HiveField(3)
  final bool isBossFloor;
  
  @HiveField(4)
  final DateTime completedAt;
  
  @HiveField(5)
  final bool wasVictory;
  
  @HiveField(6)
  final int livesLost;
  
  @HiveField(7)
  final List<Pet> shopYokai; // Yokai available in shop for this floor
  
  @HiveField(8)
  final Pet? selectedYokai; // Yokai selected from shop

  const CavernFloor({
    required this.floorNumber,
    required this.spiritValue,
    required this.enemyTeam,
    required this.isBossFloor,
    required this.completedAt,
    required this.wasVictory,
    required this.livesLost,
    required this.shopYokai,
    this.selectedYokai,
  });

  factory CavernFloor.fromJson(Map<String, dynamic> json) => _$CavernFloorFromJson(json);
  Map<String, dynamic> toJson() => _$CavernFloorToJson(this);
}

@HiveType(typeId: 13)
@JsonSerializable()
class CavernShop {
  @HiveField(0)
  final int floorNumber;
  
  @HiveField(1)
  final List<Pet> availableYokai;
  
  @HiveField(2)
  final DateTime generatedAt;
  
  @HiveField(3)
  final bool isBossReward; // If this shop has guaranteed rare+ yokai

  const CavernShop({
    required this.floorNumber,
    required this.availableYokai,
    required this.generatedAt,
    required this.isBossReward,
  });

  factory CavernShop.fromJson(Map<String, dynamic> json) => _$CavernShopFromJson(json);
  Map<String, dynamic> toJson() => _$CavernShopToJson(this);
}

@HiveType(typeId: 14)
@JsonSerializable()
class LockedTeam {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final List<Pet> team;
  
  @HiveField(3)
  final int spiritValue;
  
  @HiveField(4)
  final int lockedFloor;
  
  @HiveField(5)
  final DateTime lockedAt;
  
  @HiveField(6)
  final int wins;
  
  @HiveField(7)
  final int losses;
  
  @HiveField(8)
  final double winRate;

  const LockedTeam({
    required this.id,
    required this.userId,
    required this.team,
    required this.spiritValue,
    required this.lockedFloor,
    required this.lockedAt,
    required this.wins,
    required this.losses,
    required this.winRate,
  });

  factory LockedTeam.fromCavernRun(CavernRun run) {
    return LockedTeam(
      id: 'locked_${run.id}',
      userId: run.userId,
      team: List.from(run.team),
      spiritValue: run.currentSpirit, // Use current spirit, not locked spirit
      lockedFloor: run.currentFloor, // Use current floor, not locked floor
      lockedAt: DateTime.now(), // Use current time since we're locking now
      wins: 0,
      losses: 0,
      winRate: 0.0,
    );
  }

  LockedTeam copyWith({
    String? id,
    String? userId,
    List<Pet>? team,
    int? spiritValue,
    int? lockedFloor,
    DateTime? lockedAt,
    int? wins,
    int? losses,
    double? winRate,
  }) {
    return LockedTeam(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      team: team ?? this.team,
      spiritValue: spiritValue ?? this.spiritValue,
      lockedFloor: lockedFloor ?? this.lockedFloor,
      lockedAt: lockedAt ?? this.lockedAt,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      winRate: winRate ?? this.winRate,
    );
  }

  factory LockedTeam.fromJson(Map<String, dynamic> json) => _$LockedTeamFromJson(json);
  Map<String, dynamic> toJson() => _$LockedTeamToJson(this);
}
