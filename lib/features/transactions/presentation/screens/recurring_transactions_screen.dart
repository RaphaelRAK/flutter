import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../infrastructure/db/drift_database.dart';
import '../../../../../core/widgets/main_bottom_nav_bar.dart';
import '../../../../../domain/models/recurrence_frequency.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringRulesAsync = ref.watch(recurringRulesStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions récurrentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/add-recurring-transaction');
            },
          ),
        ],
      ),
      body: recurringRulesAsync.when(
        data: (rules) {
          if (rules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune transaction récurrente',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez une transaction récurrente pour\nautomatiser vos revenus et dépenses',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return _buildRecurringRuleCard(context, ref, rule, accountsAsync, categoriesAsync);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildRecurringRuleCard(
    BuildContext context,
    WidgetRef ref,
    RecurringRule rule,
    AsyncValue<List<Account>> accountsAsync,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '€');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: rule.type == 'income' 
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          child: Icon(
            rule.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
            color: rule.type == 'income' ? Colors.green : Colors.red,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                currencyFormat.format(rule.amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: rule.type == 'income' ? Colors.green : Colors.red,
                ),
              ),
            ),
            Switch(
              value: rule.isActive,
              onChanged: (value) {
                ref.read(recurringRulesDaoProvider).toggleRecurringRule(rule.id, value);
              },
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.account_balance_wallet,
              accountsAsync.when(
                data: (accounts) => accounts.firstWhere(
                  (a) => a.id == rule.accountId,
                  orElse: () => accounts.first,
                ).name,
                loading: () => '...',
                error: (_, __) => 'Compte inconnu',
              ),
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.category,
              categoriesAsync.when(
                data: (categories) => categories.firstWhere(
                  (c) => c.id == rule.categoryId,
                  orElse: () => categories.first,
                ).name,
                loading: () => '...',
                error: (_, __) => 'Catégorie inconnue',
              ),
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.repeat,
              _getFrequencyLabel(rule.frequency),
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.calendar_today,
              'Début: ${dateFormat.format(rule.startDate)}',
            ),
            if (rule.endDate != null)
              _buildInfoRow(
                Icons.event_busy,
                'Fin: ${dateFormat.format(rule.endDate!)}',
              ),
            if (rule.lastExecutionDate != null)
              _buildInfoRow(
                Icons.check_circle,
                'Dernière exécution: ${dateFormat.format(rule.lastExecutionDate!)}',
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteConfirmation(context, ref, rule);
            } else if (value == 'edit') {
              context.push('/add-recurring-transaction', extra: rule);
            }
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      case 'yearly':
        return 'Annuel';
      case 'custom':
        return 'Personnalisé';
      default:
        return frequency;
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, RecurringRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la transaction récurrente'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette transaction récurrente ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(recurringRulesDaoProvider).deleteRecurringRule(rule.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction récurrente supprimée')),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

