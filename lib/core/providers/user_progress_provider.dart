import 'package:flutter/foundation.dart';
import '../models/game_data.dart';
import '../services/storage_service.dart';

class UserProgressProvider extends ChangeNotifier {
  UserProgress? _userProgress;
  List<Achievement> _achievements = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UserProgress? get userProgress => _userProgress;
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => _achievements.where((a) => a.isUnlocked).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize user progress
  Future<void> initializeUserProgress() async {
    _setLoading(true);
    try {
      _userProgress = await StorageService.getOrCreateUserProgress('default_user');
      _achievements = StorageService.getAllAchievements();
      
      // Initialize default achievements if none exist
      if (_achievements.isEmpty) {
        await _initializeDefaultAchievements();
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize user progress: $e';
      if (kDebugMode) {
        print('User progress initialization error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Initialize default achievements
  Future<void> _initializeDefaultAchievements() async {
    final defaultAchievements = [
      Achievement(
        id: 'first_battle',
        name: 'First Battle',
        description: 'Win your first battle',
        iconPath: 'assets/icons/achievements/first_battle.png',
        rewardCoins: 50,
        rewardGems: 5,
        requirements: {'battles_won': 1},
        isUnlocked: false,
      ),
      Achievement(
        id: 'battle_veteran',
        name: 'Battle Veteran',
        description: 'Win 10 battles',
        iconPath: 'assets/icons/achievements/battle_veteran.png',
        rewardCoins: 200,
        rewardGems: 10,
        requirements: {'battles_won': 10},
        isUnlocked: false,
      ),
      Achievement(
        id: 'battle_master',
        name: 'Battle Master',
        description: 'Win 50 battles',
        iconPath: 'assets/icons/achievements/battle_master.png',
        rewardCoins: 500,
        rewardGems: 25,
        requirements: {'battles_won': 50},
        isUnlocked: false,
      ),
      Achievement(
        id: 'winning_streak_5',
        name: 'Hot Streak',
        description: 'Win 5 battles in a row',
        iconPath: 'assets/icons/achievements/winning_streak.png',
        rewardCoins: 100,
        rewardGems: 10,
        requirements: {'winning_streak': 5},
        isUnlocked: false,
      ),
      Achievement(
        id: 'winning_streak_10',
        name: 'Unstoppable',
        description: 'Win 10 battles in a row',
        iconPath: 'assets/icons/achievements/unstoppable.png',
        rewardCoins: 300,
        rewardGems: 20,
        requirements: {'winning_streak': 10},
        isUnlocked: false,
      ),
      Achievement(
        id: 'pet_collector',
        name: 'Pet Collector',
        description: 'Unlock 10 different pets',
        iconPath: 'assets/icons/achievements/pet_collector.png',
        rewardCoins: 150,
        rewardGems: 15,
        requirements: {'unlocked_pets': 10},
        isUnlocked: false,
      ),
      Achievement(
        id: 'pet_master',
        name: 'Pet Master',
        description: 'Unlock 25 different pets',
        iconPath: 'assets/icons/achievements/pet_master.png',
        rewardCoins: 400,
        rewardGems: 30,
        requirements: {'unlocked_pets': 25},
        isUnlocked: false,
      ),
      Achievement(
        id: 'gacha_addict',
        name: 'Gacha Addict',
        description: 'Perform 10 gacha pulls',
        iconPath: 'assets/icons/achievements/gacha_addict.png',
        rewardCoins: 100,
        rewardGems: 5,
        requirements: {'gacha_pulls': 10},
        isUnlocked: false,
      ),
      Achievement(
        id: 'lucky_pull',
        name: 'Lucky Pull',
        description: 'Get a legendary pet from gacha',
        iconPath: 'assets/icons/achievements/lucky_pull.png',
        rewardCoins: 200,
        rewardGems: 20,
        requirements: {'legendary_pets': 1},
        isUnlocked: false,
      ),
      Achievement(
        id: 'level_10',
        name: 'Rising Star',
        description: 'Reach level 10',
        iconPath: 'assets/icons/achievements/rising_star.png',
        rewardCoins: 300,
        rewardGems: 25,
        requirements: {'level': 10},
        isUnlocked: false,
      ),
    ];

    for (final achievement in defaultAchievements) {
      await StorageService.saveAchievement(achievement);
    }
    
    _achievements = defaultAchievements;
  }

  // Update user progress
  Future<void> updateUserProgress(UserProgress progress) async {
    try {
      await StorageService.saveUserProgress(progress);
      _userProgress = progress;
      await _checkAchievements();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update user progress: $e';
      notifyListeners();
    }
  }

  // Check and unlock achievements
  Future<void> _checkAchievements() async {
    if (_userProgress == null) return;

    bool hasUpdates = false;
    
    for (final achievement in _achievements) {
      if (achievement.isUnlocked) continue;
      
      if (_isAchievementUnlocked(achievement)) {
        final unlockedAchievement = Achievement(
          id: achievement.id,
          name: achievement.name,
          description: achievement.description,
          iconPath: achievement.iconPath,
          rewardCoins: achievement.rewardCoins,
          rewardGems: achievement.rewardGems,
          requirements: achievement.requirements,
          isUnlocked: true,
          unlockDate: DateTime.now(),
        );
        
        await StorageService.saveAchievement(unlockedAchievement);
        
        // Award rewards
        await _awardAchievementRewards(unlockedAchievement);
        
        hasUpdates = true;
      }
    }
    
    if (hasUpdates) {
      _achievements = StorageService.getAllAchievements();
      notifyListeners();
    }
  }

  // Check if an achievement is unlocked
  bool _isAchievementUnlocked(Achievement achievement) {
    if (_userProgress == null) return false;
    
    for (final requirement in achievement.requirements.entries) {
      final key = requirement.key;
      final requiredValue = requirement.value;
      
      switch (key) {
        case 'battles_won':
          if (_userProgress!.battlesWon < requiredValue) return false;
          break;
        case 'winning_streak':
          if (_userProgress!.bestStreak < requiredValue) return false;
          break;
        case 'unlocked_pets':
          if (_userProgress!.unlockedPets.length < requiredValue) return false;
          break;
        case 'gacha_pulls':
          // This would need to be tracked separately
          break;
        case 'legendary_pets':
          // This would need to be tracked separately
          break;
        case 'level':
          if (_userProgress!.level < requiredValue) return false;
          break;
      }
    }
    
    return true;
  }

  // Award achievement rewards
  Future<void> _awardAchievementRewards(Achievement achievement) async {
    if (_userProgress == null) return;
    
    final updatedProgress = UserProgress(
      userId: _userProgress!.userId,
      coins: _userProgress!.coins + achievement.rewardCoins,
      gems: _userProgress!.gems + achievement.rewardGems,
      level: _userProgress!.level,
      experience: _userProgress!.experience,
      unlockedPets: _userProgress!.unlockedPets,
      unlockedVariants: _userProgress!.unlockedVariants,
      battlesWon: _userProgress!.battlesWon,
      battlesLost: _userProgress!.battlesLost,
      currentStreak: _userProgress!.currentStreak,
      bestStreak: _userProgress!.bestStreak,
      lastPlayDate: _userProgress!.lastPlayDate,
      petUsageStats: _userProgress!.petUsageStats,
      achievements: [..._userProgress!.achievements, achievement.id],
      currentRound: _userProgress!.currentRound,
    );
    
    // Save directly without triggering achievement checks to avoid infinite loop
    await StorageService.saveUserProgress(updatedProgress);
    _userProgress = updatedProgress;
  }

  // Add coins
  Future<void> addCoins(int amount) async {
    if (_userProgress == null) return;
    
    final updatedProgress = _userProgress!.copyWith(
      coins: _userProgress!.coins + amount,
    );
    
    await updateUserProgress(updatedProgress);
  }

  // Add gems
  Future<void> addGems(int amount) async {
    if (_userProgress == null) return;
    
    final updatedProgress = _userProgress!.copyWith(
      gems: _userProgress!.gems + amount,
    );
    
    await updateUserProgress(updatedProgress);
  }

  // Unlock a pet
  Future<void> unlockPet(String petId) async {
    if (_userProgress == null) return;
    
    if (!_userProgress!.unlockedPets.contains(petId)) {
      final updatedPets = [..._userProgress!.unlockedPets, petId];
      
      final updatedProgress = UserProgress(
        userId: _userProgress!.userId,
        coins: _userProgress!.coins,
        gems: _userProgress!.gems,
        level: _userProgress!.level,
        experience: _userProgress!.experience,
        unlockedPets: updatedPets,
        unlockedVariants: _userProgress!.unlockedVariants,
        battlesWon: _userProgress!.battlesWon,
        battlesLost: _userProgress!.battlesLost,
        currentStreak: _userProgress!.currentStreak,
        bestStreak: _userProgress!.bestStreak,
        lastPlayDate: _userProgress!.lastPlayDate,
        petUsageStats: _userProgress!.petUsageStats,
        achievements: _userProgress!.achievements,
        currentRound: _userProgress!.currentRound,
      );
      
      await updateUserProgress(updatedProgress);
    }
  }

  // Utility Methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get progress statistics
  Map<String, dynamic> getProgressStats() {
    if (_userProgress == null) {
      return {};
    }
    
    return {
      'level': _userProgress!.level,
      'experience': _userProgress!.experience,
      'coins': _userProgress!.coins,
      'gems': _userProgress!.gems,
      'battlesWon': _userProgress!.battlesWon,
      'battlesLost': _userProgress!.battlesLost,
      'winRate': _userProgress!.battlesWon + _userProgress!.battlesLost > 0 
          ? (_userProgress!.battlesWon / (_userProgress!.battlesWon + _userProgress!.battlesLost) * 100).round()
          : 0,
      'currentStreak': _userProgress!.currentStreak,
      'bestStreak': _userProgress!.bestStreak,
      'unlockedPets': _userProgress!.unlockedPets.length,
      'unlockedAchievements': unlockedAchievements.length,
      'totalAchievements': _achievements.length,
    };
  }
}

