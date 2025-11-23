import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

class TransactionsTotalView extends ConsumerStatefulWidget {
  const TransactionsTotalView({super.key});

  @override
  ConsumerState<TransactionsTotalView> createState() => _TransactionsTotalViewState();
}

class _TransactionsTotalViewState extends ConsumerState<TransactionsTotalView> {
  int? _touchedExpenseIndex;
  int? _touchedIncomeIndex;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(filteredTransactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return transactionsAsync.when(
      data: (transactions) {
        return categoriesAsync.when(
          data: (categories) {
            // Créer une Map pour associer categoryId -> nom de catégorie
            final categoryMap = {
              for (var category in categories) category.id: category.name
            };

            // Calculer les totaux globaux
            double totalIncome = 0.0;
            double totalExpense = 0.0;
            double totalTransfers = 0.0;
            int transactionCount = transactions.length;

            Map<String, double> expensesByCategory = {};
            Map<String, double> incomeByCategory = {};

            for (final transaction in transactions) {
              // Récupérer le nom de la catégorie depuis la Map
              final categoryName = categoryMap[transaction.categoryId] ?? 'Sans catégorie';

              if (transaction.type == 'income') {
                totalIncome += transaction.amount;
                incomeByCategory[categoryName] =
                    (incomeByCategory[categoryName] ?? 0) + transaction.amount;
              } else if (transaction.type == 'expense') {
                totalExpense += transaction.amount;
                expensesByCategory[categoryName] =
                    (expensesByCategory[categoryName] ?? 0) + transaction.amount;
              } else if (transaction.type == 'transfer') {
                totalTransfers += transaction.amount;
              }
            }

            final balance = totalIncome - totalExpense;

            return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // En-tête avec titre
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Résumé global',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _exportToExcel(context, transactions),
                      tooltip: 'Exporter vers Excel',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Statistiques principales
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Revenus totaux',
                    totalIncome,
                    AppColors.income,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Dépenses totales',
                    totalExpense,
                    AppColors.expense,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Solde net',
                    balance,
                    balance >= 0 ? AppColors.income : AppColors.expense,
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Transactions',
                    transactionCount.toDouble(),
                    AppColors.accentSecondary,
                    Icons.receipt_long,
                    isCount: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Graphique circulaire des dépenses
            if (expensesByCategory.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Répartition des dépenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _buildPieChartSections(
                              expensesByCategory,
                              _touchedExpenseIndex,
                            ),
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    return; // Ne pas réinitialiser, garder la sélection
                                  }
                                  final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  if (index >= 0 && index < expensesByCategory.length) {
                                    _touchedExpenseIndex = index;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      if (_touchedExpenseIndex != null && 
                          _touchedExpenseIndex! >= 0 && 
                          _touchedExpenseIndex! < expensesByCategory.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  expensesByCategory.keys.elementAt(_touchedExpenseIndex!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(expensesByCategory.values.elementAt(_touchedExpenseIndex!))} / ${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(expensesByCategory.values.fold(0.0, (a, b) => a + b))}',
                                  style: Theme.of(context).textTheme.bodyMedium,
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
            // Graphique circulaire des revenus
            if (incomeByCategory.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Répartition des revenus',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _buildPieChartSections(
                              incomeByCategory,
                              _touchedIncomeIndex,
                            ),
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    return; // Ne pas réinitialiser, garder la sélection
                                  }
                                  final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  if (index >= 0 && index < incomeByCategory.length) {
                                    _touchedIncomeIndex = index;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      if (_touchedIncomeIndex != null && 
                          _touchedIncomeIndex! >= 0 && 
                          _touchedIncomeIndex! < incomeByCategory.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  incomeByCategory.keys.elementAt(_touchedIncomeIndex!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(incomeByCategory.values.elementAt(_touchedIncomeIndex!))} / ${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(incomeByCategory.values.fold(0.0, (a, b) => a + b))}',
                                  style: Theme.of(context).textTheme.bodyMedium,
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
            // Informations supplémentaires
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Moyenne mensuelle (revenus)',
                      NumberFormat.currency(symbol: '€', decimalDigits: 2)
                          .format(totalIncome / 12),
                      Icons.calendar_month,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Moyenne mensuelle (dépenses)',
                      NumberFormat.currency(symbol: '€', decimalDigits: 2)
                          .format(totalExpense / 12),
                      Icons.calendar_month,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Transferts totaux',
                      NumberFormat.currency(symbol: '€', decimalDigits: 2)
                          .format(totalTransfers),
                      Icons.swap_horiz,
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
            child: Text('Erreur catégories: $error'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erreur transactions: $error'),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    double value,
    Color color,
    IconData icon, {
    bool isCount = false,
  }) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isCount
                  ? value.toInt().toString()
                  : NumberFormat.currency(symbol: '€', decimalDigits: 0)
                      .format(value.abs()),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
      Map<String, double> dataByCategory, int? touchedIndex) {
    final total = dataByCategory.values.fold(0.0, (a, b) => a + b);
    final colors = [
      AppColors.expense,
      AppColors.income,
      AppColors.accentSecondary,
      AppColors.transfer,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    int colorIndex = 0;
    return dataByCategory.entries.map((entry) {
      final index = colorIndex;
      final percentage = (entry.value / total * 100);
      final color = colors[colorIndex % colors.length];
      final isTouched = index == touchedIndex;
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: isTouched ? 70 : 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.darkTextSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkTextSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _exportToExcel(
      BuildContext context, List<Transaction> transactions) async {
    // Créer un CSV simple
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Montant,Description');

    for (final transaction in transactions) {
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction.date)},'
        '${transaction.type},'
        '${transaction.amount},'
        '"${transaction.description ?? ''}"',
      );
    }

    // Partager le fichier
    await Share.share(
      buffer.toString(),
      subject: 'Export transactions ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
    );
  }
}

