enum RecurrenceFrequency {
  daily('daily', 'Quotidien'),
  weekly('weekly', 'Hebdomadaire'),
  monthly('monthly', 'Mensuel'),
  yearly('yearly', 'Annuel'),
  custom('custom', 'Personnalisé');

  final String value;
  final String label;

  const RecurrenceFrequency(this.value, this.label);
}

