import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../infrastructure/db/drift_database.dart';
import '../../../../../core/theme/app_colors.dart';

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) => transactionsAsync.when(
          data: (transactions) {
            debugPrint('🚀 ========== CALENDAR SCREEN BUILD ==========');
            debugPrint('📦 Transactions reçues du provider: ${transactions.length}');
            if (transactions.isNotEmpty) {
              debugPrint('📋 Première transaction: ${transactions.first.toString()}');
              debugPrint('📋 Date première transaction: ${transactions.first.date}');
              debugPrint('📋 Type première transaction: ${transactions.first.type}');
              debugPrint('📋 Montant première transaction: ${transactions.first.amount}');
            }
            return _buildContent(context, transactions, settings);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            debugPrint('❌ ERREUR transactionsStreamProvider: $error');
            debugPrint('❌ Stack: $stack');
            return Center(child: Text('Erreur: $error'));
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Transaction> transactions, dynamic settings) {
    debugPrint('🎨 ========== _buildContent appelé ==========');
    debugPrint('📊 Total transactions reçues: ${transactions.length}');
    debugPrint('📅 Jour sélectionné: ${_selectedDay.toString()}');
    debugPrint('📅 Jour sélectionné (normalisé): ${DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)}');
    
    // Afficher toutes les transactions avec leurs dates
    if (transactions.isNotEmpty) {
      debugPrint('📋 === TOUTES LES TRANSACTIONS ===');
      for (int i = 0; i < transactions.length && i < 10; i++) {
        final t = transactions[i];
        debugPrint('  [$i] ID: ${t.id}, Type: ${t.type}, Montant: ${t.amount}, Date: ${t.date}, Desc: ${t.description}');
      }
      if (transactions.length > 10) {
        debugPrint('  ... et ${transactions.length - 10} autres transactions');
      }
    }
    
    final currency = settings.currency;
    final currencyFormat = NumberFormat.currency(symbol: _getCurrencySymbol(currency));
    final selectedDayTransactions = _getTransactionsForDay(_selectedDay, transactions);
    
    debugPrint('📋 Transactions trouvées pour ce jour: ${selectedDayTransactions.length}');
    if (selectedDayTransactions.isNotEmpty) {
      debugPrint('📋 === TRANSACTIONS DU JOUR SÉLECTIONNÉ ===');
      for (final t in selectedDayTransactions) {
        debugPrint('  - ${t.description}: ${t.amount} (${t.type}) - ${t.date}');
      }
    }
    
    // Calculer les totaux du jour sélectionné
    double totalExpenses = 0.0;
    double totalIncome = 0.0;
    for (final transaction in selectedDayTransactions) {
      debugPrint('💰 Calcul total - Type: ${transaction.type}, Montant: ${transaction.amount}');
      if (transaction.type == 'expense') {
        totalExpenses += transaction.amount;
      } else if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      }
    }
    final netTotal = totalIncome - totalExpenses;
    debugPrint('💰 Totaux calculés - Dépenses: $totalExpenses, Revenus: $totalIncome, Net: $netTotal');

    return Column(
      children: [
        // Calendrier
        Card(
          margin: const EdgeInsets.all(16),
          child: TableCalendar(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: (day) {
              debugPrint('📅 eventLoader appelé pour le jour: ${day.toString()}');
              // Retourner une liste non vide si il y a des transactions ce jour
              final dayTransactions = _getTransactionsForDay(day, transactions);
              debugPrint('📅 eventLoader - Transactions trouvées: ${dayTransactions.length}');
              return dayTransactions.isNotEmpty ? dayTransactions : [];
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.accentSecondary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppColors.accentPrimary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 6,
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
            ),
            onDaySelected: (selectedDay, focusedDay) {
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
          ),
        ),
        
        // Totaux du jour sélectionné
        if (selectedDayTransactions.isNotEmpty)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTotalItem(
                    'Dépenses',
                    totalExpenses,
                    AppColors.expense,
                    Icons.trending_down,
                    currencyFormat,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  _buildTotalItem(
                    'Revenus',
                    totalIncome,
                    AppColors.income,
                    Icons.trending_up,
                    currencyFormat,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  _buildTotalItem(
                    'Net',
                    netTotal,
                    netTotal >= 0 ? AppColors.income : AppColors.expense,
                    Icons.account_balance_wallet,
                    currencyFormat,
                  ),
                ],
              ),
            ),
          ),
        
        // Transactions du jour sélectionné
        Expanded(
          child: selectedDayTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune transaction ce jour',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Transactions du ${DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDay)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ...selectedDayTransactions.map((transaction) =>
                        _buildTransactionTile(context, transaction, currencyFormat)),
                  ],
                ),
        ),
      ],
    );
  }

  List<Transaction> _getTransactionsForDay(DateTime day, List<Transaction> transactions) {
    debugPrint('🔍 ========== _getTransactionsForDay ==========');
    debugPrint('🔍 Jour recherché: ${day.toString()}');
    debugPrint('🔍 Nombre de transactions à tester: ${transactions.length}');
    
    if (transactions.isEmpty) {
      debugPrint('⚠️ Aucune transaction dans la liste');
      return [];
    }
    
    // Utiliser la même méthode que daily_screen qui fonctionne
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    debugPrint('🔍 Plage de recherche:');
    debugPrint('  - Début: ${startOfDay.toString()}');
    debugPrint('  - Fin: ${endOfDay.toString()}');
    debugPrint('  - Début -1s: ${startOfDay.subtract(const Duration(seconds: 1)).toString()}');

    int testedCount = 0;
    int matchedCount = 0;
    
    final matchingTransactions = transactions.where((transaction) {
      testedCount++;
      final transactionDate = transaction.date;
      final isAfterStart = transactionDate.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
      final isBeforeEnd = transactionDate.isBefore(endOfDay);
      final isInRange = isAfterStart && isBeforeEnd;
      
      if (testedCount <= 5 || isInRange) {
        debugPrint('  [$testedCount] Test transaction:');
        debugPrint('      - ID: ${transaction.id}');
        debugPrint('      - Date: ${transactionDate.toString()}');
        debugPrint('      - Date normalisée: ${DateTime(transactionDate.year, transactionDate.month, transactionDate.day)}');
        debugPrint('      - isAfter(${startOfDay.subtract(const Duration(seconds: 1))}): $isAfterStart');
        debugPrint('      - isBefore($endOfDay): $isBeforeEnd');
        debugPrint('      - ✅ DANS LA PLAGE: $isInRange');
      }
      
      if (isInRange) {
        matchedCount++;
        debugPrint('✅ Transaction MATCHÉE: ${transaction.description} - ${transactionDate.toString()}');
      }
      
      return isInRange;
    }).toList();
    
    matchingTransactions.sort((a, b) => b.date.compareTo(a.date));
    debugPrint('📊 Résultat: $matchedCount transactions trouvées sur $testedCount testées');
    debugPrint('📊 Liste finale: ${matchingTransactions.length} transactions');
    
    return matchingTransactions;
  }

  Widget _buildTotalItem(
    String label,
    double amount,
    Color color,
    IconData icon,
    NumberFormat currencyFormat,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.darkTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          currencyFormat.format(amount.abs()),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les transactions'),
        content: const Text('Options de filtrage à venir'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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

