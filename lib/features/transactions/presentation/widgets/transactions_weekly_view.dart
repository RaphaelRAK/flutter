import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../core/theme/app_colors.dart';
import 'transaction_detail_dialog.dart';

class TransactionsWeeklyView extends ConsumerStatefulWidget {
  const TransactionsWeeklyView({super.key});

  @override
  ConsumerState<TransactionsWeeklyView> createState() =>
      _TransactionsWeeklyViewState();
}

class _TransactionsWeeklyViewState
    extends ConsumerState<TransactionsWeeklyView> {
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());

  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  DateTime get _selectedWeekEnd => _selectedWeekStart.add(const Duration(days: 6));

  void _previousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(filteredTransactionsStreamProvider);

    return transactionsAsync.when(
      data: (allTransactions) {
        // Normaliser le début et la fin de la semaine
        final weekStartNormalized = DateTime(
          _selectedWeekStart.year,
          _selectedWeekStart.month,
          _selectedWeekStart.day,
        );
        final weekEndNormalized = DateTime(
          _selectedWeekEnd.year,
          _selectedWeekEnd.month,
          _selectedWeekEnd.day,
        );
        
        // Filtrer les transactions de la semaine sélectionnée
        final weekTransactions = allTransactions.where((t) {
          final transactionDate = DateTime(
            t.date.year,
            t.date.month,
            t.date.day,
          );
          return transactionDate.isAfter(
                weekStartNormalized.subtract(const Duration(seconds: 1)),
              ) &&
              transactionDate.isBefore(
                weekEndNormalized.add(const Duration(days: 1)),
              );
        }).toList();

        // Calculer les totaux
        double totalIncome = 0.0;
        double totalExpense = 0.0;
        for (final transaction in weekTransactions) {
          if (transaction.type == 'income') {
            totalIncome += transaction.amount;
          } else if (transaction.type == 'expense') {
            totalExpense += transaction.amount;
          }
        }
        final balance = totalIncome - totalExpense;

        // Grouper par jour
        final transactionsByDay = <DateTime, List<Transaction>>{};
        for (final transaction in weekTransactions) {
          final date = DateTime(
            transaction.date.year,
            transaction.date.month,
            transaction.date.day,
          );
          transactionsByDay.putIfAbsent(date, () => []).add(transaction);
        }
        
        debugPrint('📅 Semaine: ${weekStartNormalized} - ${weekEndNormalized}');
        debugPrint('📊 Transactions trouvées: ${weekTransactions.length}');
        debugPrint('📋 Transactions groupées par jour: ${transactionsByDay.length} jours');
        if (transactionsByDay.isNotEmpty) {
          debugPrint('📋 Jours avec transactions:');
          for (final entry in transactionsByDay.entries) {
            debugPrint('  - ${entry.key}: ${entry.value.length} transaction(s)');
          }
        }

        return Column(
          children: [
            // En-tête avec navigation
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousWeek,
                    ),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${DateFormat('d MMM', 'fr_FR').format(_selectedWeekStart)} - ${DateFormat('d MMM yyyy', 'fr_FR').format(_selectedWeekEnd)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildSummaryChip(
                                  'Revenus',
                                  totalIncome,
                                  AppColors.income,
                                  Icons.trending_up,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildSummaryChip(
                                  'Dépenses',
                                  totalExpense,
                                  AppColors.expense,
                                  Icons.trending_down,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildSummaryChip(
                                  'Solde',
                                  balance,
                                  balance >= 0 ? AppColors.income : AppColors.expense,
                                  Icons.account_balance_wallet,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextWeek,
                    ),
                  ],
                ),
              ),
            ),
            // Liste des transactions par jour
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                itemBuilder: (context, index) {
                  // Normaliser le jour pour la recherche dans transactionsByDay
                  final day = DateTime(
                    _selectedWeekStart.year,
                    _selectedWeekStart.month,
                    _selectedWeekStart.day,
                  ).add(Duration(days: index));
                  final dayTransactions = transactionsByDay[day] ?? [];
                  
                  if (index < 2) {
                    debugPrint('🔍 Jour [$index]: $day');
                    debugPrint('  - Transactions trouvées: ${dayTransactions.length}');
                    if (transactionsByDay.containsKey(day)) {
                      debugPrint('  - ✅ Clé trouvée dans le map');
                    } else {
                      debugPrint('  - ❌ Clé NON trouvée dans le map');
                      if (transactionsByDay.isNotEmpty) {
                        debugPrint('  - Clés disponibles: ${transactionsByDay.keys.take(3).toList()}');
                      }
                    }
                  }
                  
                  return _buildDaySection(day, dayTransactions);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erreur: $error'),
      ),
    );
  }

  Widget _buildSummaryChip(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.darkTextSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            NumberFormat.currency(symbol: '€', decimalDigits: 0).format(amount.abs()),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(DateTime day, List<Transaction> transactions) {
    final isToday = isSameDay(day, DateTime.now());
    final dayName = DateFormat('EEEE', 'fr_FR').format(day);
    final dayNumber = DateFormat('d', 'fr_FR').format(day);

    double dayTotal = 0.0;
    for (final transaction in transactions) {
      if (transaction.type == 'expense') {
        dayTotal -= transaction.amount;
      } else if (transaction.type == 'income') {
        dayTotal += transaction.amount;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isToday ? AppColors.accentSecondary.withOpacity(0.1) : null,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isToday
              ? AppColors.accentSecondary
              : AppColors.darkTextSecondary.withOpacity(0.2),
          child: Text(
            dayNumber,
            style: TextStyle(
              color: isToday ? Colors.white : AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          dayName,
          style: TextStyle(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          DateFormat('d MMM yyyy', 'fr_FR').format(day),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.darkTextSecondary,
          ),
        ),
        trailing: dayTotal != 0
            ? Text(
                '${dayTotal >= 0 ? '+' : ''}${NumberFormat.currency(symbol: '€', decimalDigits: 0).format(dayTotal.abs())}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: dayTotal >= 0 ? AppColors.income : AppColors.expense,
                ),
              )
            : Text(
                '${transactions.length} transaction${transactions.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
        children: transactions.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Aucune transaction',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ),
              ]
            : transactions.map((transaction) {
                return _buildTransactionTile(transaction);
              }).toList(),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final amountColor = isExpense
        ? AppColors.expense
        : isIncome
            ? AppColors.income
            : AppColors.transfer;

    return ListTile(
      leading: Icon(
        isExpense
            ? Icons.arrow_downward
            : isIncome
                ? Icons.arrow_upward
                : Icons.swap_horiz,
        color: amountColor,
      ),
      title: Text(
        transaction.description ?? 'Sans description',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        DateFormat('HH:mm').format(transaction.date),
        style: TextStyle(
          fontSize: 12,
          color: AppColors.darkTextSecondary,
        ),
      ),
      trailing: Text(
        '${isExpense ? '-' : isIncome ? '+' : ''}${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(transaction.amount)}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: amountColor,
        ),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => TransactionDetailDialog(transaction: transaction),
        );
      },
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

