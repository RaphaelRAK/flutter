import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../infrastructure/db/database_provider.dart';
import '../../../../../infrastructure/db/drift_database.dart';
import '../../../../../core/utils/transaction_filters_helper.dart';
import '../../../../../core/widgets/main_bottom_nav_bar.dart';

final transactionFiltersProvider =
    StateNotifierProvider<TransactionFiltersNotifier, TransactionFilters?>(
  (ref) => TransactionFiltersNotifier(),
);

class TransactionFiltersNotifier extends StateNotifier<TransactionFilters?> {
  TransactionFiltersNotifier() : super(null) {
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final filters = await TransactionFiltersHelper.loadFilters();
    state = filters;
  }

  Future<void> updateFilters(TransactionFilters filters) async {
    await TransactionFiltersHelper.saveFilters(filters);
    state = filters;
  }

  Future<void> clearFilters() async {
    await TransactionFiltersHelper.clearFilters();
    state = null;
  }
}

class TransactionFiltersScreen extends ConsumerStatefulWidget {
  const TransactionFiltersScreen({super.key});

  @override
  ConsumerState<TransactionFiltersScreen> createState() =>
      _TransactionFiltersScreenState();
}

class _TransactionFiltersScreenState
    extends ConsumerState<TransactionFiltersScreen> {
  late TransactionFilters _filters;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _filters = TransactionFilters();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final savedFilters = ref.read(transactionFiltersProvider);
      if (savedFilters != null) {
        _filters = savedFilters;
      }
      _isInitialized = true;
    }
  }

  Future<void> _saveFilters() async {
    await ref.read(transactionFiltersProvider.notifier).updateFilters(_filters);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filtres sauvegardés'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _clearFilters() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les filtres'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser tous les filtres ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _filters = TransactionFilters();
      });
      await ref.read(transactionFiltersProvider.notifier).clearFilters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filtres réinitialisés'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtrage et recherche'),
        actions: [
          if (_filters.hasFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Réinitialiser',
              onPressed: _clearFilters,
            ),
        ],
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 3),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Recherche par description
          _buildSearchField(),
          const SizedBox(height: 24),

          // Type de transaction
          _buildSectionHeader('Type de transaction'),
          _buildTypeFilter(),
          const SizedBox(height: 24),

          // Catégories
          _buildSectionHeader('Catégories'),
          categoriesAsync.when(
            data: (categories) => _buildCategoryFilter(categories),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Erreur: $e'),
          ),
          const SizedBox(height: 24),

          // Comptes
          _buildSectionHeader('Comptes'),
          accountsAsync.when(
            data: (accounts) => _buildAccountFilter(accounts),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Erreur: $e'),
          ),
          const SizedBox(height: 24),

          // Plage de dates
          _buildSectionHeader('Période'),
          _buildDateRangeFilter(),
          const SizedBox(height: 24),

          // Montant
          _buildSectionHeader('Montant'),
          _buildAmountFilter(),
          const SizedBox(height: 32),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveFilters,
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Rechercher dans les descriptions',
        hintText: 'Entrez un mot-clé...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _filters.searchQuery != null &&
                _filters.searchQuery!.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _filters = _filters.copyWith(searchQuery: '');
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _filters = _filters.copyWith(
            searchQuery: value.isEmpty ? null : value,
          );
        });
      },
      controller: TextEditingController(text: _filters.searchQuery ?? ''),
    );
  }

  Widget _buildTypeFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          label: 'Tous',
          selected: _filters.types == null,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _filters = _filters.copyWith(types: null);
              });
            }
          },
        ),
        _buildFilterChip(
          label: 'Dépenses',
          selected: _filters.types?.contains('expense') ?? false,
          onSelected: (selected) {
            setState(() {
              final types = List<String>.from(_filters.types ?? []);
              if (selected) {
                if (!types.contains('expense')) types.add('expense');
              } else {
                types.remove('expense');
              }
              _filters = _filters.copyWith(
                types: types.isEmpty ? null : types,
              );
            });
          },
        ),
        _buildFilterChip(
          label: 'Revenus',
          selected: _filters.types?.contains('income') ?? false,
          onSelected: (selected) {
            setState(() {
              final types = List<String>.from(_filters.types ?? []);
              if (selected) {
                if (!types.contains('income')) types.add('income');
              } else {
                types.remove('income');
              }
              _filters = _filters.copyWith(
                types: types.isEmpty ? null : types,
              );
            });
          },
        ),
        _buildFilterChip(
          label: 'Transferts',
          selected: _filters.types?.contains('transfer') ?? false,
          onSelected: (selected) {
            setState(() {
              final types = List<String>.from(_filters.types ?? []);
              if (selected) {
                if (!types.contains('transfer')) types.add('transfer');
              } else {
                types.remove('transfer');
              }
              _filters = _filters.copyWith(
                types: types.isEmpty ? null : types,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(List<Category> categories) {
    final selectedIds = _filters.categoryIds ?? [];
    final allSelected = selectedIds.length == categories.length;

    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: allSelected,
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(
                    categoryIds: value == true
                        ? categories.map((c) => c.id).toList()
                        : null,
                  );
                });
              },
            ),
            const Text('Toutes les catégories'),
          ],
        ),
        const SizedBox(height: 8),
        ...categories.map((category) {
          final isSelected = selectedIds.contains(category.id);
          return CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                final ids = List<int>.from(selectedIds);
                if (value == true) {
                  ids.add(category.id);
                } else {
                  ids.remove(category.id);
                }
                _filters = _filters.copyWith(
                  categoryIds: ids.isEmpty ? null : ids,
                );
              });
            },
            title: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                      category.color.replaceFirst('#', '0xFF'),
                    )),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(category.name),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAccountFilter(List<Account> accounts) {
    final selectedIds = _filters.accountIds ?? [];
    final allSelected = selectedIds.length == accounts.length;

    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: allSelected,
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(
                    accountIds: value == true
                        ? accounts.map((a) => a.id).toList()
                        : null,
                  );
                });
              },
            ),
            const Text('Tous les comptes'),
          ],
        ),
        const SizedBox(height: 8),
        ...accounts.map((account) {
          final isSelected = selectedIds.contains(account.id);
          return CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                final ids = List<int>.from(selectedIds);
                if (value == true) {
                  ids.add(account.id);
                } else {
                  ids.remove(account.id);
                }
                _filters = _filters.copyWith(
                  accountIds: ids.isEmpty ? null : ids,
                );
              });
            },
            title: Text(account.name),
          );
        }),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Date de début'),
          subtitle: Text(
            _filters.startDate != null
                ? dateFormat.format(_filters.startDate!)
                : 'Non définie',
          ),
          trailing: _filters.startDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _filters = _filters.copyWith(startDate: null);
                    });
                  },
                )
              : null,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _filters.startDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                _filters = _filters.copyWith(startDate: date);
              });
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.event),
          title: const Text('Date de fin'),
          subtitle: Text(
            _filters.endDate != null
                ? dateFormat.format(_filters.endDate!)
                : 'Non définie',
          ),
          trailing: _filters.endDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _filters = _filters.copyWith(endDate: null);
                    });
                  },
                )
              : null,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _filters.endDate ?? DateTime.now(),
              firstDate: _filters.startDate ?? DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                _filters = _filters.copyWith(endDate: date);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAmountFilter() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Montant minimum',
            hintText: '0.00',
            prefixIcon: const Icon(Icons.arrow_upward),
            suffixIcon: _filters.minAmount != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _filters = _filters.copyWith(minAmount: null);
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: TextEditingController(
            text: _filters.minAmount != null
                ? _filters.minAmount!.toStringAsFixed(2)
                : '',
          ),
          onChanged: (value) {
            final amount = double.tryParse(value);
            setState(() {
              _filters = _filters.copyWith(minAmount: amount);
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Montant maximum',
            hintText: '0.00',
            prefixIcon: const Icon(Icons.arrow_downward),
            suffixIcon: _filters.maxAmount != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _filters = _filters.copyWith(maxAmount: null);
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: TextEditingController(
            text: _filters.maxAmount != null
                ? _filters.maxAmount!.toStringAsFixed(2)
                : '',
          ),
          onChanged: (value) {
            final amount = double.tryParse(value);
            setState(() {
              _filters = _filters.copyWith(maxAmount: amount);
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

