import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../core/theme/app_colors.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _selectedPeriod = 'monthly'; // 'weekly', 'monthly', 'yearly', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _showExpenses = true; // true pour dépenses, false pour revenus

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            icon: Icon(_showExpenses ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() {
                _showExpenses = !_showExpenses;
              });
            },
            tooltip: _showExpenses ? 'Voir revenus' : 'Voir dépenses',
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
    final filteredTransactions = _filterTransactions(transactions);
    final categoryData = _calculateCategoryData(filteredTransactions);
    final currency = settings.currency;
    final currencyFormat = NumberFormat.currency(symbol: _getCurrencySymbol(currency));

    return Column(
      children: [
        // Sélecteur de période
        _buildPeriodSelector(context),
        
        // Graphique camembert
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          _showExpenses ? 'Dépenses par catégorie' : 'Revenus par catégorie',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: categoryData.isEmpty
                              ? Center(
                                  child: Text(
                                    'Aucune donnée disponible',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                )
                              : PieChart(
                                  PieChartData(
                                    sections: _buildPieChartSections(categoryData, currencyFormat),
                                    centerSpaceRadius: 60,
                                    sectionsSpace: 2,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Liste des catégories avec détails
                ...categoryData.entries.map((data) => _buildCategoryCard(
                      context,
                      data,
                      currencyFormat,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildPeriodChip('weekly', 'Hebdomadaire'),
                _buildPeriodChip('monthly', 'Mensuel'),
                _buildPeriodChip('yearly', 'Annuel'),
                _buildPeriodChip('custom', 'Personnalisée'),
              ],
            ),
            if (_selectedPeriod == 'custom') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, isStart: true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _customStartDate != null
                            ? DateFormat('dd/MM/yyyy').format(_customStartDate!)
                            : 'Date début',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, isStart: false),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _customEndDate != null
                            ? DateFormat('dd/MM/yyyy').format(_customEndDate!)
                            : 'Date fin',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = period;
        });
      },
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_customStartDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_customEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _customStartDate = date;
        } else {
          _customEndDate = date;
        }
      });
    }
  }

  List<dynamic> _filterTransactions(List transactions) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_selectedPeriod) {
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'custom':
        if (_customStartDate == null || _customEndDate == null) {
          return [];
        }
        startDate = _customStartDate!;
        endDate = _customEndDate!.add(const Duration(days: 1));
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    return transactions.where((t) {
      final transactionType = _showExpenses ? 'expense' : 'income';
      return t.type == transactionType &&
          t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Map<int, double> _calculateCategoryData(List transactions) {
    final Map<int, double> categoryTotals = {};
    double total = 0.0;

    for (final transaction in transactions) {
      final categoryId = transaction.categoryId;
      final amount = transaction.amount;
      categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0.0) + amount;
      total += amount;
    }

    return categoryTotals;
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<int, double> categoryData,
    NumberFormat currencyFormat,
  ) {
    if (categoryData.isEmpty) return [];

    final total = categoryData.values.reduce((a, b) => a + b);
    final colors = [
      AppColors.expense,
      AppColors.accentSecondary,
      AppColors.accentPrimary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    int colorIndex = 0;
    return categoryData.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryCard(
    BuildContext context,
    MapEntry<int, double> data,
    NumberFormat currencyFormat,
  ) {
    final total = data.value;
    // TODO: Récupérer le nom de la catégorie depuis la base de données
    final categoryName = 'Catégorie ${data.key}';
    final transactionsAsync = ref.read(transactionsStreamProvider);
    final allTransactions = transactionsAsync.value ?? [];
    final categoryTransactions = allTransactions
        .where((t) => t.categoryId == data.key)
        .toList();
    final totalAll = categoryTransactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );
    final percentage = totalAll > 0 ? (total / totalAll * 100) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accentSecondary.withValues(alpha: 0.2),
          child: Text(
            categoryName[0].toUpperCase(),
            style: TextStyle(
              color: AppColors.accentSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(categoryName),
        subtitle: Text('${percentage.toStringAsFixed(1)}% du total'),
        trailing: Text(
          currencyFormat.format(total),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _showExpenses ? AppColors.expense : AppColors.income,
              ),
        ),
        onTap: () {
          // TODO: Naviguer vers le détail de la catégorie
        },
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

