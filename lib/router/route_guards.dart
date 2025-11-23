import 'package:go_router/go_router.dart';
import '../core/utils/helpers/lock_helper.dart';
import '../core/constants/route_names.dart';

/// Guards de navigation pour protéger certaines routes
class RouteGuards {
  /// Vérifie si l'utilisateur est authentifié (verrouillé)
  static Future<bool> checkLock(GoRouterState state) async {
    final isLockEnabled = await LockHelper.isLockEnabled();
    
    // Si le verrouillage est activé et qu'on n'est pas déjà sur l'écran de verrouillage
    if (isLockEnabled && state.matchedLocation != RouteNames.lock) {
      // Rediriger vers l'écran de verrouillage
      return false; // Empêcher l'accès
    }
    
    return true; // Autoriser l'accès
  }

  /// Vérifie si c'est le premier lancement
  static Future<bool> checkFirstLaunch(GoRouterState state) async {
    // Cette logique est gérée dans app_router.dart
    // On peut ajouter d'autres vérifications ici si nécessaire
    return true;
  }
}

