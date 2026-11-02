import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiDictionary/server/apiSignList.dart';
import 'package:signlang/components/uiDictionary/server/category_icon.dart';
import 'package:signlang/components/uiDictionary/server/apiSignPage.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiDictionary/group/all/allPhrases.dart';
import 'package:signlang/components/web/emergency/emergencyPhrases.dart';
import 'package:signlang/components/uiDictionary/skeleton/skeleton.dart';
import 'package:signlang/components/web/download/download.dart';
import 'package:signlang/components/web/saved/saved.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:signlang/services/theme_service.dart';

import '../components/uiDictionary/nameDictionary/nameStore.dart';
import '../l10n/app_localizations.dart';

class Dictionary extends StatefulWidget{
  final bool autoFocusSearch;
  final VoidCallback? onSearchFocused;
  const Dictionary({super.key, required this.autoFocusSearch, this.onSearchFocused});

  @override
  State<Dictionary> createState() => _DictionaryState();
}

class _DictionaryState extends State<Dictionary>{
  AppColors get c => AppColors.of(context);
  bool _isLoading = true; bool _searching = false;
  int tabIndex = 1; int selectedDictionaryCards = -1;
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();


// =======================================================================
// name things
// =======================================================================
  /// Dashboard signs watched last (empty until loaded)
  List<Map<String, dynamic>> lastSeen = [];

// =======================================================================
  // signs from the server dictionary (added in the dashboard)
  List<ApiSign> _serverResults = [];
  /// Dictionary categories from the dashboard: the app shows exactly these (null until loaded)
  List<ApiCategory>? _serverCategories;
  static const String _categoriesPrefsKey = 'dictionary_categories';
  /// The categories couldn't be loaded and none were saved before (offline on the first start)
  bool _categoriesFailed = false;
  /// How many categories "Celebrities" shows; "All phrases" shows every one
  static const int _featuredCount = 4;

  /// Signs of a dashboard category (by slug); null while loading
  final Map<String, List<ApiSign>?> _categorySigns = {};

  Future<void> _loadCategorySigns(String slug) async {
    setState(() => _categorySigns[slug] = null);
    try {
      final signs = await UzslApi.allSigns(category: slug);
      if (mounted) setState(() => _categorySigns[slug] = signs);
    } catch (e) {
      debugPrint('Signs of $slug not loaded: $e');
      if (mounted) setState(() => _categorySigns[slug] = []);
    }
  }

  /// The dashboard category of the picked chip (chip 0 is "All"), or null
  ApiCategory? get _pickedServerCategory {
    final cats = _serverCategories;
    final i = selectedDictionaryCards;
    return cats != null && i > 0 && i <= cats.length ? cats[i - 1] : null;
  }

  Timer? _serverSearch;
  /// A search is waiting for the server
  bool _searchBusy = false;
  /// The last search couldn't reach the server
  bool _searchFailed = false;

  /// The categories saved last time (for offline starts), then fresh ones from the server
  Future<void> _loadServerCategories() async {
    if (_serverCategories == null) {
      try {
        final saved = (await SharedPreferences.getInstance()).getString(_categoriesPrefsKey);
        if (saved != null && mounted && _serverCategories == null) { setState(() => _serverCategories = (jsonDecode(saved) as List).map((e) => ApiCategory.fromJson(e as Map<String, dynamic>)).toList()); }
      } catch (_) {}
    }
    try {
      final cats = await UzslApi.categories();
      if (mounted) setState(() { _serverCategories = cats; _categoriesFailed = false; });
      (await SharedPreferences.getInstance()).setString(_categoriesPrefsKey, jsonEncode([for (final c in cats) c.toJson()]));
    } catch (e) {
      debugPrint('Dictionary categories not loaded: $e');
      if (mounted && _serverCategories == null) setState(() => _categoriesFailed = true);
    }
  }

  @override
  void initState(){
    super.initState();
    _loadServerCategories();
    _searchFocus.addListener(() { setState(() => _searching = _searchFocus.hasFocus || _searchController.text.isNotEmpty); });
    _searchController.addListener(_onSearchChanged);
    _initData();
  }

