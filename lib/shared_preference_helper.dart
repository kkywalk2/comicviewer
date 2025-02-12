import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  static const String _key = "remote_server_data";

  static Future<void> saveJson(Map<String, dynamic> jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(jsonData);
    await prefs.setString(_key, jsonString);
  }

  static Future<Map<String, dynamic>> loadJson() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_key);
    if (jsonString == null) return <String, dynamic>{};
    return jsonDecode(jsonString);
  }
}
