import 'package:flutter/material.dart';

/// Palette de couleurs inspirée des apps fintech (Revolut, N26, Lydia)
class AppColors {
  // Thème sombre (par défaut)
  static const Color darkBackground = Color(0xFF0B0F16);
  static const Color darkCard = Color(0xFF141927);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Thème clair
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Accents
  static const Color accentPrimary = Color(0xFF4ADE80); // Vert (positif, succès)
  static const Color accentSecondary = Color(0xFF6366F1); // Indigo (action, boutons)
  static const Color error = Color(0xFFEF4444); // Rouge (erreur)

  // Couleurs pour les transactions
  static const Color expense = Color(0xFFEF4444); // Rouge pour dépenses
  static const Color income = Color(0xFF4ADE80); // Vert pour revenus
  static const Color transfer = Color(0xFF6366F1); // Indigo pour transferts
}

