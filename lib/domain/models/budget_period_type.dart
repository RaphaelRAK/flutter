enum BudgetPeriodType {
  monthly('monthly', 'Mensuel'),
  weekly('weekly', 'Hebdomadaire'),
  custom('custom', 'Personnalisé');

  final String value;
  final String label;

  const BudgetPeriodType(this.value, this.label);
}

