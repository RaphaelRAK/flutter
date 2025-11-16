import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'infrastructure/db/drift_database.dart';
import 'infrastructure/db/daos/accounts_dao.dart';
import 'infrastructure/db/daos/reminders_dao.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les notifications
  await NotificationService.initialize();
  
  // Initialiser la base de données et mettre à jour les catégories si nécessaire
  // On crée une instance temporaire juste pour la migration
  final database = AppDatabase();
  final accountsDao = AccountsDao(database);
  try {
    await accountsDao.updateAccountCategoriesAfterMigration();
  } catch (e) {
    // Ignorer les erreurs lors de la migration
  }
  
  // Programmer les rappels existants
  try {
    final remindersDao = RemindersDao(database);
    await NotificationService.scheduleAllReminders(remindersDao);
  } catch (e) {
    // Ignorer les erreurs si la table n'existe pas encore
  }
  
  await database.close();
  
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

