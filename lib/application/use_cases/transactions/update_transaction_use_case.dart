import '../../../domain/models/transaction.dart';
import '../../../domain/repositories/transaction_repository.dart';

/// Use case pour mettre à jour une transaction
class UpdateTransactionUseCase {
  final TransactionRepository _repository;

  UpdateTransactionUseCase(this._repository);

  /// Met à jour une transaction existante
  Future<bool> call(DomainTransaction transaction) async {
    return await _repository.updateTransaction(transaction);
  }
}

