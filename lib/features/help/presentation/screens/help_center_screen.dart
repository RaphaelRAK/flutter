import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final helpCategories = [
      {
        'title': 'Premiers pas',
        'icon': Icons.play_circle_outline,
        'items': [
          'Comment créer un compte',
          'Comment ajouter une transaction',
          'Comment définir un budget',
        ],
      },
      {
        'title': 'Fonctionnalités',
        'icon': Icons.featured_play_list,
        'items': [
          'Transactions récurrentes',
          'Transferts entre comptes',
          'Graphiques et statistiques',
          'Export de données',
        ],
      },
      {
        'title': 'Paramètres',
        'icon': Icons.settings,
        'items': [
          'Changer la devise',
          'Personnaliser les couleurs',
          'Configurer les rappels',
          'Sauvegarde et restauration',
        ],
      },
      {
        'title': 'Problèmes courants',
        'icon': Icons.help_outline,
        'items': [
          'L\'application ne démarre pas',
          'Les données ne se synchronisent pas',
          'Comment restaurer une sauvegarde',
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre d\'aide'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: helpCategories.length,
        itemBuilder: (context, index) {
          final category = helpCategories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: Icon(category['icon'] as IconData),
              title: Text(category['title'] as String),
              children: (category['items'] as List<String>).map((item) {
                return ListTile(
                  title: Text(item),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    // TODO: Naviguer vers la page de détail de l'aide
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Aide: $item')),
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

