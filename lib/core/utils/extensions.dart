import 'package:flutter/material.dart';
import 'formatters.dart';

/// Extensions Dart utiles pour l'application

/// Extension pour DateTime
extension DateTimeExtension on DateTime {
  /// Retourne true si la date est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Retourne true si la date est hier
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Retourne true si la date est demain
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// Retourne le début du jour
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Retourne la fin du jour
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Retourne le début du mois
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Retourne la fin du mois
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Formate la date
  String toFormattedDate() => Formatters.formatDate(this);

  /// Formate la date et l'heure
  String toFormattedDateTime() => Formatters.formatDateTime(this);

  /// Formate la date relative
  String toRelativeDate() => Formatters.formatRelativeDate(this);
}

/// Extension pour double (montants)
extension DoubleExtension on double {
  /// Formate un montant avec devise
  String toFormattedAmount({String currency = 'EUR', int decimalPlaces = 2}) {
    return Formatters.formatAmount(this, currency: currency, decimalPlaces: decimalPlaces);
  }

  /// Formate un montant sans symbole
  String toFormattedAmountWithoutSymbol({int decimalPlaces = 2}) {
    return Formatters.formatAmountWithoutSymbol(this, decimalPlaces: decimalPlaces);
  }
}

/// Extension pour String
extension StringExtension on String {
  /// Retourne true si la chaîne est vide ou ne contient que des espaces
  bool get isBlank => trim().isEmpty;

  /// Retourne true si la chaîne n'est pas vide
  bool get isNotBlank => !isBlank;

  /// Parse un montant depuis la chaîne
  double? toAmount() => Formatters.parseAmount(this);
}

/// Extension pour BuildContext (navigation, thème, etc.)
extension BuildContextExtension on BuildContext {
  /// Récupère le thème
  ThemeData get theme => Theme.of(this);

  /// Récupère les couleurs du thème
  ColorScheme get colors => theme.colorScheme;

  /// Récupère la taille de l'écran
  Size get screenSize => MediaQuery.of(this).size;

  /// Récupère la largeur de l'écran
  double get screenWidth => screenSize.width;

  /// Récupère la hauteur de l'écran
  double get screenHeight => screenSize.height;

  /// Retourne true si l'écran est en mode paysage
  bool get isLandscape => screenWidth > screenHeight;

  /// Retourne true si l'écran est en mode portrait
  bool get isPortrait => screenHeight > screenWidth;
}

