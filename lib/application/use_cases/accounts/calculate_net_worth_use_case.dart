import '../../../domain/repositories/account_repository.dart';

/// Use case pour calculer le patrimoine net
class CalculateNetWorthUseCase {
  final AccountRepository _repository;

  CalculateNetWorthUseCase(this._repository);

  /// Calcule le patrimoine net (Assets - Liabilities)
  Future<double> call() async {
    return await _repository.getNetWorth();
  }

  /// Calcule le total des actifs
  Future<double> getTotalAssets() async {
    return await _repository.getTotalAssets();
  }

  /// Calcule le total des passifs
  Future<double> getTotalLiabilities() async {
    return await _repository.getTotalLiabilities();
  }

  /// Calcule le solde d'un compte
  Future<double> getAccountBalance(int accountId) async {
    return await _repository.getAccountBalance(accountId);
  }
}

