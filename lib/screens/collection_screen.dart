import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/user_progress_provider.dart';
import '../core/models/pet.dart';
import '../core/services/storage_service.dart';
import '../widgets/currency_display.dart';

// Helper class to group pets by their unique characteristics
class PetCollectionItem {
  final Pet pet;
  final int quantity;
  final String uniqueKey; // Combination of name + rarity + variant

  PetCollectionItem({
    required this.pet,
    required this.quantity,
    required this.uniqueKey,
  });
}

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<Pet> _userPets = [];
  List<PetCollectionItem> _collectionItems = [];
  List<PetCollectionItem> _filteredItems = [];
  PetRarity? _selectedRarity; // null means "All"
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload pets when returning to this screen (e.g., from gacha)
    _loadUserPets();
  }

  Future<void> _loadUserPets() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final pets = StorageService.getAllPets();
      
      // Group pets by their unique characteristics
      final Map<String, List<Pet>> groupedPets = {};
      
      for (final pet in pets) {
        // Create a unique key based on name, rarity, and variant
        final uniqueKey = '${pet.name}_${pet.rarity.name}_${pet.variantId}';
        
        if (!groupedPets.containsKey(uniqueKey)) {
          groupedPets[uniqueKey] = [];
        }
        groupedPets[uniqueKey]!.add(pet);
      }
      
      // Create collection items with quantities
      final collectionItems = <PetCollectionItem>[];
      groupedPets.forEach((uniqueKey, petList) {
        // Use the first pet as the representative (they should all be the same)
        final representativePet = petList.first;
        collectionItems.add(PetCollectionItem(
          pet: representativePet,
          quantity: petList.length,
          uniqueKey: uniqueKey,
        ));
      });
      
      // Sort by rarity (legendary first) then by name
      collectionItems.sort((a, b) {
        final rarityOrder = {
          PetRarity.legendary: 0,
          PetRarity.epic: 1,
          PetRarity.rare: 2,
          PetRarity.common: 3,
        };
        
        final aRarityOrder = rarityOrder[a.pet.rarity] ?? 4;
        final bRarityOrder = rarityOrder[b.pet.rarity] ?? 4;
        
        if (aRarityOrder != bRarityOrder) {
          return aRarityOrder.compareTo(bRarityOrder);
        }
        
        return a.pet.name.compareTo(b.pet.name);
      });
      
      setState(() {
        _userPets = pets;
        _collectionItems = collectionItems;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedRarity == null) {
      // Show all rarities
      _filteredItems = List.from(_collectionItems);
    } else {
      // Filter by selected rarity
      _filteredItems = _collectionItems
          .where((item) => item.pet.rarity == _selectedRarity)
          .toList();
    }
  }

  void _onRarityFilterChanged(PetRarity? rarity) {
    setState(() {
      _selectedRarity = rarity;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection'),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCollectionContent(),
    );
  }

  Widget _buildCollectionContent() {
    final unlockedItems = _filteredItems.where((item) => item.pet.isUnlocked).length;
    final totalItems = _filteredItems.length;
    final totalPetCount = _userPets.length; // Total individual pets

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCollectionStats(unlockedItems, totalItems, totalPetCount),
          const SizedBox(height: 16),
          _buildRarityFilter(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildPetGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionStats(int unlockedItems, int totalItems, int totalPetCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Unique',
              unlockedItems.toString(),
              Icons.pets,
              AppTheme.primaryColor,
            ),
            _buildStatItem(
              'Total Pets',
              totalPetCount.toString(),
              Icons.collections,
              AppTheme.secondaryColor,
            ),
            _buildStatItem(
              'Completion',
              totalItems > 0 ? '${(unlockedItems / totalItems * 100).round()}%' : '0%',
              Icons.percent,
              AppTheme.successColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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

  Widget _buildPetGrid() {
    if (_filteredItems.isEmpty) {
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // More compact - 3 columns instead of 2
        crossAxisSpacing: 12, // Apple's preferred spacing
        mainAxisSpacing: 12,
        childAspectRatio: 0.65, // Slightly taller for better text readability
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildPetCard(_filteredItems[index]);
      },
    );
  }

  Widget _buildPetCard(PetCollectionItem collectionItem) {
    final pet = collectionItem.pet;
    final quantity = collectionItem.quantity;
    final isUnlocked = pet.isUnlocked;
    final rarityColor = _getRarityColor(pet.rarity);

    return Card(
      elevation: isUnlocked ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUnlocked 
                ? rarityColor.withOpacity(0.5)
                : AppTheme.dividerColor,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
            // Name and Rarity Section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? rarityColor.withOpacity(0.1)
                      : AppTheme.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: isUnlocked
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pet.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: rarityColor,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rarityColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pet.rarity.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Text(
                          '???',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ),
            // Yokai Icon Section - Centered
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? rarityColor.withOpacity(0.05)
                      : AppTheme.backgroundColor,
                ),
                child: isUnlocked
                    ? Center(
                        child: Icon(
                          _getPetIcon(pet.type),
                          size: 40,
                          color: rarityColor,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.lock,
                          size: 24,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
              ),
            ),
            // Stats Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? rarityColor.withOpacity(0.15)
                      : AppTheme.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                ),
                child: isUnlocked
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Attack with Lightning Icon
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flash_on,
                                size: 14,
                                color: AppTheme.accentColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${pet.baseAttack}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
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
                                size: 14,
                                color: AppTheme.successColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${pet.baseHealth}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const Center(
                        child: Text(
                          'Locked',
                          style: TextStyle(
                            color: AppTheme.secondaryTextColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
              ),
            ),
              ],
            ),
            // Quantity Badge - only show if quantity > 1
            if (quantity > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'x$quantity',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
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

