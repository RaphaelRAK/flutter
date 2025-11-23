import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/transaction.dart';
import '../../../../application/use_cases/transactions/get_transactions_use_case.dart';
import '../../domain/use_cases/filter_transactions_use_case.dart';
import '../../../../core/utils/helpers/transaction_filters_helper.dart';

/// État de la liste de transactions
class TransactionListState {
  final List<DomainTransaction> transactions;
  final TransactionFilters? filters;
  final bool isLoading;
  final String? error;

  TransactionListState({
    required this.transactions,
    this.filters,
    this.isLoading = false,
    this.error,
  });

  TransactionListState copyWith({
    List<DomainTransaction>? transactions,
    TransactionFilters? filters,
    bool? isLoading,
    String? error,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Controller pour la liste de transactions
class TransactionListController extends StateNotifier<TransactionListState> {
  final GetTransactionsUseCase _getTransactionsUseCase;
  final FilterTransactionsUseCase _filterTransactionsUseCase;

  TransactionListController(
    this._getTransactionsUseCase,
    this._filterTransactionsUseCase,
  ) : super(TransactionListState(transactions: [])) {
    _loadTransactions();
  }

  /// Charge les transactions
  void _loadTransactions() {
    state = state.copyWith(isLoading: true, error: null);
    _getTransactionsUseCase().listen(
      (transactions) {
        _applyFilters(transactions);
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.toString(),
        );
      },
    );
  }

  /// Applique les filtres
  void _applyFilters(List<DomainTransaction> transactions) {
    final filtered = _filterTransactionsUseCase.applyFilters(
      transactions,
      state.filters,
    );
    state = state.copyWith(
      transactions: filtered,
      isLoading: false,
    );
  }

  /// Met à jour les filtres
  void updateFilters(TransactionFilters? filters) {
    state = state.copyWith(filters: filters);
    _loadTransactions();
  }

  /// Supprime les filtres
  void clearFilters() {
    updateFilters(null);
  }

  /// Rafraîchit la liste
  void refresh() {
    _loadTransactions();
  }
}

