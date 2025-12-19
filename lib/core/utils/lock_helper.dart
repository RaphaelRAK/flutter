import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum LockType {
  none,
  pin,
  password,
  biometric,
}

class LockHelper {
  static const _storage = FlutterSecureStorage();
  static const _keyLockType = 'lock_type';
  static const _keyLockHash = 'lock_hash'; // Hash du PIN ou mot de passe

  /// Sauvegarde le type de verrouillage
  static Future<void> setLockType(LockType type) async {
    await _storage.write(key: _keyLockType, value: type.name);
  }

  /// Récupère le type de verrouillage
  static Future<LockType> getLockType() async {
    final value = await _storage.read(key: _keyLockType);
    if (value == null) return LockType.none;
    return LockType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LockType.none,
    );
  }

  /// Hash un PIN ou mot de passe
  static String _hashValue(String value) {
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sauvegarde le hash d'un PIN ou mot de passe
  static Future<void> setLockHash(String value) async {
    final hash = _hashValue(value);
    await _storage.write(key: _keyLockHash, value: hash);
  }

  /// Vérifie si un PIN ou mot de passe correspond
  static Future<bool> verifyLockValue(String value) async {
    final storedHash = await _storage.read(key: _keyLockHash);
    if (storedHash == null) return false;

    final inputHash = _hashValue(value);
    return storedHash == inputHash;
  }

  /// Supprime le verrouillage
  static Future<void> clearLock() async {
    await _storage.delete(key: _keyLockType);
    await _storage.delete(key: _keyLockHash);
  }

  /// Vérifie si un verrouillage est configuré
  static Future<bool> isLockEnabled() async {
    final type = await getLockType();
    return type != LockType.none;
  }
}









