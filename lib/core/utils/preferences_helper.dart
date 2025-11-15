import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesHelper {
  static const _storage = FlutterSecureStorage();
  static const _keyFirstLaunch = 'first_launch';

  static Future<bool> isFirstLaunch() async {
    final value = await _storage.read(key: _keyFirstLaunch);
    return value == null || value == 'true';
  }

  static Future<void> setFirstLaunchCompleted() async {
    await _storage.write(key: _keyFirstLaunch, value: 'false');
  }
}

