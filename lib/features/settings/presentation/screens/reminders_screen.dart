import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../core/widgets/navigation/main_bottom_nav_bar.dart';
import '../../../../core/services/notification_service.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rappels'),
        actions: [
          // Menu de test pour vérifier les notifications
          PopupMenuButton<String>(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Tester les notifications',
            onSelected: (value) async {
              try {
                if (value == 'immediate') {
                  await NotificationService.showTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification immédiate envoyée !'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else if (value == 'scheduled') {
                  await NotificationService.scheduleTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification programmée pour dans 5 secondes !'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors du test: $e'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'immediate',
                child: Row(
                  children: [
                    Icon(Icons.notifications, size: 20),
                    SizedBox(width: 8),
                    Text('Test immédiat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'scheduled',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20),
                    SizedBox(width: 8),
                    Text('Test programmé (5s)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/add-reminder');
            },
          ),
        ],
      ),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun rappel configuré',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez un rappel pour être notifié\nde renseigner vos dépenses',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return _buildReminderCard(context, ref, reminder);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) {
    final timeFormat = DateFormat('HH:mm');
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    final timeString = timeFormat.format(
      DateTime(2000, 1, 1, reminder.hour, reminder.minute),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: reminder.isActive
              ? Colors.blue.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          child: Icon(
            Icons.notifications,
            color: reminder.isActive ? Colors.blue : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminder.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              timeString,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: reminder.isActive ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reminder.isActive,
              onChanged: (value) async {
                await ref
                    .read(remindersDaoProvider)
                    .toggleReminder(reminder.id, value);
                // Reprogrammer les notifications
                await NotificationService.scheduleAllReminders(
                  ref.read(remindersDaoProvider),
                );
              },
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation(context, ref, reminder);
                } else if (value == 'edit') {
                  context.push('/add-reminder', extra: reminder);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rappel'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce rappel ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await NotificationService.cancelReminder(reminder.id);
              await ref.read(remindersDaoProvider).deleteReminder(reminder.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rappel supprimé')),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

