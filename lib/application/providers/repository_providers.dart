import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/db/database_provider.dart';
import '../../infrastructure/db/daos/transactions_dao.dart';
import '../../infrastructure/db/daos/accounts_dao.dart';
import '../../infrastructure/db/daos/categories_dao.dart';
import '../../infrastructure/repositories/transaction_repository_impl.dart';
import '../../infrastructure/repositories/account_repository_impl.dart';
import '../../infrastructure/repositories/category_repository_impl.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/category_repository.dart';

/// Providers pour les repositories
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dao = ref.watch(transactionsDaoProvider);
  return TransactionRepositoryImpl(dao);
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final dao = ref.watch(accountsDaoProvider);
  return AccountRepositoryImpl(dao);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dao = ref.watch(categoriesDaoProvider);
  return CategoryRepositoryImpl(dao);
});

