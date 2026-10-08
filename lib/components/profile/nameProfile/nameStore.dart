import 'package:shared_preferences/shared_preferences.dart';

class ImageStorage {
  static const _key = 'profile_image_path';
  static Future<void> save(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }
  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key);
    return (path != null && path.isNotEmpty) ? path : null;
  }
}

class NameStorage {
  static const _key = 'first_name';
  static Future<void> save(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name);
  }
  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key);
    return (path != null && path.isNotEmpty) ? path : null;
  }
}

class LastNameStorage {
  static const _key = 'last_name';
  static Future<void> save(String lastName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lastName);
  }
  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key);
    return (path != null && path.isNotEmpty) ? path : null;
  }
}

class NumberStorage {
  static const _key = 'phone_number';

  static Future<void> save(String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, number);
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key);
    return (path != null && path.isNotEmpty) ? path : null;
  }
}

class EmailStorage {
  static const _key = 'email';

  static Future<void> save(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, email);
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_key);
    return (email != null && email.isNotEmpty) ? email : null;
  }
}

class LinkStorage {
  static const _appleKey = 'apple_connected';
  static const _googleKey = 'google_connected';
  static const _appleEmailKey = 'apple_email';
  static const _googleEmailKey = 'google_email';

  static Future<void> saveApple(bool connected, String? email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appleKey, connected);
    if (email != null) await prefs.setString(_appleEmailKey, email);
  }

  static Future<void> saveGoogle(bool connected, String? email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_googleKey, connected);
    if (email != null) await prefs.setString(_googleEmailKey, email);
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'apple': prefs.getBool(_appleKey) ?? false,
      'google': prefs.getBool(_googleKey) ?? false,
      'apple_email': prefs.getString(_appleEmailKey) ?? '',
      'google_email': prefs.getString(_googleEmailKey) ?? '',
    };
  }
}