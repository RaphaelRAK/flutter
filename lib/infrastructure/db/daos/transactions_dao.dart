import 'package:drift/drift.dart';
import '../drift_database.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(AppDatabase db) : super(db);

  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<Transaction>> getAllTransactions() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getTransactionsByCategory(int categoryId) {
    return (select(transactions)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getTransactionsByAccount(int accountId) {
    return (select(transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getRecentTransactions({int limit = 10}) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
  }

  Future<Transaction?> getTransactionById(int id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertTransaction(TransactionsCompanion transaction) {
    return into(transactions).insert(transaction);
  }

  Future<bool> updateTransaction(TransactionsCompanion transaction) {
    return update(transactions).replace(transaction);
  }

  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  // Calculs agrégés
  Future<double> getTotalExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(transactions.type.equals('expense') &
          transactions.date.isBiggerOrEqualValue(start) &
          transactions.date.isSmallerOrEqualValue(end));

    final result = await query.getSingle();
    return result.read(transactions.amount.sum()) ?? 0.0;
  }

  Future<double> getTotalIncomeByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(transactions.type.equals('income') &
          transactions.date.isBiggerOrEqualValue(start) &
          transactions.date.isSmallerOrEqualValue(end));

    final result = await query.getSingle();
    return result.read(transactions.amount.sum()) ?? 0.0;
  }
}

