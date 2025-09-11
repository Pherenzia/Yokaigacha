import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/models/pet.dart';
import '../core/services/storage_service.dart';
import '../core/providers/user_progress_provider.dart';
import '../widgets/currency_display.dart';
import 'battle_game_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Pet> _availablePets = [];
  List<Pet> _selectedPets = [];
  bool _isLoading = true;
  int _shopTier = 1;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all unlocked pets from collection
      final allPets = StorageService.getAllPets();
      final unlockedPets = allPets.where((pet) => pet.isUnlocked).toList();
      
      // Filter pets by shop tier (higher tier = better pets)
      _availablePets = _getPetsForTier(unlockedPets, _shopTier);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Pet> _getPetsForTier(List<Pet> pets, int tier) {
    // Shop tier determines which pets are available
    // Tier 1: Common pets only
    // Tier 2: Common + Rare pets
    // Tier 3: Common + Rare + Epic pets
    // Tier 4: All pets including Legendary
    
    switch (tier) {
      case 1:
        return pets.where((pet) => pet.rarity == PetRarity.common).toList();
      case 2:
        return pets.where((pet) => 
          pet.rarity == PetRarity.common || pet.rarity == PetRarity.rare).toList();
      case 3:
        return pets.where((pet) => 
          pet.rarity == PetRarity.common || 
          pet.rarity == PetRarity.rare || 
          pet.rarity == PetRarity.epic).toList();
      case 4:
        return pets; // All pets
      default:
        return pets.where((pet) => pet.rarity == PetRarity.common).toList();
    }
  }

  int _getPetCost(Pet pet) {
    // Cost based on rarity and tier
    int baseCost = 3; // Base cost for common pets
    
    switch (pet.rarity) {
      case PetRarity.common:
        baseCost = 3;
        break;
      case PetRarity.rare:
        baseCost = 6;
        break;
      case PetRarity.epic:
        baseCost = 9;
        break;
      case PetRarity.legendary:
        baseCost = 12;
        break;
    }
    
    // Add tier multiplier
    return baseCost * _shopTier;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop - Tier $_shopTier'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CurrencyDisplay(),
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
                    _buildShopHeader(),
                    _buildSelectedPets(),
                    Expanded(
                      child: _buildPetGrid(),
                    ),
                    _buildShopControls(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildShopHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Select up to 5 pets for your team',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTierButton(1, 'Tier 1'),
              _buildTierButton(2, 'Tier 2'),
              _buildTierButton(3, 'Tier 3'),
              _buildTierButton(4, 'Tier 4'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierButton(int tier, String label) {
    final isSelected = _shopTier == tier;
    return GestureDetector(
      onTap: () {
        setState(() {
          _shopTier = tier;
        });
        _loadShopData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
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
              '${pet.baseAttack}/${pet.baseHealth}',
              style: const TextStyle(fontSize: 8),
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8, // Adjusted for better layout
      ),
      itemCount: _availablePets.length,
      itemBuilder: (context, index) {
        return _buildPetCard(_availablePets[index]);
      },
    );
  }

  Widget _buildPetCard(Pet pet) {
    final cost = _getPetCost(pet);
    final isSelected = _selectedPets.contains(pet);
    final canAfford = _canAffordPet(cost);
    final canSelect = _selectedPets.length < 5 && !isSelected;
    final rarityColor = _getRarityColor(pet.rarity);

    return Card(
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
                        Text(
                          '$cost coins',
                          style: TextStyle(
                            color: canAfford ? AppTheme.successColor : AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 24)
                        else if (canSelect && canAfford)
                          IconButton(
                            icon: const Icon(Icons.add_circle, size: 28),
                            onPressed: () => _selectPet(pet, cost),
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
                              '${pet.baseAttack}',
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
                              '${pet.baseHealth}',
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
    );
  }

  Widget _buildShopControls() {
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
                'Start Battle (${_selectedPets.length} pets)',
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

  bool _canAffordPet(int cost) {
    final userProgress = Provider.of<UserProgressProvider>(context, listen: false);
    return (userProgress.userProgress?.coins ?? 0) >= cost;
  }

  void _selectPet(Pet pet, int cost) {
    if (_selectedPets.length >= 5) return;
    
    final userProgress = Provider.of<UserProgressProvider>(context, listen: false);
    if ((userProgress.userProgress?.coins ?? 0) < cost) return;
    
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
      );
      _selectedPets.add(uniquePet);
    });
    
    // Deduct coins
    userProgress.addCoins(-cost);
  }

  void _removePet(int index) {
    setState(() {
      _selectedPets.removeAt(index);
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
}

