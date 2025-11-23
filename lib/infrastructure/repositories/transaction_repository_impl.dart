import '../../domain/models/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../db/daos/transactions_dao.dart';
import '../db/drift_database.dart';
import '../mappers/transaction_mapper.dart';
import 'package:drift/drift.dart';

/// Implémentation du repository de transactions utilisant Drift
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionsDao _dao;

  TransactionRepositoryImpl(this._dao);

  @override
  Stream<List<DomainTransaction>> watchAllTransactions() {
    return _dao.watchAllTransactions().map(TransactionMapper.toDomainList);
  }

  @override
  Future<List<DomainTransaction>> getAllTransactions() async {
    final transactions = await _dao.getAllTransactions();
    return TransactionMapper.toDomainList(transactions);
  }

  @override
  Future<List<DomainTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await _dao.getTransactionsByDateRange(start, end);
    return TransactionMapper.toDomainList(transactions);
  }

  @override
  Future<List<DomainTransaction>> getTransactionsByCategory(
    int categoryId,
  ) async {
    final transactions = await _dao.getTransactionsByCategory(categoryId);
    return TransactionMapper.toDomainList(transactions);
  }

  @override
  Future<List<DomainTransaction>> getTransactionsByAccount(
    int accountId,
  ) async {
    final transactions = await _dao.getTransactionsByAccount(accountId);
    return TransactionMapper.toDomainList(transactions);
  }

  @override
  Future<List<DomainTransaction>> getRecentTransactions({
    int limit = 10,
  }) async {
    final transactions = await _dao.getRecentTransactions(limit: limit);
    return TransactionMapper.toDomainList(transactions);
  }

  @override
  Future<DomainTransaction?> getTransactionById(int id) async {
    final transaction = await _dao.getTransactionById(id);
    return transaction != null ? TransactionMapper.toDomain(transaction) : null;
  }

  @override
  Future<int> insertTransaction(DomainTransaction transaction) async {
    final companion = TransactionMapper.toDrift(transaction);
    // Pour l'insertion, on ne met pas l'id (auto-increment)
    final companionWithoutId = TransactionsCompanion(
      accountId: companion.accountId,
      categoryId: companion.categoryId,
      type: companion.type,
      amount: companion.amount,
      date: companion.date,
      description: companion.description,
      images: companion.images,
      isRecurringInstance: companion.isRecurringInstance,
      recurrenceId: companion.recurrenceId,
      createdAt: companion.createdAt,
      updatedAt: companion.updatedAt,
    );
    return await _dao.insertTransaction(companionWithoutId);
  }

  @override
  Future<bool> updateTransaction(DomainTransaction transaction) async {
    final companion = TransactionMapper.toDrift(transaction);
    return await _dao.updateTransaction(companion);
  }

  @override
  Future<int> deleteTransaction(int id) async {
    return await _dao.deleteTransaction(id);
  }

  @override
  Future<double> getTotalExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _dao.getTotalExpensesByDateRange(start, end);
  }

  @override
  Future<double> getTotalIncomeByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _dao.getTotalIncomeByDateRange(start, end);
  }
}

