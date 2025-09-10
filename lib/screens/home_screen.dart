import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/game_provider.dart';
import '../core/providers/user_progress_provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/currency_display.dart';
import '../widgets/main_menu_button.dart';
import 'battle_screen.dart';
import 'battle_game_screen.dart';
import 'shop_screen.dart';
import 'collection_screen.dart';
import 'gacha_screen.dart';
import 'achievements_screen.dart';
import 'privacy_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Initialize game after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  Future<void> _initializeGame() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final userProgressProvider = Provider.of<UserProgressProvider>(context, listen: false);
    
    await Future.wait([
      gameProvider.initializeGame(),
      userProgressProvider.initializeUserProgress(),
    ]);
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Super Auto Pets',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Consumer<UserProgressProvider>(
                    builder: (context, provider, child) {
                      final stats = provider.getProgressStats();
                      return Text(
                        'Level ${stats['level'] ?? 1}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _navigateToScreen(const PrivacyScreen()),
                    tooltip: 'Privacy Settings',
                  ),
                  const CurrencyDisplay(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Consumer<UserProgressProvider>(
      builder: (context, provider, child) {
        final stats = provider.getProgressStats();
        final level = stats['level'] ?? 1;
        final experience = stats['experience'] ?? 0;
        final experienceToNext = level * 100;
        final progress = experience / experienceToNext;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Experience',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '$experience / $experienceToNext',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.dividerColor,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 8,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: _buildMainMenu(),
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 1,
            child: _buildQuickStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu() {
    return Column(
      children: [
        // Main Play Button
        Container(
          width: double.infinity,
          height: 120,
          margin: const EdgeInsets.only(bottom: 24),
          child: ElevatedButton(
            onPressed: () => _startQuickBattle(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: AppTheme.primaryColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'PLAY',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Quick Battle',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Other Menu Options
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              MainMenuButton(
                title: 'Shop',
                subtitle: 'Buy pets for battle',
                icon: Icons.store,
                color: AppTheme.primaryColor,
                onTap: () => _navigateToScreen(const ShopScreen()),
              ),
              MainMenuButton(
                title: 'Collection',
                subtitle: 'View your pets',
                icon: Icons.pets,
                color: AppTheme.secondaryColor,
                onTap: () => _navigateToScreen(const CollectionScreen()),
              ),
              MainMenuButton(
                title: 'Gacha',
                subtitle: 'Get new pets',
                icon: Icons.card_giftcard,
                color: AppTheme.accentColor,
                onTap: () => _navigateToScreen(const GachaScreen()),
              ),
              MainMenuButton(
                title: 'Achievements',
                subtitle: 'Track your progress',
                icon: Icons.emoji_events,
                color: AppTheme.successColor,
                onTap: () => _navigateToScreen(const AchievementsScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Consumer<UserProgressProvider>(
      builder: (context, provider, child) {
        final stats = provider.getProgressStats();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Stats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Battles Won',
                      '${stats['battlesWon'] ?? 0}',
                      Icons.sports_mma,
                    ),
                    _buildStatItem(
                      'Win Rate',
                      '${stats['winRate'] ?? 0}%',
                      Icons.trending_up,
                    ),
                    _buildStatItem(
                      'Pets',
                      '${stats['unlockedPets'] ?? 0}',
                      Icons.pets,
                    ),
                    _buildStatItem(
                      'Streak',
                      '${stats['currentStreak'] ?? 0}',
                      Icons.local_fire_department,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
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

  Future<void> _startQuickBattle() async {
    // Navigate directly to battle with current round difficulty
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const BattleGameScreen(),
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

  void _showBattleResult(dynamic result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isVictory ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              color: result.isVictory ? AppTheme.successColor : AppTheme.errorColor,
            ),
            const SizedBox(width: 8),
            Text(result.isVictory ? 'Victory!' : 'Defeat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Battle completed in ${result.turnsTaken} turns'),
            const SizedBox(height: 8),
            Text('Coins earned: ${result.coinsEarned}'),
            Text('Experience earned: ${result.experienceEarned}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
