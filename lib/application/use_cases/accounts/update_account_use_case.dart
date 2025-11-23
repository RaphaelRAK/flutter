import '../../../domain/models/account.dart';
import '../../../domain/repositories/account_repository.dart';

/// Use case pour mettre à jour un compte
class UpdateAccountUseCase {
  final AccountRepository _repository;

  UpdateAccountUseCase(this._repository);

  /// Met à jour un compte existant
  Future<bool> call(DomainAccount account) async {
    return await _repository.updateAccount(account);
  }
}

