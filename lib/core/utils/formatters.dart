import 'package:intl/intl.dart';

/// Formateurs pour les dates, montants, etc.
class Formatters {
  // Format de date
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat timeFormat = DateFormat('HH:mm');
  static final DateFormat monthYearFormat = DateFormat('MMMM yyyy', 'fr_FR');
  static final DateFormat dayMonthFormat = DateFormat('dd MMMM', 'fr_FR');

  /// Formate un montant avec la devise
  static String formatAmount(double amount, {String currency = 'EUR', int decimalPlaces = 2}) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: decimalPlaces,
      locale: 'fr_FR',
    );
    return formatter.format(amount);
  }

  /// Formate un montant sans symbole de devise
  static String formatAmountWithoutSymbol(double amount, {int decimalPlaces = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimalPlaces}', 'fr_FR');
    return formatter.format(amount);
  }

  /// Formate une date
  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }

  /// Formate une date et heure
  static String formatDateTime(DateTime date) {
    return dateTimeFormat.format(date);
  }

  /// Formate une heure
  static String formatTime(DateTime date) {
    return timeFormat.format(date);
  }

  /// Formate un mois et année
  static String formatMonthYear(DateTime date) {
    return monthYearFormat.format(date);
  }

  /// Formate un jour et mois
  static String formatDayMonth(DateTime date) {
    return dayMonthFormat.format(date);
  }

  /// Formate une date relative (aujourd'hui, hier, etc.)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference == -1) {
      return 'Demain';
    } else if (difference < 7 && difference > 0) {
      return 'Il y a $difference jour(s)';
    } else {
      return formatDate(date);
    }
  }

  /// Récupère le symbole d'une devise
  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'MGA':
        return 'Ar';
      case 'CHF':
        return 'CHF';
      default:
        return currency;
    }
  }

  /// Parse un montant depuis une chaîne
  static double? parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
  }
}

