import '../../../domain/repositories/account_repository.dart';

/// Use case pour supprimer un compte
class DeleteAccountUseCase {
  final AccountRepository _repository;

  DeleteAccountUseCase(this._repository);

  /// Supprime un compte par son ID
  Future<int> call(int id) async {
    return await _repository.deleteAccount(id);
  }
}

