import 'package:flutter/material.dart';
import '../core/models/cavern_run.dart';
import '../core/models/pet.dart';
import '../core/services/cavern_service.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';

class LockedTeamsScreen extends StatefulWidget {
  const LockedTeamsScreen({super.key});

  @override
  State<LockedTeamsScreen> createState() => _LockedTeamsScreenState();
}

class _LockedTeamsScreenState extends State<LockedTeamsScreen> {
  List<LockedTeam> _lockedTeams = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLockedTeams();
  }

  Future<void> _loadLockedTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProgress = StorageService.getUserProgress();
      if (userProgress == null) {
        setState(() {
          _errorMessage = 'User progress not found';
          _isLoading = false;
        });
        return;
      }

      final allLockedTeams = await CavernService.getLockedTeams();
      _lockedTeams = allLockedTeams
          .where((team) => team.userId == userProgress.userId)
          .toList();

      // Sort by locked date (newest first)
      _lockedTeams.sort((a, b) => b.lockedAt.compareTo(a.lockedAt));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load locked teams: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Locked Teams'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadLockedTeams,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locked Teams'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            onPressed: _loadLockedTeams,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _lockedTeams.isEmpty
          ? _buildEmptyState()
          : _buildTeamsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Locked Teams',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lock teams in The Cavern to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.terrain),
            label: const Text('Go to The Cavern'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsList() {
    return Column(
      children: [
        // Header with stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Teams', '${_lockedTeams.length}'),
              _buildStatItem('Total Wins', '${_lockedTeams.fold(0, (sum, team) => sum + team.wins)}'),
              _buildStatItem('Total Battles', '${_lockedTeams.fold(0, (sum, team) => sum + team.wins + team.losses)}'),
            ],
          ),
        ),
        
        // Teams list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _lockedTeams.length,
            itemBuilder: (context, index) {
              final team = _lockedTeams[index];
              return _buildTeamCard(team);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTeamCard(LockedTeam team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with team info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Floor ${team.lockedFloor} Team',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Spirit Value: ${team.spiritValue}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${team.wins}W - ${team.losses}L',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: team.winRate >= 0.5 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '${(team.winRate * 100).toStringAsFixed(1)}% WR',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: team.winRate >= 0.5 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Team yokai display
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: team.team.length,
                itemBuilder: (context, index) {
                  final yokai = team.team[index];
                  return _buildYokaiCard(yokai);
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Lock date and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Locked: ${_formatDate(team.lockedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    if (team.wins + team.losses > 0)
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: team.winRate >= 0.5 ? Colors.green : Colors.red,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      'Competitive',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYokaiCard(Pet yokai) {
    final rarityColor = _getRarityColor(yokai.rarity);
    
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getPetIcon(yokai.type),
              size: 24,
              color: rarityColor,
            ),
            const SizedBox(height: 4),
            Text(
              yokai.name,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (yokai.starLevel > 0)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: _getStarColor(yokai.starLevel),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '★${yokai.starLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '${yokai.currentAttack}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${yokai.currentHealth}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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

  IconData _getPetIcon(PetType type) {
    switch (type) {
      case PetType.mammal:
        return Icons.pets;
      case PetType.bird:
        return Icons.flight;
      case PetType.reptile:
        return Icons.cruelty_free;
      case PetType.fish:
        return Icons.water;
      case PetType.insect:
        return Icons.bug_report;
      case PetType.mythical:
        return Icons.auto_awesome;
    }
  }

  Color _getStarColor(int starLevel) {
    switch (starLevel) {
      case 1:
        return const Color(0xFF4CAF50); // Green
      case 2:
        return const Color(0xFF2196F3); // Blue
      case 3:
        return const Color(0xFF9C27B0); // Purple
      case 4:
        return const Color(0xFFFF9800); // Orange
      case 5:
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}
