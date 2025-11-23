import '../../../domain/models/account.dart';
import '../../../domain/repositories/account_repository.dart';

/// Use case pour ajouter un compte
class AddAccountUseCase {
  final AccountRepository _repository;

  AddAccountUseCase(this._repository);

  /// Ajoute un nouveau compte
  Future<int> call(DomainAccount account) async {
    return await _repository.insertAccount(account);
  }
}

