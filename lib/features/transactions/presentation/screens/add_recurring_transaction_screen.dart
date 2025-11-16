import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../domain/models/recurrence_frequency.dart';

class AddRecurringTransactionScreen extends ConsumerStatefulWidget {
  final RecurringRule? ruleToEdit;

  const AddRecurringTransactionScreen({super.key, this.ruleToEdit});

  @override
  ConsumerState<AddRecurringTransactionScreen> createState() =>
      _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState
    extends ConsumerState<AddRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'expense'; // 'expense' ou 'income'
  int? _selectedAccountId;
  int? _selectedCategoryId;
  String _selectedFrequency = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _dayOfMonth;
  int? _weekday;
  bool _hasEndDate = false;

  @override
  void initState() {
    super.initState();
    if (widget.ruleToEdit != null) {
      final rule = widget.ruleToEdit!;
      _selectedType = rule.type;
      _selectedAccountId = rule.accountId;
      _selectedCategoryId = rule.categoryId;
      _amountController.text = rule.amount.toString();
      _selectedFrequency = rule.frequency;
      _startDate = rule.startDate;
      _endDate = rule.endDate;
      _hasEndDate = rule.endDate != null;
      _dayOfMonth = rule.dayOfMonth;
      _weekday = rule.weekday;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ruleToEdit == null
            ? 'Nouvelle transaction récurrente'
            : 'Modifier la transaction récurrente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type de transaction
            Card(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'expense',
                    label: Text('Dépense'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: 'income',
                    label: Text('Revenu'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedCategoryId = null; // Réinitialiser la catégorie
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Compte
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 48),
                          const SizedBox(height: 8),
                          const Text('Aucun compte disponible'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context.push('/accounts'),
                            child: const Text('Créer un compte'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (_selectedAccountId == null && accounts.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedAccountId = accounts.first.id;
                    });
                  });
                }
                return _buildAccountField(accounts);
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 16),

            // Catégorie
            categoriesAsync.when(
              data: (categories) {
                final filteredCategories = categories
                    .where((c) => c.type == _selectedType)
                    .toList();
                return _buildCategoryField(filteredCategories);
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 16),

            // Montant
            _buildAmountField(),
            const SizedBox(height: 16),

            // Fréquence
            _buildFrequencyField(),
            const SizedBox(height: 16),

            // Options spécifiques selon la fréquence
            if (_selectedFrequency == 'monthly') _buildDayOfMonthField(),
            if (_selectedFrequency == 'weekly') _buildWeekdayField(),
            if (_selectedFrequency == 'monthly' || _selectedFrequency == 'weekly')
              const SizedBox(height: 16),

            // Date de début
            _buildStartDateField(),
            const SizedBox(height: 16),

            // Date de fin (optionnelle)
            _buildEndDateField(),
            const SizedBox(height: 24),

            // Bouton de sauvegarde
            ElevatedButton(
              onPressed: _saveRecurringTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.ruleToEdit == null
                  ? 'Créer la transaction récurrente'
                  : 'Modifier la transaction récurrente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountField(List<Account> accounts) {
    return Card(
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Compte',
          prefixIcon: Icon(Icons.account_balance_wallet),
          border: OutlineInputBorder(),
        ),
        value: _selectedAccountId,
        items: accounts.map((account) {
          return DropdownMenuItem<int>(
            value: account.id,
            child: Text(account.name),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedAccountId = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Veuillez sélectionner un compte';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryField(List<Category> categories) {
    if (categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Aucune catégorie disponible pour les ${_selectedType == 'expense' ? 'dépenses' : 'revenus'}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedCategoryId = categories.first.id;
        });
      });
    }

    return Card(
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Catégorie',
          prefixIcon: Icon(Icons.category),
          border: OutlineInputBorder(),
        ),
        value: _selectedCategoryId,
        items: categories.map((category) {
          return DropdownMenuItem<int>(
            value: category.id,
            child: Text(category.name),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategoryId = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Veuillez sélectionner une catégorie';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAmountField() {
    return Card(
      child: TextFormField(
        controller: _amountController,
        decoration: const InputDecoration(
          labelText: 'Montant',
          prefixIcon: Icon(Icons.attach_money),
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un montant';
          }
          final amount = double.tryParse(value);
          if (amount == null || amount <= 0) {
            return 'Veuillez entrer un montant valide';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildFrequencyField() {
    return Card(
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Fréquence',
          prefixIcon: Icon(Icons.repeat),
          border: OutlineInputBorder(),
        ),
        value: _selectedFrequency,
        items: RecurrenceFrequency.values.map((frequency) {
          return DropdownMenuItem<String>(
            value: frequency.value,
            child: Text(frequency.label),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedFrequency = value ?? 'monthly';
            _dayOfMonth = null;
            _weekday = null;
          });
        },
      ),
    );
  }

  Widget _buildDayOfMonthField() {
    return Card(
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Jour du mois',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        value: _dayOfMonth,
        items: List.generate(31, (index) => index + 1).map((day) {
          return DropdownMenuItem<int>(
            value: day,
            child: Text('Jour $day'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _dayOfMonth = value;
          });
        },
        hint: const Text('Optionnel'),
      ),
    );
  }

  Widget _buildWeekdayField() {
    final weekdays = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];

    return Card(
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Jour de la semaine',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        value: _weekday,
        items: List.generate(7, (index) => index + 1).map((day) {
          return DropdownMenuItem<int>(
            value: day,
            child: Text(weekdays[day - 1]),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _weekday = value;
          });
        },
        hint: const Text('Optionnel'),
      ),
    );
  }

  Widget _buildStartDateField() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Date de début'),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _startDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              _startDate = picked;
            });
          }
        },
      ),
    );
  }

  Widget _buildEndDateField() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Date de fin'),
            subtitle: Text(_hasEndDate
                ? _endDate != null
                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                    : 'Non définie'
                : 'Aucune date de fin'),
            value: _hasEndDate,
            onChanged: (value) {
              setState(() {
                _hasEndDate = value;
                if (!value) {
                  _endDate = null;
                } else if (_endDate == null) {
                  _endDate = _startDate.add(const Duration(days: 365));
                }
              });
            },
          ),
          if (_hasEndDate)
            ListTile(
              leading: const Icon(Icons.event_busy),
              title: Text(_endDate != null
                  ? DateFormat('dd/MM/yyyy').format(_endDate!)
                  : 'Non définie'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
                  firstDate: _startDate,
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _endDate = picked;
                  });
                }
              },
            ),
        ],
      ),
    );
  }

  Future<void> _saveRecurringTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAccountId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);

    try {
      final companion = RecurringRulesCompanion(
        accountId: Value(_selectedAccountId!),
        categoryId: Value(_selectedCategoryId!),
        type: Value(_selectedType),
        amount: Value(amount),
        frequency: Value(_selectedFrequency),
        dayOfMonth: Value(_dayOfMonth),
        weekday: Value(_weekday),
        startDate: Value(_startDate),
        endDate: Value(_hasEndDate ? _endDate : null),
        isActive: const Value(true),
      );

      if (widget.ruleToEdit == null) {
        await ref.read(recurringRulesDaoProvider).insertRecurringRule(companion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction récurrente créée avec succès')),
          );
          context.pop();
        }
      } else {
        await ref.read(recurringRulesDaoProvider).updateRecurringRule(
              companion.copyWith(id: Value(widget.ruleToEdit!.id)),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction récurrente modifiée avec succès')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

