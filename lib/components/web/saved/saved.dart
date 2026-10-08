import 'dart:convert';
import 'package:signlang/services/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:signlang/services/theme_service.dart';
class Saved extends StatefulWidget {
  const Saved({super.key});

  @override
  State<Saved> createState() => _SavedState();
}

class _SavedState extends State<Saved> {
  bool _isLoading = true;
  int _selectedTab = 0;
  final SpeechToText _speech = SpeechToText();
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initData();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  void _onSearchChanged() { _filterItems(); }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        final matchesQuery = (item['word'] ?? '').toLowerCase().contains(query);
        final matchesTab = _selectedTab == 0 ||
          (_selectedTab == 1 && (item['type'] == 'word' || item['type'] == null)) ||
          (_selectedTab == 2 && item['type'] == 'phrase');
        return matchesQuery && matchesTab;
      }).toList();
    });
  }

// =======================================================================
  Future<void> _initializeData() async { await Future.wait([ AppLoading.ready() ]); if (!mounted) return; setState(() { _isLoading = false; }); }

  Future<void> _initData() async {
    final items = await SavedStore.instance.load();
    await AppLoading.ready();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
      _filterItems();
    });
  }

  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }

// ================================ Button ==================================
  void _handleNext() { Navigator.pop(context); }
  void _toggleSave(Map<String, dynamic> item) {
    // Optimistic update: remove from UI immediately
    setState(() { _items.removeWhere((e) => e['word'] == item['word']); _filterItems(); });

    SavedStore.instance.toggle(item);
  }

  void _handleVoiceSearch() async {
    final available = await _speech.initialize();
    _searchFocus.requestFocus();
    if (available) { _speech.listen(onResult: (result) { setState(() { _searchController.text = result.recognizedWords; _onSearchChanged(); }); }); }
  }

  @override
  Widget build(BuildContext context){
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Icon(Icons.arrow_back_outlined, color: AppPalette.fg(Color(0xFF334155)), size: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : ( _items.isEmpty ? _isNoSaved(loc) : _isSaved(loc) ))
              ],
            )
          ),
        ),
      ),
    );
  }

  Widget _searchBar(AppLocalizations loc) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: loc.translate('search_saved_hint'),
        hintStyle: TextStyle(color: AppPalette.fg(Colors.blueGrey), fontWeight: FontWeight.w400, fontSize: 16),
        prefixIcon: Icon(Icons.search, color: AppPalette.fg(Color(0xFF94A3B8))),
        suffixIcon: GestureDetector(
          onTap: _handleVoiceSearch,
          child: Padding(padding: const EdgeInsets.all(12), child: Image.asset('web/icons/voice.png', width: 26, height: 26)),
        ),
        filled: true,
        fillColor: AppPalette.bg(Color(0xFFEDF2F7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _tabs(AppLocalizations loc) {
    final tabs = [loc.translate('all'), loc.translate('words_tab'), loc.translate('phrases_tab')];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)]
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isActive = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _selectedTab = index); _filterItems(); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppPalette.bg(Color(0xFFE3F2FD)).withValues(alpha: 0.8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12), border: Border.all(width: isActive ? 1 : 0, color: isActive ? AppPalette.border(Colors.white) : Colors.transparent),
                ),
                child: Text(
                  tabs[index], textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? AppPalette.fg(Colors.black) : AppPalette.fg(Colors.grey[700]!)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _isNoSaved(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Image.asset('web/images/saved.png', height: 220),
          const SizedBox(height: 25),
          Text(loc.translate('no_saved_phrases'), textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A)))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(loc.translate('no_saved_phrases_sub'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18, color: AppPalette.fg(Colors.grey[600]!), height: 1.4)),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.bg(Color(0xFFBBDEFB)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                shadowColor: AppPalette.shadow(Color(0xFF0D47A1)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF0D47A1)).withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.translate('see_achievement'),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppPalette.fg(Colors.white))
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: AppPalette.fg(Colors.white), size: 20),
                ],
              )
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _isSaved(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.translate('saved'), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A)))),
              Text(loc.translate('saved_subtitle'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.grey[600]!))),
              const SizedBox(height: 24),
              _searchBar(loc),
              const SizedBox(height: 16),
              _tabs(loc),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6), physics: const BouncingScrollPhysics(),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) { final item = _filteredItems[index]; return _wordCard(item); },
          ),
        )
      ],
    );
  }

  Widget _wordCard(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.blue).withValues(alpha: 0.9), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              height: 64, width: 64, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), border: Border.all(width: 1, color: AppPalette.border(Color(0xFF80D8FF))), borderRadius: BorderRadius.circular(16)),
              child: Center(child: Image.asset(item['image'] ?? 'web/images/sign.png', width: 40, errorBuilder: (_, __, ___) => Icon(Icons.account_circle, size: 40, color: AppPalette.fg(Colors.grey)))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['word'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A)))),
                  const SizedBox(height: 4),
                  Text(item['phonetic'] ?? '', style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.grey[600]!)),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _toggleSave(item),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(12), border: Border.all(width: 1, color: AppPalette.border(Color(0xFF80D8FF)))),
                child: Icon(Icons.bookmark, color: AppPalette.fg(Color(0xFF4A7FD0)), size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedStore {
  SavedStore._();
  static final SavedStore instance = SavedStore._();
  static const _key = 'saved_words';

  Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final stored = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();

    // repair entries saved by older versions (whole lesson card instead of its text); drop empties and duplicates
    final seen = <String>{};
    final items = [
      for (final e in stored.map(_normalize))
        if ((e['word'] as String).isNotEmpty && seen.add(e['word'])) e,
    ];
    if (items.length != stored.length || !stored.every((e) => e['word'] is String)) {
      await prefs.setString(_key, jsonEncode(items));
    }
    return items;
  }

  Future<void> toggle(Map<String, dynamic> item) async {
    item = _normalize(item);
    if ((item['word'] as String).isEmpty) return;
    final items = await load();
    final index = items.indexWhere((e) => e['word'] == item['word']);
    if (index >= 0) {
      items.removeAt(index);
    } else {
      items.insert(0, item);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items));
  }

  /// Lessons may pass the whole card ({'image': ..., 'label': ...}) as the word; keep only its text.
  static Map<String, dynamic> _normalize(Map<String, dynamic> item) => {...item, 'word': _wordText(item['word'])};

  static String _wordText(dynamic word) {
    if (word is String) return word;
    if (word is Map) return (word['label'] ?? word['title'] ?? word['word'] ?? '').toString();
    return word?.toString() ?? '';
  }

  Future<bool> isSaved(String word) async {
    final items = await load();
    return items.any((e) => e['word'] == word);
  }
}
