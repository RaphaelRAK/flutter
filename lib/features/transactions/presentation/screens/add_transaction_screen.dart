import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../domain/models/transaction_type.dart';
import '../../../accounts/presentation/screens/accounts_screen.dart';
import 'dart:io';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  int? _selectedAccountId;
  int? _selectedCategoryId;
  int? _selectedToAccountId; // Pour les transferts
  final List<XFile> _selectedImages = [];
  bool _isRecurring = false;
  String _recurrenceFrequency = 'monthly';
  bool _isInstallment = false;
  int _installmentCount = 1;
  bool _isBookmark = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedType = TransactionType.values[_tabController.index];
        _selectedCategoryId = null; // Réinitialiser la catégorie
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesDaoProvider).getCategoriesByType(
          _selectedType == TransactionType.transfer
              ? 'expense'
              : _selectedType.value,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle transaction'),
        bottom: TabBar(
          controller: _tabController,
          tabs: TransactionType.values.map((type) {
            return Tab(
              text: type.label,
              icon: Icon(_getTypeIcon(type)),
            );
          }).toList(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date
            _buildDateField(),
            const SizedBox(height: 16),

            // Compte
            if (_selectedType != TransactionType.transfer)
              accountsAsync.when(
                data: (accounts) => _buildAccountField(accounts),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erreur: $e'),
              ),

            // Transfert : Compte source et destination
            if (_selectedType == TransactionType.transfer)
              accountsAsync.when(
                data: (accounts) => Column(
                  children: [
                    _buildAccountField(accounts, label: 'De'),
                    const SizedBox(height: 16),
                    _buildAccountField(accounts, label: 'Vers', isToAccount: true),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erreur: $e'),
              ),

            const SizedBox(height: 16),

            // Catégorie (pas pour les transferts)
            if (_selectedType != TransactionType.transfer)
              FutureBuilder<List<Category>>(
                future: categoriesAsync,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur: ${snapshot.error}');
                  }
                  return _buildCategoryField(snapshot.data ?? []);
                },
              ),

            const SizedBox(height: 16),

            // Montant
            _buildAmountField(),
            const SizedBox(height: 16),

            // Note/Description
            _buildNoteField(),
            const SizedBox(height: 16),

            // Images
            _buildImagesSection(),
            const SizedBox(height: 16),

            // Options avancées
            _buildAdvancedOptions(),
            const SizedBox(height: 24),

            // Boutons Save et Continue
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  // Préserver l'heure actuelle lors de la sélection de date
                  _selectedDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    _selectedDate.hour,
                    _selectedDate.minute,
                  );
                });
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Heure'),
            subtitle: Text(DateFormat('HH:mm', 'fr_FR').format(_selectedDate)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: _selectedDate.hour,
                  minute: _selectedDate.minute,
                ),
              );
              if (time != null) {
                setState(() {
                  // Préserver la date lors de la sélection de l'heure
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountField(List<Account> accounts, {String? label, bool isToAccount = false}) {
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

    // Initialiser avec le premier compte si aucun n'est sélectionné
    if (isToAccount && _selectedToAccountId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedToAccountId = accounts.first.id;
        });
      });
    } else if (!isToAccount && _selectedAccountId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedAccountId = accounts.first.id;
        });
      });
    }

    final selectedId = isToAccount ? _selectedToAccountId : _selectedAccountId;

    return Card(
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: label ?? 'Compte',
          prefixIcon: const Icon(Icons.account_balance_wallet),
          border: const OutlineInputBorder(),
        ),
        value: selectedId,
        items: accounts.map((account) {
          return DropdownMenuItem<int>(
            value: account.id,
            child: Row(
              children: [
                Icon(_getAccountTypeIcon(account.type)),
                const SizedBox(width: 8),
                Text(account.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            if (isToAccount) {
              _selectedToAccountId = value;
            } else {
              _selectedAccountId = value;
            }
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
            child: Row(
              children: [
                Text(category.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(category.name),
              ],
            ),
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
          prefixIcon: Icon(Icons.euro),
          border: OutlineInputBorder(),
          hintText: '0.00',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un montant';
          }
          final amount = double.tryParse(value);
          if (amount == null || amount <= 0) {
            return 'Montant invalide';
          }
          return null;
        },
        onChanged: (value) {
          // Calculatrice intégrée : évaluer les expressions simples
          if (value.contains('+') || value.contains('-') || 
              value.contains('*') || value.contains('/')) {
            try {
              // Simple évaluation (attention à la sécurité en production)
              final result = _evaluateExpression(value);
              if (result != null && result != double.tryParse(value)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _amountController.value = TextEditingValue(
                    text: result.toStringAsFixed(2),
                    selection: TextSelection.collapsed(offset: result.toStringAsFixed(2).length),
                  );
                });
              }
            } catch (e) {
              // Ignorer les erreurs d'évaluation
            }
          }
        },
      ),
    );
  }

  double? _evaluateExpression(String expression) {
    try {
      // Simple évaluation pour les expressions basiques
      expression = expression.replaceAll(' ', '');
      if (expression.contains('+')) {
        final parts = expression.split('+');
        if (parts.length == 2) {
          final a = double.tryParse(parts[0]);
          final b = double.tryParse(parts[1]);
          if (a != null && b != null) return a + b;
        }
      }
      if (expression.contains('-') && expression.indexOf('-') > 0) {
        final parts = expression.split('-');
        if (parts.length == 2) {
          final a = double.tryParse(parts[0]);
          final b = double.tryParse(parts[1]);
          if (a != null && b != null) return a - b;
        }
      }
      if (expression.contains('*')) {
        final parts = expression.split('*');
        if (parts.length == 2) {
          final a = double.tryParse(parts[0]);
          final b = double.tryParse(parts[1]);
          if (a != null && b != null) return a * b;
        }
      }
      if (expression.contains('/')) {
        final parts = expression.split('/');
        if (parts.length == 2) {
          final a = double.tryParse(parts[0]);
          final b = double.tryParse(parts[1]);
          if (a != null && b != null && b != 0) return a / b;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Widget _buildNoteField() {
    return Card(
      child: TextFormField(
        controller: _noteController,
        decoration: const InputDecoration(
          labelText: 'Note / Description',
          prefixIcon: Icon(Icons.note),
          border: OutlineInputBorder(),
          hintText: 'Ajouter une note...',
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Photos / Reçus'),
          ),
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImages[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Appareil photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  Widget _buildAdvancedOptions() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.settings),
        title: const Text('Options avancées'),
        children: [
          if (_selectedType != TransactionType.transfer) ...[
            SwitchListTile(
              title: const Text('Transaction récurrente'),
              subtitle: const Text('Répéter cette transaction'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
            if (_isRecurring)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Fréquence'),
                  value: _recurrenceFrequency,
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Quotidien')),
                    DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
                    DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
                    DropdownMenuItem(value: 'yearly', child: Text('Annuel')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _recurrenceFrequency = value ?? 'monthly';
                    });
                  },
                ),
              ),
            SwitchListTile(
              title: const Text('Paiement en plusieurs fois'),
              subtitle: const Text('Installment'),
              value: _isInstallment,
              onChanged: (value) {
                setState(() {
                  _isInstallment = value;
                });
              },
            ),
            if (_isInstallment)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  initialValue: _installmentCount.toString(),
                  decoration: const InputDecoration(labelText: 'Nombre de versements'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _installmentCount = int.tryParse(value) ?? 1;
                  },
                ),
              ),
          ],
          SwitchListTile(
            title: const Text('Marquer comme favori'),
            subtitle: const Text('Réutiliser rapidement'),
            value: _isBookmark,
            onChanged: (value) {
              setState(() {
                _isBookmark = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveTransaction,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _saveAndContinue,
            icon: const Icon(Icons.add),
            label: const Text('Enregistrer et continuer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      await _insertTransaction();
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      await _insertTransaction();
      if (mounted) {
        // Réinitialiser le formulaire
        _amountController.clear();
        _noteController.clear();
        _selectedImages.clear();
        _selectedCategoryId = null;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction enregistrée')),
        );
      }
    }
  }

  Future<void> _insertTransaction() async {
    try {
      final amount = double.parse(_amountController.text);
      final transactionsDao = ref.read(transactionsDaoProvider);

      if (_selectedType == TransactionType.transfer) {
        // Pour les transferts, créer deux transactions
        if (_selectedAccountId != null && _selectedToAccountId != null) {
          // Transaction sortante
          await transactionsDao.insertTransaction(
            TransactionsCompanion(
              accountId: drift.Value(_selectedAccountId!),
              categoryId: drift.Value(1), // Catégorie par défaut
              type: const drift.Value('transfer'),
              amount: drift.Value(amount),
              date: drift.Value(_selectedDate),
              description: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
            ),
          );
          // Transaction entrante
          await transactionsDao.insertTransaction(
            TransactionsCompanion(
              accountId: drift.Value(_selectedToAccountId!),
              categoryId: drift.Value(1), // Catégorie par défaut
              type: const drift.Value('transfer'),
              amount: drift.Value(amount),
              date: drift.Value(_selectedDate),
              description: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
            ),
          );
        }
      } else {
        if (_selectedAccountId != null && _selectedCategoryId != null) {
          await transactionsDao.insertTransaction(
            TransactionsCompanion(
              accountId: drift.Value(_selectedAccountId!),
              categoryId: drift.Value(_selectedCategoryId!),
              type: drift.Value(_selectedType.value),
              amount: drift.Value(amount),
              date: drift.Value(_selectedDate),
              description: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
            ),
          );
        }
      }

      // TODO: Gérer les images (sauvegarder dans le stockage local)
      // TODO: Gérer la récurrence (créer RecurringRule)
      // TODO: Gérer les installments

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction enregistrée avec succès')),
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

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return Icons.arrow_downward;
      case TransactionType.income:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
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
      default:
        return Icons.account_balance_wallet;
    }
  }
}
