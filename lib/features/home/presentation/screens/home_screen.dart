import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/navigation/main_bottom_nav_bar.dart';
import '../../../../../core/localization/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('app_name')),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Section Hero avec slogan
            _buildHeroSection(context),
            
            // Section Statistiques
            _buildStatsSection(context),
            
            // Section Téléchargement
            _buildDownloadSection(context),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentSecondary.withValues(alpha: 0.1),
            AppColors.accentPrimary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: AppColors.accentSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.translate('easiest_way_manage_finances'),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('manage_finances_simplicity'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('statistics'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.download,
                  label: l10n.translate('downloads'),
                  value: '10K+',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.star,
                  label: l10n.translate('rating'),
                  value: '4.8',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.people,
                  label: l10n.translate('users'),
                  value: '5K+',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.thumb_up,
                  label: l10n.translate('reviews'),
                  value: '500+',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.accentSecondary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            l10n.translate('download_app'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDownloadButton(
                context,
                icon: Icons.android,
                label: l10n.translate('google_play'),
                onPressed: () => _launchUrl('https://play.google.com/store'),
              ),
              const SizedBox(width: 16),
              _buildDownloadButton(
                context,
                icon: Icons.apple,
                label: l10n.translate('app_store'),
                onPressed: () => _launchUrl('https://apps.apple.com'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(l10n.home),
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: Text(l10n.translate('features')),
              onTap: () {
                Navigator.pop(context);
                context.push('/features');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.translate('screenshots')),
              onTap: () {
                Navigator.pop(context);
                context.push('/screenshots');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_center),
              title: Text(l10n.translate('help_center')),
              onTap: () {
                Navigator.pop(context);
                context.push('/help');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

