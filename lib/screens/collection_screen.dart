import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/user_progress_provider.dart';
import '../core/models/pet.dart';
import '../core/services/storage_service.dart';
import '../core/services/star_service.dart';
import '../widgets/currency_display.dart';
import 'yokai_detail_screen.dart';

// Helper class to group pets by their unique characteristics
class PetCollectionItem {
  final Pet pet;
  final int quantity;
  final String uniqueKey; // Combination of name + rarity + variant
  final bool canStarUp;
  final int availableCopiesForStarUp;
  final int materialCount; // Number of 0-star pets available as materials

  PetCollectionItem({
    required this.pet,
    required this.quantity,
    required this.uniqueKey,
    required this.canStarUp,
    required this.availableCopiesForStarUp,
    this.materialCount = 0,
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
      final allPets = StorageService.getAllPets();
      
      // Filter out removed pets (those with '_removed' in their ID)
      final pets = allPets.where((pet) => !pet.id.contains('_removed')).toList();
      
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
      
      // Create collection items with quantities and star level info
      final collectionItems = <PetCollectionItem>[];
      groupedPets.forEach((uniqueKey, petList) {
        // Separate starred pets from material pets (0-star pets)
        final starredPets = petList.where((p) => p.starLevel > 0).toList();
        final materialPets = petList.where((p) => p.starLevel == 0).toList();
        
        if (starredPets.isNotEmpty) {
          // Show the highest star pet as the main card
          final highestStarPet = StarService.getHighestStarPet(starredPets) ?? starredPets.first;
          final canStarUp = StarService.canStarUp(highestStarPet);
          final availableCopies = StarService.getAvailableCopiesForStarUp(highestStarPet);
          
          collectionItems.add(PetCollectionItem(
            pet: highestStarPet,
            quantity: starredPets.length,
            uniqueKey: uniqueKey,
            canStarUp: canStarUp,
            availableCopiesForStarUp: availableCopies,
            materialCount: materialPets.length, // Show material count separately
          ));
        } else if (materialPets.isNotEmpty) {
          // Show material pets as a regular card
          final materialPet = materialPets.first;
          final canStarUp = StarService.canStarUp(materialPet);
          final availableCopies = StarService.getAvailableCopiesForStarUp(materialPet);
          
          collectionItems.add(PetCollectionItem(
            pet: materialPet,
            quantity: materialPets.length,
            uniqueKey: uniqueKey,
            canStarUp: canStarUp,
            availableCopiesForStarUp: availableCopies,
            materialCount: materialPets.length, // All 0-star pets are materials
          ));
        }
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
    final canStarUp = collectionItem.canStarUp;
    final availableCopies = collectionItem.availableCopiesForStarUp;
    final isUnlocked = pet.isUnlocked;
    final rarityColor = _getRarityColor(pet.rarity);

    return GestureDetector(
      onTap: isUnlocked ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YokaiDetailScreen(yokai: pet),
          ),
        );
      } : null,
      child: Card(
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
                                '${pet.currentAttack}',
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
                                '${pet.currentHealth}',
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
            // Star Level Badge
            if (pet.starLevel > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStarColor(pet.starLevel),
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
                    StarService.getStarDisplay(pet.starLevel),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
            // Starring Progress Badge - show available copies vs required copies
            if (collectionItem.materialCount > 0)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
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
                    '${collectionItem.materialCount}/${StarService.getCopiesRequiredForNextStar(pet.starLevel)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Star Up Button
            if (isUnlocked && canStarUp)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showStarUpDialog(collectionItem),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
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

  void _showStarUpDialog(PetCollectionItem collectionItem) {
    final pet = collectionItem.pet;
    final requiredCopies = StarService.getCopiesRequiredForNextStar(pet.starLevel);
    final availableCopies = collectionItem.availableCopiesForStarUp;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Star Up ${pet.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Star Level: ${StarService.getStarDisplay(pet.starLevel)}'),
              const SizedBox(height: 8),
              Text('Required Copies: $requiredCopies'),
              Text('Available Copies: $availableCopies'),
              const SizedBox(height: 8),
              Text('New Star Level: ${StarService.getStarDisplay(pet.starLevel + 1)}'),
              const SizedBox(height: 8),
              Text('Stat Bonuses:'),
              Text('• Attack: +3'),
              Text('• Health: +5'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performStarUp(collectionItem);
              },
              child: const Text('Star Up'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performStarUp(PetCollectionItem collectionItem) async {
    try {
      final success = await StarService.starUpPet(collectionItem.pet);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${collectionItem.pet.name} starred up successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reload the collection to show updated star levels
        _loadUserPets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to star up pet. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

