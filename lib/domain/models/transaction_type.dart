enum TransactionType {
  expense('expense', 'Dépense'),
  income('income', 'Revenu'),
  transfer('transfer', 'Transfert');

  final String value;
  final String label;

  const TransactionType(this.value, this.label);
}

