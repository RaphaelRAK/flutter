import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../infrastructure/db/drift_database.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/models/account_type.dart';
import '../../../../../core/widgets/main_bottom_nav_bar.dart';

final accountsStreamProvider = StreamProvider((ref) {
  return ref.watch(accountsDaoProvider).watchAllAccounts();
});

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comptes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAccountDialog(context),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 2),
      body: settingsAsync.when(
        data: (settings) => accountsAsync.when(
          data: (accounts) => _buildContent(context, accounts, settings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List accounts, dynamic settings) {
    final currency = settings.currency;
    final currencyFormat = NumberFormat.currency(symbol: _getCurrencySymbol(currency));

    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun compte',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre premier compte',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddAccountDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un compte'),
            ),
          ],
        ),
      );
    }

    return ReorderableListView(
      padding: const EdgeInsets.all(16),
      onReorder: (oldIndex, newIndex) {
        // TODO: Implémenter la réorganisation des comptes
        // Cela nécessiterait un champ 'order' dans la table Accounts
      },
      children: [
        // Total des actifs
        Card(
          key: const ValueKey('total'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total des actifs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                FutureBuilder<double>(
                  future: ref.read(accountsDaoProvider).getTotalBalance(),
                  builder: (context, snapshot) {
                    final total = snapshot.data ?? 0.0;
                    return Text(
                      currencyFormat.format(total),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentSecondary,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Liste des comptes
        ...accounts.asMap().entries.map((entry) {
          final account = entry.value;
          return _buildAccountCard(
            context,
            account,
            currencyFormat,
            entry.key,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    dynamic account,
    NumberFormat currencyFormat,
    int index,
  ) {
    return Card(
      key: ValueKey(account.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAccountTypeColor(account.type).withValues(alpha: 0.2),
          child: Icon(
            _getAccountTypeIcon(account.type),
            color: _getAccountTypeColor(account.type),
          ),
        ),
        title: Text(account.name),
        subtitle: Text(_getAccountTypeLabel(account.type)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormat.format(account.initialBalance),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleAccountAction(context, account, value),
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
                const PopupMenuItem(
                  value: 'hide',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_off, size: 20),
                      SizedBox(width: 8),
                      Text('Cacher'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'transfer',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 20),
                      SizedBox(width: 8),
                      Text('Transfer as Expense'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'exclude',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 20),
                      SizedBox(width: 8),
                      Text('Exclure du total'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showAccountDetails(context, account),
      ),
    );
  }

  IconData _getAccountTypeIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'credit':
        return Icons.credit_card;
      case 'loan':
        return Icons.receipt_long;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getAccountTypeColor(String type) {
    switch (type) {
      case 'bank':
        return AppColors.accentSecondary;
      case 'cash':
        return AppColors.accentPrimary;
      case 'wallet':
        return Colors.orange;
      case 'credit':
        return Colors.purple;
      case 'loan':
        return AppColors.error;
      default:
        return AppColors.accentSecondary;
    }
  }

  String _getAccountTypeLabel(String type) {
    switch (type) {
      case 'bank':
        return 'Banque';
      case 'cash':
        return 'Espèces';
      case 'wallet':
        return 'Portefeuille';
      case 'credit':
        return 'Carte de crédit';
      case 'loan':
        return 'Prêt';
      default:
        return type;
    }
  }

  void _handleAccountAction(BuildContext context, dynamic account, String action) {
    switch (action) {
      case 'edit':
        _showEditAccountDialog(context, account);
        break;
      case 'hide':
        _hideAccount(account);
        break;
      case 'transfer':
        _showTransferAsExpenseDialog(context, account);
        break;
      case 'exclude':
        _toggleExcludeFromTotal(account);
        break;
      case 'delete':
        _showDeleteConfirmation(context, account);
        break;
    }
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'bank';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un compte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du compte',
                    hintText: 'Ex: Compte courant',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'bank', child: Text('Banque')),
                    DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                    DropdownMenuItem(value: 'wallet', child: Text('Portefeuille')),
                    DropdownMenuItem(value: 'credit', child: Text('Carte de crédit')),
                    DropdownMenuItem(value: 'loan', child: Text('Prêt')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value ?? 'bank';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Solde initial',
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text) ?? 0.0;
                if (name.isNotEmpty) {
                  _addAccount(name, selectedType, balance);
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAccountDialog(BuildContext context, dynamic account) {
    final nameController = TextEditingController(text: account.name);
    final balanceController = TextEditingController(text: account.initialBalance.toString());
    String selectedType = account.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le compte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom du compte'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'bank', child: Text('Banque')),
                    DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                    DropdownMenuItem(value: 'wallet', child: Text('Portefeuille')),
                    DropdownMenuItem(value: 'credit', child: Text('Carte de crédit')),
                    DropdownMenuItem(value: 'loan', child: Text('Prêt')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value ?? 'bank';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: balanceController,
                  decoration: const InputDecoration(labelText: 'Solde initial'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text) ?? 0.0;
                if (name.isNotEmpty) {
                  _updateAccount(account, name, selectedType, balance);
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountDetails(BuildContext context, dynamic account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(account.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getAccountTypeLabel(account.type)}'),
            const SizedBox(height: 8),
            Text('Solde: ${account.initialBalance}'),
            const SizedBox(height: 8),
            Text('Créé le: ${DateFormat('dd/MM/yyyy').format(account.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showTransferAsExpenseDialog(BuildContext context, dynamic account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer as Expense'),
        content: Text(
          'Cette option permet de traiter les transferts depuis "${account.name}" comme des dépenses.\n\n'
          'Utile pour les comptes d\'épargne, assurances, prêts, etc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter la logique "Transfer as Expense"
              // Cela nécessiterait un champ dans Settings ou Accounts
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Option activée pour ce compte')),
              );
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${account.name}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteAccount(account);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAccount(String name, String type, double balance) async {
    try {
      await ref.read(accountsDaoProvider).insertAccount(
            AccountsCompanion(
              name: drift.Value(name),
              type: drift.Value(type),
              initialBalance: drift.Value(balance),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte ajouté avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _updateAccount(
    dynamic account,
    String name,
    String type,
    double balance,
  ) async {
    try {
      await ref.read(accountsDaoProvider).updateAccount(
            AccountsCompanion(
              id: drift.Value(account.id),
              name: drift.Value(name),
              type: drift.Value(type),
              initialBalance: drift.Value(balance),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte modifié avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _hideAccount(dynamic account) async {
    try {
      await ref.read(accountsDaoProvider).updateAccount(
            AccountsCompanion(
              id: drift.Value(account.id),
              archived: const drift.Value(true),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte caché')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount(dynamic account) async {
    try {
      await ref.read(accountsDaoProvider).deleteAccount(account.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte supprimé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _toggleExcludeFromTotal(dynamic account) {
    // TODO: Implémenter l'exclusion du total des actifs
    // Cela nécessiterait un champ 'excludedFromTotal' dans Accounts
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Option à venir')),
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

