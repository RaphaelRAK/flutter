import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
import 'package:drift/drift.dart' show Value;
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../infrastructure/db/drift_database.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/preferences_helper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final local_auth.LocalAuthentication _localAuth = local_auth.LocalAuthentication();

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: settingsAsync.when(
        data: (settings) => _buildContent(context, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Apparence
        _buildSectionHeader(context, 'Apparence'),
        _buildThemeSelector(context, settings),
        _buildStartScreenSelector(context, settings),
        _buildColorCustomization(context, settings),
        const SizedBox(height: 24),

        // Général
        _buildSectionHeader(context, 'Général'),
        _buildLanguageSelector(context, settings),
        _buildCurrencySelector(context, settings),
        _buildSubCurrencies(context, settings),
        _buildDecimalPlaces(context, settings),
        const SizedBox(height: 24),

        // Transactions
        _buildSectionHeader(context, 'Transactions'),
        _buildTransactionRecurrence(context, settings),
        _buildTransactionReminders(context, settings),
        _buildTransactionFilters(context, settings),
        const SizedBox(height: 24),

        // Sécurité
        _buildSectionHeader(context, 'Sécurité'),
        _buildPasscodeSettings(context, settings),
        const SizedBox(height: 24),

        // Sauvegarde
        _buildSectionHeader(context, 'Sauvegarde'),
        _buildBackupRestore(context, settings),
        _buildExportData(context, settings),
        const SizedBox(height: 24),

        // Avancé
        _buildSectionHeader(context, 'Avancé'),
        _buildMonthStartDate(context, settings),
        _buildSubCategoryToggle(context, settings),
        _buildPcManager(context, settings),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.palette),
        title: const Text('Thème'),
        subtitle: Text(settings.theme == 'dark' ? 'Sombre' : 'Clair'),
        trailing: Switch(
          value: settings.theme == 'dark',
          onChanged: (value) => _updateTheme(value ? 'dark' : 'light'),
        ),
      ),
    );
  }

  Widget _buildStartScreenSelector(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.home),
        title: const Text('Écran de démarrage'),
        subtitle: const Text('Choisir l\'écran au démarrage'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showStartScreenDialog(context, settings),
      ),
    );
  }

  Widget _buildColorCustomization(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.color_lens),
        title: const Text('Couleurs personnalisées'),
        subtitle: const Text('Revenus / Dépenses'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showColorCustomizationDialog(context),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.language),
        title: const Text('Langue'),
        subtitle: const Text('Français'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLanguageDialog(context),
      ),
    );
  }

  Widget _buildCurrencySelector(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.currency_exchange),
        title: const Text('Devise principale'),
        subtitle: Text(settings.currency),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showCurrencyDialog(context, settings),
      ),
    );
  }

  Widget _buildSubCurrencies(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.attach_money),
        title: const Text('Sous-devises'),
        subtitle: const Text('Ajouter des devises supplémentaires'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showSubCurrenciesDialog(context),
      ),
    );
  }

  Widget _buildDecimalPlaces(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.numbers),
        title: const Text('Décimales'),
        subtitle: const Text('Nombre de décimales à afficher'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showDecimalPlacesDialog(context),
      ),
    );
  }

  Widget _buildTransactionRecurrence(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.repeat),
        title: const Text('Répétition des transactions'),
        subtitle: const Text('Gérer les transactions récurrentes'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/recurring-transactions'),
      ),
    );
  }

  Widget _buildTransactionReminders(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications),
        title: const Text('Rappels (alarme)'),
        subtitle: Text(settings.dailyReminderTime ?? 'Non configuré'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showReminderTimeDialog(context, settings),
      ),
    );
  }

  Widget _buildTransactionFilters(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.filter_list),
        title: const Text('Filtrage et recherche'),
        subtitle: const Text('Options de filtrage des transactions'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/transaction-filters'),
      ),
    );
  }

  Widget _buildPasscodeSettings(BuildContext context, dynamic settings) {
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.lock),
        title: const Text('Verrouillage par code'),
        subtitle: const Text('Protéger l\'application avec un code PIN'),
        value: settings.biometricLockEnabled,
        onChanged: (value) => _toggleBiometricLock(value),
      ),
    );
  }

  Widget _buildBackupRestore(BuildContext context, dynamic settings) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Sauvegarde'),
            subtitle: const Text('Sauvegarder sur Google Drive'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _performBackup(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restauration'),
            subtitle: const Text('Restaurer depuis une sauvegarde'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _performRestore(context),
          ),
        ],
      ),
    );
  }

  Widget _buildExportData(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.file_download),
        title: const Text('Exporter les données'),
        subtitle: const Text('Excel, CSV, TXT'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showExportDialog(context),
      ),
    );
  }

  Widget _buildMonthStartDate(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Date de début du mois'),
        subtitle: const Text('Personnaliser le cycle budgétaire'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showMonthStartDateDialog(context),
      ),
    );
  }

  Widget _buildSubCategoryToggle(BuildContext context, dynamic settings) {
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.category),
        title: const Text('Sous-catégories'),
        subtitle: const Text('Activer/désactiver les sous-catégories'),
        value: true, // TODO: Récupérer depuis settings
        onChanged: (value) {
          // TODO: Sauvegarder dans settings
        },
      ),
    );
  }

  Widget _buildPcManager(BuildContext context, dynamic settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.computer),
        title: const Text('PC Manager'),
        subtitle: const Text('Voir et modifier via WiFi sur PC'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showPcManagerDialog(context),
      ),
    );
  }

  // Dialogues et actions
  void _showStartScreenDialog(BuildContext context, dynamic settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Écran de démarrage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Daily'),
              value: 'daily',
              groupValue: 'daily', // TODO: Récupérer depuis settings
              onChanged: (value) {
                // TODO: Sauvegarder
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Calendar'),
              value: 'calendar',
              groupValue: 'daily',
              onChanged: (value) {
                // TODO: Sauvegarder
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorCustomizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Couleurs personnalisées'),
        content: const Text('Sélectionnez les couleurs pour les revenus et dépenses'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Langue'),
        content: const Text('Sélectionnez votre langue'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, dynamic settings) {
    final currencies = ['EUR', 'USD', 'GBP', 'MGA'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Devise principale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) {
            return RadioListTile<String>(
              title: Text(currency),
              value: currency,
              groupValue: settings.currency,
              onChanged: (value) {
                if (value != null) {
                  _updateCurrency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSubCurrenciesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sous-devises'),
        content: const Text('Ajouter des devises supplémentaires'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showDecimalPlacesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Décimales'),
        content: const Text('Nombre de décimales à afficher'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showReminderTimeDialog(BuildContext context, dynamic settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Heure de rappel'),
        content: const Text('Configurer l\'heure de rappel quotidien'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter les données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel (.xls)'),
              onTap: () {
                Navigator.pop(context);
                _exportData('xls');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('CSV (.csv)'),
              onTap: () {
                Navigator.pop(context);
                _exportData('csv');
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Texte (.txt)'),
              onTap: () {
                Navigator.pop(context);
                _exportData('txt');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthStartDateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Date de début du mois'),
        content: const Text('Choisissez le jour de début de votre cycle budgétaire'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPcManagerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PC Manager'),
        content: const Text(
          'Connectez-vous via WiFi pour accéder à vos données depuis votre PC.\n\n'
          'Cette fonctionnalité nécessite que votre appareil et votre PC soient sur le même réseau WiFi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTheme(String theme) async {
    try {
      await ref.read(settingsDaoProvider).updateSettings(
            SettingsCompanion(
              id: Value(1),
              theme: Value(theme),
            ),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _updateCurrency(String currency) async {
    try {
      await ref.read(settingsDaoProvider).updateSettings(
            SettingsCompanion(
              id: Value(1),
              currency: Value(currency),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devise mise à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _toggleBiometricLock(bool enabled) async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable && enabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biométrie non disponible')),
          );
        }
        return;
      }

      await ref.read(settingsDaoProvider).updateSettings(
            SettingsCompanion(
              id: Value(1),
              biometricLockEnabled: Value(enabled),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(enabled ? 'Verrouillage activé' : 'Verrouillage désactivé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _performBackup(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sauvegarde en cours...')),
    );
    // TODO: Implémenter la sauvegarde Google Drive
  }

  Future<void> _performRestore(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restauration en cours...')),
    );
    // TODO: Implémenter la restauration
  }

  Future<void> _exportData(String format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export $format en cours...')),
    );
    // TODO: Implémenter l'export
  }
}
