import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/user_progress_provider.dart';
import '../core/models/pet.dart';
import '../core/services/storage_service.dart';
import '../widgets/currency_display.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<Pet> _userPets = [];
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
      setState(() {
        _userPets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
    final unlockedPets = _userPets.where((pet) => pet.isUnlocked).length;
    final totalPets = _userPets.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCollectionStats(unlockedPets, totalPets),
          const SizedBox(height: 16),
          Expanded(
            child: _buildPetGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionStats(int unlockedPets, int totalPets) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Unlocked',
              unlockedPets.toString(),
              Icons.pets,
              AppTheme.primaryColor,
            ),
            _buildStatItem(
              'Total',
              totalPets.toString(),
              Icons.collections,
              AppTheme.secondaryColor,
            ),
            _buildStatItem(
              'Completion',
              totalPets > 0 ? '${(unlockedPets / totalPets * 100).round()}%' : '0%',
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

  Widget _buildPetGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // More compact - 3 columns instead of 2
        crossAxisSpacing: 12, // Apple's preferred spacing
        mainAxisSpacing: 12,
        childAspectRatio: 0.65, // Slightly taller for better text readability
      ),
      itemCount: _userPets.length,
      itemBuilder: (context, index) {
        return _buildPetCard(_userPets[index]);
      },
    );
  }

  Widget _buildPetCard(Pet pet) {
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
        child: Column(
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

