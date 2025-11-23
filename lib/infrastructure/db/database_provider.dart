import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'drift_database.dart';
import 'daos/accounts_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/transactions_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/custom_currencies_dao.dart';
import 'daos/recurring_rules_dao.dart';
import 'daos/reminders_dao.dart';
import '../../core/utils/helpers/transaction_filters_helper.dart';
import '../../features/settings/presentation/screens/transaction_filters_screen.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final accountsDaoProvider = Provider<AccountsDao>((ref) {
  return AccountsDao(ref.watch(databaseProvider));
});

final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  return CategoriesDao(ref.watch(databaseProvider));
});

final transactionsDaoProvider = Provider<TransactionsDao>((ref) {
  return TransactionsDao(ref.watch(databaseProvider));
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(databaseProvider));
});

final customCurrenciesDaoProvider = Provider<CustomCurrenciesDao>((ref) {
  return CustomCurrenciesDao(ref.watch(databaseProvider));
});

final recurringRulesDaoProvider = Provider<RecurringRulesDao>((ref) {
  return RecurringRulesDao(ref.watch(databaseProvider));
});

final remindersDaoProvider = Provider<RemindersDao>((ref) {
  return RemindersDao(ref.watch(databaseProvider));
});

// Stream providers pour les données réactives
final settingsStreamProvider = StreamProvider((ref) {
  return ref.watch(settingsDaoProvider).watchSettings();
});

final transactionsStreamProvider = StreamProvider((ref) {
  return ref.watch(transactionsDaoProvider).watchAllTransactions();
});

// Provider pour les transactions filtrées
final filteredTransactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final filters = ref.watch(transactionFiltersProvider);
  final transactionsStream = ref.watch(transactionsDaoProvider).watchAllTransactions();
  
  return transactionsStream.map((transactions) {
    return TransactionFiltersHelper.applyFilters(transactions, filters);
  });
});

final accountsStreamProvider = StreamProvider((ref) {
  return ref.watch(accountsDaoProvider).watchAllAccounts();
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoriesDaoProvider).watchAllCategories();
});

// Providers pour les comptes par catégorie
final assetAccountsStreamProvider = StreamProvider((ref) {
  return ref.watch(accountsDaoProvider).watchAccountsByCategory('asset');
});

final liabilityAccountsStreamProvider = StreamProvider((ref) {
  return ref.watch(accountsDaoProvider).watchAccountsByCategory('liability');
});

final customAccountsStreamProvider = StreamProvider((ref) {
  return ref.watch(accountsDaoProvider).watchAccountsByCategory('custom');
});

// Providers pour les totaux
final totalAssetsProvider = FutureProvider<double>((ref) {
  return ref.watch(accountsDaoProvider).getTotalAssets();
});

final totalLiabilitiesProvider = FutureProvider<double>((ref) {
  return ref.watch(accountsDaoProvider).getTotalLiabilities();
});

final netWorthProvider = FutureProvider<double>((ref) {
  return ref.watch(accountsDaoProvider).getNetWorth();
});

// Provider pour les devises personnalisées
final customCurrenciesStreamProvider = StreamProvider((ref) {
  return ref.watch(customCurrenciesDaoProvider).watchAllCustomCurrencies();
});

// Provider pour les règles récurrentes
final recurringRulesStreamProvider = StreamProvider((ref) {
  return ref.watch(recurringRulesDaoProvider).watchAllRecurringRules();
});

// Provider pour les rappels
final remindersStreamProvider = StreamProvider((ref) {
  return ref.watch(remindersDaoProvider).watchAllReminders();
});

