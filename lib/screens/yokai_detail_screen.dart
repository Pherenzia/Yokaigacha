import 'package:flutter/material.dart';
import '../core/models/pet.dart';
import '../core/theme/app_theme.dart';

class YokaiDetailScreen extends StatelessWidget {
  final Pet yokai;

  const YokaiDetailScreen({
    Key? key,
    required this.yokai,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          yokai.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _getRarityColor(yokai.rarity),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section with Large Image and Basic Info
            _buildHeroSection(),
            const SizedBox(height: 24),
            
            // Stats Section
            _buildStatsSection(),
            const SizedBox(height: 24),
            
            // Description Section
            _buildDescriptionSection(),
            const SizedBox(height: 24),
            
            // Abilities Section
            _buildAbilitiesSection(),
            const SizedBox(height: 24),
            
            // Type and Rarity Info
            _buildTypeRaritySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getRarityColor(yokai.rarity).withOpacity(0.8),
            _getRarityColor(yokai.rarity).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getRarityColor(yokai.rarity).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Icon(
              _getTypeIcon(yokai.type),
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Yokai Name and Star Level
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                yokai.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (yokai.starLevel > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '★${yokai.starLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Rarity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              yokai.rarity.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Attack Stat
          _buildStatRow(
            'Attack',
            yokai.baseAttack,
            yokai.currentAttack,
            Icons.flash_on,
            Colors.red,
          ),
          const SizedBox(height: 12),
          
          // Health Stat
          _buildStatRow(
            'Health',
            yokai.baseHealth,
            yokai.currentHealth,
            Icons.favorite,
            Colors.green,
          ),
          const SizedBox(height: 12),
          
          // Level Info
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Level ${yokai.level}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const Spacer(),
              if (yokai.starLevel > 0)
                Text(
                  'Star Level ${yokai.starLevel}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int baseValue, int currentValue, IconData icon, Color color) {
    final hasBoost = currentValue > baseValue;
    
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              '$currentValue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: hasBoost ? AppTheme.accentColor : AppTheme.primaryTextColor,
              ),
            ),
            if (hasBoost) ...[
              const SizedBox(width: 4),
              Text(
                '(+${currentValue - baseValue})',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            yokai.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.secondaryTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilitiesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Abilities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          
          if (yokai.abilities.isEmpty)
            const Text(
              'No special abilities',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...yokai.abilities.map((ability) => _buildAbilityCard(ability)),
        ],
      ),
    );
  }

  Widget _buildAbilityCard(PetAbility ability) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                ability.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lv.${ability.triggerLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ability.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.secondaryTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trigger: ${ability.triggerCondition.replaceAll('_', ' ').toUpperCase()}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRaritySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Classification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Type
              Expanded(
                child: _buildClassificationCard(
                  'Type',
                  yokai.type.name.toUpperCase(),
                  _getTypeIcon(yokai.type),
                  _getTypeColor(yokai.type),
                ),
              ),
              const SizedBox(width: 12),
              
              // Rarity
              Expanded(
                child: _buildClassificationCard(
                  'Rarity',
                  yokai.rarity.name.toUpperCase(),
                  Icons.star,
                  _getRarityColor(yokai.rarity),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(PetRarity rarity) {
    switch (rarity) {
      case PetRarity.common:
        return Colors.grey;
      case PetRarity.rare:
        return Colors.blue;
      case PetRarity.epic:
        return Colors.purple;
      case PetRarity.legendary:
        return Colors.orange;
    }
  }

  Color _getTypeColor(PetType type) {
    switch (type) {
      case PetType.mythical:
        return Colors.purple;
      case PetType.fish:
        return Colors.blue;
      case PetType.mammal:
        return Colors.brown;
      case PetType.bird:
        return Colors.green;
      case PetType.reptile:
        return Colors.green.shade700;
      case PetType.insect:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(PetType type) {
    switch (type) {
      case PetType.mythical:
        return Icons.auto_awesome;
      case PetType.fish:
        return Icons.water;
      case PetType.mammal:
        return Icons.pets;
      case PetType.bird:
        return Icons.flight;
      case PetType.reptile:
        return Icons.cruelty_free;
      case PetType.insect:
        return Icons.bug_report;
    }
  }
}
