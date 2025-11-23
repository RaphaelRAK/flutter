import '../../../domain/models/transaction.dart';
import '../../../domain/repositories/transaction_repository.dart';

/// Use case pour ajouter une transaction
class AddTransactionUseCase {
  final TransactionRepository _repository;

  AddTransactionUseCase(this._repository);

  /// Ajoute une nouvelle transaction
  Future<int> call(DomainTransaction transaction) async {
    return await _repository.insertTransaction(transaction);
  }
}

