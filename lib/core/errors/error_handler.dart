import 'exceptions.dart';
import 'failure.dart';

/// Gestionnaire d'erreurs centralisé
class ErrorHandler {
  /// Convertit une exception en Failure
  static Failure handleException(dynamic exception) {
    if (exception is AppException) {
      if (exception is DatabaseException) {
        return DatabaseFailure.fromException(exception);
      } else if (exception is ValidationException) {
        return ValidationFailure.fromException(exception);
      } else if (exception is NetworkException) {
        return NetworkFailure.fromException(exception);
      } else if (exception is AuthenticationException) {
        return AuthenticationFailure.fromException(exception);
      } else if (exception is PermissionException) {
        return PermissionFailure.fromException(exception);
      }
    }

    // Exception générique
    return GenericFailure(
      exception.toString(),
      code: 'UNKNOWN',
    );
  }

  /// Récupère un message d'erreur lisible pour l'utilisateur
  static String getUserFriendlyMessage(Failure failure) {
    if (failure is DatabaseFailure) {
      return 'Une erreur de base de données est survenue. Veuillez réessayer.';
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Problème de connexion. Vérifiez votre connexion internet.';
    } else if (failure is AuthenticationFailure) {
      return 'Erreur d\'authentification. Veuillez réessayer.';
    } else if (failure is PermissionFailure) {
      return 'Permission refusée. Veuillez vérifier les paramètres.';
    }

    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}

