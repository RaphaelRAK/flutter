import '../models/transaction.dart';

/// Interface du repository pour les transactions
/// Définit les contrats d'accès aux données sans dépendre de l'implémentation
abstract class TransactionRepository {
  /// Récupère toutes les transactions en stream
  Stream<List<DomainTransaction>> watchAllTransactions();

  /// Récupère toutes les transactions
  Future<List<DomainTransaction>> getAllTransactions();

  /// Récupère les transactions dans une plage de dates
  Future<List<DomainTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Récupère les transactions par catégorie
  Future<List<DomainTransaction>> getTransactionsByCategory(int categoryId);

  /// Récupère les transactions par compte
  Future<List<DomainTransaction>> getTransactionsByAccount(int accountId);

  /// Récupère les transactions récentes
  Future<List<DomainTransaction>> getRecentTransactions({int limit = 10});

  /// Récupère une transaction par ID
  Future<DomainTransaction?> getTransactionById(int id);

  /// Insère une nouvelle transaction
  Future<int> insertTransaction(DomainTransaction transaction);

  /// Met à jour une transaction existante
  Future<bool> updateTransaction(DomainTransaction transaction);

  /// Supprime une transaction
  Future<int> deleteTransaction(int id);

  /// Calcule le total des dépenses dans une plage de dates
  Future<double> getTotalExpensesByDateRange(DateTime start, DateTime end);

  /// Calcule le total des revenus dans une plage de dates
  Future<double> getTotalIncomeByDateRange(DateTime start, DateTime end);
}

