import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'drift_database.dart';
import 'daos/accounts_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/transactions_dao.dart';
import 'daos/settings_dao.dart';

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

// Stream providers pour les données réactives
final settingsStreamProvider = StreamProvider((ref) {
  return ref.watch(settingsDaoProvider).watchSettings();
});

final transactionsStreamProvider = StreamProvider((ref) {
  return ref.watch(transactionsDaoProvider).watchAllTransactions();
});

