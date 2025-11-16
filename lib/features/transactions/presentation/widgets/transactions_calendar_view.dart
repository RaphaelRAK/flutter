import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../core/theme/app_colors.dart';
import 'transaction_detail_dialog.dart';

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class TransactionsCalendarView extends ConsumerStatefulWidget {
  const TransactionsCalendarView({super.key});

  @override
  ConsumerState<TransactionsCalendarView> createState() =>
      _TransactionsCalendarViewState();
}

class _TransactionsCalendarViewState
    extends ConsumerState<TransactionsCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return transactionsAsync.when(
      data: (transactions) {
        print('🚀 ========== TransactionsCalendarView BUILD ==========');
        print('📦 Transactions reçues du provider: ${transactions.length}');
        debugPrint('🚀 ========== TransactionsCalendarView BUILD ==========');
        debugPrint('📦 Transactions reçues du provider: ${transactions.length}');
        
        if (transactions.isNotEmpty) {
          print('📋 Première transaction:');
          print('  - ID: ${transactions.first.id}');
          print('  - Date: ${transactions.first.date}');
          print('  - Type: ${transactions.first.type}');
          print('  - Montant: ${transactions.first.amount}');
          print('  - Description: ${transactions.first.description}');
          debugPrint('📋 Première transaction: ID=${transactions.first.id}, Date=${transactions.first.date}, Type=${transactions.first.type}, Montant=${transactions.first.amount}');
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
        
        print('📅 Transactions groupées par date: ${transactionsByDate.length} jours');
        debugPrint('📅 Transactions groupées par date: ${transactionsByDate.length} jours');
        if (transactionsByDate.isNotEmpty) {
          print('📅 Exemples de dates dans le map:');
          debugPrint('📅 Exemples de dates dans le map:');
          int count = 0;
          for (final entry in transactionsByDate.entries) {
            if (count < 5) {
              print('  - ${entry.key}: ${entry.value.length} transaction(s)');
              debugPrint('  - ${entry.key}: ${entry.value.length} transaction(s)');
              count++;
            }
          }
        }

        // Calculer les montants par jour
        final amountsByDate = <DateTime, double>{};
        for (final entry in transactionsByDate.entries) {
          double total = 0.0;
          for (final transaction in entry.value) {
            if (transaction.type == 'expense') {
              total -= transaction.amount;
            } else if (transaction.type == 'income') {
              total += transaction.amount;
            }
          }
          amountsByDate[entry.key] = total;
        }
        
        // Normaliser le jour sélectionné pour la recherche
        final selectedDayNormalized = DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
        );
        
        print('📅 Jour sélectionné: ${_selectedDay}');
        print('📅 Jour sélectionné (normalisé): ${selectedDayNormalized}');
        print('📅 Transactions pour ce jour: ${transactionsByDate[selectedDayNormalized]?.length ?? 0}');
        debugPrint('📅 Jour sélectionné: ${_selectedDay}');
        debugPrint('📅 Jour sélectionné (normalisé): ${selectedDayNormalized}');
        debugPrint('📅 Transactions pour ce jour: ${transactionsByDate[selectedDayNormalized]?.length ?? 0}');
        
        if (transactionsByDate[selectedDayNormalized] != null) {
          print('📋 === TRANSACTIONS DU JOUR SÉLECTIONNÉ ===');
          debugPrint('📋 === TRANSACTIONS DU JOUR SÉLECTIONNÉ ===');
          for (final t in transactionsByDate[selectedDayNormalized]!) {
            print('  - ${t.description}: ${t.amount} (${t.type}) - ${t.date}');
            debugPrint('  - ${t.description}: ${t.amount} (${t.type}) - ${t.date}');
          }
        } else {
          print('⚠️ AUCUNE TRANSACTION TROUVÉE pour le jour normalisé: $selectedDayNormalized');
          debugPrint('⚠️ AUCUNE TRANSACTION TROUVÉE pour le jour normalisé: $selectedDayNormalized');
        }

        return Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: TableCalendar<Transaction>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: (day) {
                  final date = DateTime(day.year, day.month, day.day);
                  final events = transactionsByDate[date] ?? [];
                  if (events.isNotEmpty) {
                    print('📅 eventLoader - Jour: $date, Transactions: ${events.length}');
                    debugPrint('📅 eventLoader - Jour: $date, Transactions: ${events.length}');
                  }
                  return events;
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: AppColors.accentSecondary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.accentSecondary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.accentPrimary,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  markerSize: 6,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: AppColors.accentSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  print('📅 Jour sélectionné (onDaySelected): $selectedDay');
                  debugPrint('📅 Jour sélectionné (onDaySelected): $selectedDay');
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox.shrink();
                    
                    // Normaliser la date pour la recherche dans amountsByDate
                    final dateNormalized = DateTime(date.year, date.month, date.day);
                    final amount = amountsByDate[dateNormalized] ?? 0.0;
                    
                    // Si le montant est 0, ne rien afficher
                    if (amount == 0.0) return const SizedBox.shrink();
                    
                    // Option 1: Afficher juste un petit point coloré (plus simple et compact)
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: amount >= 0
                              ? AppColors.income
                              : AppColors.expense,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                    
                    // Option 2: Afficher le montant formaté (décommenter si tu préfères)
                    /*
                    final amountText = amount.abs() >= 1000
                        ? '${(amount.abs() / 1000).toStringAsFixed(1)}k'
                        : amount.abs().toStringAsFixed(0);
                    
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: amount >= 0
                              ? AppColors.income.withOpacity(0.8)
                              : AppColors.expense.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${amount >= 0 ? '+' : '-'}$amountText',
                          style: const TextStyle(
                            fontSize: 7,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                    */
                  },
                ),
              ),
            ),
            Expanded(
              child: _buildSelectedDayTransactions(
                transactionsByDate[selectedDayNormalized] ?? [],
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

  Widget _buildSelectedDayTransactions(List<Transaction> transactions) {
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
              'Aucune transaction ce jour',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
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

