import '../models/account.dart';

/// Interface du repository pour les comptes
abstract class AccountRepository {
  Stream<List<DomainAccount>> watchAllAccounts();
  Future<List<DomainAccount>> getAllAccounts();
  Stream<List<DomainAccount>> watchAccountsByCategory(String category);
  Future<List<DomainAccount>> getAccountsByCategory(String category);
  Future<DomainAccount?> getAccountById(int id);
  Future<int> insertAccount(DomainAccount account);
  Future<bool> updateAccount(DomainAccount account);
  Future<int> deleteAccount(int id);
  Future<double> getAccountBalance(int accountId);
  Future<double> getTotalAssets();
  Future<double> getTotalLiabilities();
  Future<double> getNetWorth();
  Future<void> updateAccountOrder(int accountId, int newOrder);
  Future<void> reorderAccounts(List<int> accountIds);
}

