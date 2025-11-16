import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fonctionnalités'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeatureCard(
            context,
            icon: Icons.bar_chart,
            title: 'Visualisation',
            description:
                'Totaux hebdomadaires/mensuels + budgets. Visualisez vos finances en un coup d\'œil.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.camera_alt,
            title: 'Sauvegarde photo',
            description:
                'Prenez en photo un reçu ou un souvenir pour l\'associer à vos transactions.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.filter_list,
            title: 'Filtrage renforcé',
            description:
                'Filtrez les transactions selon divers critères : compte, catégorie, type, période, etc.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.calendar_month,
            title: 'Calendrier visuel',
            description:
                'Visualisez toutes les transactions mensuelles dans un seul écran avec vue calendrier.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.pie_chart,
            title: 'Graphiques améliorés',
            description:
                'Visualisez vos dépenses via des graphiques bien organisés (camembert, barres, lignes).',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.account_balance,
            title: 'Double-entrée simplifiée',
            description:
                'Gérez vos économies, assurances, prêts, immobilier avec la comptabilité en partie double.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.savings,
            title: 'Budgets avancés',
            description:
                'Définissez un budget mensuel par catégorie et suivez vos dépenses en temps réel.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.trending_up,
            title: 'Graphiques d\'actifs',
            description:
                'Visualisez la tendance de vos actifs au fil du temps avec des graphiques évolutifs.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.credit_card,
            title: 'Gestion carte crédit/débit',
            description:
                'Saisissez la date de règlement, suivez le solde en attente et gérez vos cartes.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.lock,
            title: 'Protection (passcode)',
            description:
                'Sécurisez l\'accès à votre application avec un code PIN ou biométrie.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.swap_horiz,
            title: 'Transferts / virements / récurrences',
            description:
                'Effectuez des transferts entre comptes, automatisez salaire, assurance, dépôt terme, prêt.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.bookmark,
            title: 'Signets',
            description:
                'Enregistrez vos dépenses fréquentes pour les réutiliser rapidement.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.backup,
            title: 'Sauvegarde / restauration',
            description:
                'Exportez vers Excel, sauvegardez sur Google Drive, restaurez vos données facilement.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.currency_exchange,
            title: 'Multi-devises',
            description:
                'Utilisez plusieurs devises, configurez chacune des entrées selon vos besoins.',
          ),
          _buildFeatureCard(
            context,
            icon: Icons.settings,
            title: 'Autres réglages',
            description:
                'Style visuel, période mensuelle/hebdo personnalisée, couleur, langue, sous-devises, etc.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.accentSecondary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

