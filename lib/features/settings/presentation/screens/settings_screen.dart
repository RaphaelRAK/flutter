import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
import 'package:drift/drift.dart' show Value;
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../infrastructure/db/drift_database.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/main_bottom_nav_bar.dart';
import '../../../../../core/utils/currencies_list.dart';

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
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 3),
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
    final decimalPlaces = settings.decimalPlaces ?? 2;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.numbers),
        title: const Text('Décimales'),
        subtitle: Text('$decimalPlaces ${decimalPlaces > 1 ? 'décimales' : 'décimale'}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showDecimalPlacesDialog(context, settings),
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
    final settingsAsync = ref.read(settingsStreamProvider);
    
    settingsAsync.when(
      data: (settings) {
        // Couleurs par défaut
        Color incomeColor = AppColors.income;
        Color expenseColor = AppColors.expense;
        
        // Charger les couleurs personnalisées si elles existent
        if (settings.incomeColor != null && settings.incomeColor!.isNotEmpty) {
          try {
            incomeColor = Color(int.parse(settings.incomeColor!.replaceFirst('#', '0xFF')));
          } catch (e) {
            // Si erreur de parsing, utiliser la couleur par défaut
          }
        }
        if (settings.expenseColor != null && settings.expenseColor!.isNotEmpty) {
          try {
            expenseColor = Color(int.parse(settings.expenseColor!.replaceFirst('#', '0xFF')));
          } catch (e) {
            // Si erreur de parsing, utiliser la couleur par défaut
          }
        }
        
        showDialog(
          context: context,
          builder: (dialogContext) => _ColorCustomizationDialog(
            initialIncomeColor: incomeColor,
            initialExpenseColor: expenseColor,
            onSave: (income, expense) async {
              await _updateColors(income, expense);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
          ),
        );
      },
      loading: () {
        // Afficher un indicateur de chargement ou utiliser les couleurs par défaut
        showDialog(
          context: context,
          builder: (dialogContext) => _ColorCustomizationDialog(
            initialIncomeColor: AppColors.income,
            initialExpenseColor: AppColors.expense,
            onSave: (income, expense) async {
              await _updateColors(income, expense);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
          ),
        );
      },
      error: (error, stack) {
        // En cas d'erreur, utiliser les couleurs par défaut
        showDialog(
          context: context,
          builder: (dialogContext) => _ColorCustomizationDialog(
            initialIncomeColor: AppColors.income,
            initialExpenseColor: AppColors.expense,
            onSave: (income, expense) async {
              await _updateColors(income, expense);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
          ),
        );
      },
    );
  }
  
  Future<void> _updateColors(Color incomeColor, Color expenseColor) async {
    try {
      // Convertir les couleurs en format hexadécimal
      final incomeHex = '#${incomeColor.value.toRadixString(16).substring(2).toUpperCase()}';
      final expenseHex = '#${expenseColor.value.toRadixString(16).substring(2).toUpperCase()}';
      
      await ref.read(settingsDaoProvider).updateSettings(
            SettingsCompanion(
              id: const Value(1),
              incomeColor: Value(incomeHex),
              expenseColor: Value(expenseHex),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couleurs mises à jour')),
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
    // Récupérer toutes les devises de la liste complète
    final allCurrencies = CurrenciesList.getAllCurrenciesSorted();
    final availableCurrencies = allCurrencies.map((c) => c['code']!).toList();
    
    showDialog(
      context: context,
      builder: (context) => _CurrencySelectionDialog(
        currencies: availableCurrencies,
        selectedCurrency: settings.currency,
        onCurrencySelected: (currency) {
          _updateCurrency(currency);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSubCurrenciesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SubCurrenciesDialog(),
    );
  }

  void _showDecimalPlacesDialog(BuildContext context, dynamic settings) {
    final currentDecimalPlaces = settings.decimalPlaces ?? 2;
    final options = [0, 1, 2, 3, 4];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre de décimales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((value) {
            return RadioListTile<int>(
              title: Text('$value ${value > 1 ? 'décimales' : 'décimale'}'),
              value: value,
              groupValue: currentDecimalPlaces,
              onChanged: (selectedValue) {
                if (selectedValue != null) {
                  _updateDecimalPlaces(selectedValue);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateDecimalPlaces(int decimalPlaces) async {
    try {
      await ref.read(settingsDaoProvider).updateSettings(
            SettingsCompanion(
              id: const Value(1),
              decimalPlaces: Value(decimalPlaces),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nombre de décimales mis à jour : $decimalPlaces')),
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

// Widget pour la personnalisation des couleurs
class _ColorCustomizationDialog extends StatefulWidget {
  final Color initialIncomeColor;
  final Color initialExpenseColor;
  final Function(Color, Color) onSave;

  const _ColorCustomizationDialog({
    required this.initialIncomeColor,
    required this.initialExpenseColor,
    required this.onSave,
  });

  @override
  State<_ColorCustomizationDialog> createState() => _ColorCustomizationDialogState();
}

class _ColorCustomizationDialogState extends State<_ColorCustomizationDialog> {
  late Color _selectedIncomeColor;
  late Color _selectedExpenseColor;

  @override
  void initState() {
    super.initState();
    _selectedIncomeColor = widget.initialIncomeColor;
    _selectedExpenseColor = widget.initialExpenseColor;
  }

  // Palette de couleurs prédéfinies
  final List<Color> _colorPalette = [
    const Color(0xFF4ADE80), // Vert (défaut revenus)
    const Color(0xFF10B981), // Vert émeraude
    const Color(0xFF22C55E), // Vert clair
    const Color(0xFFEF4444), // Rouge (défaut dépenses)
    const Color(0xFFDC2626), // Rouge foncé
    const Color(0xFFF59E0B), // Orange
    const Color(0xFF3B82F6), // Bleu
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Rose
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF14B8A6), // Turquoise
  ];

  Future<void> _showColorPicker(Color currentColor, bool isIncome) async {
    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isIncome ? 'Couleur des revenus' : 'Couleur des dépenses'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sélectionnez une couleur',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorPalette.map((color) {
                  final isSelected = currentColor.value == color.value;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, color),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.black
                              : Colors.grey.withValues(alpha: 0.3),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (pickedColor != null) {
      setState(() {
        if (isIncome) {
          _selectedIncomeColor = pickedColor;
        } else {
          _selectedExpenseColor = pickedColor;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Couleurs personnalisées'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sélectionnez les couleurs pour les revenus et dépenses'),
            const SizedBox(height: 24),
            // Sélection couleur revenus
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedIncomeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              title: const Text('Revenus'),
              subtitle: const Text('Couleur pour les revenus'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showColorPicker(_selectedIncomeColor, true),
            ),
            const SizedBox(height: 16),
            // Sélection couleur dépenses
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedExpenseColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              title: const Text('Dépenses'),
              subtitle: const Text('Couleur pour les dépenses'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showColorPicker(_selectedExpenseColor, false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            widget.onSave(_selectedIncomeColor, _selectedExpenseColor);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

// Widget pour la sélection de devise principale
class _CurrencySelectionDialog extends StatefulWidget {
  final List<String> currencies;
  final String selectedCurrency;
  final Function(String) onCurrencySelected;

  const _CurrencySelectionDialog({
    required this.currencies,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  State<_CurrencySelectionDialog> createState() => _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<_CurrencySelectionDialog> {
  late List<String> _filteredCurrencies;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.currencies;
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = widget.currencies;
      } else {
        _filteredCurrencies = widget.currencies.where((code) {
          final currency = CurrenciesList.getCurrencyByCode(code);
          return code.toLowerCase().contains(query) ||
              (currency != null && currency['name']!.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Devise principale'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher une devise...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final code = _filteredCurrencies[index];
                  final currency = CurrenciesList.getCurrencyByCode(code);
                  final isSelected = code == widget.selectedCurrency;
                  
                  return RadioListTile<String>(
                    title: Text(code),
                    subtitle: currency != null ? Text(currency['name']!) : null,
                    value: code,
                    groupValue: widget.selectedCurrency,
                    onChanged: (value) {
                      if (value != null) {
                        widget.onCurrencySelected(value);
                      }
                    },
                    selected: isSelected,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

// Widget pour gérer les sous-devises
class _SubCurrenciesDialog extends ConsumerStatefulWidget {
  const _SubCurrenciesDialog();

  @override
  ConsumerState<_SubCurrenciesDialog> createState() => _SubCurrenciesDialogState();
}

class _SubCurrenciesDialogState extends ConsumerState<_SubCurrenciesDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = CurrenciesList.getAllCurrenciesSorted();
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = CurrenciesList.getAllCurrenciesSorted();
      } else {
        _filteredCurrencies = CurrenciesList.searchCurrencies(query);
      }
    });
  }

  Future<void> _addCurrency(String code) async {
    final currency = CurrenciesList.getCurrencyByCode(code);
    if (currency == null) return;

    try {
      await ref.read(customCurrenciesDaoProvider).insertCurrency(
            CustomCurrenciesCompanion(
              code: Value(code),
              name: Value(currency['name']!),
              symbol: Value(currency['symbol']),
            ),
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${currency['name']} ajouté')),
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

  Future<void> _removeCurrency(String code) async {
    try {
      await ref.read(customCurrenciesDaoProvider).deleteCurrencyByCode(code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devise supprimée')),
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

  @override
  Widget build(BuildContext context) {
    final customCurrenciesAsync = ref.watch(customCurrenciesStreamProvider);

    return AlertDialog(
      title: const Text('Sous-devises'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher une devise...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            customCurrenciesAsync.when(
              data: (customCurrencies) {
                final addedCodes = customCurrencies.map((c) => c.code).toList();
                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency = _filteredCurrencies[index];
                      final code = currency['code']!;
                      final isAdded = addedCodes.contains(code);
                      
                      return ListTile(
                        title: Text(code),
                        subtitle: Text(currency['name']!),
                        trailing: isAdded
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeCurrency(code),
                              )
                            : IconButton(
                                icon: const Icon(Icons.add, color: Colors.green),
                                onPressed: () => _addCurrency(code),
                              ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
