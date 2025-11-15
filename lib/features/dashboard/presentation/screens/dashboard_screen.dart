import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flut Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) => transactionsAsync.when(
          data: (transactions) => _buildDashboardContent(context, settings, transactions),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/transactions');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    dynamic settings,
    List<dynamic> transactions,
  ) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Calculer les totaux du mois
    double totalExpenses = 0.0;
    double totalIncome = 0.0;

    for (final transaction in transactions) {
      final date = transaction.date;
      if (date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        if (transaction.type == 'expense') {
          totalExpenses += transaction.amount;
        } else if (transaction.type == 'income') {
          totalIncome += transaction.amount;
        }
      }
    }

    final balance = totalIncome - totalExpenses;
    final currency = settings.currency;
    final currencyFormat = NumberFormat.currency(symbol: _getCurrencySymbol(currency));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solde global
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solde global',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<double>(
                    future: ref.read(accountsDaoProvider).getTotalBalance(),
                    builder: (context, snapshot) {
                      final balance = snapshot.data ?? 0.0;
                      return Text(
                        currencyFormat.format(balance),
                        style: Theme.of(context).textTheme.displayLarge,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Résumé du mois
          Text(
            'Résumé du mois',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revenus',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(totalIncome),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.income,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dépenses',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(totalExpenses),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.expense,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    currencyFormat.format(balance),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: balance >= 0 ? AppColors.income : AppColors.expense,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Dernières transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dernières transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () => context.push('/transactions'),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune transaction',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appuie sur le bouton + pour ajouter ta première transaction',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...transactions.take(5).map((transaction) => _buildTransactionTile(context, transaction, currencyFormat)),
        ],
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
          DateFormat('dd/MM/yyyy').format(transaction.date),
        ),
        trailing: Text(
          '${isExpense ? '-' : '+'}${currencyFormat.format(transaction.amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
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

