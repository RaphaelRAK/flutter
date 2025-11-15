import 'package:drift/drift.dart';
import '../drift_database.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts, Transactions])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(AppDatabase db) : super(db);

  Stream<List<Account>> watchAllAccounts() {
    return (select(accounts)
          ..where((a) => a.archived.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.order), (a) => OrderingTerm.asc(a.name)]))
        .watch();
  }

  Future<List<Account>> getAllAccounts() {
    return (select(accounts)
          ..where((a) => a.archived.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.order), (a) => OrderingTerm.asc(a.name)]))
        .get();
  }

  Stream<List<Account>> watchAccountsByCategory(String category) {
    return (select(accounts)
          ..where((a) => a.archived.equals(false) & a.accountCategory.equals(category))
          ..orderBy([(a) => OrderingTerm.asc(a.order), (a) => OrderingTerm.asc(a.name)]))
        .watch();
  }

  Future<List<Account>> getAccountsByCategory(String category) {
    return (select(accounts)
          ..where((a) => a.archived.equals(false) & a.accountCategory.equals(category))
          ..orderBy([(a) => OrderingTerm.asc(a.order), (a) => OrderingTerm.asc(a.name)]))
        .get();
  }

  Future<Account?> getAccountById(int id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }

  Future<bool> updateAccount(AccountsCompanion account) {
    return update(accounts).replace(account);
  }

  Future<int> deleteAccount(int id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }

  /// Calcule le solde réel d'un compte (solde initial + transactions)
  Future<double> getAccountBalance(int accountId) async {
    final account = await getAccountById(accountId);
    if (account == null) return 0.0;

    double balance = account.initialBalance;

    // Récupérer toutes les transactions du compte
    final accountTransactions = await (select(transactions)
          ..where((t) => t.accountId.equals(accountId)))
        .get();

    for (final transaction in accountTransactions) {
      if (transaction.type == 'income') {
        balance += transaction.amount;
      } else if (transaction.type == 'expense') {
        balance -= transaction.amount;
      } else if (transaction.type == 'transfer') {
        // Pour les transferts, on doit vérifier si c'est un transfert entrant ou sortant
        // Pour simplifier, on considère que les transferts sortants sont des dépenses
        // et les transferts entrants sont des revenus
        // TODO: Améliorer la logique des transferts avec un champ toAccountId
        balance -= transaction.amount; // Par défaut, on considère comme sortant
      }
    }

    return balance;
  }

  /// Calcule le total des actifs (comptes non exclus)
  Future<double> getTotalAssets() async {
    final assetAccounts = await getAccountsByCategory('asset');
    double total = 0.0;
    for (final account in assetAccounts) {
      if (!account.excludedFromTotal) {
        total += await getAccountBalance(account.id);
      }
    }
    return total;
  }

  /// Calcule le total des passifs (comptes non exclus)
  Future<double> getTotalLiabilities() async {
    final liabilityAccounts = await getAccountsByCategory('liability');
    double total = 0.0;
    for (final account in liabilityAccounts) {
      if (!account.excludedFromTotal) {
        final balance = await getAccountBalance(account.id);
        // Pour les passifs, on prend la valeur absolue car c'est une dette
        total += balance.abs();
      }
    }
    return total;
  }

  /// Calcule le patrimoine net (Assets - Liabilities)
  Future<double> getNetWorth() async {
    final assets = await getTotalAssets();
    final liabilities = await getTotalLiabilities();
    return assets - liabilities;
  }

  /// Ancienne méthode pour compatibilité (utilise maintenant le solde réel)
  Future<double> getTotalBalance() async {
    return await getTotalAssets();
  }

  /// Met à jour l'ordre des comptes
  Future<void> updateAccountOrder(int accountId, int newOrder) async {
    final account = await getAccountById(accountId);
    if (account != null) {
      await updateAccount(
        AccountsCompanion(
          id: Value(accountId),
          order: Value(newOrder),
        ),
      );
    }
  }

  /// Réorganise les comptes après un glisser-déposer
  Future<void> reorderAccounts(List<int> accountIds) async {
    for (int i = 0; i < accountIds.length; i++) {
      await updateAccountOrder(accountIds[i], i);
    }
  }

  /// Met à jour les catégories des comptes existants après la migration
  /// Cette méthode doit être appelée une fois après la migration vers la version 2
  Future<void> updateAccountCategoriesAfterMigration() async {
    try {
      final allAccounts = await getAllAccounts();
      for (final account in allAccounts) {
        // Si le compte est de type 'credit' ou 'loan' et a encore 'asset' comme catégorie
        if ((account.type == 'credit' || account.type == 'loan') &&
            account.accountCategory == 'asset') {
          await updateAccount(
            AccountsCompanion(
              id: Value(account.id),
              accountCategory: const Value('liability'),
            ),
          );
        }
      }
    } catch (e) {
      // Ignorer les erreurs
    }
  }
}

