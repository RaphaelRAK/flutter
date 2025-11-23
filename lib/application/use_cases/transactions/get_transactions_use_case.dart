import '../../../domain/models/transaction.dart';
import '../../../domain/repositories/transaction_repository.dart';

/// Use case pour récupérer toutes les transactions
class GetTransactionsUseCase {
  final TransactionRepository _repository;

  GetTransactionsUseCase(this._repository);

  /// Récupère toutes les transactions en stream
  Stream<List<DomainTransaction>> call() {
    return _repository.watchAllTransactions();
  }

  /// Récupère toutes les transactions (une fois)
  Future<List<DomainTransaction>> getAll() {
    return _repository.getAllTransactions();
  }
}

