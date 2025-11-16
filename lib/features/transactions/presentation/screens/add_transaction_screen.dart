import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../domain/models/transaction_type.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/localization/app_localizations.dart';
import 'dart:io';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transactionToEdit;
  
  const AddTransactionScreen({super.key, this.transactionToEdit});

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
    
    // Si on est en mode édition, pré-remplir les champs
    if (widget.transactionToEdit != null) {
      final transaction = widget.transactionToEdit!;
      _selectedDate = transaction.date;
      _selectedAccountId = transaction.accountId;
      _selectedCategoryId = transaction.categoryId;
      _amountController.text = transaction.amount.toString();
      _noteController.text = transaction.description ?? '';
      
      // Déterminer le type de transaction
      if (transaction.type == 'expense') {
        _selectedType = TransactionType.expense;
      } else if (transaction.type == 'income') {
        _selectedType = TransactionType.income;
      } else {
        _selectedType = TransactionType.transfer;
      }
      
      // Charger les images existantes si présentes
      // Note: On ne peut pas charger les XFile depuis les chemins existants directement
      // Les images seront affichées dans le dialogue de détails, mais pour les modifier
      // il faudra les re-sélectionner. On stocke juste les chemins pour référence.
      // Les images existantes seront préservées si aucune nouvelle image n'est ajoutée.
    }
    
    _tabController = TabController(length: 3, vsync: this);
    // Positionner le tab sur le bon type
    _tabController.index = _selectedType.index;
    _tabController.addListener(() {
      setState(() {
        _selectedType = TransactionType.values[_tabController.index];
        if (widget.transactionToEdit == null) {
          _selectedCategoryId = null; // Réinitialiser la catégorie seulement en mode création
        }
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

    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionToEdit == null ? l10n.newTransaction : l10n.editTransaction),
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
                error: (e, _) => Text('${AppLocalizations.of(context)?.translate('error') ?? 'Erreur'}: $e'),
              ),

            // Transfert : Compte source et destination
            if (_selectedType == TransactionType.transfer)
              accountsAsync.when(
                data: (accounts) => Column(
                  children: [
                    _buildAccountField(accounts, label: AppLocalizations.of(context)!.translate('from')),
                    const SizedBox(height: 16),
                    _buildAccountField(accounts, label: AppLocalizations.of(context)!.translate('to'), isToAccount: true),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('${AppLocalizations.of(context)?.translate('error') ?? 'Erreur'}: $e'),
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
                    return Text('${AppLocalizations.of(context)?.translate('error') ?? 'Erreur'}: ${snapshot.error}');
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(l10n.date),
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
            title: Text(AppLocalizations.of(context)!.time),
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
    final l10n = AppLocalizations.of(context)!;
    if (accounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet, size: 48),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.translate('no_account_available')),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddAccountDialog(context),
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.translate('create_account')),
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
            return l10n.translate('select_account');
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryField(List<Category> categories) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: l10n.category,
          prefixIcon: const Icon(Icons.category),
          border: const OutlineInputBorder(),
        ),
        value: _selectedCategoryId,
        items: [
          ...categories.map((category) {
            return DropdownMenuItem<int>(
              value: category.id,
              child: Row(
                children: [
                  Icon(
                    CategoryIcons.getCategoryIcon(category.name, category.icon),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          DropdownMenuItem<int>(
            value: -1, // Valeur spéciale pour "Ajouter une catégorie"
            child: Row(
              children: [
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.addCategory,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          if (value == -1) {
            // Ouvrir le dialogue pour ajouter une catégorie
            _showAddCategoryDialog(context);
          } else {
            setState(() {
              _selectedCategoryId = value;
            });
          }
        },
        validator: (value) {
          if (value == null || value == -1) {
            return l10n.translate('select_category');
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAmountField() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: TextFormField(
        controller: _amountController,
        decoration: InputDecoration(
          labelText: l10n.amount,
          prefixIcon: const Icon(Icons.euro),
          border: const OutlineInputBorder(),
          hintText: '0.00',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.translate('enter_amount');
          }
          final amount = double.tryParse(value);
          if (amount == null || amount <= 0) {
            return l10n.translate('invalid_amount');
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
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.translate('note_description'),
          prefixIcon: const Icon(Icons.note),
          border: const OutlineInputBorder(),
          hintText: AppLocalizations.of(context)!.translate('add_note'),
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildImagesSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(l10n.translate('photos_receipts')),
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
                    label: Text(l10n.translate('camera')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(l10n.translate('gallery')),
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.settings),
        title: Text(l10n.translate('advanced_options')),
        children: [
          if (_selectedType != TransactionType.transfer) ...[
            SwitchListTile(
              title: Text(l10n.translate('recurring_transaction')),
              subtitle: Text(l10n.translate('repeat_transaction')),
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
                  decoration: InputDecoration(labelText: l10n.translate('frequency')),
                  value: _recurrenceFrequency,
                  items: [
                    DropdownMenuItem(value: 'daily', child: Text(l10n.translate('daily'))),
                    DropdownMenuItem(value: 'weekly', child: Text(l10n.translate('weekly'))),
                    DropdownMenuItem(value: 'monthly', child: Text(l10n.translate('monthly'))),
                    DropdownMenuItem(value: 'yearly', child: Text(l10n.translate('yearly'))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _recurrenceFrequency = value ?? 'monthly';
                    });
                  },
                ),
              ),
            SwitchListTile(
              title: Text(l10n.translate('installment_payment')),
              subtitle: Text(l10n.translate('split_amount_months')),
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
                  decoration: InputDecoration(labelText: l10n.translate('installment_count')),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _installmentCount = int.tryParse(value) ?? 1;
                  },
                ),
              ),
          ],
          SwitchListTile(
            title: Text(l10n.translate('bookmark')),
            subtitle: Text(l10n.translate('reuse_quickly')),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveTransaction,
            icon: const Icon(Icons.save),
            label: Text(l10n.save),
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
            label: Text(l10n.translate('save_and_continue')),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.translate('transaction_saved'))),
        );
      }
    }
  }

  Future<void> _insertTransaction() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final amount = double.parse(_amountController.text);
      final transactionsDao = ref.read(transactionsDaoProvider);

      // Sauvegarder les images d'abord
      String? imagesPaths;
      if (_selectedImages.isNotEmpty) {
        final savedPaths = await _saveImages();
        imagesPaths = savedPaths.join(',');
      } else if (widget.transactionToEdit != null) {
        // En mode édition, si aucune nouvelle image n'est ajoutée, conserver les images existantes
        imagesPaths = widget.transactionToEdit!.images;
      }

      // Si on est en mode édition, mettre à jour la transaction existante
      if (widget.transactionToEdit != null) {
        final transaction = widget.transactionToEdit!;
        await transactionsDao.updateTransaction(
          TransactionsCompanion(
            id: drift.Value(transaction.id),
            accountId: drift.Value(_selectedAccountId ?? transaction.accountId),
            categoryId: drift.Value(_selectedCategoryId ?? transaction.categoryId),
            type: drift.Value(_selectedType.value),
            amount: drift.Value(amount),
            date: drift.Value(_selectedDate),
            description: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
            images: drift.Value(imagesPaths),
          ),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('transaction_updated'))),
          );
          context.pop();
        }
        return;
      }

      // Créer les transactions avec les images incluses directement
      if (_selectedType == TransactionType.transfer) {
        // Pour les transferts, créer deux transactions avec images
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
              images: drift.Value(imagesPaths),
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
              images: drift.Value(imagesPaths),
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
              images: drift.Value(imagesPaths),
            ),
          );
        }
      }

      // TODO: Gérer la récurrence (créer RecurringRule)
      // TODO: Gérer les installments

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('transaction_saved_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.translate('error')}: $e')),
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

  /// Sauvegarde les images sélectionnées dans le répertoire de l'application
  Future<List<String>> _saveImages() async {
    final List<String> savedPaths = [];
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'transaction_images'));
    
    // Créer le répertoire s'il n'existe pas
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    for (final xFile in _selectedImages) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(xFile.path)}';
      final savedFile = File(path.join(imagesDir.path, fileName));
      
      // Copier le fichier
      await File(xFile.path).copy(savedFile.path);
      savedPaths.add(savedFile.path);
    }

    return savedPaths;
  }

  void _showAddCategoryDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    String selectedIcon = 'category';
    String selectedColor = '#6B7280';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.addCategory),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('category_name'),
                    hintText: l10n.translate('category_name_example'),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedIcon,
                  decoration: InputDecoration(labelText: l10n.translate('icon')),
                  items: [
                    DropdownMenuItem(
                      value: 'home',
                      child: Row(
                        children: [
                          const Icon(Icons.home, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('housing')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'shopping_cart',
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('groceries')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'restaurant',
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('restaurant')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'directions_car',
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('transport')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'sports_esports',
                      child: Row(
                        children: [
                          const Icon(Icons.sports_esports, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('leisure')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'local_hospital',
                      child: Row(
                        children: [
                          const Icon(Icons.local_hospital, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('health')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'school',
                      child: Row(
                        children: [
                          const Icon(Icons.school, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('education')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'work',
                      child: Row(
                        children: [
                          const Icon(Icons.work, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('salary')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'laptop',
                      child: Row(
                        children: [
                          const Icon(Icons.laptop, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('freelance')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'trending_up',
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('investment')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'attach_money',
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('other_income')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'category',
                      child: Row(
                        children: [
                          const Icon(Icons.category, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.translate('other')),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedIcon = value ?? 'category';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      if (name.isNotEmpty) {
        try {
          final categoryType = _selectedType == TransactionType.income ? 'income' : 'expense';
          final newCategoryId = await ref.read(categoriesDaoProvider).insertCategory(
                CategoriesCompanion(
                  name: drift.Value(name),
                  type: drift.Value(categoryType),
                  icon: drift.Value(selectedIcon),
                  color: drift.Value(selectedColor),
                  isDefault: drift.Value(false),
                ),
              );
          
          setState(() {
            _selectedCategoryId = newCategoryId;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.translate('category_added'))),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${AppLocalizations.of(context)!.translate('error')}: $e')),
            );
          }
        }
      }
    }
  }

  void _showAddAccountDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'bank';
    String selectedCategory = 'asset';

    final result = await showDialog<bool>(
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
                  autofocus: true,
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
                  items: _getAccountTypeOptions(selectedCategory, l10n),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      final balance = double.tryParse(balanceController.text) ?? 0.0;
      if (name.isNotEmpty) {
        try {
          await ref.read(accountsDaoProvider).insertAccount(
                AccountsCompanion(
                  name: drift.Value(name),
                  type: drift.Value(selectedType),
                  accountCategory: drift.Value(selectedCategory),
                  initialBalance: drift.Value(balance),
                ),
              );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.translate('account_added'))),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${AppLocalizations.of(context)!.translate('error')}: $e')),
            );
          }
        }
      }
    }
  }

  List<DropdownMenuItem<String>> _getAccountTypeOptions(String category, AppLocalizations l10n) {
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
}
