import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A remembered sign's word in the app's language: 'wordRu' / 'wordEn' are kept beside the Uzbek 'word'.
String storedWordFor(Map<String, dynamic> item, String lang) {
  final String? translated = switch (lang) { 'ru' => item['wordRu'], 'en' => item['wordEn'], _ => null };
  return translated == null || translated.isEmpty ? (item['word'] ?? '').toString() : translated;
}

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
    // only signs from the dashboard (words seen on the app's old category pages are dropped)
    return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).where((e) => e['source'] == 'api').take(maxItems).toList();
  }

  /// [source] + [id] say which dictionary category page and item the word came from, so it can be reopened.
  Future<void> add(String word, String image, {String? source, String? id, String? wordRu, String? wordEn}) async {
    final items = await load();
    items.removeWhere((e) => e['word'] == word);
    items.insert(0, {'word': word, 'wordRu': ?wordRu, 'wordEn': ?wordEn, 'image': image, 'source': ?source, 'id': ?id});
    if (items.length > maxItems) items.removeRange(maxItems, items.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items));
  }
}