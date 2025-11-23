import 'package:local_auth/local_auth.dart';
import '../errors/exceptions.dart';

/// Service pour l'authentification biométrique
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Vérifie si l'authentification biométrique est disponible
  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Récupère les types biométriques disponibles
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authentifie l'utilisateur avec la biométrie
  static Future<bool> authenticate({
    String localizedReason = 'Authentifiez-vous pour continuer',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
        ),
      );
    } catch (e) {
      throw AuthenticationException(
        'Erreur lors de l\'authentification biométrique: ${e.toString()}',
      );
    }
  }

  /// Vérifie si l'authentification biométrique est activée
  static Future<bool> isBiometricEnabled() async {
    try {
      final available = await isAvailable();
      if (!available) return false;

      final biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

