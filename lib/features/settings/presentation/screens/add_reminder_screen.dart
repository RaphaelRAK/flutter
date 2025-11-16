import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../../../infrastructure/db/database_provider.dart';
import '../../../../infrastructure/db/drift_database.dart';
import '../../../../core/services/notification_service.dart';

class AddReminderScreen extends ConsumerStatefulWidget {
  final Reminder? reminderToEdit;

  const AddReminderScreen({super.key, this.reminderToEdit});

  @override
  ConsumerState<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 21, minute: 0);
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.reminderToEdit != null) {
      final reminder = widget.reminderToEdit!;
      _titleController.text = reminder.title;
      _messageController.text = reminder.message;
      _selectedTime = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
      _isActive = reminder.isActive;
    } else {
      _titleController.text = 'Rappel de dépenses';
      _messageController.text = 'N\'oubliez pas de renseigner vos dépenses';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminderToEdit == null
            ? 'Nouveau rappel'
            : 'Modifier le rappel'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titre
            Card(
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Card(
              child: TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  prefixIcon: Icon(Icons.message),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un message';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Heure
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Heure'),
                subtitle: Text(
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedTime = picked;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Actif/Inactif
            Card(
              child: SwitchListTile(
                title: const Text('Activer le rappel'),
                subtitle: const Text('Le rappel sera envoyé à l\'heure sélectionnée'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Bouton de sauvegarde
            ElevatedButton(
              onPressed: _saveReminder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.reminderToEdit == null
                  ? 'Créer le rappel'
                  : 'Modifier le rappel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final companion = RemindersCompanion(
        title: Value(_titleController.text),
        message: Value(_messageController.text),
        hour: Value(_selectedTime.hour),
        minute: Value(_selectedTime.minute),
        isActive: Value(_isActive),
      );

      if (widget.reminderToEdit == null) {
        final id = await ref.read(remindersDaoProvider).insertReminder(companion);
        // Programmer la notification
        final reminder = Reminder(
          id: id,
          title: _titleController.text,
          message: _messageController.text,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          isActive: _isActive,
          order: 0,
          createdAt: DateTime.now(),
        );
        try {
          await NotificationService.scheduleReminder(reminder);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rappel créé avec succès pour ${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                duration: const Duration(seconds: 3),
              ),
            );
            context.pop();
          }
        } catch (e) {
          // Si l'erreur persiste même après le fallback, afficher un message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rappel créé mais erreur lors de la programmation: $e'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Tester',
                  onPressed: () async {
                    try {
                      await NotificationService.showTestNotification();
                    } catch (testError) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur test: $testError')),
                        );
                      }
                    }
                  },
                ),
              ),
            );
            context.pop();
          }
        }
      } else {
        // Annuler l'ancienne notification
        await NotificationService.cancelReminder(widget.reminderToEdit!.id);
        
        await ref.read(remindersDaoProvider).updateReminder(
              companion.copyWith(id: Value(widget.reminderToEdit!.id)),
            );
        
        // Programmer la nouvelle notification
        final reminder = Reminder(
          id: widget.reminderToEdit!.id,
          title: _titleController.text,
          message: _messageController.text,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          isActive: _isActive,
          order: widget.reminderToEdit!.order,
          createdAt: widget.reminderToEdit!.createdAt,
        );
        try {
          await NotificationService.scheduleReminder(reminder);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rappel modifié avec succès')),
            );
            context.pop();
          }
        } catch (e) {
          // Si l'erreur persiste même après le fallback, afficher un message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rappel modifié mais erreur lors de la programmation: ${e.toString()}'),
                duration: const Duration(seconds: 5),
              ),
            );
            context.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showPermissionDialog(BuildContext context, bool isNew) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'Pour programmer des rappels précis, l\'application a besoin de la permission '
          'pour les alarmes exactes. Veuillez l\'activer dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openAppSettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isNew
                        ? 'Rappel créé. Activez la permission dans les paramètres.'
                        : 'Rappel modifié. Activez la permission dans les paramètres.'),
                  ),
                );
                context.pop();
              }
            },
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppSettings() async {
    if (Platform.isAndroid) {
      // Ouvrir les paramètres de l'application sur Android
      const packageName = 'com.example.flut_budget';
      try {
        // Essayer d'ouvrir directement les paramètres de l'application
        final uri = Uri.parse('package:$packageName');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // Si ça ne fonctionne pas, essayer les paramètres de notifications
        try {
          final settingsUri = Uri.parse('android.settings.APP_NOTIFICATION_SETTINGS');
          await launchUrl(settingsUri, mode: LaunchMode.externalApplication);
        } catch (e2) {
          // Dernier recours : paramètres généraux
          final generalSettings = Uri.parse('android.settings.SETTINGS');
          await launchUrl(generalSettings, mode: LaunchMode.externalApplication);
        }
      }
    } else if (Platform.isIOS) {
      // Ouvrir les paramètres de l'application sur iOS
      final settingsUri = Uri.parse('app-settings:');
      await launchUrl(settingsUri, mode: LaunchMode.externalApplication);
    }
  }
}

