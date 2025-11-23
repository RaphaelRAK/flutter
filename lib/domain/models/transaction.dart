/// Modèle de domaine pour une transaction
/// Indépendant de Drift et de toute implémentation
class DomainTransaction {
  final int id;
  final int accountId;
  final int categoryId;
  final String type; // 'expense', 'income', 'transfer'
  final double amount;
  final DateTime date;
  final String? description;
  final String? images; // Chemins des images séparés par des virgules
  final bool isRecurringInstance;
  final int? recurrenceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DomainTransaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.images,
    required this.isRecurringInstance,
    this.recurrenceId,
    required this.createdAt,
    required this.updatedAt,
  });

  DomainTransaction copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    String? type,
    double? amount,
    DateTime? date,
    String? description,
    String? images,
    bool? isRecurringInstance,
    int? recurrenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DomainTransaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      images: images ?? this.images,
      isRecurringInstance: isRecurringInstance ?? this.isRecurringInstance,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

