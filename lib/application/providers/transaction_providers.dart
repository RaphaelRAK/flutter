import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../use_cases/transactions/get_transactions_use_case.dart';
import '../use_cases/transactions/add_transaction_use_case.dart';
import '../use_cases/transactions/update_transaction_use_case.dart';
import '../use_cases/transactions/delete_transaction_use_case.dart';
import '../../domain/models/transaction.dart';
import 'repository_providers.dart';

/// Providers pour les use cases de transactions
final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetTransactionsUseCase(repository);
});

final addTransactionUseCaseProvider = Provider<AddTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return AddTransactionUseCase(repository);
});

final updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return UpdateTransactionUseCase(repository);
});

final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return DeleteTransactionUseCase(repository);
});

/// Provider pour le stream de toutes les transactions
final transactionsStreamProvider = StreamProvider<List<DomainTransaction>>((ref) {
  final useCase = ref.watch(getTransactionsUseCaseProvider);
  return useCase();
});

