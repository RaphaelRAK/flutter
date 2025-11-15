import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../core/theme/app_colors.dart';

class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vue quotidienne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) => transactionsAsync.when(
          data: (transactions) => _buildContent(context, transactions, settings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List transactions, dynamic settings) {
    final currency = settings.currency;
    final currencyFormat = NumberFormat.currency(symbol: _getCurrencySymbol(currency));
    
    final dayTransactions = _getTransactionsForDay(_selectedDate, transactions);
    final dayTotals = _calculateDayTotals(dayTransactions);

    return Column(
      children: [
        // En-tête avec date et totaux
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTotalCard(
                        context,
                        'Revenus',
                        dayTotals['income'] ?? 0.0,
                        AppColors.income,
                        currencyFormat,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTotalCard(
                        context,
                        'Dépenses',
                        dayTotals['expense'] ?? 0.0,
                        AppColors.expense,
                        currencyFormat,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppColors.accentSecondary.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Balance',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          currencyFormat.format(dayTotals['balance'] ?? 0.0),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Liste des transactions
        Expanded(
          child: dayTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune transaction ce jour',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez sur + pour ajouter une transaction',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dayTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = dayTransactions[index];
                    return _buildTransactionTile(
                      context,
                      transaction,
                      currencyFormat,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(
    BuildContext context,
    String label,
    double amount,
    Color color,
    NumberFormat currencyFormat,
  ) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    dynamic transaction,
    NumberFormat currencyFormat,
  ) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? AppColors.expense : AppColors.income;
    final icon = isExpense ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(transaction.description ?? 'Sans description'),
        subtitle: Text(
          DateFormat('HH:mm').format(transaction.date),
        ),
        trailing: Text(
          '${isExpense ? '-' : '+'}${currencyFormat.format(transaction.amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => context.push('/transaction-detail', extra: transaction),
      ),
    );
  }

  List _getTransactionsForDay(DateTime day, List transactions) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return transactions.where((transaction) {
      return transaction.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          transaction.date.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, double> _calculateDayTotals(List transactions) {
    double income = 0.0;
    double expense = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else if (transaction.type == 'expense') {
        expense += transaction.amount;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'MGA':
        return 'Ar';
      default:
        return currency;
    }
  }
}

