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
    
    final updatedProgress = _userProgress!.copyWith(
      coins: _userProgress!.coins + amount,
    );
    
    await updateUserProgress(updatedProgress);
  }

  Future<void> addGems(int amount) async {
    if (_userProgress == null) return;
    
    final updatedProgress = _userProgress!.copyWith(
      gems: _userProgress!.gems + amount,
    );
    
    await updateUserProgress(updatedProgress);
  }

  Future<void> addExperience(int amount) async {
    if (_userProgress == null) return;
    
    int newExperience = _userProgress!.experience + amount;
    int newLevel = _userProgress!.level;
    
    while (newExperience >= newLevel * 100) {
      newExperience -= newLevel * 100;
      newLevel++;
    }
    
    // Calculate new spirit based on new level (11 + level)
    int newSpirit = 11 + newLevel;
    
    final updatedProgress = _userProgress!.copyWith(
      level: newLevel,
      experience: newExperience,
      spirit: newSpirit,
      lastPlayDate: DateTime.now(),
    );
    
    await updateUserProgress(updatedProgress);
  }

  // Battle Management
  Future<BattleResult> startBattle(List<BattlePet> playerTeam) async {
    if (_userProgress == null) {
      throw Exception('User progress not initialized');
    }

    final battleId = _uuid.v4();
    final currentRound = _userProgress!.currentRound;
    final enemyTeam = BattleService.generateEnemyTeam(currentRound);
    final battleResult = BattleService.simulateBattle(
      playerTeam: playerTeam,
      enemyTeam: enemyTeam,
      battleId: battleId,
      currentRound: currentRound,
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
    
    return await startBattle(playerTeam);
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
    int newCurrentRound = _userProgress!.currentRound;
    
    if (result.isVictory) {
      newBattlesWon++;
      newCurrentStreak++;
      newCurrentRound++; // Advance to next round on victory
      if (newCurrentStreak > newBestStreak) {
        newBestStreak = newCurrentStreak;
      }
    } else {
      newBattlesLost++;
      newCurrentStreak = 0;
      // Don't advance round on defeat - player stays on current round
    }
    
    final updatedProgress = _userProgress!.copyWith(
      coins: _userProgress!.coins + result.coinsEarned,
      experience: _userProgress!.experience + result.experienceEarned,
      battlesWon: newBattlesWon,
      battlesLost: newBattlesLost,
      currentStreak: newCurrentStreak,
      bestStreak: newBestStreak,
      currentRound: newCurrentRound,
      lastPlayDate: DateTime.now(),
      petUsageStats: updatedStats,
    );
    
    await updateUserProgress(updatedProgress);
  }

  // Team Management
  void _loadCurrentTeam() {
    _currentTeam = null;
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