  @override
  void dispose() { _serverSearch?.cancel(); _searchController.dispose(); _searchFocus.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(Dictionary old) {
    super.didUpdateWidget(old);
    if (widget.autoFocusSearch && !old.autoFocusSearch) { WidgetsBinding.instance.addPostFrameCallback((_) { _searchFocus.requestFocus(); widget.onSearchFocused?.call(); }); }
  }

  @override
  void didChangeDependencies() { super.didChangeDependencies(); _loadLastSeen(); }

// =======================================================================
  Future<void> _initializeData() async { await Future.wait([ AppLoading.ready(), ]); if (!mounted) return; setState(() { _isLoading = false; }); }
  Future<void> _handleRefresh() async {
    await Future.wait([_initializeData(), _loadServerCategories()]);
    final picked = _pickedServerCategory;
    if (picked != null) await _loadCategorySigns(picked.slug); // new signs from the dashboard
  }
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _loadLastSeen() async { final items = await LastSeenStore.instance.load(); if (mounted) setState(() => lastSeen = items); }

// ================================ Button ==================================
  void _handleEmergency() { Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyPhrases())); }
  /// Every dashboard category; picking one there opens its signs here
  void _handleAllPhrases() async {
    final picked = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => AllPhrases(categories: _serverCategories ?? const [])));
    if (picked != null && mounted) onDictionaryCardsTap(picked + 1);
  }
  void _handleVoiceSearch() async {
    final available = await _speech.initialize();
    _searchFocus.requestFocus(); if (available) { _speech.listen(onResult: (result) { setState(() { _searchController.text = result.recognizedWords; _onSearchChanged(); }); }); }
  }
  void _exitSearch() { _searchController.clear(); _searchFocus.unfocus(); setState(() => _searching = false); }
  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() => _searching = _searchFocus.hasFocus || q.isNotEmpty);
    // search the dashboard's dictionary (debounced)
    _serverSearch?.cancel();
    if (q.isEmpty) { setState(() { _serverResults = []; _searchBusy = false; _searchFailed = false; }); return; }
    setState(() => _searchBusy = true);
    _serverSearch = Timer(const Duration(milliseconds: 350), () async {
      try {
        final page = await UzslApi.signs(query: q, limit: 30);
        if (!mounted || _searchController.text.trim().toLowerCase() != q) return;
        setState(() { _serverResults = page.items; _searchBusy = false; _searchFailed = false; });
      } catch (e) {
        debugPrint('Dictionary search on the server failed: $e');
        if (mounted) setState(() { _serverResults = []; _searchBusy = false; _searchFailed = true; });
      }
    });
  }
  void onDictionaryCardsTap(int index) {
    setState(() => selectedDictionaryCards = index);
    final cat = _pickedServerCategory;
    if (cat != null) _loadCategorySigns(cat.slug);
  }
  /// Opens a "Last seen" word's video page again; watching it moves it back to the front.
  Future<void> _playSign(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');
    if (id == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ApiSignPage(signId: id)));
    _loadLastSeen();
  }

// =======================================================================
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: c.surface,
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.bgGradient)),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                if (_isLoading)
                // ======= 1 =======
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: c.isDark ? Colors.white12 : Colors.grey[200]!, highlightColor: const Color(0xFF42A5F5).withValues(alpha: 0.2), child: DictionarySkeleton.buildSkeleton()))
                else ... [
                  // ======= 2 =======
                  SliverToBoxAdapter(child: _header(context)),
                  if(_searching)
                    _searchBusy && _serverResults.isEmpty
                      ? const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))) : _searchFailed
                      ? SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: _offlineNotice(_onSearchChanged))) : _serverResults.isEmpty
                      ? SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: Center(child: Text(AppLocalizations.of(context)!.translate('dict_no_results')))))
                      : SliverList(delegate: SliverChildBuilderDelegate((_, i) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: ApiSignTile(sign: _serverResults[i])), childCount: _serverResults.length))
                  else ...[ SliverToBoxAdapter(child: _cardsView()), SliverToBoxAdapter(child: _browseView()), SliverFillRemaining(hasScrollBody: false, child: ColoredBox(color: c.surface)) ]
                ]
              ]
            )
          )
        )
      )
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_searching)
                GestureDetector(
                  onTap: _exitSearch,
                  child: Container(width: 46, height: 46, decoration: BoxDecoration(color: c.isDark ? c.chip : Colors.white, borderRadius: BorderRadius.circular(15)), child: Icon(Icons.arrow_back, color: c.isDark ? c.text : const Color(0xFF334155)))
                )
              else
                const SizedBox(width: 46),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {Navigator.push(context, MaterialPageRoute(builder: (_) => const Download()));},
                      child: Container(width: 46, height: 46, decoration: BoxDecoration(color: c.isDark ? c.chip : Colors.white, borderRadius: BorderRadius.circular(15)), child: Icon(Icons.download, color: c.text))
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const Saved())); },
                      child: Container(width: 46, height: 46, decoration: BoxDecoration(color: c.isDark ? c.chip : Colors.white, borderRadius: BorderRadius.circular(15)), child: Icon(Icons.bookmark, color: c.text))
                    )
                  ]
                )
            ]
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController, focusNode: _searchFocus,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('search_word'), hintStyle: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w400, fontSize: 16),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
              suffixIcon: GestureDetector(onTap: _handleVoiceSearch, child: Padding(padding: const EdgeInsets.all(12), child: Image.asset('web/icons/voice.webp', width: 26, height: 26))),
              suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              filled: true, fillColor: c.isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEDF2F7), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)
            )
          )
        ]
      )
    );
  }
