import 'package:drift/drift.dart';
import '../drift_database.dart';

part 'reminders_dao.g.dart';

@DriftAccessor(tables: [Reminders])
class RemindersDao extends DatabaseAccessor<AppDatabase>
    with _$RemindersDaoMixin {
  RemindersDao(super.db);

  Future<List<Reminder>> getAllReminders() async {
    return (select(reminders)
          ..orderBy([(r) => OrderingTerm.asc(r.hour), (r) => OrderingTerm.asc(r.minute)]))
        .get();
  }

  Stream<List<Reminder>> watchAllReminders() {
    return (select(reminders)
          ..orderBy([(r) => OrderingTerm.asc(r.hour), (r) => OrderingTerm.asc(r.minute)]))
        .watch();
  }

  Future<List<Reminder>> getActiveReminders() async {
    return (select(reminders)
          ..where((r) => r.isActive.equals(true))
          ..orderBy([(r) => OrderingTerm.asc(r.hour), (r) => OrderingTerm.asc(r.minute)]))
        .get();
  }

  Future<Reminder?> getReminderById(int id) async {
    return (select(reminders)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertReminder(RemindersCompanion reminder) async {
    return await into(reminders).insert(reminder);
  }

  Future<bool> updateReminder(RemindersCompanion reminder) async {
    return await update(reminders).replace(reminder);
  }

  Future<bool> deleteReminder(int id) async {
    return await (delete(reminders)..where((r) => r.id.equals(id))).go() > 0;
  }

  Future<bool> toggleReminder(int id, bool isActive) async {
    final result = await (update(reminders)..where((r) => r.id.equals(id)))
        .write(RemindersCompanion(isActive: Value(isActive)));
    return result > 0;
  }
}

