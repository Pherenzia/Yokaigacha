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
        _userProgressBox = await Hive.openBox<UserProgress>('user_progress');
        _petsBox = await Hive.openBox<Pet>('pets');
        _battleResultsBox = await Hive.openBox<BattleResult>('battle_results');
        _gachaResultsBox = await Hive.openBox<GachaResult>('gacha_results');
        _achievementsBox = await Hive.openBox<Achievement>('achievements');
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
      if (_userProgressBox.isOpen) {
        await _userProgressBox.put('current_user', progress);
      } else {
        // Fallback to SharedPreferences
        await _prefs.setString('user_progress', progress.toJson().toString());
      }
    } catch (e) {
      print('Failed to save user progress: $e');
    }
  }

  static UserProgress? getUserProgress() {
    try {
      if (_userProgressBox.isOpen) {
        return _userProgressBox.get('current_user');
      } else {
        // Fallback to SharedPreferences
        final jsonString = _prefs.getString('user_progress');
        if (jsonString != null) {
          // For now, return a default progress if we can't parse
          return UserProgress.initial('default_user');
        }
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
      if (_petsBox.isOpen) {
        await _petsBox.put(pet.id, pet);
      }
    } catch (e) {
      print('Failed to save pet: $e');
    }
  }

  static Pet? getPet(String petId) {
    try {
      if (_petsBox.isOpen) {
        return _petsBox.get(petId);
      }
    } catch (e) {
      print('Failed to get pet: $e');
    }
    return null;
  }

  static List<Pet> getAllPets() {
    try {
      if (_petsBox.isOpen) {
        return _petsBox.values.toList();
      }
    } catch (e) {
      print('Failed to get all pets: $e');
    }
    return [];
  }

  static List<Pet> getUnlockedPets() {
    try {
      if (_petsBox.isOpen) {
        return _petsBox.values.where((pet) => pet.isUnlocked).toList();
      }
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
      if (_battleResultsBox.isOpen) {
        await _battleResultsBox.put(result.battleId, result);
      }
    } catch (e) {
      print('Failed to save battle result: $e');
    }
  }

  static List<BattleResult> getBattleHistory() {
    try {
      if (_battleResultsBox.isOpen) {
        return _battleResultsBox.values.toList()
          ..sort((a, b) => b.battleDate.compareTo(a.battleDate));
      }
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
      if (_gachaResultsBox.isOpen) {
        await _gachaResultsBox.put(result.id, result);
      }
    } catch (e) {
      print('Failed to save gacha result: $e');
    }
  }

  static List<GachaResult> getGachaHistory() {
    try {
      if (_gachaResultsBox.isOpen) {
        return _gachaResultsBox.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      print('Failed to get gacha history: $e');
    }
    return [];
  }

  // Achievement Methods
  static Future<void> saveAchievement(Achievement achievement) async {
    try {
      if (_achievementsBox.isOpen) {
        await _achievementsBox.put(achievement.id, achievement);
      }
    } catch (e) {
      print('Failed to save achievement: $e');
    }
  }

  static List<Achievement> getAllAchievements() {
    try {
      if (_achievementsBox.isOpen) {
        return _achievementsBox.values.toList();
      }
    } catch (e) {
      print('Failed to get all achievements: $e');
    }
    return [];
  }

  static List<Achievement> getUnlockedAchievements() {
    try {
      if (_achievementsBox.isOpen) {
        return _achievementsBox.values.where((achievement) => achievement.isUnlocked).toList();
      }
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

