import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../infrastructure/db/drift_database.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/main_bottom_nav_bar.dart';
import '../../../../../core/localization/app_localizations.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final assetAccountsAsync = ref.watch(assetAccountsStreamProvider);
    final liabilityAccountsAsync = ref.watch(liabilityAccountsStreamProvider);
    final customAccountsAsync = ref.watch(customAccountsStreamProvider);
    final totalAssetsAsync = ref.watch(totalAssetsProvider);
    final totalLiabilitiesAsync = ref.watch(totalLiabilitiesProvider);
    final netWorthAsync = ref.watch(netWorthProvider);

    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accounts),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAccountDialog(context),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 2),
      body: settingsAsync.when(
        data: (settings) {
          final currency = settings.currency;
          final currencyFormat = NumberFormat.currency(symbol: _getCurrencySymbol(currency));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(totalAssetsProvider);
              ref.invalidate(totalLiabilitiesProvider);
              ref.invalidate(netWorthProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Totaux
                  _buildTotalsSection(
                    context,
                    currencyFormat,
                    totalAssetsAsync,
                    totalLiabilitiesAsync,
                    netWorthAsync,
                  ),
                  const SizedBox(height: 24),

                  // Section Actifs (Assets)
                  _buildSectionHeader(
                    context,
                    l10n.translate('assets'),
                    Icons.account_balance_wallet,
                    AppColors.accentPrimary,
                  ),
                  const SizedBox(height: 12),
                  assetAccountsAsync.when(
                    data: (accounts) => accounts.isEmpty
                        ? _buildEmptySection(context, l10n.translate('no_asset_account'))
                        : _buildAccountsList(context, accounts, currencyFormat, 'asset'),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('${l10n.error}: $error'),
                  ),
                  const SizedBox(height: 24),

                  // Section Passifs (Liabilities)
                  _buildSectionHeader(
                    context,
                    l10n.translate('liabilities_debts'),
                    Icons.receipt_long,
                    AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  liabilityAccountsAsync.when(
                    data: (accounts) => accounts.isEmpty
                        ? _buildEmptySection(context, l10n.translate('no_liability'))
                        : _buildAccountsList(context, accounts, currencyFormat, 'liability'),
          loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('${l10n.error}: $error'),
                  ),
                  const SizedBox(height: 24),

                  // Section Comptes Personnalisés
                  customAccountsAsync.when(
                    data: (accounts) {
                      if (accounts.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            context,
                            l10n.translate('custom_accounts'),
                            Icons.category,
                            AppColors.accentSecondary,
                          ),
                          const SizedBox(height: 12),
                          _buildAccountsList(context, accounts, currencyFormat, 'custom'),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${AppLocalizations.of(context)?.error ?? 'Erreur'}: $error')),
      ),
    );
  }

  Widget _buildTotalsSection(
    BuildContext context,
    NumberFormat currencyFormat,
    AsyncValue<double> totalAssetsAsync,
    AsyncValue<double> totalLiabilitiesAsync,
    AsyncValue<double> netWorthAsync,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('financial_balance'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            // Total Assets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: AppColors.accentPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.translate('total_assets'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                totalAssetsAsync.when(
                  data: (total) => Text(
                    currencyFormat.format(total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentPrimary,
                        ),
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('--'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Total Liabilities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_down, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
            Text(
                      AppLocalizations.of(context)!.translate('total_liabilities'),
                      style: Theme.of(context).textTheme.bodyLarge,
            ),
                  ],
                ),
                totalLiabilitiesAsync.when(
                  data: (total) => Text(
                    currencyFormat.format(total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('--'),
            ),
          ],
        ),
            const Divider(height: 32),
            // Net Worth
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('net_worth'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                netWorthAsync.when(
                  data: (netWorth) {
                    final isPositive = netWorth >= 0;
                    return Text(
                      currencyFormat.format(netWorth.abs()),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? AppColors.accentPrimary : AppColors.error,
                          ),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('--'),
                ),
              ],
            ),
          ],
          ),
        ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ),
    );
  }

  Widget _buildAccountsList(
    BuildContext context,
    List<Account> accounts,
    NumberFormat currencyFormat,
    String category,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (accounts.isEmpty) {
      return _buildEmptySection(context, l10n.translate('no_account'));
    }

    return Column(
      children: accounts.map((account) {
        return _buildAccountCard(context, account, currencyFormat, category);
      }).toList(),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    Account account,
    NumberFormat currencyFormat,
    String category,
  ) {
    return FutureBuilder<double>(
      future: ref.read(accountsDaoProvider).getAccountBalance(account.id),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? account.initialBalance;
        final isPositive = balance >= 0;
        final isLiability = category == 'liability';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAccountTypeColor(account.type).withValues(alpha: 0.2),
          child: Icon(
                _getAccountIcon(account),
            color: _getAccountTypeColor(account.type),
          ),
        ),
            title: Row(
          children: [
                Expanded(child: Text(account.name)),
                if (account.excludedFromTotal)
                  Icon(
                    Icons.block,
                    size: 16,
                    color: Colors.grey[600],
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text(_getAccountTypeLabel(account.type)),
                if (account.notes != null && account.notes!.isNotEmpty)
                  Text(
                    account.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (isLiability && account.creditLimit != null)
                  Text(
                    '${AppLocalizations.of(context)!.translate('credit_limit')}: ${currencyFormat.format(account.creditLimit)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                Text(
                  currencyFormat.format(balance.abs()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLiability
                            ? AppColors.error
                            : (isPositive ? AppColors.accentPrimary : AppColors.error),
                      ),
                ),
                if (account.currency != null && account.currency!.isNotEmpty)
                  Text(
                    account.currency!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        onTap: () => _showAccountDetails(context, account),
            onLongPress: () => _showAccountOptions(context, account),
      ),
    );
      },
    );
  }

  IconData _getAccountIcon(Account account) {
    if (account.icon != null && account.icon!.isNotEmpty) {
      // Essayer de trouver l'icône par nom
      switch (account.icon) {
        case 'account_balance':
          return Icons.account_balance;
        case 'account_balance_wallet':
          return Icons.account_balance_wallet;
        case 'money':
          return Icons.money;
        case 'credit_card':
          return Icons.credit_card;
        case 'savings':
          return Icons.savings;
        case 'trending_up':
          return Icons.trending_up;
        case 'phone_android':
          return Icons.phone_android;
        default:
          return _getAccountTypeIcon(account.type);
      }
    }
    return _getAccountTypeIcon(account.type);
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
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      case 'mobile_money':
        return Icons.phone_android;
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
      case 'savings':
        return Colors.teal;
      case 'investment':
        return Colors.blue;
      case 'mobile_money':
        return Colors.green;
      default:
        return AppColors.accentSecondary;
    }
  }

  String _getAccountTypeLabel(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'bank':
        return l10n.translate('bank');
      case 'cash':
        return l10n.translate('cash');
      case 'wallet':
        return l10n.translate('wallet');
      case 'credit':
        return l10n.translate('credit_card');
      case 'loan':
        return l10n.translate('loan');
      case 'savings':
        return l10n.translate('savings');
      case 'investment':
        return l10n.translate('investment');
      case 'mobile_money':
        return l10n.translate('mobile_money');
      case 'custom':
        return l10n.translate('custom');
      default:
        return type;
    }
  }

  void _showAccountDetails(BuildContext context, Account account) {
    final l10n = AppLocalizations.of(context)!;
    // TODO: Implémenter l'écran de détails avec graphique et transactions
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(account.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.translate('account_type_label')}: ${_getAccountTypeLabel(account.type)}'),
            const SizedBox(height: 8),
            FutureBuilder<double>(
              future: ref.read(accountsDaoProvider).getAccountBalance(account.id),
              builder: (context, snapshot) {
                final balance = snapshot.data ?? account.initialBalance;
                final settingsAsync = ref.read(settingsStreamProvider);
                return settingsAsync.when(
                  data: (settings) {
                    final currency = settings.currency;
                    final currencyFormat = NumberFormat.currency(symbol: _getCurrencySymbol(currency));
                    return Text('${l10n.translate('balance')}: ${currencyFormat.format(balance)}');
                  },
                  loading: () => Text('${l10n.translate('balance')}: ${NumberFormat.currency(symbol: '€').format(balance)}'),
                  error: (_, __) => Text('${l10n.translate('balance')}: ${NumberFormat.currency(symbol: '€').format(balance)}'),
                );
              },
            ),
            if (account.notes != null && account.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${l10n.translate('notes')}: ${account.notes}'),
            ],
            if (account.creditLimit != null) ...[
              const SizedBox(height: 8),
              FutureBuilder(
                future: ref.read(settingsStreamProvider.future),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final currency = snapshot.data!.currency;
                    final currencyFormat = NumberFormat.currency(symbol: _getCurrencySymbol(currency));
                    return Text('${l10n.translate('credit_limit')}: ${currencyFormat.format(account.creditLimit)}');
                  }
                  return Text('${l10n.translate('credit_limit')}: ${NumberFormat.currency(symbol: '€').format(account.creditLimit)}');
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showAccountOptions(BuildContext context, Account account) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.pop(context);
        _showEditAccountDialog(context, account);
              },
            ),
            ListTile(
              leading: Icon(account.excludedFromTotal ? Icons.check_circle : Icons.circle_outlined),
              title: Text(l10n.translate('exclude_from_total')),
              onTap: () {
                _toggleExcludeFromTotal(account);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(account.transferAsExpense ? Icons.check_circle : Icons.circle_outlined),
              title: Text(l10n.translate('treat_transfers_as_expenses')),
              onTap: () {
                _toggleTransferAsExpense(account);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(account.archived ? Icons.visibility : Icons.visibility_off),
              title: Text(account.archived ? l10n.translate('show') : l10n.translate('hide')),
              onTap: () {
                if (account.archived) {
                  _unhideAccount(account);
                } else {
        _hideAccount(account);
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
        _showDeleteConfirmation(context, account);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'bank';
    String selectedCategory = 'asset';
    String? selectedCurrency;
    String? selectedIcon;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.addAccount),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('account_name'),
                    hintText: l10n.translate('account_name_example'),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(labelText: l10n.translate('account_category')),
                  items: [
                    DropdownMenuItem(value: 'asset', child: Text(l10n.translate('asset'))),
                    DropdownMenuItem(value: 'liability', child: Text(l10n.translate('liability'))),
                    DropdownMenuItem(value: 'custom', child: Text(l10n.translate('custom'))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value ?? 'asset';
                      // Ajuster le type par défaut selon la catégorie
                      if (selectedCategory == 'liability') {
                        selectedType = 'credit';
                      } else if (selectedCategory == 'asset') {
                        selectedType = 'bank';
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: l10n.translate('account_type')),
                  items: _getTypeOptions(selectedCategory, l10n),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value ?? 'bank';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: balanceController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('initial_balance'),
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('notes_optional'),
                    hintText: l10n.translate('account_description'),
                  ),
                  maxLines: 2,
                ),
                if (selectedType == 'credit') ...[
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: l10n.translate('credit_limit_optional'),
                      hintText: '0.00',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text) ?? 0.0;
                if (name.isNotEmpty) {
                  _addAccount(
                    name,
                    selectedType,
                    selectedCategory,
                    balance,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    currency: selectedCurrency,
                    icon: selectedIcon,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getTypeOptions(String category, AppLocalizations l10n) {
    if (category == 'liability') {
      return [
        DropdownMenuItem(value: 'credit', child: Text(l10n.translate('credit_card'))),
        DropdownMenuItem(value: 'loan', child: Text(l10n.translate('loan'))),
      ];
    } else if (category == 'asset') {
      return [
        DropdownMenuItem(value: 'bank', child: Text(l10n.translate('bank'))),
        DropdownMenuItem(value: 'cash', child: Text(l10n.translate('cash'))),
        DropdownMenuItem(value: 'wallet', child: Text(l10n.translate('wallet'))),
        DropdownMenuItem(value: 'savings', child: Text(l10n.translate('savings'))),
        DropdownMenuItem(value: 'investment', child: Text(l10n.translate('investment'))),
        DropdownMenuItem(value: 'mobile_money', child: Text(l10n.translate('mobile_money'))),
      ];
    } else {
      return [
        DropdownMenuItem(value: 'custom', child: Text(l10n.translate('custom'))),
      ];
    }
  }

  void _showEditAccountDialog(BuildContext context, Account account) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: account.name);
    final balanceController = TextEditingController(text: account.initialBalance.toString());
    final notesController = TextEditingController(text: account.notes ?? '');
    String selectedType = account.type;
    String selectedCategory = account.accountCategory;
    String? selectedCurrency = account.currency;
    String? selectedIcon = account.icon;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.translate('edit_account')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.translate('account_name')),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(labelText: l10n.translate('account_category')),
                  items: [
                    DropdownMenuItem(value: 'asset', child: Text(l10n.translate('asset'))),
                    DropdownMenuItem(value: 'liability', child: Text(l10n.translate('liability'))),
                    DropdownMenuItem(value: 'custom', child: Text(l10n.translate('custom'))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value ?? 'asset';
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: l10n.translate('account_type')),
                  items: _getTypeOptions(selectedCategory, l10n),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value ?? 'bank';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: balanceController,
                  decoration: InputDecoration(labelText: l10n.translate('initial_balance')),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: l10n.translate('notes')),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text) ?? 0.0;
                if (name.isNotEmpty) {
                  _updateAccount(
                    account,
                    name,
                    selectedType,
                    selectedCategory,
                    balance,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    currency: selectedCurrency,
                    icon: selectedIcon,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Account account) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('delete_account')),
        content: Text(
          '${l10n.translate('delete_account_confirmation')} "${account.name}" ?\n\n'
          '${l10n.translate('irreversible_action')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteAccount(account);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _addAccount(
    String name,
    String type,
    String category,
    double balance, {
    String? notes,
    String? currency,
    String? icon,
  }) async {
    try {
      await ref.read(accountsDaoProvider).insertAccount(
            AccountsCompanion(
              name: drift.Value(name),
              type: drift.Value(type),
              accountCategory: drift.Value(category),
              initialBalance: drift.Value(balance),
              notes: drift.Value(notes),
              currency: drift.Value(currency),
              icon: drift.Value(icon),
            ),
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('account_added'))),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _updateAccount(
    Account account,
    String name,
    String type,
    String category,
    double balance, {
    String? notes,
    String? currency,
    String? icon,
  }) async {
    try {
      await ref.read(accountsDaoProvider).updateAccount(
            AccountsCompanion(
              id: drift.Value(account.id),
              name: drift.Value(name),
              type: drift.Value(type),
              accountCategory: drift.Value(category),
              initialBalance: drift.Value(balance),
              notes: drift.Value(notes),
              currency: drift.Value(currency),
              icon: drift.Value(icon),
            ),
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('account_updated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _hideAccount(Account account) async {
    try {
      await ref.read(accountsDaoProvider).updateAccount(
            AccountsCompanion(
              id: drift.Value(account.id),
              archived: const drift.Value(true),
            ),
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('account_hidden'))),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _unhideAccount(Account account) async {
    try {
      await ref.read(accountsDaoProvider).updateAccount(
            AccountsCompanion(
              id: drift.Value(account.id),
              archived: const drift.Value(false),
            ),
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('account_shown'))),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount(Account account) async {
    try {
      await ref.read(accountsDaoProvider).deleteAccount(account.id);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('account_deleted'))),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _toggleExcludeFromTotal(Account account) async {
    try {
      await ref.read(accountsDaoProvider).updateAccount(
            AccountsCompanion(
              id: drift.Value(account.id),
              excludedFromTotal: drift.Value(!account.excludedFromTotal),
            ),
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              account.excludedFromTotal
                  ? l10n.translate('include_in_total')
                  : l10n.translate('excluded_from_total'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _toggleTransferAsExpense(Account account) async {
    try {
      await ref.read(accountsDaoProvider).updateAccount(
            AccountsCompanion(
              id: drift.Value(account.id),
              transferAsExpense: drift.Value(!account.transferAsExpense),
            ),
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              account.transferAsExpense
                  ? l10n.translate('transfers_as_expenses_disabled')
                  : l10n.translate('transfers_as_expenses_enabled'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
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
