import 'package:drift/drift.dart';
import '../drift_database.dart';

part 'recurring_rules_dao.g.dart';

@DriftAccessor(tables: [RecurringRules])
class RecurringRulesDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringRulesDaoMixin {
  RecurringRulesDao(super.db);

  Future<List<RecurringRule>> getAllRecurringRules() async {
    return (select(recurringRules)
          ..orderBy([(r) => OrderingTerm.desc(r.startDate)]))
        .get();
  }

  Stream<List<RecurringRule>> watchAllRecurringRules() {
    return (select(recurringRules)
          ..orderBy([(r) => OrderingTerm.desc(r.startDate)]))
        .watch();
  }

  Future<List<RecurringRule>> getActiveRecurringRules() async {
    return (select(recurringRules)
          ..where((r) => r.isActive.equals(true))
          ..orderBy([(r) => OrderingTerm.desc(r.startDate)]))
        .get();
  }

  Future<RecurringRule?> getRecurringRuleById(int id) async {
    return (select(recurringRules)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertRecurringRule(RecurringRulesCompanion rule) async {
    return await into(recurringRules).insert(rule);
  }

  Future<bool> updateRecurringRule(RecurringRulesCompanion rule) async {
    return await update(recurringRules).replace(rule);
  }

  Future<bool> deleteRecurringRule(int id) async {
    return await (delete(recurringRules)..where((r) => r.id.equals(id))).go() > 0;
  }

  Future<bool> toggleRecurringRule(int id, bool isActive) async {
    final result = await (update(recurringRules)..where((r) => r.id.equals(id)))
        .write(RecurringRulesCompanion(isActive: Value(isActive)));
    return result > 0;
  }
}

