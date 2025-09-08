import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/user_progress_provider.dart';

class CurrencyDisplay extends StatelessWidget {
  const CurrencyDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProgressProvider>(
      builder: (context, provider, child) {
        final userProgress = provider.userProgress;
        
        if (userProgress == null) {
          return const SizedBox.shrink();
        }
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrencyItem(
              icon: Icons.monetization_on,
              value: userProgress.coins.toString(),
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: 12),
            _buildCurrencyItem(
              icon: Icons.diamond,
              value: userProgress.gems.toString(),
              color: AppTheme.primaryColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrencyItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

