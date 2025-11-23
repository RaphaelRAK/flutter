class AppConstants {
  // Devises supportées
  static const List<String> supportedCurrencies = [
    'EUR',
    'USD',
    'MGA',
    'GBP',
    'CHF',
  ];

  // Catégories par défaut
  static const List<Map<String, dynamic>> defaultExpenseCategories = [
    {'name': 'Logement', 'icon': 'home', 'color': '#3B82F6'},
    {'name': 'Courses', 'icon': 'shopping_cart', 'color': '#10B981'},
    {'name': 'Restaurants', 'icon': 'restaurant', 'color': '#F59E0B'},
    {'name': 'Transport', 'icon': 'directions_car', 'color': '#8B5CF6'},
    {'name': 'Loisirs', 'icon': 'sports_esports', 'color': '#EC4899'},
    {'name': 'Santé', 'icon': 'local_hospital', 'color': '#EF4444'},
    {'name': 'Éducation', 'icon': 'school', 'color': '#06B6D4'},
    {'name': 'Autres', 'icon': 'category', 'color': '#6B7280'},
  ];

  static const List<Map<String, dynamic>> defaultIncomeCategories = [
    {'name': 'Salaire', 'icon': 'work', 'color': '#4ADE80'},
    {'name': 'Freelance', 'icon': 'laptop', 'color': '#10B981'},
    {'name': 'Investissements', 'icon': 'trending_up', 'color': '#6366F1'},
    {'name': 'Autres revenus', 'icon': 'attach_money', 'color': '#8B5CF6'},
  ];

  // Fréquences récurrentes
  static const List<String> recurrenceFrequencies = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  // Types de périodes de budget
  static const List<String> budgetPeriodTypes = [
    'monthly',
    'weekly',
    'custom',
  ];

  // Seuils d'alerte budget (en pourcentage)
  static const double budgetWarningThreshold = 80.0;
  static const double budgetExceededThreshold = 100.0;
}