// =======================================================================
// Cards View
// =======================================================================
  Widget _cardsView() {
    final lang = Localizations.localeOf(context).languageCode;
    final List<Map<String, dynamic>> chips = [
      {'icon': CategoryIcon.all, 'title': AppLocalizations.of(context)!.translate('all')},
      for (final cat in _serverCategories ?? const <ApiCategory>[]) {'icon': cat.icon ?? CategoryIcon.bySlug[cat.slug] ?? CategoryIcon.fallback, 'title': cat.nameFor(lang)},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(chips.length, (index) {
            final item = chips[index];
            final isActive = selectedDictionaryCards == index || (selectedDictionaryCards == -1 && index == 0);
            return Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: GestureDetector(
                onTap: () => onDictionaryCardsTap(index),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                  decoration: BoxDecoration(
                    color: isActive ? c.card : c.chip, border: Border.all(width: 1, color: c.isDark ? c.cardBorder : (isActive ? const Color(0xFFE0F7FA) : Colors.white)),
                    borderRadius: BorderRadius.circular(17), boxShadow: [BoxShadow(color: isActive ? c.glow : (c.isDark ? Colors.transparent : Colors.grey), blurRadius: 15)]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CategoryIcon(item['icon'], size: 20, color: isActive ? (c.isDark ? c.accent : AppPalette.season(Colors.blue[900]!)) : c.text), const SizedBox(width: 8),
                      Text(item['title'], style: TextStyle(color: isActive ? (c.isDark ? c.accent : AppPalette.season(Colors.blue[900]!)) : c.text, fontSize: 16, fontWeight: FontWeight.w600))
                    ]
                  )
                )
              )
            );
          })
        )
      )
    );
  }

  Widget _browseView() {
    final picked = _pickedServerCategory;
    if (picked != null) return _serverCategorySigns(picked);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), decoration: BoxDecoration(color: c.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _emergencyBanner(), const SizedBox(height: 18), _lastSeenSection(), const SizedBox(height: 18),
          // "Celebrities": the first categories made in the dashboard (names, counts and order from there)
          if (_serverCategories != null)
            for (final cat in _serverCategories!.take(_featuredCount)) _serverCategoryRow(cat)
          else if (_categoriesFailed)
            _offlineNotice(_loadServerCategories)
          else
            const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
        ]
      )
    );
  }

