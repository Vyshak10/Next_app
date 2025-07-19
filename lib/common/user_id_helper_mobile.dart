import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _storage = FlutterSecureStorage();

Future<String?> getUserId() async {
  String? id = await _storage.read(key: 'user_id');
  if (id == null) {
    final prefs = await SharedPreferences.getInstance();
    id = prefs.getString('user_id');
  }
  return id;
}

Future<void> setUserId(String id) async {
  await _storage.write(key: 'user_id', value: id);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_id', id);
} 