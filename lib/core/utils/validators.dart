/// Validateurs de formulaires réutilisables
class Validators {
  /// Valide qu'un champ n'est pas vide
  static String? required(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? 'Ce champ est requis';
    }
    return null;
  }

  /// Valide un montant (nombre positif)
  static String? amount(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? 'Le montant est requis';
    }
    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null) {
      return errorMessage ?? 'Montant invalide';
    }
    if (amount <= 0) {
      return errorMessage ?? 'Le montant doit être supérieur à 0';
    }
    return null;
  }

  /// Valide un nom (non vide, longueur minimale)
  static String? name(String? value, {int minLength = 1, String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? 'Le nom est requis';
    }
    if (value.trim().length < minLength) {
      return errorMessage ?? 'Le nom doit contenir au moins $minLength caractère(s)';
    }
    return null;
  }

  /// Valide un email
  static String? email(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return errorMessage ?? 'Email invalide';
    }
    return null;
  }

  /// Valide un PIN (4-6 chiffres)
  static String? pin(String? value, {int length = 4, String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? 'Le PIN est requis';
    }
    if (value.length != length) {
      return errorMessage ?? 'Le PIN doit contenir $length chiffres';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return errorMessage ?? 'Le PIN doit contenir uniquement des chiffres';
    }
    return null;
  }

  /// Valide une longueur minimale
  static String? minLength(String? value, int minLength, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? 'Ce champ est requis';
    }
    if (value.trim().length < minLength) {
      return errorMessage ?? 'Ce champ doit contenir au moins $minLength caractère(s)';
    }
    return null;
  }

  /// Valide une longueur maximale
  static String? maxLength(String? value, int maxLength, {String? errorMessage}) {
    if (value == null) return null;
    if (value.length > maxLength) {
      return errorMessage ?? 'Ce champ ne doit pas dépasser $maxLength caractère(s)';
    }
    return null;
  }
}

