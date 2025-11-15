import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'drift_database.g.dart';

// Table Accounts
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'bank', 'cash', 'wallet'
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

// Table Categories
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'expense' ou 'income'
  TextColumn get color => text()(); // code couleur hexadécimal
  TextColumn get icon => text()(); // identifiant d'icône
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

// Table Transactions
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer()();
  IntColumn get categoryId => integer()();
  TextColumn get type => text()(); // 'expense', 'income', 'transfer'
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().nullable()();
  BoolColumn get isRecurringInstance =>
      boolean().withDefault(const Constant(false))();
  IntColumn get recurrenceId => integer().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// Table RecurringRules
class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer()();
  IntColumn get categoryId => integer()();
  TextColumn get type => text()(); // 'expense' ou 'income'
  RealColumn get amount => real()();
  TextColumn get frequency =>
      text()(); // 'daily', 'weekly', 'monthly', 'yearly', 'custom'
  IntColumn get dayOfMonth => integer().nullable()();
  IntColumn get weekday => integer().nullable()(); // 1-7 (Lundi-Dimanche)
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastExecutionDate => dateTime().nullable()();
}

// Table Budgets
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer()();
  TextColumn get periodType => text()(); // 'monthly', 'weekly', 'custom'
  RealColumn get amount => real()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// Table Goals
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount =>
      real().withDefault(const Constant(0.0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(2))(); // 1-3
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// Table Settings
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  TextColumn get theme => text().withDefault(const Constant('dark'))(); // 'system', 'light', 'dark'
  TextColumn get dailyReminderTime =>
      text().nullable()(); // Format: 'HH:mm' (ex: '20:00')
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
  BoolColumn get biometricLockEnabled =>
      boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [
  Accounts,
  Categories,
  Transactions,
  RecurringRules,
  Budgets,
  Goals,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedDefaultData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Gérer les migrations futures ici
      },
    );
  }

  Future<void> _seedDefaultData() async {
    // Créer les catégories par défaut
    final expenseCategories = [
      {'name': 'Logement', 'icon': 'home', 'color': '#3B82F6'},
      {'name': 'Courses', 'icon': 'shopping_cart', 'color': '#10B981'},
      {'name': 'Restaurants', 'icon': 'restaurant', 'color': '#F59E0B'},
      {'name': 'Transport', 'icon': 'directions_car', 'color': '#8B5CF6'},
      {'name': 'Loisirs', 'icon': 'sports_esports', 'color': '#EC4899'},
      {'name': 'Santé', 'icon': 'local_hospital', 'color': '#EF4444'},
      {'name': 'Éducation', 'icon': 'school', 'color': '#06B6D4'},
      {'name': 'Autres', 'icon': 'category', 'color': '#6B7280'},
    ];

    final incomeCategories = [
      {'name': 'Salaire', 'icon': 'work', 'color': '#4ADE80'},
      {'name': 'Freelance', 'icon': 'laptop', 'color': '#10B981'},
      {'name': 'Investissements', 'icon': 'trending_up', 'color': '#6366F1'},
      {'name': 'Autres revenus', 'icon': 'attach_money', 'color': '#8B5CF6'},
    ];

    for (final cat in expenseCategories) {
      await into(categories).insert(
        CategoriesCompanion(
          name: Value(cat['name'] as String),
          type: const Value('expense'),
          color: Value(cat['color'] as String),
          icon: Value(cat['icon'] as String),
          isDefault: const Value(true),
        ),
      );
    }

    for (final cat in incomeCategories) {
      await into(categories).insert(
        CategoriesCompanion(
          name: Value(cat['name'] as String),
          type: const Value('income'),
          color: Value(cat['color'] as String),
          icon: Value(cat['icon'] as String),
          isDefault: const Value(true),
        ),
      );
    }

    // Créer un compte par défaut
    await into(accounts).insert(
      AccountsCompanion(
        name: const Value('Compte principal'),
        type: const Value('bank'),
        initialBalance: const Value(0.0),
      ),
    );

    // Créer les paramètres par défaut
    await into(settings).insert(
      const SettingsCompanion(
        id: Value(1),
        currency: Value('EUR'),
        theme: Value('dark'),
        isPremium: Value(false),
        biometricLockEnabled: Value(false),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budget.db'));
    return NativeDatabase(file);
  });
}

