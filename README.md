# Flut Budget

Application de gestion de budget - Local first, sans compte

## Architecture

- **Presentation** : Widgets Flutter, écrans, composants UI
- **Application** : Services métiers, use cases, orchestrations
- **Domain** : Modèles métier, interfaces de repositories, règles métier
- **Infrastructure** : Implémentations des repositories, accès DB locale, notifications

## Stack technique

- Flutter (Dart)
- Riverpod (State Management)
- go_router (Navigation)
- Drift (Base de données locale)
- flutter_secure_storage (Stockage sécurisé)
- flutter_local_notifications (Notifications)
- workmanager (Tâches de fond)
- fl_chart (Graphiques)

## Développement

```bash
# Installer les dépendances
flutter pub get

# Générer les fichiers (Drift, Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# Lancer l'application
flutter run
```

# flutter
# flutter
