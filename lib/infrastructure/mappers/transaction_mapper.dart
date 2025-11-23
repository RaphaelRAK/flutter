import '../../domain/models/transaction.dart';
import '../db/drift_database.dart';
import 'package:drift/drift.dart';

/// Mapper pour convertir entre les modèles Drift et Domain
class TransactionMapper {
  /// Convertit un Transaction (Drift) en DomainTransaction
  static DomainTransaction toDomain(Transaction driftTransaction) {
    return DomainTransaction(
      id: driftTransaction.id,
      accountId: driftTransaction.accountId,
      categoryId: driftTransaction.categoryId,
      type: driftTransaction.type,
      amount: driftTransaction.amount,
      date: driftTransaction.date,
      description: driftTransaction.description,
      images: driftTransaction.images,
      latitude: driftTransaction.latitude,
      longitude: driftTransaction.longitude,
      address: driftTransaction.address,
      isRecurringInstance: driftTransaction.isRecurringInstance,
      recurrenceId: driftTransaction.recurrenceId,
      createdAt: driftTransaction.createdAt,
      updatedAt: driftTransaction.updatedAt,
    );
  }

  /// Convertit une liste de Transaction (Drift) en liste de DomainTransaction
  static List<DomainTransaction> toDomainList(List<Transaction> driftList) {
    return driftList.map(toDomain).toList();
  }

  /// Convertit un DomainTransaction en TransactionsCompanion (Drift)
  static TransactionsCompanion toDrift(DomainTransaction domain) {
    return TransactionsCompanion(
      id: Value(domain.id),
      accountId: Value(domain.accountId),
      categoryId: Value(domain.categoryId),
      type: Value(domain.type),
      amount: Value(domain.amount),
      date: Value(domain.date),
      description: Value(domain.description),
      images: Value(domain.images),
      latitude: Value(domain.latitude),
      longitude: Value(domain.longitude),
      address: Value(domain.address),
      isRecurringInstance: Value(domain.isRecurringInstance),
      recurrenceId: Value(domain.recurrenceId),
      createdAt: Value(domain.createdAt),
      updatedAt: Value(domain.updatedAt),
    );
  }
}

