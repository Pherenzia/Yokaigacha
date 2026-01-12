import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/models/pet.dart';
import '../core/services/storage_service.dart';
import '../core/services/star_service.dart';
import '../core/providers/user_progress_provider.dart';
import '../widgets/currency_display.dart';
import 'battle_game_screen.dart';
import 'yokai_detail_screen.dart';

class TeamBuilderScreen extends StatefulWidget {
  const TeamBuilderScreen({super.key});

  @override
  State<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends State<TeamBuilderScreen> {
  List<Pet> _availablePets = [];
  List<Pet> _filteredPets = [];
  List<Pet> _selectedPets = [];
  bool _isLoading = true;
  PetRarity? _selectedRarity; // null means "All"

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all unlocked pets from collection
      final allPets = StorageService.getAllPets();
      // Filter out removed pets (those with '_removed' in their ID)
      final activePets = allPets.where((pet) => !pet.id.contains('_removed')).toList();
      final unlockedPets = activePets.where((pet) => pet.isUnlocked).toList();
      
      // Store all available pets
      _availablePets = unlockedPets;
      
      // Apply rarity filter
      _applyRarityFilter();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyRarityFilter() {
    List<Pet> petsToFilter;
    
    if (_selectedRarity == null) {
      // Show all rarities
      petsToFilter = List.from(_availablePets);
    } else {
      // Filter by selected rarity
      petsToFilter = _availablePets
          .where((pet) => pet.rarity == _selectedRarity)
          .toList();
    }
    
    // Group pets by unique characteristics (name, rarity, variantId)
    final Map<String, List<Pet>> petGroups = {};
    for (final pet in petsToFilter) {
      final uniqueKey = '${pet.name}_${pet.rarity.name}_${pet.variantId}';
      if (!petGroups.containsKey(uniqueKey)) {
        petGroups[uniqueKey] = [];
      }
      petGroups[uniqueKey]!.add(pet);
    }
    
    // For each group, get the highest star level pet
    final List<Pet> uniquePets = [];
    for (final group in petGroups.values) {
      // Sort by star level (highest first), then by unlock date (newest first)
      group.sort((a, b) {
        if (a.starLevel != b.starLevel) {
          return b.starLevel.compareTo(a.starLevel); // Higher star level first
        }
        if (a.unlockDate != null && b.unlockDate != null) {
          return b.unlockDate!.compareTo(a.unlockDate!); // Newer first
        }
        return 0;
      });
      
      // Take the highest star level pet
      uniquePets.add(group.first);
    }
    
    // Sort the final list: starred pets first, then by rarity, then by name
    uniquePets.sort((a, b) {
      // First, sort by star level (starred pets at top)
      if (a.starLevel != b.starLevel) {
        return b.starLevel.compareTo(a.starLevel);
      }
      
      // Then by rarity (legendary first, then epic, rare, common)
      if (a.rarity != b.rarity) {
        return _getRaritySortOrder(b.rarity).compareTo(_getRaritySortOrder(a.rarity));
      }
      
      // Finally by name
      return a.name.compareTo(b.name);
    });
    
    _filteredPets = uniquePets;
  }
  
  int _getRaritySortOrder(PetRarity rarity) {
    switch (rarity) {
      case PetRarity.legendary:
        return 4;
      case PetRarity.epic:
        return 3;
      case PetRarity.rare:
        return 2;
      case PetRarity.common:
        return 1;
    }
  }

  void _onRarityFilterChanged(PetRarity? rarity) {
    setState(() {
      _selectedRarity = rarity;
      _applyRarityFilter();
    });
  }

  int _getPetSpiritCost(Pet pet) {
    // Spirit costs based on rarity (no tier multiplier for spirit)
    switch (pet.rarity) {
      case PetRarity.common:
        return 2;
      case PetRarity.rare:
        return 3;
      case PetRarity.epic:
        return 4;
      case PetRarity.legendary:
        return 5;
    }
  }
  
  int _getUsedSpirit() {
    int usedSpirit = 0;
    for (Pet pet in _selectedPets) {
      usedSpirit += _getPetSpiritCost(pet);
    }
    return usedSpirit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Builder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Consumer<UserProgressProvider>(
              builder: (context, userProgress, child) {
                final totalSpirit = userProgress.userProgress?.totalSpirit ?? 12;
                final usedSpirit = _getUsedSpirit();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.accentColor),
                    const SizedBox(width: 4),
                    Text(
                      '$usedSpirit/$totalSpirit',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.surfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildTeamHeader(),
                    _buildSelectedPets(),
                    Expanded(
                      child: _buildPetGrid(),
                    ),
                    _buildTeamControls(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTeamHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Build your team using Spirit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Consumer<UserProgressProvider>(
            builder: (context, userProgress, child) {
              final totalSpirit = userProgress.userProgress?.totalSpirit ?? 12;
              final usedSpirit = _getUsedSpirit();
              return Text(
                'Spirit: $usedSpirit/$totalSpirit (Common: 2, Rare: 3, Epic: 4, Legendary: 5)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 16),
          _buildRarityFilter(),
        ],
      ),
    );
  }

  Widget _buildRarityFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Rarity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Common', PetRarity.common),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rare', PetRarity.rare),
                  const SizedBox(width: 8),
                  _buildFilterChip('Epic', PetRarity.epic),
                  const SizedBox(width: 8),
                  _buildFilterChip('Legendary', PetRarity.legendary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, PetRarity? rarity) {
    final isSelected = _selectedRarity == rarity;
    final rarityColor = rarity != null ? _getRarityColor(rarity) : AppTheme.primaryColor;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : rarityColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        _onRarityFilterChanged(selected ? rarity : null);
      },
      backgroundColor: rarityColor.withOpacity(0.1),
      selectedColor: rarityColor,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: rarityColor.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  Widget _buildSelectedPets() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'Selected Team (${_selectedPets.length}/5)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                if (index < _selectedPets.length) {
                  return _buildSelectedPetCard(_selectedPets[index], index);
                } else {
                  return _buildEmptySlot();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPetCard(Pet pet, int index) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getPetIcon(pet.type),
              size: 24,
              color: _getRarityColor(pet.rarity),
            ),
            const SizedBox(height: 4),
            Text(
              pet.name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${pet.currentAttack}/${pet.currentHealth}',
              style: const TextStyle(fontSize: 8),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 10, color: AppTheme.accentColor),
                Text(
                  '${_getPetSpiritCost(pet)}',
                  style: TextStyle(fontSize: 8, color: AppTheme.accentColor),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle, size: 16),
              onPressed: () => _removePet(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.dividerColor,
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetGrid() {
    if (_filteredPets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.secondaryTextColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No pets found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different rarity filter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8, // Adjusted for better layout
      ),
      itemCount: _filteredPets.length,
      itemBuilder: (context, index) {
        return _buildPetCard(_filteredPets[index]);
      },
    );
  }

  Widget _buildPetCard(Pet pet) {
    final spiritCost = _getPetSpiritCost(pet);
    final isSelected = _selectedPets.any((selectedPet) => 
      selectedPet.name == pet.name && 
      selectedPet.rarity == pet.rarity && 
      selectedPet.variantId == pet.variantId &&
      selectedPet.starLevel == pet.starLevel
    );
    final canAfford = _canAffordSpirit(spiritCost);
    final canSelect = _selectedPets.length < 5 && !isSelected;
    final rarityColor = _getRarityColor(pet.rarity);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YokaiDetailScreen(yokai: pet),
          ),
        );
      },
      child: Card(
        elevation: isSelected ? 8 : 2,
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? rarityColor
                : rarityColor.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            // Name and Rarity Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pet.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: rarityColor,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pet.starLevel > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStarColor(pet.starLevel),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              StarService.getStarDisplay(pet.starLevel),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: rarityColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            pet.rarity.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Yokai Icon Section - Centered
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.05),
                ),
                child: Center(
                  child: Icon(
                    _getPetIcon(pet.type),
                    size: 50,
                    color: rarityColor,
                  ),
                ),
              ),
            ),
            // Stats and Action Section
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cost and Action Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 16, color: AppTheme.accentColor),
                            const SizedBox(width: 4),
                            Text(
                              '$spiritCost',
                              style: TextStyle(
                                color: canAfford ? AppTheme.successColor : AppTheme.errorColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          IconButton(
                            icon: const Icon(Icons.remove_circle, size: 28),
                            onPressed: () => _removeSelectedPet(pet),
                            color: AppTheme.errorColor,
                          )
                        else if (canSelect && canAfford)
                          IconButton(
                            icon: const Icon(Icons.add_circle, size: 28),
                            onPressed: () => _selectPet(pet, spiritCost),
                            color: rarityColor,
                          )
                        else
                          Icon(
                            Icons.lock,
                            color: AppTheme.secondaryTextColor,
                            size: 20,
                          ),
                      ],
                    ),
                    // Attack and Health with Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Attack with Lightning Icon
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flash_on,
                              size: 16,
                              color: AppTheme.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${pet.currentAttack}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        // Health with Heart Icon
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 16,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${pet.currentHealth}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTeamControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedPets.isEmpty ? null : _startBattle,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'Start Battle (${_selectedPets.length} pets, ${_getUsedSpirit()} Spirit)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canAffordSpirit(int spiritCost) {
    final userProgress = Provider.of<UserProgressProvider>(context, listen: false);
    final totalSpirit = userProgress.userProgress?.totalSpirit ?? 12;
    final usedSpirit = _getUsedSpirit();
    return (usedSpirit + spiritCost) <= totalSpirit;
  }

  void _selectPet(Pet pet, int spiritCost) {
    if (_selectedPets.length >= 5) return;
    
    if (!_canAffordSpirit(spiritCost)) return;
    
    setState(() {
      // Create a copy of the pet with a unique ID
      final uniquePet = Pet(
        id: '${pet.id}_${DateTime.now().millisecondsSinceEpoch}_${_selectedPets.length}',
        name: pet.name,
        description: pet.description,
        rarity: pet.rarity,
        type: pet.type,
        baseAttack: pet.baseAttack,
        baseHealth: pet.baseHealth,
        level: pet.level,
        experience: pet.experience,
        abilities: pet.abilities,
        imagePath: pet.imagePath,
        variantId: pet.variantId,
        isUnlocked: pet.isUnlocked,
        unlockDate: pet.unlockDate,
        starLevel: pet.starLevel, // Include the star level!
      );
      _selectedPets.add(uniquePet);
    });
    
    // Spirit is not consumed - it's just a limit
  }

  void _removePet(int index) {
    setState(() {
      _selectedPets.removeAt(index);
    });
  }

  void _removeSelectedPet(Pet pet) {
    print('Attempting to remove pet: ${pet.name} (${pet.rarity.name}, Star: ${pet.starLevel})');
    print('Current selected pets count: ${_selectedPets.length}');
    
    setState(() {
      // Find and remove the pet from selected pets by matching the original pet data
      final initialCount = _selectedPets.length;
      _selectedPets.removeWhere((selectedPet) => 
        selectedPet.name == pet.name && 
        selectedPet.rarity == pet.rarity && 
        selectedPet.variantId == pet.variantId &&
        selectedPet.starLevel == pet.starLevel
      );
      
      final removedCount = initialCount - _selectedPets.length;
      print('Removed $removedCount pets from team');
      print('New selected pets count: ${_selectedPets.length}');
    });
  }

  void _startBattle() {
    if (_selectedPets.isEmpty) return;
    
    // Navigate to battle with selected pets
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BattleGameScreen(selectedPets: _selectedPets),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Color _getRarityColor(PetRarity rarity) {
    switch (rarity) {
      case PetRarity.common:
        return AppTheme.petRarityCommon;
      case PetRarity.rare:
        return AppTheme.petRarityRare;
      case PetRarity.epic:
        return AppTheme.petRarityEpic;
      case PetRarity.legendary:
        return AppTheme.petRarityLegendary;
    }
  }

  IconData _getPetIcon(PetType type) {
    switch (type) {
      case PetType.mammal:
        return Icons.pets; // Tanuki, Kitsune, Bakeneko
      case PetType.bird:
        return Icons.flight; // Tengu
      case PetType.reptile:
        return Icons.eco; // Not used in Yokai theme
      case PetType.fish:
        return Icons.water; // Not used in Yokai theme
      case PetType.insect:
        return Icons.bug_report; // Not used in Yokai theme
      case PetType.mythical:
        return Icons.auto_awesome; // All other Yokai
    }
  }

  Color _getStarColor(int starLevel) {
    switch (starLevel) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
