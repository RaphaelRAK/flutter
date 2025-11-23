import '../../domain/models/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../db/daos/accounts_dao.dart';
import '../db/drift_database.dart';
import '../mappers/account_mapper.dart';
import 'package:drift/drift.dart';

/// Implémentation du repository de comptes utilisant Drift
class AccountRepositoryImpl implements AccountRepository {
  final AccountsDao _dao;

  AccountRepositoryImpl(this._dao);

  @override
  Stream<List<DomainAccount>> watchAllAccounts() {
    return _dao.watchAllAccounts().map(AccountMapper.toDomainList);
  }

  @override
  Future<List<DomainAccount>> getAllAccounts() async {
    final accounts = await _dao.getAllAccounts();
    return AccountMapper.toDomainList(accounts);
  }

  @override
  Stream<List<DomainAccount>> watchAccountsByCategory(String category) {
    return _dao.watchAccountsByCategory(category).map(AccountMapper.toDomainList);
  }

  @override
  Future<List<DomainAccount>> getAccountsByCategory(String category) async {
    final accounts = await _dao.getAccountsByCategory(category);
    return AccountMapper.toDomainList(accounts);
  }

  @override
  Future<DomainAccount?> getAccountById(int id) async {
    final account = await _dao.getAccountById(id);
    return account != null ? AccountMapper.toDomain(account) : null;
  }

  @override
  Future<int> insertAccount(DomainAccount account) async {
    final companion = AccountMapper.toDrift(account);
    final companionWithoutId = AccountsCompanion(
      name: companion.name,
      type: companion.type,
      accountCategory: companion.accountCategory,
      initialBalance: companion.initialBalance,
      icon: companion.icon,
      currency: companion.currency,
      notes: companion.notes,
      order: companion.order,
      excludedFromTotal: companion.excludedFromTotal,
      transferAsExpense: companion.transferAsExpense,
      includeInBudget: companion.includeInBudget,
      archived: companion.archived,
      createdAt: companion.createdAt,
      creditLimit: companion.creditLimit,
      billingDay: companion.billingDay,
      paymentDay: companion.paymentDay,
      billingBalance: companion.billingBalance,
      pendingBalance: companion.pendingBalance,
    );
    return await _dao.insertAccount(companionWithoutId);
  }

  @override
  Future<bool> updateAccount(DomainAccount account) async {
    final companion = AccountMapper.toDrift(account);
    return await _dao.updateAccount(companion);
  }

  @override
  Future<int> deleteAccount(int id) async {
    return await _dao.deleteAccount(id);
  }

  @override
  Future<double> getAccountBalance(int accountId) async {
    return await _dao.getAccountBalance(accountId);
  }

  @override
  Future<double> getTotalAssets() async {
    return await _dao.getTotalAssets();
  }

  @override
  Future<double> getTotalLiabilities() async {
    return await _dao.getTotalLiabilities();
  }

  @override
  Future<double> getNetWorth() async {
    return await _dao.getNetWorth();
  }

  @override
  Future<void> updateAccountOrder(int accountId, int newOrder) async {
    return await _dao.updateAccountOrder(accountId, newOrder);
  }

  @override
  Future<void> reorderAccounts(List<int> accountIds) async {
    return await _dao.reorderAccounts(accountIds);
  }
}

