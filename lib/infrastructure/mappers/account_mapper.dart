import '../../domain/models/account.dart';
import '../db/drift_database.dart';
import 'package:drift/drift.dart';

/// Mapper pour convertir entre les modèles Drift et Domain pour les comptes
class AccountMapper {
  /// Convertit un Account (Drift) en DomainAccount
  static DomainAccount toDomain(Account drift) {
    return DomainAccount(
      id: drift.id,
      name: drift.name,
      type: drift.type,
      accountCategory: drift.accountCategory,
      initialBalance: drift.initialBalance,
      icon: drift.icon,
      currency: drift.currency,
      notes: drift.notes,
      order: drift.order,
      excludedFromTotal: drift.excludedFromTotal,
      transferAsExpense: drift.transferAsExpense,
      includeInBudget: drift.includeInBudget,
      archived: drift.archived,
      createdAt: drift.createdAt,
      creditLimit: drift.creditLimit,
      billingDay: drift.billingDay,
      paymentDay: drift.paymentDay,
      billingBalance: drift.billingBalance,
      pendingBalance: drift.pendingBalance,
    );
  }

  /// Convertit une liste de Account (Drift) en liste de DomainAccount
  static List<DomainAccount> toDomainList(List<Account> driftList) {
    return driftList.map(toDomain).toList();
  }

  /// Convertit un DomainAccount en AccountsCompanion (Drift)
  static AccountsCompanion toDrift(DomainAccount domain) {
    return AccountsCompanion(
      id: Value(domain.id),
      name: Value(domain.name),
      type: Value(domain.type),
      accountCategory: Value(domain.accountCategory),
      initialBalance: Value(domain.initialBalance),
      icon: Value(domain.icon),
      currency: Value(domain.currency),
      notes: Value(domain.notes),
      order: Value(domain.order),
      excludedFromTotal: Value(domain.excludedFromTotal),
      transferAsExpense: Value(domain.transferAsExpense),
      includeInBudget: Value(domain.includeInBudget),
      archived: Value(domain.archived),
      createdAt: Value(domain.createdAt),
      creditLimit: Value(domain.creditLimit),
      billingDay: Value(domain.billingDay),
      paymentDay: Value(domain.paymentDay),
      billingBalance: Value(domain.billingBalance),
      pendingBalance: Value(domain.pendingBalance),
    );
  }
}

