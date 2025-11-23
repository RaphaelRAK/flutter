/// Exceptions personnalisées de l'application
/// 
/// Exception de base pour toutes les exceptions de l'application
abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Exception pour les erreurs de base de données
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code});
}

/// Exception pour les erreurs de validation
class ValidationException extends AppException {
  ValidationException(super.message, {super.code});
}

/// Exception pour les erreurs de réseau (si ajouté plus tard)
class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

/// Exception pour les erreurs d'authentification
class AuthenticationException extends AppException {
  AuthenticationException(super.message, {super.code});
}

/// Exception pour les erreurs de permissions
class PermissionException extends AppException {
  PermissionException(super.message, {super.code});
}

