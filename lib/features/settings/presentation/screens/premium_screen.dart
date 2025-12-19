import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/premium_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../infrastructure/db/database_provider.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumStatusAsync = ref.watch(premiumStatusProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        centerTitle: true,
      ),
      body: premiumStatusAsync.when(
        data: (isPremium) => _buildContent(context, ref, isPremium),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, bool isPremium) {
    if (isPremium) {
      return _buildPremiumActiveView(context);
    }
    return _buildPremiumUpgradeView(context, ref);
  }

  Widget _buildPremiumActiveView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          Text(
            'Vous êtes Premium !',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Profitez de toutes les fonctionnalités avancées',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumUpgradeView(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentSecondary, AppColors.accentSecondary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.star,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                Text(
                  'Passez à Premium',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Débloquez toutes les fonctionnalités avancées',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Fonctionnalités Premium
          Text(
            'Fonctionnalités Premium',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          _buildFeatureItem(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Multi-comptes illimités',
            description: 'Gérez autant de comptes que vous le souhaitez',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.notifications,
            title: 'Rappels illimités',
            description: 'Créez autant de rappels personnalisés que nécessaire',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.trending_up,
            title: 'Budgets illimités',
            description: 'Définissez des budgets pour toutes vos catégories',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.savings,
            title: 'Objectifs illimités',
            description: 'Suivez plusieurs objectifs d\'épargne simultanément',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.category,
            title: 'Catégories personnalisées illimitées',
            description: 'Créez autant de catégories que vous le souhaitez',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.repeat,
            title: 'Transactions récurrentes illimitées',
            description: 'Automatisez toutes vos transactions régulières',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.photo_library,
            title: 'Photos illimitées par transaction',
            description: 'Ajoutez plusieurs photos à chaque transaction',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.cloud_upload,
            title: 'Sauvegarde cloud',
            description: 'Sauvegardez vos données de manière sécurisée',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.bar_chart,
            title: 'Statistiques avancées',
            description: 'Analyses détaillées et comparaisons',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.picture_as_pdf,
            title: 'Export PDF et Excel',
            description: 'Exportez vos données dans tous les formats',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.widgets,
            title: 'Widgets',
            description: 'Accédez rapidement à vos finances depuis l\'écran d\'accueil',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.palette,
            title: 'Thèmes personnalisés',
            description: 'Personnalisez l\'apparence de l\'application',
          ),

          const SizedBox(height: 32),

          // Comparaison Gratuit vs Premium
          _buildComparisonTable(context),

          const SizedBox(height: 32),

          // Options d'achat
          Text(
            'Choisissez votre option',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Abonnement mensuel
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Abonnement mensuel',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '2,99€ / mois',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.accentSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _handlePurchase(context, ref, 'monthly'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentSecondary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('S\'abonner'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Abonnement annuel (meilleure valeur)
          Card(
            elevation: 4,
            color: AppColors.accentSecondary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MEILLEURE VALEUR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Abonnement annuel',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '19,99€ / an',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.accentSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '≈ 1,67€ / mois',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _handlePurchase(context, ref, 'yearly'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentSecondary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('S\'abonner'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Achat unique
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achat unique',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '14,99€ (à vie)',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.accentSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _handlePurchase(context, ref, 'lifetime'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentSecondary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Acheter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Les achats sont gérés par votre compte Google Play / App Store. Vous pouvez annuler votre abonnement à tout moment.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accentSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gratuit vs Premium',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildComparisonRow(context, 'Comptes', '1', 'Illimité'),
            _buildComparisonRow(context, 'Rappels', '1', 'Illimité'),
            _buildComparisonRow(context, 'Budgets', '3', 'Illimité'),
            _buildComparisonRow(context, 'Objectifs', '1', 'Illimité'),
            _buildComparisonRow(context, 'Catégories personnalisées', '5', 'Illimité'),
            _buildComparisonRow(context, 'Transactions récurrentes', '3', 'Illimité'),
            _buildComparisonRow(context, 'Photos par transaction', '1', 'Illimité'),
            _buildComparisonRow(context, 'Export', 'CSV uniquement', 'CSV, PDF, Excel'),
            _buildComparisonRow(context, 'Sauvegarde cloud', '❌', '✅'),
            _buildComparisonRow(context, 'Statistiques avancées', '❌', '✅'),
            _buildComparisonRow(context, 'Widgets', '❌', '✅'),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    String feature,
    String free,
    String premium,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              free,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              premium,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.accentSecondary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(BuildContext context, WidgetRef ref, String type) {
    // TODO: Implémenter l'intégration avec in_app_purchase
    // Pour l'instant, on simule l'activation premium
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Achat Premium'),
        content: Text(
          'L\'intégration avec le système de paiement sera bientôt disponible.\n\n'
          'Type d\'achat: ${type == 'monthly' ? 'Mensuel' : type == 'yearly' ? 'Annuel' : 'À vie'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Pour les tests, on active directement le premium
              await PremiumService.activatePremium(ref);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Premium activé avec succès !'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Tester (Activer Premium)'),
          ),
        ],
      ),
    );
  }
}

