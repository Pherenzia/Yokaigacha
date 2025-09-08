import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/game_data.dart';
import '../models/pet.dart';
import '../services/storage_service.dart';
import '../services/battle_service.dart';
import '../data/pet_data.dart';

class GameProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  
  UserProgress? _userProgress;
  BattleTeam? _currentTeam;
  List<BattleResult> _battleHistory = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UserProgress? get userProgress => _userProgress;
  BattleTeam? get currentTeam => _currentTeam;
  List<BattleResult> get battleHistory => _battleHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize the game
  Future<void> initializeGame() async {
    _setLoading(true);
    try {
      _userProgress = await StorageService.getOrCreateUserProgress('default_user');
      _battleHistory = StorageService.getBattleHistory();
      await _initializeStarterPets();
      _loadCurrentTeam();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize game: $e';
      if (kDebugMode) {
        print('Game initialization error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Initialize starter pets
  Future<void> _initializeStarterPets() async {
    final starterPets = PetData.getStarterPets();
    for (final pet in starterPets) {
      await StorageService.savePet(pet);
    }
  }

  // User Progress Management
  Future<void> updateUserProgress(UserProgress progress) async {
    try {
      await StorageService.saveUserProgress(progress);
      _userProgress = progress;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update user progress: $e';
      notifyListeners();
    }
  }

  Future<void> addCoins(int amount) async {
    if (_userProgress == null) return;
    
    final updatedProgress = UserProgress(
      userId: _userProgress!.userId,
      coins: _userProgress!.coins + amount,
      gems: _userProgress!.gems,
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
      achievements: _userProgress!.achievements,
    );
    
    await updateUserProgress(updatedProgress);
  }

  Future<void> addGems(int amount) async {
    if (_userProgress == null) return;
    
    final updatedProgress = UserProgress(
      userId: _userProgress!.userId,
      coins: _userProgress!.coins,
      gems: _userProgress!.gems + amount,
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
      achievements: _userProgress!.achievements,
    );
    
    await updateUserProgress(updatedProgress);
  }

  Future<void> addExperience(int amount) async {
    if (_userProgress == null) return;
    
    int newExperience = _userProgress!.experience + amount;
    int newLevel = _userProgress!.level;
    
    // Check for level up
    while (newExperience >= newLevel * 100) {
      newExperience -= newLevel * 100;
      newLevel++;
    }
    
    final updatedProgress = UserProgress(
      userId: _userProgress!.userId,
      coins: _userProgress!.coins,
      gems: _userProgress!.gems,
      level: newLevel,
      experience: newExperience,
      unlockedPets: _userProgress!.unlockedPets,
      unlockedVariants: _userProgress!.unlockedVariants,
      battlesWon: _userProgress!.battlesWon,
      battlesLost: _userProgress!.battlesLost,
      currentStreak: _userProgress!.currentStreak,
      bestStreak: _userProgress!.bestStreak,
      lastPlayDate: DateTime.now(),
      petUsageStats: _userProgress!.petUsageStats,
      achievements: _userProgress!.achievements,
    );
    
    await updateUserProgress(updatedProgress);
  }

  // Battle Management
  Future<BattleResult> startBattle(List<BattlePet> playerTeam, {int difficulty = 1}) async {
    if (_userProgress == null) {
      throw Exception('User progress not initialized');
    }

    final battleId = _uuid.v4();
    final enemyTeam = BattleService.generateEnemyTeam(difficulty);
    final battleResult = BattleService.simulateBattle(
      playerTeam: playerTeam,
      enemyTeam: enemyTeam,
      battleId: battleId,
    );
    
    // Save battle result
    await StorageService.saveBattleResult(battleResult);
    _battleHistory.insert(0, battleResult);
    
    // Update user progress based on battle result
    await _updateProgressAfterBattle(battleResult);
    
    notifyListeners();
    return battleResult;
  }

  // Quick battle with default team
  Future<BattleResult> quickBattle() async {
    final starterPets = PetData.getStarterPets();
    final playerTeam = starterPets.take(3).map((pet) => BattlePet(
      pet: pet,
      currentHealth: pet.currentHealth,
      currentAttack: pet.currentAttack,
      position: starterPets.indexOf(pet),
      activeEffects: [],
      isAlive: true,
    )).toList();
    
    return await startBattle(playerTeam, difficulty: 1);
  }

  Future<void> _updateProgressAfterBattle(BattleResult result) async {
    if (_userProgress == null) return;
    
    final updatedStats = Map<String, int>.from(_userProgress!.petUsageStats);
    for (final petId in result.petsUsed) {
      updatedStats[petId] = (updatedStats[petId] ?? 0) + 1;
    }
    
    int newBattlesWon = _userProgress!.battlesWon;
    int newBattlesLost = _userProgress!.battlesLost;
    int newCurrentStreak = _userProgress!.currentStreak;
    int newBestStreak = _userProgress!.bestStreak;
    
    if (result.isVictory) {
      newBattlesWon++;
      newCurrentStreak++;
      if (newCurrentStreak > newBestStreak) {
        newBestStreak = newCurrentStreak;
      }
    } else {
      newBattlesLost++;
      newCurrentStreak = 0;
    }
    
    final updatedProgress = UserProgress(
      userId: _userProgress!.userId,
      coins: _userProgress!.coins + result.coinsEarned,
      gems: _userProgress!.gems,
      level: _userProgress!.level,
      experience: _userProgress!.experience + result.experienceEarned,
      unlockedPets: _userProgress!.unlockedPets,
      unlockedVariants: _userProgress!.unlockedVariants,
      battlesWon: newBattlesWon,
      battlesLost: newBattlesLost,
      currentStreak: newCurrentStreak,
      bestStreak: newBestStreak,
      lastPlayDate: DateTime.now(),
      petUsageStats: updatedStats,
      achievements: _userProgress!.achievements,
    );
    
    await updateUserProgress(updatedProgress);
  }

  // Team Management
  void _loadCurrentTeam() {
    // Load the last used team or create a default one
    // This would typically load from storage
    _currentTeam = null; // Placeholder
  }

  void setCurrentTeam(BattleTeam team) {
    _currentTeam = team;
    notifyListeners();
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

  // Data Export for Privacy Compliance
  Future<Map<String, dynamic>?> exportUserData() async {
    try {
      await StorageService.exportUserData();
      return StorageService.getExportedUserData();
    } catch (e) {
      _error = 'Failed to export user data: $e';
      notifyListeners();
      return null;
    }
  }

  // Data Deletion for Privacy Compliance
  Future<void> deleteAllUserData() async {
    try {
      await StorageService.clearAllData();
      _userProgress = null;
      _currentTeam = null;
      _battleHistory.clear();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete user data: $e';
      notifyListeners();
    }
  }
}

