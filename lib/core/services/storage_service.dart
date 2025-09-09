import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_data.dart';
import '../models/pet.dart';

class StorageService {
  static late Box<UserProgress> _userProgressBox;
  static late Box<Pet> _petsBox;
  static late Box<BattleResult> _battleResultsBox;
  static late Box<GachaResult> _gachaResultsBox;
  static late Box<Achievement> _achievementsBox;
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    try {
      // Initialize SharedPreferences first (works on web)
      _prefs = await SharedPreferences.getInstance();
      
      // Try to initialize Hive boxes (may fail on web)
      try {
        // For now, skip Hive adapter registration and use SharedPreferences fallback
        // This ensures the app works while we can focus on the core gameplay
        print('Using SharedPreferences for data storage (Hive adapters not available)');
      } catch (hiveError) {
        print('Hive initialization failed, using SharedPreferences only: $hiveError');
        // Continue with SharedPreferences only
      }
    } catch (e) {
      print('Storage service initialization failed: $e');
      // Continue without storage - the app will still work
    }
  }

  // User Progress Methods
  static Future<void> saveUserProgress(UserProgress progress) async {
    try {
      // Use SharedPreferences for now
      await _prefs.setString('user_progress', progress.toJson().toString());
    } catch (e) {
      print('Failed to save user progress: $e');
    }
  }

  static UserProgress? getUserProgress() {
    try {
      // Use SharedPreferences for now
      final jsonString = _prefs.getString('user_progress');
      if (jsonString != null) {
        return UserProgress.fromJson(jsonDecode(jsonString));
      }
    } catch (e) {
      print('Failed to get user progress: $e');
    }
    return null;
  }

  static Future<UserProgress> getOrCreateUserProgress(String userId) async {
    final existing = getUserProgress();
    if (existing != null) {
      return existing;
    }
    
    final newProgress = UserProgress.initial(userId);
    await saveUserProgress(newProgress);
    return newProgress;
  }

  // Pet Methods
  static Future<void> savePet(Pet pet) async {
    try {
      // Use SharedPreferences for now
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
      // Use SharedPreferences for now
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
      // Use SharedPreferences for now
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
      // Use SharedPreferences for now
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

  // Battle Results Methods
  static Future<void> saveBattleResult(BattleResult result) async {
    try {
      // Use SharedPreferences for now
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
      // Use SharedPreferences for now
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

  // Gacha Results Methods
  static Future<void> saveGachaResult(GachaResult result) async {
    try {
      // Use SharedPreferences for now
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
      // Use SharedPreferences for now
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

  // Achievement Methods
  static Future<void> saveAchievement(Achievement achievement) async {
    try {
      // Use SharedPreferences for now
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
      // Use SharedPreferences for now
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
      // Use SharedPreferences for now
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

  // Settings and Preferences
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

  // Privacy and Data Management
  static Future<void> clearAllData() async {
    await _userProgressBox.clear();
    await _petsBox.clear();
    await _battleResultsBox.clear();
    await _gachaResultsBox.clear();
    await _achievementsBox.clear();
    await _prefs.clear();
  }

  static Future<void> exportUserData() async {
    // This would be used for data portability compliance
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

  // Cleanup
  static Future<void> close() async {
    await _userProgressBox.close();
    await _petsBox.close();
    await _battleResultsBox.close();
    await _gachaResultsBox.close();
    await _achievementsBox.close();
  }
}

