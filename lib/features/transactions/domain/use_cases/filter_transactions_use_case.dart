import '../../../../domain/models/transaction.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../../../core/utils/helpers/transaction_filters_helper.dart';
import '../../../../infrastructure/db/drift_database.dart';

/// Use case pour filtrer les transactions
class FilterTransactionsUseCase {
  final TransactionRepository _repository;

  FilterTransactionsUseCase(this._repository);

  /// Applique les filtres à une liste de transactions
  List<DomainTransaction> applyFilters(
    List<DomainTransaction> transactions,
    TransactionFilters? filters,
  ) {
    // Convertir DomainTransaction en Transaction (Drift) pour le helper
    // Note: Le helper utilise encore Transaction (Drift), on devrait le migrer aussi
    final driftTransactions = transactions.map((domain) {
      // Créer un Transaction temporaire pour le filtrage
      // TODO: Migrer TransactionFiltersHelper pour utiliser DomainTransaction
      return Transaction(
        id: domain.id,
        accountId: domain.accountId,
        categoryId: domain.categoryId,
        type: domain.type,
        amount: domain.amount,
        date: domain.date,
        description: domain.description,
        images: domain.images,
        isRecurringInstance: domain.isRecurringInstance,
        recurrenceId: domain.recurrenceId,
        createdAt: domain.createdAt,
        updatedAt: domain.updatedAt,
      );
    }).toList();

    final filtered = TransactionFiltersHelper.applyFilters(driftTransactions, filters);

    // Convertir back en DomainTransaction
    return filtered.map((drift) {
      return DomainTransaction(
        id: drift.id,
        accountId: drift.accountId,
        categoryId: drift.categoryId,
        type: drift.type,
        amount: drift.amount,
        date: drift.date,
        description: drift.description,
        images: drift.images,
        isRecurringInstance: drift.isRecurringInstance,
        recurrenceId: drift.recurrenceId,
        createdAt: drift.createdAt,
        updatedAt: drift.updatedAt,
      );
    }).toList();
  }
}

