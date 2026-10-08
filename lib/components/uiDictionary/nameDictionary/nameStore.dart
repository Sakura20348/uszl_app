import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LastSeenStore {
  LastSeenStore._();
  static final LastSeenStore instance = LastSeenStore._();
  static const _key = 'last_seen';
  /// How many recent words "Last seen" shows.
  static const maxItems = 4;

  Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).take(maxItems).toList();
  }

  /// [source] + [id] say which dictionary category page and item the word came from, so it can be reopened.
  Future<void> add(String word, String image, {String? source, String? id}) async {
    final items = await load();
    items.removeWhere((e) => e['word'] == word);
    items.insert(0, {'word': word, 'image': image, 'source': ?source, 'id': ?id});
    if (items.length > maxItems) items.removeRange(maxItems, items.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items));
  }
}