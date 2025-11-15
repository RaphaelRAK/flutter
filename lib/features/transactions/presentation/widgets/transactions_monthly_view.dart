import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

class TransactionsMonthlyView extends ConsumerStatefulWidget {
  const TransactionsMonthlyView({super.key});

  @override
  ConsumerState<TransactionsMonthlyView> createState() =>
      _TransactionsMonthlyViewState();
}

class _TransactionsMonthlyViewState
    extends ConsumerState<TransactionsMonthlyView> {
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return transactionsAsync.when(
      data: (allTransactions) {
        // Filtrer les transactions du mois sélectionné
        final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

        final monthTransactions = allTransactions.where((t) {
          final transactionDate = DateTime(
            t.date.year,
            t.date.month,
            t.date.day,
          );
          return transactionDate.isAfter(
                monthStart.subtract(const Duration(days: 1)),
              ) &&
              transactionDate.isBefore(monthEnd.add(const Duration(days: 1)));
        }).toList();

        // Calculer les totaux
        double totalIncome = 0.0;
        double totalExpense = 0.0;
        Map<String, double> expensesByCategory = {};
        Map<String, double> incomeByCategory = {};

        for (final transaction in monthTransactions) {
          if (transaction.type == 'income') {
            totalIncome += transaction.amount;
            // TODO: Récupérer le nom de la catégorie depuis la DB
            incomeByCategory['Catégorie'] =
                (incomeByCategory['Catégorie'] ?? 0) + transaction.amount;
          } else if (transaction.type == 'expense') {
            totalExpense += transaction.amount;
            // TODO: Récupérer le nom de la catégorie depuis la DB
            expensesByCategory['Catégorie'] =
                (expensesByCategory['Catégorie'] ?? 0) + transaction.amount;
          }
        }

        final balance = totalIncome - totalExpense;

        // Grouper par jour pour le graphique
        final dailyData = <DateTime, Map<String, double>>{};
        for (int day = 1; day <= monthEnd.day; day++) {
          final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
          dailyData[date] = {'income': 0.0, 'expense': 0.0};
        }

        for (final transaction in monthTransactions) {
          final date = DateTime(
            transaction.date.year,
            transaction.date.month,
            transaction.date.day,
          );
          if (transaction.type == 'income') {
            dailyData[date]!['income'] =
                (dailyData[date]!['income'] ?? 0) + transaction.amount;
          } else if (transaction.type == 'expense') {
            dailyData[date]!['expense'] =
                (dailyData[date]!['expense'] ?? 0) + transaction.amount;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // En-tête avec navigation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Résumé mensuel
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Revenus',
                    totalIncome,
                    AppColors.income,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Dépenses',
                    totalExpense,
                    AppColors.expense,
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Solde',
                    balance,
                    balance >= 0 ? AppColors.income : AppColors.expense,
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Graphique des revenus vs dépenses
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenus vs Dépenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: [totalIncome, totalExpense].reduce((a, b) => a > b ? a : b) * 1.2,
                          barTouchData: BarTouchData(
                            enabled: false,
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      value.toInt() == 0
                                          ? 'Revenus'
                                          : value.toInt() == 1
                                              ? 'Dépenses'
                                              : '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${(value / 1000).toStringAsFixed(1)}k',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: totalIncome,
                                  color: AppColors.income,
                                  width: 40,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: totalExpense,
                                  color: AppColors.expense,
                                  width: 40,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Graphique quotidien
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Évolution quotidienne',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: dailyData.entries.map((entry) {
                                final dayIndex = entry.key.day - 1;
                                return FlSpot(dayIndex.toDouble(), entry.value['income'] ?? 0);
                              }).toList(),
                              isCurved: true,
                              color: AppColors.income,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                            LineChartBarData(
                              spots: dailyData.entries.map((entry) {
                                final dayIndex = entry.key.day - 1;
                                return FlSpot(dayIndex.toDouble(), entry.value['expense'] ?? 0);
                              }).toList(),
                              isCurved: true,
                              color: AppColors.expense,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: '€', decimalDigits: 0).format(amount.abs()),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

