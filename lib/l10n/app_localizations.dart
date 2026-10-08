import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  Future<void> load() async {
    print(locale.languageCode);
    String jsonString = await rootBundle.loadString('lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // word -> its syllables from the "Phrases" part of the language file,
  // e.g. "uncle" -> "un-cle" (from "uncle" and "uncle_phrases")
  Map<String, String>? _phrasesByWord;

  // Same spelling for lookups: case, ё/е, the Uzbek apostrophes, spaces around "/"
  static String _norm(String word) => word.trim().toLowerCase().replaceAll('ё', 'е')
      .replaceAll(RegExp('[ʻʼ‘’`´]'), "'").replaceAll(RegExp(r'\s*/\s*'), '/').replaceAll(RegExp(r'\s+'), ' ');

  /// The pronunciation of [word] in this language, like the app's own word rows; null when unknown
  String? phrasesFor(String word) {
    final index = _phrasesByWord ??= () {
      final map = <String, String>{};
      for (final e in _localizedStrings.entries) {
        if (!e.key.endsWith('_phrases') || e.value.trim().isEmpty) continue;
        final title = _localizedStrings[e.key.substring(0, e.key.length - 8)];
        if (title == null) continue;
        // "Брат (старший / младший)" is also found as "Брат"
        final bare = title.replaceAll(RegExp(r'\s*\(.*?\)'), '');
        for (final w in {title, bare}) {
          map.putIfAbsent(_norm(w), () => e.value);
        }
      }
      return map;
    }();
    return index[_norm(word)];
  }
}
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'uz', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
