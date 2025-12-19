import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Widget pour afficher une limitation premium et rediriger vers l'écran premium
class PremiumLimitWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? currentCount;
  final String? maxCount;

  const PremiumLimitWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.star,
    this.currentCount,
    this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.accentSecondary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.accentSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (currentCount != null && maxCount != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$currentCount / $maxCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/premium'),
              icon: const Icon(Icons.star),
              label: const Text('Passer à Premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentSecondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



