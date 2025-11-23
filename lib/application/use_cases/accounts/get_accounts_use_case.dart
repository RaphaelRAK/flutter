import '../../../domain/models/account.dart';
import '../../../domain/repositories/account_repository.dart';

/// Use case pour récupérer les comptes
class GetAccountsUseCase {
  final AccountRepository _repository;

  GetAccountsUseCase(this._repository);

  /// Récupère tous les comptes en stream
  Stream<List<DomainAccount>> call() {
    return _repository.watchAllAccounts();
  }

  /// Récupère tous les comptes (une fois)
  Future<List<DomainAccount>> getAll() {
    return _repository.getAllAccounts();
  }

  /// Récupère les comptes par catégorie en stream
  Stream<List<DomainAccount>> getByCategory(String category) {
    return _repository.watchAccountsByCategory(category);
  }

  /// Récupère les comptes par catégorie (une fois)
  Future<List<DomainAccount>> getByCategoryOnce(String category) {
    return _repository.getAccountsByCategory(category);
  }

  /// Récupère un compte par ID
  Future<DomainAccount?> getById(int id) {
    return _repository.getAccountById(id);
  }
}

