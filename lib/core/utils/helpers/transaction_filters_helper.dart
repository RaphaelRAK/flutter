import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../infrastructure/db/drift_database.dart';

class TransactionFilters {
  final List<String>? types; // 'expense', 'income', 'transfer' ou null pour tous
  final List<int>? categoryIds; // IDs des catégories ou null pour toutes
  final List<int>? accountIds; // IDs des comptes ou null pour tous
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? searchQuery; // Recherche dans la description

  TransactionFilters({
    this.types,
    this.categoryIds,
    this.accountIds,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
  });

  bool get hasFilters {
    return types != null ||
        categoryIds != null ||
        accountIds != null ||
        startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  Map<String, dynamic> toJson() {
    return {
      'types': types,
      'categoryIds': categoryIds,
      'accountIds': accountIds,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'searchQuery': searchQuery,
    };
  }

  factory TransactionFilters.fromJson(Map<String, dynamic> json) {
    return TransactionFilters(
      types: json['types'] != null ? List<String>.from(json['types']) : null,
      categoryIds:
          json['categoryIds'] != null ? List<int>.from(json['categoryIds']) : null,
      accountIds:
          json['accountIds'] != null ? List<int>.from(json['accountIds']) : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate:
          json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      minAmount: json['minAmount']?.toDouble(),
      maxAmount: json['maxAmount']?.toDouble(),
      searchQuery: json['searchQuery'],
    );
  }

  TransactionFilters copyWith({
    List<String>? types,
    List<int>? categoryIds,
    List<int>? accountIds,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
  }) {
    return TransactionFilters(
      types: types ?? this.types,
      categoryIds: categoryIds ?? this.categoryIds,
      accountIds: accountIds ?? this.accountIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TransactionFiltersHelper {
  static const _storage = FlutterSecureStorage();
  static const _keyFilters = 'transaction_filters';

  static Future<void> saveFilters(TransactionFilters filters) async {
    final json = jsonEncode(filters.toJson());
    await _storage.write(key: _keyFilters, value: json);
  }

  static Future<TransactionFilters?> loadFilters() async {
    final json = await _storage.read(key: _keyFilters);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return TransactionFilters.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearFilters() async {
    await _storage.delete(key: _keyFilters);
  }

  /// Applique les filtres à une liste de transactions
  static List<Transaction> applyFilters(
    List<Transaction> transactions,
    TransactionFilters? filters,
  ) {
    if (filters == null || !filters.hasFilters) {
      return transactions;
    }

    return transactions.where((transaction) {
      // Filtre par type
      if (filters.types != null && filters.types!.isNotEmpty) {
        if (!filters.types!.contains(transaction.type)) {
          return false;
        }
      }

      // Filtre par catégorie
      if (filters.categoryIds != null && filters.categoryIds!.isNotEmpty) {
        if (!filters.categoryIds!.contains(transaction.categoryId)) {
          return false;
        }
      }

      // Filtre par compte
      if (filters.accountIds != null && filters.accountIds!.isNotEmpty) {
        if (!filters.accountIds!.contains(transaction.accountId)) {
          return false;
        }
      }

      // Filtre par date
      if (filters.startDate != null) {
        final startOfDay = DateTime(
          filters.startDate!.year,
          filters.startDate!.month,
          filters.startDate!.day,
        );
        if (transaction.date.isBefore(startOfDay)) {
          return false;
        }
      }

      if (filters.endDate != null) {
        final endOfDay = DateTime(
          filters.endDate!.year,
          filters.endDate!.month,
          filters.endDate!.day,
          23,
          59,
          59,
        );
        if (transaction.date.isAfter(endOfDay)) {
          return false;
        }
      }

      // Filtre par montant
      if (filters.minAmount != null) {
        if (transaction.amount < filters.minAmount!) {
          return false;
        }
      }

      if (filters.maxAmount != null) {
        if (transaction.amount > filters.maxAmount!) {
          return false;
        }
      }

      // Filtre par recherche dans la description
      if (filters.searchQuery != null &&
          filters.searchQuery!.isNotEmpty) {
        final query = filters.searchQuery!.toLowerCase();
        final description = transaction.description?.toLowerCase() ?? '';
        if (!description.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

