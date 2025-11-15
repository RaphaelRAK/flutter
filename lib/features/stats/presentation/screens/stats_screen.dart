import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../infrastructure/db/drift_database.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/main_bottom_nav_bar.dart';
import '../../../../../core/utils/category_icons.dart';
import '../../../transactions/presentation/widgets/transaction_detail_dialog.dart';
import '../../../accounts/presentation/screens/accounts_screen.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _chartTypeController;
  String _selectedPeriod = 'monthly'; // 'daily', 'weekly', 'monthly', 'yearly', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _selectedDataType = 'expense'; // 'expense', 'income', 'both'
  Set<int> _selectedAccountIds = {}; // Filtre par comptes
  int? _selectedPieSectionIndex; // Pour l'interaction avec le camembert
  String _chartView = 'pie'; // 'pie', 'bar', 'line'
  String _sortBy = 'amount'; // 'amount', 'name', 'count'

  @override
  void initState() {
    super.initState();
    _chartTypeController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _chartTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesDaoProvider).getAllCategories();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _showPeriodSelector(context),
          tooltip: 'Période',
        ),
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, accountsAsync),
            tooltip: 'Filtres',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _exportStats(context, transactionsAsync),
            tooltip: 'Partager',
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 1),
      body: settingsAsync.when(
        data: (settings) => transactionsAsync.when(
          data: (transactions) => FutureBuilder<List<Category>>(
            future: categoriesAsync,
            builder: (context, categoriesSnapshot) {
              if (!categoriesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildContent(
                context,
                transactions,
                settings,
                categoriesSnapshot.data!,
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Transaction> transactions,
    dynamic settings,
    List<Category> categories,
  ) {
    final filteredTransactions = _filterTransactions(transactions);
    final categoryData = _calculateCategoryData(filteredTransactions, categories);
    final currency = settings.currency;
    final currencyFormat = NumberFormat.currency(symbol: _getCurrencySymbol(currency));

    // Calculer les totaux
    double totalExpenses = 0.0;
    double totalIncome = 0.0;
    for (final transaction in filteredTransactions) {
      if (transaction.type == 'expense') {
        totalExpenses += transaction.amount;
      } else if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      }
    }
    final netTotal = totalIncome - totalExpenses;

    return Column(
      children: [
        // Totaux (plus compacts)
        _buildTotalsCard(context, totalExpenses, totalIncome, netTotal, currencyFormat),
        
        // Sélecteur de type (Dépenses/Revenus/Les deux)
        _buildDataTypeSelector(context),
        
        // Graphiques
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Graphique principal
                  _buildMainChart(
                    context,
                    categoryData,
                    filteredTransactions,
                    currencyFormat,
                    categories,
                  ),
                  const SizedBox(height: 16),
                  
                  // Sélecteur de type de graphique (horizontal scrollable)
                  _buildChartTypeSelector(context),
                  const SizedBox(height: 16),
                  
                  // Liste des catégories avec barres de progression
                  _buildCategoryList(
                    context,
                    categoryData,
                    filteredTransactions,
                    currencyFormat,
                    categories,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsCard(
    BuildContext context,
    double expenses,
    double income,
    double net,
    NumberFormat currencyFormat,
  ) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: _buildTotalItem(
                'Dépenses',
                expenses,
                AppColors.expense,
                Icons.trending_down,
                currencyFormat,
              ),
            ),
            Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.3)),
            Expanded(
              child: _buildTotalItem(
                'Revenus',
                income,
                AppColors.income,
                Icons.trending_up,
                currencyFormat,
              ),
            ),
            Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.3)),
            Expanded(
              child: _buildTotalItem(
                'Net',
                net,
                net >= 0 ? AppColors.income : AppColors.expense,
                Icons.account_balance_wallet,
                currencyFormat,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildDataTypeSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'expense',
            label: Text('Dépenses'),
            icon: Icon(Icons.trending_down, size: 16),
          ),
          ButtonSegment(
            value: 'income',
            label: Text('Revenus'),
            icon: Icon(Icons.trending_up, size: 16),
          ),
          ButtonSegment(
            value: 'both',
            label: Text('Les deux'),
            icon: Icon(Icons.compare_arrows, size: 16),
          ),
        ],
        selected: {_selectedDataType},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() {
            _selectedDataType = newSelection.first;
            _selectedPieSectionIndex = null; // Réinitialiser la sélection
          });
        },
      ),
    );
  }

  Widget _buildChartTypeSelector(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildChartTypeChip('pie', 'Camembert', Icons.pie_chart),
          const SizedBox(width: 8),
          _buildChartTypeChip('bar', 'Barres', Icons.bar_chart),
          const SizedBox(width: 8),
          _buildChartTypeChip('line', 'Ligne', Icons.show_chart),
        ],
      ),
    );
  }

  Widget _buildChartTypeChip(String type, String label, IconData icon) {
    final isSelected = _chartView == type;
    return InkWell(
      onTap: () {
        setState(() {
          _chartView = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentSecondary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accentSecondary
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.accentSecondary
                  : AppColors.darkTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.accentSecondary
                    : AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPeriodSelector(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionner la période',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPeriodChip('daily', 'Jour'),
                _buildPeriodChip('weekly', 'Semaine'),
                _buildPeriodChip('monthly', 'Mois'),
                _buildPeriodChip('yearly', 'Année'),
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
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _customStartDate != null
                            ? DateFormat('dd/MM/yyyy').format(_customStartDate!)
                            : 'Date début',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, isStart: false),
                      icon: const Icon(Icons.calendar_today, size: 18),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Appliquer'),
              ),
            ),
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
      selectedColor: AppColors.accentSecondary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.accentSecondary,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = period;
        });
      },
    );
  }

  Widget _buildMainChart(
    BuildContext context,
    Map<int, CategoryData> categoryData,
    List<Transaction> transactions,
    NumberFormat currencyFormat,
    List<Category> categories,
  ) {
    switch (_chartView) {
      case 'pie':
        return _buildPieChart(context, categoryData, currencyFormat, categories);
      case 'bar':
        return _buildBarChart(context, transactions, currencyFormat);
      case 'line':
        return _buildLineChart(context, transactions, currencyFormat);
      default:
        return _buildPieChart(context, categoryData, currencyFormat, categories);
    }
  }

  Widget _buildPieChart(
    BuildContext context,
    Map<int, CategoryData> categoryData,
    NumberFormat currencyFormat,
    List<Category> categories,
  ) {
    if (categoryData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.pie_chart, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Aucune donnée disponible',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final total = categoryData.values.fold<double>(
      0.0,
      (sum, data) => sum + data.amount,
    );

    // Utiliser les couleurs des catégories depuis la DB
    int colorIndex = 0;
    final sections = categoryData.entries.map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => categories.first,
      );
      final data = entry.value;
      final percentage = (data.amount / total * 100);
      final categoryColor = _getCategoryColor(category.color);
      final isSelected = _selectedPieSectionIndex == colorIndex;
      colorIndex++;

      return PieChartSectionData(
        value: data.amount,
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        color: categoryColor,
        radius: isSelected ? 110 : 100,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getContrastColor(categoryColor),
        ),
        badgeWidget: percentage > 5
            ? null
            : Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getContrastColor(categoryColor),
                  ),
                ),
              ),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _selectedDataType == 'expense'
                  ? 'Dépenses par catégorie'
                  : _selectedDataType == 'income'
                      ? 'Revenus par catégorie'
                      : 'Répartition globale',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 45,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                          final touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                          _selectedPieSectionIndex = _selectedPieSectionIndex == touchedIndex
                              ? null
                              : touchedIndex;
                        } else if (event is FlTapUpEvent) {
                          _selectedPieSectionIndex = null;
                        }
                      });
                    },
                  ),
                  startDegreeOffset: -90,
                ),
              ),
            ),
            if (_selectedPieSectionIndex != null) ...[
              const SizedBox(height: 16),
              _buildSelectedCategoryDetails(
                categoryData.entries.elementAt(_selectedPieSectionIndex!),
                currencyFormat,
                categories,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    List<Transaction> transactions,
    NumberFormat currencyFormat,
  ) {
    // Grouper par jour
    final dailyData = <DateTime, Map<String, double>>{};
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyData.putIfAbsent(date, () => {'expense': 0.0, 'income': 0.0});
      if (transaction.type == 'expense') {
        dailyData[date]!['expense'] =
            (dailyData[date]!['expense'] ?? 0) + transaction.amount;
      } else if (transaction.type == 'income') {
        dailyData[date]!['income'] =
            (dailyData[date]!['income'] ?? 0) + transaction.amount;
      }
    }

    final sortedDates = dailyData.keys.toList()..sort();
    final maxValue = dailyData.values
        .fold<double>(0.0, (max, data) => (data['expense']! + data['income']!) > max
            ? (data['expense']! + data['income']!)
            : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution quotidienne',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < sortedDates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('d/M').format(sortedDates[value.toInt()]),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
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
                  barGroups: sortedDates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final date = entry.value;
                    final data = dailyData[date]!;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        if (_selectedDataType == 'expense' || _selectedDataType == 'both')
                          BarChartRodData(
                            toY: data['expense']!,
                            color: AppColors.expense,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxValue * 1.2,
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                          ),
                        if (_selectedDataType == 'income' || _selectedDataType == 'both')
                          BarChartRodData(
                            toY: data['income']!,
                            color: AppColors.income,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxValue * 1.2,
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
    BuildContext context,
    List<Transaction> transactions,
    NumberFormat currencyFormat,
  ) {
    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.show_chart, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Aucune donnée disponible',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Grouper par jour
    final dailyData = <DateTime, Map<String, double>>{};
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyData.putIfAbsent(date, () => {'expense': 0.0, 'income': 0.0});
      if (transaction.type == 'expense') {
        dailyData[date]!['expense'] =
            (dailyData[date]!['expense'] ?? 0) + transaction.amount;
      } else if (transaction.type == 'income') {
        dailyData[date]!['income'] =
            (dailyData[date]!['income'] ?? 0) + transaction.amount;
      }
    }

    final sortedDates = dailyData.keys.toList()..sort();
    if (sortedDates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Text(
              'Aucune donnée disponible',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final maxValue = dailyData.values
        .fold<double>(0.0, (max, data) => (data['expense']! + data['income']!) > max
            ? (data['expense']! + data['income']!)
            : max);

    final expenseSpots = sortedDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      return FlSpot(index.toDouble(), dailyData[date]!['expense']!);
    }).toList();

    final incomeSpots = sortedDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      return FlSpot(index.toDouble(), dailyData[date]!['income']!);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution dans le temps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue > 0 ? maxValue / 5 : 100,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                            final date = sortedDates[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('d/M').format(date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (maxValue > 0) {
                            return Text(
                              '${(value / 1000).toStringAsFixed(1)}k',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
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
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  minX: 0,
                  maxX: (sortedDates.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxValue * 1.2,
                  lineBarsData: [
                    if (_selectedDataType == 'expense' || _selectedDataType == 'both')
                      LineChartBarData(
                        spots: expenseSpots,
                        isCurved: true,
                        color: AppColors.expense,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: sortedDates.length <= 15,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.expense,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.expense.withValues(alpha: 0.3),
                              AppColors.expense.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    if (_selectedDataType == 'income' || _selectedDataType == 'both')
                      LineChartBarData(
                        spots: incomeSpots,
                        isCurved: true,
                        color: AppColors.income,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: sortedDates.length <= 15,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.income,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.income.withValues(alpha: 0.3),
                              AppColors.income.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    Map<int, CategoryData> categoryData,
    List<Transaction> transactions,
    NumberFormat currencyFormat,
    List<Category> categories,
  ) {
    if (categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Tri amélioré selon le critère sélectionné
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) {
        switch (_sortBy) {
          case 'name':
            final categoryA = categories.firstWhere(
              (c) => c.id == a.key,
              orElse: () => categories.first,
            );
            final categoryB = categories.firstWhere(
              (c) => c.id == b.key,
              orElse: () => categories.first,
            );
            return categoryA.name.compareTo(categoryB.name);
          case 'count':
            return b.value.transactionCount.compareTo(a.value.transactionCount);
          case 'amount':
          default:
            return b.value.amount.compareTo(a.value.amount);
        }
      });
    final total = categoryData.values.fold<double>(
      0.0,
      (sum, data) => sum + data.amount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Détails par catégorie',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort, size: 20),
                    tooltip: 'Trier',
                    onSelected: (value) {
                      setState(() {
                        _sortBy = value;
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'amount',
                        child: Row(
                          children: [
                            Icon(
                              _sortBy == 'amount' ? Icons.check : null,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('Par montant'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'name',
                        child: Row(
                          children: [
                            Icon(
                              _sortBy == 'name' ? Icons.check : null,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('Par nom'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'count',
                        child: Row(
                          children: [
                            Icon(
                              _sortBy == 'count' ? Icons.check : null,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text('Par nombre'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${sortedCategories.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...sortedCategories.map((entry) {
          final categoryId = entry.key;
          final data = entry.value;
          final category = categories.firstWhere(
            (c) => c.id == categoryId,
            orElse: () => categories.first,
          );
          final percentage = (data.amount / total * 100);
          final categoryTransactions = transactions
              .where((t) => t.categoryId == categoryId)
              .toList();

          // Obtenir l'icône de la catégorie
          final categoryIcon = CategoryIcons.getCategoryIcon(category.name, category.icon);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _showCategoryDetails(
                context,
                category,
                categoryTransactions,
                data.amount,
                currencyFormat,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category.color)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            categoryIcon,
                            color: _getCategoryColor(category.color),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${categoryTransactions.length} transaction${categoryTransactions.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(data.amount),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _selectedDataType == 'expense'
                                    ? AppColors.expense
                                    : AppColors.income,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (_selectedDataType == 'expense'
                                        ? AppColors.expense
                                        : AppColors.income)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedDataType == 'expense'
                                      ? AppColors.expense
                                      : AppColors.income,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 4,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _selectedDataType == 'expense'
                              ? AppColors.expense
                              : AppColors.income,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getCategoryColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return AppColors.accentSecondary;
    }
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.accentSecondary;
    }
  }

  Color _getContrastColor(Color color) {
    // Calculer la luminosité pour déterminer si on utilise blanc ou noir
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildSelectedCategoryDetails(
    MapEntry<int, CategoryData> entry,
    NumberFormat currencyFormat,
    List<Category> categories,
  ) {
    final category = categories.firstWhere(
      (c) => c.id == entry.key,
      orElse: () => categories.first,
    );
    final categoryIcon = CategoryIcons.getCategoryIcon(category.name, category.icon);
    
    return Card(
      color: _getCategoryColor(category.color).withValues(alpha: 0.1),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getCategoryColor(category.color).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            categoryIcon,
            color: _getCategoryColor(category.color),
            size: 24,
          ),
        ),
        title: Text(category.name),
        subtitle: Text('${entry.value.transactionCount} transactions'),
        trailing: Text(
          currencyFormat.format(entry.value.amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getCategoryColor(category.color),
          ),
        ),
      ),
    );
  }

  Future<void> _showCategoryDetails(
    BuildContext context,
    Category category,
    List<Transaction> transactions,
    double total,
    NumberFormat currencyFormat,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        category.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currencyFormat.format(total),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  // Vérifier si on a un logo de service connu
                  final serviceIcon = CategoryIcons.getServiceIcon(transaction.description);
                  
                  return ListTile(
                    leading: serviceIcon ??
                        CircleAvatar(
                          backgroundColor: AppColors.accentSecondary.withValues(alpha: 0.2),
                          child: Icon(
                            transaction.type == 'expense'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: transaction.type == 'expense'
                                ? AppColors.expense
                                : AppColors.income,
                          ),
                        ),
                    title: Text(
                      transaction.description ?? 'Sans description',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(DateFormat('d MMM yyyy à HH:mm', 'fr_FR')
                        .format(transaction.date)),
                    trailing: Text(
                      currencyFormat.format(transaction.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transaction.type == 'expense'
                            ? AppColors.expense
                            : AppColors.income,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) =>
                            TransactionDetailDialog(transaction: transaction),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterDialog(
    BuildContext context,
    AsyncValue<List<Account>> accountsAsync,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Filtrer par compte'),
              const SizedBox(height: 16),
              accountsAsync.when(
                data: (accounts) => Column(
                  children: accounts.map((account) {
                    final isSelected = _selectedAccountIds.contains(account.id);
                    return CheckboxListTile(
                      title: Text(account.name),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedAccountIds.add(account.id);
                          } else {
                            _selectedAccountIds.remove(account.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erreur: $e'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedAccountIds.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Réinitialiser'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportStats(
    BuildContext context,
    AsyncValue<List<Transaction>> transactionsAsync,
  ) async {
    transactionsAsync.whenData((transactions) async {
      final filtered = _filterTransactions(transactions);
      final buffer = StringBuffer();
      buffer.writeln('Date,Type,Catégorie,Montant,Description');

      for (final transaction in filtered) {
        buffer.writeln(
          '${DateFormat('yyyy-MM-dd').format(transaction.date)},'
          '${transaction.type},'
          'Catégorie ${transaction.categoryId},'
          '${transaction.amount},'
          '"${transaction.description ?? ''}"',
        );
      }

      await Share.share(
        buffer.toString(),
        subject: 'Export statistiques ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
      );
    });
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

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_selectedPeriod) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'weekly':
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59));
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
      // Filtre par type
      if (_selectedDataType == 'expense' && t.type != 'expense') return false;
      if (_selectedDataType == 'income' && t.type != 'income') return false;
      if (_selectedDataType == 'both' && t.type == 'transfer') return false;

      // Filtre par date
      if (!t.date.isAfter(startDate.subtract(const Duration(days: 1))) ||
          !t.date.isBefore(endDate.add(const Duration(days: 1)))) {
        return false;
      }

      // Filtre par compte
      if (_selectedAccountIds.isNotEmpty &&
          !_selectedAccountIds.contains(t.accountId)) {
        return false;
      }

      return true;
    }).toList();
  }

  Map<int, CategoryData> _calculateCategoryData(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final Map<int, CategoryData> categoryData = {};

    for (final transaction in transactions) {
      final categoryId = transaction.categoryId;
      if (!categoryData.containsKey(categoryId)) {
        categoryData[categoryId] = CategoryData(amount: 0.0, transactionCount: 0);
      }
      categoryData[categoryId]!.amount += transaction.amount;
      categoryData[categoryId]!.transactionCount += 1;
    }

    return categoryData;
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

class CategoryData {
  double amount;
  int transactionCount;

  CategoryData({required this.amount, required this.transactionCount});
}
