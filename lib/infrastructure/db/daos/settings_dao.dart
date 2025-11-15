import 'package:drift/drift.dart';
import '../drift_database.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(AppDatabase db) : super(db);

  Future<Setting> getSettings() async {
    return (select(settings)..where((s) => s.id.equals(1)))
        .getSingle();
  }

  Stream<Setting> watchSettings() {
    return (select(settings)..where((s) => s.id.equals(1))).watchSingle();
  }

  Future<bool> updateSettings(SettingsCompanion settingsCompanion) {
    return update(settings)
        .replace(settingsCompanion.copyWith(id: const Value(1)));
  }
}