// =======================================================================
// That isAll group
// =======================================================================
  Widget _emergencyBanner(){
    const String imageEmergency = 'web/icons/emergency.webp';
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== 1) emergency =====
        GestureDetector(
          onTap: _handleEmergency,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: Colors.red), boxShadow: [BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.9), blurRadius: 15)]),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFEBEE).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14), border: Border.all(width: 1, color: const Color(0xFFFFEBEE))),
                    child: Image.asset(imageEmergency, width: 25, height: 25),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.translate('emergency_phrases'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                        Text(loc.translate('emergency_phrases_sub'), style: TextStyle(fontSize: 13, color: Colors.grey[300])),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFFFEBEE).withValues(alpha: 0.6), border: Border.all(width: 1, color: const Color(0xFFFFEBEE)), shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_right, size: 20)
                  )
                ]
              )
            )
          )
        )
      ]
    );
  }
  Widget _lastSeenSection() {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('last_seen'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: c.text)), const SizedBox(height: 16),
        lastSeen.isEmpty
          ? Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 30), decoration: BoxDecoration(color: c.isDark ? c.chip : const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(20)),
            child: Column(children: [Icon(Icons.history, size: 40, color: Colors.grey[400]), const SizedBox(height: 8), Text(loc.translate('no_recent'), style: TextStyle(fontSize: 15, color: Colors.grey[600]))])
          )
          : SizedBox(height: 150, child: ListView.builder(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: lastSeen.length, itemBuilder: (_, index) => _lastSeenCard(lastSeen[index]))),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.translate('celebrities'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: c.text)),
            GestureDetector(
              onTap: _handleAllPhrases,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: c.cardBorder), boxShadow: [BoxShadow(color: c.glow, blurRadius: 15, offset: const Offset(0, 6))]),
                child: Row(children: [Text(loc.translate('all_phrases'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: c.text)), const SizedBox(width: 2), Icon(Icons.keyboard_arrow_right_outlined, size: 19, color: c.text)])
              )
            )
          ]
        ),
        const SizedBox(height: 8)
      ]
    );
  }

  Widget _lastSeenCard(Map<String, dynamic> item) {
    final String image = item['image'] ?? '', label = storedWordFor(item, Localizations.localeOf(context).languageCode);
    return GestureDetector(
      onTap: () => _playSign(item),
      child: Container(
        width: 150, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: c.chip, border: Border.all(width: 1, color: c.cardBorder), borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            // character image
            Positioned.fill(
              top: 15,
              child: ClipRRect(
                child: image.startsWith('http') ? Image.network(image, errorBuilder: (_, _, _) => const Icon(Icons.person, size: 60, color: Colors.blue)) : Image.asset(image, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: Colors.blue))
              )
            ),
            // play button top-right
            Positioned(
              top: 10, right: 10,
              child: Container(
                height: 35, width: 35, decoration: BoxDecoration(color: AppPalette.season(const Color(0xFF4A7FD0)).withValues(alpha: 0.3), shape: BoxShape.circle),
                child: Center(child: Container(height: 20, width: 20, decoration: BoxDecoration(color: AppPalette.season(const Color(0xFF4A7FD0)), shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.white, size: 18)))
              )
            ),
            // word label bottom
            Positioned(
              left: 10, right: 10, bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.white).withValues(alpha: 0.9), blurRadius: 15)]),
                child: Center(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.fg(const Color(0xFF0F172A)))))
              )
            )
          ]
        )
      )
    );
  }

// =======================================================================
  /// The signs of a dashboard category, as the dashboard shows them.
  Widget _serverCategorySigns(ApiCategory cat) {
    final loc = AppLocalizations.of(context)!;
    final signs = _categorySigns[cat.slug];
    List<ApiSign> ofKind(String kind) => (signs ?? const <ApiSign>[]).where((s) => s.kind == kind).toList()..sort(ApiSign.compare);
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 20, 16, 20), decoration: BoxDecoration(color: c.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: signs == null
        ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())) : signs.isEmpty
          ? Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(loc.translate('dict_no_results'), style: TextStyle(fontSize: 15, color: c.subText))))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // words first, then phrases (letters, numbers)
            for (final kind in const ['word', 'phrase', 'letter', 'number'])
              for (final sign in ofKind(kind)) ApiSignTile(sign: sign)
          ])
    );
  }

  /// The server can't be reached: a message and a retry button
  Widget _offlineNotice(VoidCallback onRetry) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(color: c.isDark ? c.chip : const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Icon(Icons.wifi_off, size: 36, color: Colors.grey[500]), const SizedBox(height: 8),
        Text(loc.translate('no_internet'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: c.subText)),
        TextButton(onPressed: onRetry, child: Text(loc.translate('try_again'))),
      ]),
    );
  }

  /// A dashboard category as a row: its name in the app's language and how many signs it has.
  Widget _serverCategoryRow(ApiCategory cat) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final unit = lang == 'uz' && (cat.unitLabel?.isNotEmpty ?? false) ? cat.unitLabel! : loc.translate('dict_signs_count');
    return _categoryRow({'icon': cat.icon ?? CategoryIcon.bySlug[cat.slug] ?? CategoryIcon.fallback, 'title': cat.nameFor(lang), 'title_sub': '${cat.signCount} $unit'}, onTap: () => onDictionaryCardsTap((_serverCategories?.indexOf(cat) ?? -1) + 1));
  }

// =======================================================================
// that not isAll group if other cards all group subject
// =======================================================================
  Widget _categoryRow(Map<String, dynamic> item, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: c.cardBorder), boxShadow: [BoxShadow(color: c.glow, blurRadius: 15)]),
        child: Row(
          children: [
            Container(height: 56, width: 56, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Center(child: CategoryIcon(item['icon'], size: 28, color: AppPalette.season(Colors.blue[700]!)))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'], style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.text)),
                  Text(item['title_sub'] ?? '', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: c.isDark ? c.subText : Colors.grey[700]))
                ]
              )
            ),
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: c.chip, border: Border.all(width: 1, color: c.cardBorder), shape: BoxShape.circle), child: const Icon(Icons.chevron_right))
          ]
        )
      )
    );
  }

}
