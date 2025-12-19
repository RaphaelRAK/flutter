import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../infrastructure/db/database_provider.dart';
import '../../infrastructure/db/drift_database.dart';

/// Service pour gérer les fonctionnalités premium
class PremiumService {
  /// Limites pour la version gratuite
  static const int maxFreeAccounts = 1;
  static const int maxFreeReminders = 1;
  static const int maxFreeBudgets = 3;
  static const int maxFreeGoals = 1;
  static const int maxFreeCustomCategories = 5;
  static const int maxFreeRecurringTransactions = 3;
  static const int maxFreePhotosPerTransaction = 1;

  /// Vérifie si l'utilisateur a la version premium
  static Future<bool> isPremium(WidgetRef ref) async {
    try {
      final settings = await ref.read(settingsDaoProvider).getSettings();
      return settings.isPremium;
    } catch (e) {
      return false;
    }
  }

  /// Stream pour surveiller le statut premium
  static Stream<bool> watchPremiumStatus(WidgetRef ref) {
    return ref.watch(settingsDaoProvider).watchSettings().map((settings) => settings.isPremium);
  }

  /// Vérifie si l'utilisateur peut créer un nouveau compte
  static Future<bool> canCreateAccount(WidgetRef ref) async {
    final isPremiumUser = await isPremium(ref);
    if (isPremiumUser) return true;

    final accounts = await ref.read(accountsDaoProvider).getAllAccounts();
    final activeAccounts = accounts.where((a) => !a.archived).length;
    return activeAccounts < maxFreeAccounts;
  }

  /// Vérifie si l'utilisateur peut créer un nouveau rappel
  static Future<bool> canCreateReminder(WidgetRef ref) async {
    final isPremiumUser = await isPremium(ref);
    if (isPremiumUser) return true;

    final reminders = await ref.read(remindersDaoProvider).getAllReminders();
    return reminders.length < maxFreeReminders;
  }

  /// Vérifie si l'utilisateur peut créer un nouveau budget
  static Future<bool> canCreateBudget(WidgetRef ref) async {
    final isPremiumUser = await isPremium(ref);
    if (isPremiumUser) return true;

    // TODO: Implémenter quand le DAO des budgets sera disponible
    // final budgets = await ref.read(budgetsDaoProvider).getAllBudgets();
    // final activeBudgets = budgets.where((b) => b.isActive).length;
    // return activeBudgets < maxFreeBudgets;
    return true; // Temporaire
  }

  /// Vérifie si l'utilisateur peut créer un nouvel objectif
  static Future<bool> canCreateGoal(WidgetRef ref) async {
    final isPremiumUser = await isPremium(ref);
    if (isPremiumUser) return true;

    // TODO: Implémenter quand le DAO des objectifs sera disponible
    // final goals = await ref.read(goalsDaoProvider).getAllGoals();
    // return goals.length < maxFreeGoals;
    return true; // Temporaire
  }

  /// Vérifie si l'utilisateur peut créer une nouvelle catégorie personnalisée
  static Future<bool> canCreateCustomCategory(WidgetRef ref) async {
    final isPremiumUser = await isPremium(ref);
    if (isPremiumUser) return true;

    final categories = await ref.read(categoriesDaoProvider).getAllCategories();
    final customCategories = categories.where((c) => !c.isDefault).length;
    return customCategories < maxFreeCustomCategories;
  }

  /// Vérifie si l'utilisateur peut créer une nouvelle transaction récurrente
  static Future<bool> canCreateRecurringTransaction(WidgetRef ref) async {
    final isPremiumUser = await isPremium(ref);
    if (isPremiumUser) return true;

    final recurringRules = await ref.read(recurringRulesDaoProvider).getAllRecurringRules();
    final activeRules = recurringRules.where((r) => r.isActive).length;
    return activeRules < maxFreeRecurringTransactions;
  }

  /// Vérifie si l'utilisateur peut ajouter une photo à une transaction
  static Future<bool> canAddPhotoToTransaction(WidgetRef ref, int currentPhotoCount) async {
    final isPremiumUser = await isPremium(ref);
    if (isPremiumUser) return true;

    return currentPhotoCount < maxFreePhotosPerTransaction;
  }

  /// Active le statut premium
  static Future<void> activatePremium(WidgetRef ref) async {
    await ref.read(settingsDaoProvider).updateSettings(
      SettingsCompanion(
        id: const Value(1),
        isPremium: const Value(true),
      ),
    );
  }

  /// Désactive le statut premium
  static Future<void> deactivatePremium(WidgetRef ref) async {
    await ref.read(settingsDaoProvider).updateSettings(
      SettingsCompanion(
        id: const Value(1),
        isPremium: const Value(false),
      ),
    );
  }
}

/// Provider pour le statut premium
final premiumStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(settingsDaoProvider).watchSettings().map((settings) => settings.isPremium);
});

