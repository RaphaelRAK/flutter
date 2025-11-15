import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/preferences_helper.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _selectedCurrency = 'EUR';
  TimeOfDay? _reminderTime;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final settingsDao = ref.read(settingsDaoProvider);
      final reminderTimeString = _reminderTime != null
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
          : null;

      await settingsDao.updateSettings(
        SettingsCompanion(
          currency: Value(_selectedCurrency),
          dailyReminderTime: Value(reminderTimeString),
        ),
      );

      // Marquer le premier lancement comme terminé
      await PreferencesHelper.setFirstLaunchCompleted();

      if (mounted) {
        context.go('/transactions');
      }
    } catch (e) {
      // En cas d'erreur, on crée les settings s'ils n'existent pas
      final settingsDao = ref.read(settingsDaoProvider);
      final reminderTimeString = _reminderTime != null
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
          : null;

      try {
        await settingsDao.getSettings();
        // Si les settings existent, on les met à jour
        await settingsDao.updateSettings(
          SettingsCompanion(
            currency: Value(_selectedCurrency),
            dailyReminderTime: Value(reminderTimeString),
          ),
        );
      } catch (_) {
        // Si les settings n'existent pas, la base de données les créera automatiquement
      }

      // Marquer le premier lancement comme terminé
      await PreferencesHelper.setFirstLaunchCompleted();

      if (mounted) {
        context.go('/transactions');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildPrivacyPage(),
                  _buildConfigurationPage(),
                ],
              ),
            ),
            _buildPageIndicator(),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 32),
          Text(
            'On t\'aide à prendre le contrôle de ton budget.',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Une application simple et sécurisée pour suivre tes dépenses et revenus.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 32),
          Text(
            'Toutes tes données restent sur ton téléphone.',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune synchronisation avec un serveur. Tes informations financières sont privées et sécurisées localement.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.settings,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 32),
          Text(
            'Configuration rapide',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // Sélection de la devise
          DropdownButtonFormField<String>(
            initialValue: _selectedCurrency,
            decoration: const InputDecoration(
              labelText: 'Devise',
              border: OutlineInputBorder(),
            ),
            items: AppConstants.supportedCurrencies
                .map((currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCurrency = value;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          // Sélection de l'heure de rappel
          ListTile(
            title: const Text('Rappel quotidien'),
            subtitle: Text(
              _reminderTime != null
                  ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                  : 'Non configuré (optionnel)',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectReminderTime,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tu peux configurer le rappel plus tard dans les paramètres.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Précédent'),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: () {
              if (_currentPage < 2) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _completeOnboarding();
              }
            },
            child: Text(_currentPage < 2 ? 'Suivant' : 'Commencer'),
          ),
        ],
      ),
    );
  }
}

