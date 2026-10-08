import 'dart:async';

import 'package:flutter/material.dart';

import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiDictionary/server/apiSignPage.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/lesson_parts.dart';
import 'package:signlang/components/web/loading/bookLoading.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/theme_service.dart';

/// Every sign in the server dictionary (added in the dashboard), by category, with search.
class ApiSignList extends StatefulWidget {
  /// Category slug to open on (null = all signs)
  final String? initialCategory;
  const ApiSignList({super.key, this.initialCategory});

  @override
  State<ApiSignList> createState() => _ApiSignListState();
}

class _ApiSignListState extends State<ApiSignList> {
  List<ApiCategory> _categories = [];
  late String? _category = widget.initialCategory; // slug, null = all
  List<ApiSign>? _signs;
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _load();
    _search.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), _load);
    });
  }

  @override
  void dispose() { _debounce?.cancel(); _search.dispose(); super.dispose(); }

  Future<void> _loadCategories() async {
    try {
      final cats = await UzslApi.categories();
      if (mounted) setState(() => _categories = cats.where((c) => c.signCount > 0).toList());
    } on ApiException catch (e) {
      debugPrint('Categories not loaded: $e');
    }
  }

  Future<void> _load() async {
    final query = _search.text.trim();
    try {
      final signs = query.isEmpty ? await UzslApi.allSigns(category: _category) : (await UzslApi.signs(query: query, category: _category)).items;
      if (mounted) setState(() => _signs = signs);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _signs ??= []);
      showApiError(context, e, onRetry: _load);
    }
  }

  void _pickCategory(String? slug) {
    setState(() { _category = slug; _signs = null; });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final signs = _signs;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.bgGradient)),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 1) back · title =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.arrow_back_outlined)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(loc.translate('dict_all_signs'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text))),
                ]),
              ),
              // ===== 2) search =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: c.isDark ? c.card : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.cardBorder)),
                  child: TextField(
                    controller: _search, textInputAction: TextInputAction.search,
                    style: TextStyle(fontSize: 16, color: c.text),
                    decoration: InputDecoration(border: InputBorder.none, icon: Icon(Icons.search_rounded, color: c.subText), hintText: loc.translate('dict_search_hint'), hintStyle: TextStyle(color: c.subText)),
                  ),
                ),
              ),
              // ===== 3) categories =====
              SizedBox(
                height: 58,
                child: ListView(
                  scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  children: [
                    _categoryChip(loc.translate('all'), null, c),
                    for (final cat in _categories) _categoryChip('${cat.nameFor(lang)} · ${cat.signCount}', cat.slug, c),
                  ],
                ),
              ),
              // ===== 4) signs =====
              Expanded(
                child: signs == null
                    ? Center(child: BookLoader(label: loc.translate('loading')))
                    : signs.isEmpty
                        ? Center(child: Text(loc.translate('dict_no_results'), style: TextStyle(color: c.subText, fontSize: 15)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(16, 6, 16, 20 + MediaQuery.of(context).viewPadding.bottom),
                              itemCount: signs.length,
                              itemBuilder: (_, i) => ApiSignTile(sign: signs[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label, String? slug, AppColors c) {
    final bool active = _category == slug;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _pickCategory(slug),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppPalette.bg(lessonBlue) : (c.isDark ? c.chip : Colors.white.withValues(alpha: 0.7)), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? AppPalette.border(lessonBlue) : c.cardBorder),
          ),
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: active ? Colors.white : c.text)),
        ),
      ),
    );
  }
}

/// One server sign in a list, with the same look as the app's own word rows: picture, word,
/// syllables / translation, arrow. Opens the sign's page.
class ApiSignTile extends StatelessWidget {
  final ApiSign sign;
  const ApiSignTile({super.key, required this.sign});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final loc = AppLocalizations.of(context)!;
    final String word = sign.wordFor(lang);
    // like the app's own rows: the word and its syllables, both in the chosen language
    // (the dashboard's transcription in that language; otherwise the "Phrases" of the language file)
    final String? syllables = sign.ownTranscription(lang) ?? loc.phrasesFor(word);
    final String sub = syllables ?? loc.translate('dict_kind_${sign.kind}');
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApiSignPage(signId: sign.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
          boxShadow: [BoxShadow(color: AppPalette.shadow(const Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)],
        ),
        child: Row(children: [
          Container(
            height: 56, width: 56, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(16)),
            child: sign.thumbnail != null
                ? Image.network(sign.thumbnail!, fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(Icons.person, size: 35, color: AppPalette.fg(Colors.blue)))
                : Icon(Icons.person, size: 35, color: AppPalette.fg(Colors.blue)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (sub.isNotEmpty) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!))),
          ])),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE3F2FD)).withValues(alpha: 0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_right),
          ),
        ]),
      ),
    );
  }
}
