/// Modèle de domaine pour un compte
class DomainAccount {
  final int id;
  final String name;
  final String type; // 'bank', 'cash', 'wallet', 'credit', 'loan', etc.
  final String accountCategory; // 'asset', 'liability', 'custom'
  final double initialBalance;
  final String? icon;
  final String? currency;
  final String? notes;
  final int order;
  final bool excludedFromTotal;
  final bool transferAsExpense;
  final bool includeInBudget;
  final bool archived;
  final DateTime createdAt;
  
  // Champs spécifiques aux cartes de crédit
  final double? creditLimit;
  final int? billingDay;
  final int? paymentDay;
  final double? billingBalance;
  final double? pendingBalance;

  DomainAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.accountCategory,
    required this.initialBalance,
    this.icon,
    this.currency,
    this.notes,
    required this.order,
    required this.excludedFromTotal,
    required this.transferAsExpense,
    required this.includeInBudget,
    required this.archived,
    required this.createdAt,
    this.creditLimit,
    this.billingDay,
    this.paymentDay,
    this.billingBalance,
    this.pendingBalance,
  });

  DomainAccount copyWith({
    int? id,
    String? name,
    String? type,
    String? accountCategory,
    double? initialBalance,
    String? icon,
    String? currency,
    String? notes,
    int? order,
    bool? excludedFromTotal,
    bool? transferAsExpense,
    bool? includeInBudget,
    bool? archived,
    DateTime? createdAt,
    double? creditLimit,
    int? billingDay,
    int? paymentDay,
    double? billingBalance,
    double? pendingBalance,
  }) {
    return DomainAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      accountCategory: accountCategory ?? this.accountCategory,
      initialBalance: initialBalance ?? this.initialBalance,
      icon: icon ?? this.icon,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      order: order ?? this.order,
      excludedFromTotal: excludedFromTotal ?? this.excludedFromTotal,
      transferAsExpense: transferAsExpense ?? this.transferAsExpense,
      includeInBudget: includeInBudget ?? this.includeInBudget,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      creditLimit: creditLimit ?? this.creditLimit,
      billingDay: billingDay ?? this.billingDay,
      paymentDay: paymentDay ?? this.paymentDay,
      billingBalance: billingBalance ?? this.billingBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
    );
  }
}

