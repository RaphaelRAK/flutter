import 'package:drift/drift.dart';
import '../drift_database.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(AppDatabase db) : super(db);

  Future<List<Account>> getAllAccounts() {
    return (select(accounts)..where((a) => a.archived.equals(false))).get();
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

  Future<double> getTotalBalance() async {
    final allAccounts = await getAllAccounts();
    double total = 0.0;
    for (final account in allAccounts) {
      total += account.initialBalance;
    }
    // TODO: Ajouter le calcul des transactions pour avoir le solde réel
    return total;
  }
}

