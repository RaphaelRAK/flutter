import 'exceptions.dart';

/// Classe Failure pour représenter les erreurs dans l'application
/// Utilisée dans les use cases et repositories
abstract class Failure {
  final String message;
  final String? code;

  Failure(this.message, {this.code});

  @override
  String toString() => message;
}

/// Failure pour les erreurs de base de données
class DatabaseFailure extends Failure {
  DatabaseFailure(super.message, {super.code});

  factory DatabaseFailure.fromException(DatabaseException exception) {
    return DatabaseFailure(exception.message, code: exception.code);
  }
}

/// Failure pour les erreurs de validation
class ValidationFailure extends Failure {
  ValidationFailure(super.message, {super.code});

  factory ValidationFailure.fromException(ValidationException exception) {
    return ValidationFailure(exception.message, code: exception.code);
  }
}

/// Failure pour les erreurs de réseau
class NetworkFailure extends Failure {
  NetworkFailure(super.message, {super.code});

  factory NetworkFailure.fromException(NetworkException exception) {
    return NetworkFailure(exception.message, code: exception.code);
  }
}

/// Failure pour les erreurs d'authentification
class AuthenticationFailure extends Failure {
  AuthenticationFailure(super.message, {super.code});

  factory AuthenticationFailure.fromException(AuthenticationException exception) {
    return AuthenticationFailure(exception.message, code: exception.code);
  }
}

/// Failure pour les erreurs de permissions
class PermissionFailure extends Failure {
  PermissionFailure(super.message, {super.code});

  factory PermissionFailure.fromException(PermissionException exception) {
    return PermissionFailure(exception.message, code: exception.code);
  }
}

/// Failure générique
class GenericFailure extends Failure {
  GenericFailure(super.message, {super.code});
}

