import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service pour le stockage sécurisé
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  /// Écrit une valeur
  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Lit une valeur
  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Supprime une valeur
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Supprime toutes les valeurs
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Vérifie si une clé existe
  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
}

