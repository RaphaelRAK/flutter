import '../../../domain/repositories/transaction_repository.dart';

/// Use case pour supprimer une transaction
class DeleteTransactionUseCase {
  final TransactionRepository _repository;

  DeleteTransactionUseCase(this._repository);

  /// Supprime une transaction par son ID
  Future<int> call(int id) async {
    return await _repository.deleteTransaction(id);
  }
}

