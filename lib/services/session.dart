import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class Session {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _keyToken = 'access_token';
  static const _keyVehicles = 'cached_vehicles';

  static Future<void> saveToken(String token) => _storage.write(key: _keyToken, value: token);
  static Future<String?> getToken() => _storage.read(key: _keyToken);
  static Future<void> clearToken() => _storage.delete(key: _keyToken);

  static Future<void> saveVehicles(List<dynamic> vehicles) async {
    final String jsonStr = jsonEncode(vehicles);
    await _storage.write(key: _keyVehicles, value: jsonStr);
  }

  static Future<List<dynamic>?> getVehicles() async {
    final String? jsonStr = await _storage.read(key: _keyVehicles);
    if (jsonStr != null) {
      return jsonDecode(jsonStr);
    }
    return null;
  }
}
