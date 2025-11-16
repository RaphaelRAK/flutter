import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart';
import '../../infrastructure/db/drift_database.dart';
import '../../infrastructure/db/daos/reminders_dao.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialiser timezone avec les données complètes
    initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized != true) {
      return;
    }

    // Créer le canal de notification pour Android 8+
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      const androidChannel = AndroidNotificationChannel(
        'reminders_channel',
        'Rappels de dépenses',
        description: 'Notifications pour rappeler de renseigner les dépenses',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation.createNotificationChannel(androidChannel);
    }

    // Demander les permissions pour Android 13+
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Gérer le tap sur la notification si nécessaire
  }

  static Future<bool> _canScheduleExactAlarms() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation == null) {
      return false;
    }
    
    return await androidImplementation.canScheduleExactNotifications() ?? false;
  }

  static Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isActive) {
      await cancelReminder(reminder.id);
      return;
    }

    // Annuler l'ancienne notification si elle existe
    await cancelReminder(reminder.id);

    // Utiliser le fuseau horaire local du système
    final now = tz.TZDateTime.now(tz.local);
    
    // Créer la date programmée avec le fuseau horaire local
    // L'heure et la minute sont déjà dans le fuseau horaire local de l'utilisateur
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );

    // Si l'heure est déjà passée aujourd'hui, programmer pour demain
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Debug: Afficher l'heure programmée
    print('📅 Programmation notification:');
    print('   Rappel ID: ${reminder.id}');
    print('   Titre: ${reminder.title}');
    print('   Heure demandée: ${reminder.hour}:${reminder.minute.toString().padLeft(2, '0')}');
    print('   Date programmée: $scheduledDate');
    print('   Fuseau horaire: ${scheduledDate.location.name}');
    print('   Maintenant: $now');

    // Vérifier si on peut programmer des alarmes exactes
    final canScheduleExact = await _canScheduleExactAlarms();
    var scheduleMode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    
    print('   Mode de programmation: ${canScheduleExact ? "EXACT" : "INEXACT"}');

    // Programmer une notification récurrente quotidienne
    try {
      await _notifications.zonedSchedule(
        reminder.id,
        reminder.title,
        reminder.message,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders_channel',
            'Rappels de dépenses',
            channelDescription: 'Notifications pour rappeler de renseigner les dépenses',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Répéter chaque jour à la même heure
      );
      
      print('   ✅ Notification programmée avec succès');
    } catch (e) {
      print('   ❌ Erreur lors de la programmation: $e');
      // Si l'erreur est liée aux alarmes exactes, essayer avec un mode moins strict
      if (e.toString().contains('exact_alarms_not_permitted') && 
          scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        // Réessayer avec le mode moins strict
        await _notifications.zonedSchedule(
          reminder.id,
          reminder.title,
          reminder.message,
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminders_channel',
              'Rappels de dépenses',
              channelDescription: 'Notifications pour rappeler de renseigner les dépenses',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        // Relancer l'erreur si ce n'est pas lié aux alarmes exactes
        rethrow;
      }
    }
  }

  static Future<void> scheduleAllReminders(RemindersDao remindersDao) async {
    final activeReminders = await remindersDao.getActiveReminders();
    
    for (final reminder in activeReminders) {
      await scheduleReminder(reminder);
    }
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  // Méthode de test pour vérifier que les notifications fonctionnent
  static Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'Test de notification',
      'Si vous voyez ce message, les notifications fonctionnent !',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Rappels de dépenses',
          channelDescription: 'Notifications pour rappeler de renseigner les dépenses',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // Programmer une notification de test dans 5 secondes
  static Future<void> scheduleTestNotification() async {
    // Annuler l'ancienne notification de test si elle existe
    await cancelReminder(999);
    
    final now = tz.TZDateTime.now(tz.local);
    final testDate = now.add(const Duration(seconds: 5));

    print('🧪 Test de notification programmée:');
    print('   Maintenant: $now');
    print('   Programmée pour: $testDate');
    print('   Dans: 5 secondes');

    // Vérifier si on peut programmer des alarmes exactes
    final canScheduleExact = await _canScheduleExactAlarms();
    final scheduleMode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    
    print('   Mode: ${canScheduleExact ? "EXACT" : "INEXACT"}');

    try {
      await _notifications.zonedSchedule(
        999,
        'Test de notification programmée',
        'Cette notification a été programmée pour dans 5 secondes',
        testDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders_channel',
            'Rappels de dépenses',
            channelDescription: 'Notifications pour rappeler de renseigner les dépenses',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('   ✅ Notification de test programmée avec succès');
    } catch (e) {
      print('   ❌ Erreur lors de la programmation du test: $e');
      
      // Si l'erreur est liée aux alarmes exactes, essayer avec un mode moins strict
      if (e.toString().contains('exact_alarms_not_permitted') && 
          scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        print('   🔄 Réessai avec mode INEXACT...');
        try {
          await _notifications.zonedSchedule(
            999,
            'Test de notification programmée',
            'Cette notification a été programmée pour dans 5 secondes',
            testDate,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'reminders_channel',
                'Rappels de dépenses',
                channelDescription: 'Notifications pour rappeler de renseigner les dépenses',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          print('   ✅ Notification de test programmée avec mode INEXACT');
        } catch (e2) {
          print('   ❌ Erreur même avec mode INEXACT: $e2');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }
}

