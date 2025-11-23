import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../application/providers/transaction_providers.dart';
import '../../../../application/providers/repository_providers.dart';
import '../../domain/use_cases/filter_transactions_use_case.dart';
import '../controllers/transaction_list_controller.dart';

/// Provider pour FilterTransactionsUseCase
final filterTransactionsUseCaseProvider = Provider<FilterTransactionsUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return FilterTransactionsUseCase(repository);
});

/// Provider pour TransactionListController
final transactionListControllerProvider =
    StateNotifierProvider<TransactionListController, TransactionListState>((ref) {
  final getUseCase = ref.watch(getTransactionsUseCaseProvider);
  final filterUseCase = ref.watch(filterTransactionsUseCaseProvider);
  return TransactionListController(getUseCase, filterUseCase);
});

