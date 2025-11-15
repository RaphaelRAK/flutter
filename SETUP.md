# Instructions de configuration

## Étapes pour démarrer le projet

1. **Installer les dépendances Flutter**
```bash
flutter pub get
```

2. **Générer les fichiers de code (Drift, Riverpod)**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Créer les fichiers de configuration Android/iOS** (si nécessaire)
```bash
flutter create .
```

4. **Lancer l'application**
```bash
flutter run
```

## Structure du projet

Le projet suit une architecture en couches :

- **lib/core/** : Thème, utilitaires, constantes
- **lib/domain/** : Modèles métier, enums
- **lib/infrastructure/** : Base de données (Drift), DAOs, providers
- **lib/application/** : Services métiers (à implémenter)
- **lib/features/** : Écrans et contrôleurs par fonctionnalité
- **lib/router/** : Configuration de navigation (go_router)

## Fonctionnalités implémentées

✅ Structure de base Flutter avec toutes les dépendances
✅ Thème sombre/clair inspiré des apps fintech
✅ Base de données Drift avec tous les modèles
✅ DAOs pour accès aux données
✅ Providers Riverpod pour la gestion d'état
✅ Navigation avec go_router
✅ Écran d'onboarding (3 étapes)
✅ Dashboard avec solde, résumé du mois, liste des transactions

## Fonctionnalités à implémenter

- [ ] Formulaire d'ajout de transaction
- [ ] Liste complète des transactions
- [ ] Gestion des budgets
- [ ] Gestion des objectifs d'épargne
- [ ] Statistiques avec graphiques (fl_chart)
- [ ] Notifications locales
- [ ] Tâches de fond (workmanager)
- [ ] Export des données
- [ ] Paramètres complets
- [ ] Sécurité (PIN, biométrie)

## Notes importantes

- La base de données se crée automatiquement au premier lancement avec les catégories par défaut
- Le premier lancement redirige vers l'onboarding
- Les données sont stockées localement (local first)
- Le thème par défaut est sombre

