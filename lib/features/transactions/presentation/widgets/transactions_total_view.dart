import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

class TransactionsTotalView extends ConsumerWidget {
  const TransactionsTotalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsStreamProvider);

    return transactionsAsync.when(
      data: (transactions) {
        // Calculer les totaux globaux
        double totalIncome = 0.0;
        double totalExpense = 0.0;
        double totalTransfers = 0.0;
        int transactionCount = transactions.length;

        Map<String, double> expensesByCategory = {};
        Map<String, double> incomeByCategory = {};

        for (final transaction in transactions) {
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
                            sections: _buildPieChartSections(expensesByCategory),
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
                            sections: _buildPieChartSections(incomeByCategory),
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
        child: Text('Erreur: $error'),
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
      Map<String, double> dataByCategory) {
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
      final percentage = (entry.value / total * 100);
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 60,
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

