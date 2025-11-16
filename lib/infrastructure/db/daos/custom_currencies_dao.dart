import 'package:drift/drift.dart';
import '../drift_database.dart';

part 'custom_currencies_dao.g.dart';

@DriftAccessor(tables: [CustomCurrencies])
class CustomCurrenciesDao extends DatabaseAccessor<AppDatabase>
    with _$CustomCurrenciesDaoMixin {
  CustomCurrenciesDao(super.db);

  Future<List<CustomCurrency>> getAllCustomCurrencies() async {
    return await select(customCurrencies).get();
  }

  Stream<List<CustomCurrency>> watchAllCustomCurrencies() {
    return select(customCurrencies).watch();
  }

  Future<CustomCurrency?> getCurrencyByCode(String code) async {
    return (select(customCurrencies)..where((c) => c.code.equals(code)))
        .getSingleOrNull();
  }

  Future<int> insertCurrency(CustomCurrenciesCompanion currency) async {
    return await into(customCurrencies).insert(currency);
  }

  Future<bool> deleteCurrency(int id) async {
    return await (delete(customCurrencies)..where((c) => c.id.equals(id))).go() > 0;
  }

  Future<bool> deleteCurrencyByCode(String code) async {
    return await (delete(customCurrencies)..where((c) => c.code.equals(code))).go() > 0;
  }
}

