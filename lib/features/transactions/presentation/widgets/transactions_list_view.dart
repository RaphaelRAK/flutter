import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../core/theme/app_colors.dart';
import 'transaction_detail_dialog.dart';

class TransactionsListView extends ConsumerWidget {
  const TransactionsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AppColors.darkTextSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune transaction',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        // Grouper les transactions par date
        final transactionsByDate = <DateTime, List<Transaction>>{};
        for (final transaction in transactions) {
          final date = DateTime(
            transaction.date.year,
            transaction.date.month,
            transaction.date.day,
          );
          transactionsByDate.putIfAbsent(date, () => []).add(transaction);
        }

        // Trier les dates par ordre décroissant
        final sortedDates = transactionsByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayTransactions = transactionsByDate[date]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de date
                Padding(
                  padding: EdgeInsets.only(bottom: 8, top: index == 0 ? 0 : 16),
                  child: Text(
                    _formatDateHeader(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ),
                // Transactions du jour
                ...dayTransactions.map((transaction) => _buildTransactionCard(
                  context,
                  transaction,
                )),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erreur: $error'),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateNormalized = DateTime(date.year, date.month, date.day);

    if (dateNormalized == today) {
      return 'Aujourd\'hui';
    } else if (dateNormalized == yesterday) {
      return 'Hier';
    } else {
      return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    }
  }

  Widget _buildTransactionCard(BuildContext context, Transaction transaction) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';

    Color amountColor;
    IconData iconData;
    String prefix = '';

    if (isExpense) {
      amountColor = AppColors.expense;
      iconData = Icons.arrow_downward;
      prefix = '-';
    } else if (isIncome) {
      amountColor = AppColors.income;
      iconData = Icons.arrow_upward;
      prefix = '+';
    } else {
      amountColor = AppColors.transfer;
      iconData = Icons.swap_horiz;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => TransactionDetailDialog(transaction: transaction),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: amountColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ?? 'Sans description',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(transaction.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$prefix${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(transaction.amount)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

