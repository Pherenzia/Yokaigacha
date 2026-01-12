import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_data.dart';
import '../models/pet.dart';
import '../models/cavern_run.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      print('Storage service initialization failed: $e');
    }
  }

  static Future<void> saveUserProgress(UserProgress progress) async {
    try {
      await _prefs.setString('user_progress', jsonEncode(progress.toJson()));
    } catch (e) {
      print('Failed to save user progress: $e');
    }
  }

  static UserProgress? getUserProgress() {
    try {
      final jsonString = _prefs.getString('user_progress');
      if (jsonString != null) {
        return UserProgress.fromJson(jsonDecode(jsonString));
      }
    } catch (e) {
      print('Failed to get user progress: $e');
      _prefs.remove('user_progress');
    }
    return null;
  }

  static Future<void> clearCorruptedData() async {
    try {
      await _prefs.remove('user_progress');
      await _prefs.remove('pets');
      await _prefs.remove('battle_results');
      await _prefs.remove('gacha_results');
      await _prefs.remove('achievements');
      print('Cleared corrupted data');
    } catch (e) {
      print('Failed to clear corrupted data: $e');
    }
  }

  static Future<UserProgress> getOrCreateUserProgress(String userId) async {
    try {
      final existing = getUserProgress();
      if (existing != null) {
        return existing;
      }
    } catch (e) {
      print('Corrupted user progress detected, clearing data: $e');
      await clearCorruptedData();
    }
    
    final newProgress = UserProgress.initial(userId);
    await saveUserProgress(newProgress);
    return newProgress;
  }

  static Future<void> savePet(Pet pet) async {
    try {
      final petsJson = _prefs.getString('pets') ?? '{}';
      final petsMap = Map<String, dynamic>.from(jsonDecode(petsJson));
      petsMap[pet.id] = pet.toJson();
      await _prefs.setString('pets', jsonEncode(petsMap));
    } catch (e) {
      print('Failed to save pet: $e');
    }
  }

  static Pet? getPet(String petId) {
    try {
      final petsJson = _prefs.getString('pets') ?? '{}';
      final petsMap = Map<String, dynamic>.from(jsonDecode(petsJson));
      if (petsMap.containsKey(petId)) {
        return Pet.fromJson(petsMap[petId]);
      }
    } catch (e) {
      print('Failed to get pet: $e');
    }
    return null;
  }

  static List<Pet> getAllPets() {
    try {
      final petsJson = _prefs.getString('pets') ?? '{}';
      final petsMap = Map<String, dynamic>.from(jsonDecode(petsJson));
      return petsMap.values.map((petJson) => Pet.fromJson(petJson)).toList();
    } catch (e) {
      print('Failed to get all pets: $e');
    }
    return [];
  }

  static List<Pet> getUnlockedPets() {
    try {
      final petsJson = _prefs.getString('pets') ?? '{}';
      final petsMap = Map<String, dynamic>.from(jsonDecode(petsJson));
      return petsMap.values
          .map((petJson) => Pet.fromJson(petJson))
          .where((pet) => pet.isUnlocked)
          .toList();
    } catch (e) {
      print('Failed to get unlocked pets: $e');
    }
    return [];
  }

  static Future<void> unlockPet(String petId) async {
    final pet = getPet(petId);
    if (pet != null) {
      final unlockedPet = pet.copyWith(
        isUnlocked: true,
        unlockDate: DateTime.now(),
      );
      await savePet(unlockedPet);
    }
  }

  static Future<void> saveBattleResult(BattleResult result) async {
    try {
      final battleJson = _prefs.getString('battle_results') ?? '{}';
      final battleMap = Map<String, dynamic>.from(jsonDecode(battleJson));
      battleMap[result.battleId] = result.toJson();
      await _prefs.setString('battle_results', jsonEncode(battleMap));
    } catch (e) {
      print('Failed to save battle result: $e');
    }
  }

  static List<BattleResult> getBattleHistory() {
    try {
      final battleJson = _prefs.getString('battle_results') ?? '{}';
      final battleMap = Map<String, dynamic>.from(jsonDecode(battleJson));
      final results = battleMap.values.map((resultJson) => BattleResult.fromJson(resultJson)).toList();
      results.sort((a, b) => b.battleDate.compareTo(a.battleDate));
      return results;
    } catch (e) {
      print('Failed to get battle history: $e');
    }
    return [];
  }

  static List<BattleResult> getRecentBattles(int limit) {
    final allBattles = getBattleHistory();
    return allBattles.take(limit).toList();
  }

  static Future<void> saveGachaResult(GachaResult result) async {
    try {
      final gachaJson = _prefs.getString('gacha_results') ?? '{}';
      final gachaMap = Map<String, dynamic>.from(jsonDecode(gachaJson));
      gachaMap[result.id] = result.toJson();
      await _prefs.setString('gacha_results', jsonEncode(gachaMap));
    } catch (e) {
      print('Failed to save gacha result: $e');
    }
  }

  static List<GachaResult> getGachaHistory() {
    try {
      final gachaJson = _prefs.getString('gacha_results') ?? '{}';
      final gachaMap = Map<String, dynamic>.from(jsonDecode(gachaJson));
      final results = gachaMap.values.map((resultJson) => GachaResult.fromJson(resultJson)).toList();
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return results;
    } catch (e) {
      print('Failed to get gacha history: $e');
    }
    return [];
  }

  static Future<void> saveAchievement(Achievement achievement) async {
    try {
      final achievementsJson = _prefs.getString('achievements') ?? '{}';
      final achievementsMap = Map<String, dynamic>.from(jsonDecode(achievementsJson));
      achievementsMap[achievement.id] = achievement.toJson();
      await _prefs.setString('achievements', jsonEncode(achievementsMap));
    } catch (e) {
      print('Failed to save achievement: $e');
    }
  }

  static List<Achievement> getAllAchievements() {
    try {
      final achievementsJson = _prefs.getString('achievements') ?? '{}';
      final achievementsMap = Map<String, dynamic>.from(jsonDecode(achievementsJson));
      return achievementsMap.values.map((achievementJson) => Achievement.fromJson(achievementJson)).toList();
    } catch (e) {
      print('Failed to get all achievements: $e');
    }
    return [];
  }

  static List<Achievement> getUnlockedAchievements() {
    try {
      final achievementsJson = _prefs.getString('achievements') ?? '{}';
      final achievementsMap = Map<String, dynamic>.from(jsonDecode(achievementsJson));
      return achievementsMap.values
          .map((achievementJson) => Achievement.fromJson(achievementJson))
          .where((achievement) => achievement.isUnlocked)
          .toList();
    } catch (e) {
      print('Failed to get unlocked achievements: $e');
    }
    return [];
  }

  static Future<void> setSetting(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      await _prefs.setString(key, jsonEncode(value));
    }
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    if (T == String) {
      return _prefs.getString(key) as T? ?? defaultValue;
    } else if (T == int) {
      return _prefs.getInt(key) as T? ?? defaultValue;
    } else if (T == double) {
      return _prefs.getDouble(key) as T? ?? defaultValue;
    } else if (T == bool) {
      return _prefs.getBool(key) as T? ?? defaultValue;
    } else if (T == List<String>) {
      return _prefs.getStringList(key) as T? ?? defaultValue;
    } else {
      final stringValue = _prefs.getString(key);
      if (stringValue != null) {
        try {
          return jsonDecode(stringValue) as T;
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }
  }

  static Future<void> clearAllData() async {
    await _prefs.clear();
  }

  static Future<void> exportUserData() async {
    final userData = {
      'userProgress': getUserProgress()?.toJson(),
      'pets': getAllPets().map((pet) => pet.toJson()).toList(),
      'battleResults': getBattleHistory().map((result) => result.toJson()).toList(),
      'gachaResults': getGachaHistory().map((result) => result.toJson()).toList(),
      'achievements': getAllAchievements().map((achievement) => achievement.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
    
    await setSetting('user_data_export', jsonEncode(userData));
  }

  static Map<String, dynamic>? getExportedUserData() {
    final exportData = getSetting<String>('user_data_export');
    if (exportData != null) {
      try {
        return jsonDecode(exportData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> saveCavernRun(CavernRun run) async {
    try {
      final runs = getAllCavernRuns();
      runs.removeWhere((r) => r.id == run.id);
      runs.add(run);
      await _prefs.setString('cavern_runs', jsonEncode(runs.map((r) => r.toJson()).toList()));
    } catch (e) {
      print('Failed to save cavern run: $e');
    }
  }

  static List<CavernRun> getAllCavernRuns() {
    try {
      final jsonString = _prefs.getString('cavern_runs');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => CavernRun.fromJson(json)).toList();
      }
    } catch (e) {
      print('Failed to load cavern runs: $e');
    }
    return [];
  }

  static CavernRun? getCavernRun(String id) {
    try {
      final runs = getAllCavernRuns();
      return runs.where((run) => run.id == id).firstOrNull;
    } catch (e) {
      print('Failed to get cavern run: $e');
    }
    return null;
  }

  static Future<void> saveLockedTeam(LockedTeam team) async {
    try {
      final teams = getAllLockedTeams();
      teams.removeWhere((t) => t.id == team.id);
      teams.add(team);
      await _prefs.setString('locked_teams', jsonEncode(teams.map((t) => t.toJson()).toList()));
    } catch (e) {
      print('Failed to save locked team: $e');
    }
  }

  static List<LockedTeam> getAllLockedTeams() {
    try {
      final jsonString = _prefs.getString('locked_teams');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => LockedTeam.fromJson(json)).toList();
      }
    } catch (e) {
      print('Failed to load locked teams: $e');
    }
    return [];
  }

  static LockedTeam? getLockedTeam(String id) {
    try {
      final teams = getAllLockedTeams();
      return teams.where((team) => team.id == id).firstOrNull;
    } catch (e) {
      print('Failed to get locked team: $e');
    }
    return null;
  }

  static Future<void> close() async {
  }
}

