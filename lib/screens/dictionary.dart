import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiDictionary/server/apiSignList.dart';
import 'package:signlang/components/uiDictionary/server/category_icon.dart';
import 'package:signlang/components/uiDictionary/server/apiSignPage.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiDictionary/group/all/allPhrases.dart';
import 'package:signlang/components/web/emergency/emergencyPhrases.dart';
import 'package:signlang/components/uiDictionary/group/name/birthOrderMultiples.dart';
import 'package:signlang/components/uiDictionary/group/name/cereal.dart';
import 'package:signlang/components/uiDictionary/group/name/dairy.dart';
import 'package:signlang/components/uiDictionary/group/name/extended_family.dart';
import 'package:signlang/components/uiDictionary/group/name/food.dart';
import 'package:signlang/components/uiDictionary/group/name/fruits.dart';
import 'package:signlang/components/uiDictionary/group/name/householdLineageTerms.dart';
import 'package:signlang/components/uiDictionary/group/name/immediateFamily.dart';
import 'package:signlang/components/uiDictionary/group/name/numberFive.dart';
import 'package:signlang/components/uiDictionary/group/name/numberFour.dart';
import 'package:signlang/components/uiDictionary/group/name/numberOne.dart';
import 'package:signlang/components/uiDictionary/group/name/numberThree.dart';
import 'package:signlang/components/uiDictionary/group/name/numberTwo.dart';
import 'package:signlang/components/uiDictionary/group/name/partners_exes.dart';
import 'package:signlang/components/uiDictionary/group/name/vegetables.dart';
import 'package:signlang/components/uiDictionary/nameDictionary/nameDictionary.dart';
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

  final List<Map<String, dynamic>> _allWords = [];
  final Set<String> _savedWordSet = {};

// =======================================================================
// name things
// =======================================================================
  late final dictionaryCardsData = DictionaryCardsData(context: context);
  late final dictionaryCardsItems = dictionaryCardsData.dictionaryCardsList;
  late final storesDictionaryCardsData = StoresDictionaryCardsData(context: context);
  late var lastSeen = LastSeenData(context: context).lastSeenItems;
  late var results = ResultsData(context: context).resultsItems;

// =======================================================================
  // signs from the server dictionary (added in the dashboard)
  List<ApiSign> _serverResults = [];
  /// Dictionary categories from the dashboard (null until loaded / when offline: the app's own list is shown)
  List<ApiCategory>? _serverCategories;

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

  Future<void> _loadServerCategories() async {
    try {
      final cats = await UzslApi.categories();
      if (mounted) setState(() => _serverCategories = cats);
    } catch (e) {
      debugPrint('Dictionary categories not loaded: $e');
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
  void didChangeDependencies() { super.didChangeDependencies(); _loadLastSeen(); _loadSaved(); if (_allWords.isEmpty) { _allWords.addAll(ResultsData(context: context).resultsItems); } }

// =======================================================================
  Future<void> _initializeData() async { await Future.wait([ AppLoading.ready(), ]); if (!mounted) return; setState(() { _isLoading = false; }); }
  Future<void> _handleRefresh() async {
    setState(() { _isLoading = true; });
    await Future.wait([_initializeData(), _loadServerCategories()]);
    final picked = _pickedServerCategory;
    if (picked != null) await _loadCategorySigns(picked.slug); // new signs from the dashboard
  }
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _loadLastSeen() async { final items = await LastSeenStore.instance.load(); if (mounted) setState(() => lastSeen = items); }
  Future<void> _loadSaved() async { final items = await SavedStore.instance.load(); if (mounted) { setState(() { _savedWordSet.clear(); for (var it in items) { if (it['word'] != null) _savedWordSet.add(it['word']); } }); } }

// ================================ Button ==================================
  void _handleEmergency() { Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyPhrases())); }
  void _handleAllPhrases() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AllPhrases())); }
  void _handleVoiceSearch() async {
    final available = await _speech.initialize();
    _searchFocus.requestFocus(); if (available) { _speech.listen(onResult: (result) { setState(() { _searchController.text = result.recognizedWords; _onSearchChanged(); }); }); }
  }
  void _exitSearch() { _searchController.clear(); _searchFocus.unfocus(); setState(() => _searching = false); }
  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() { _searching = _searchFocus.hasFocus || q.isNotEmpty; results = q.isEmpty ? [] : _allWords.where((w) => (w['word']).toLowerCase().contains(q)).toList(); });
    // the server dictionary too (debounced); words the app already has are not shown twice
    _serverSearch?.cancel();
    if (q.isEmpty) { setState(() => _serverResults = []); return; }
    _serverSearch = Timer(const Duration(milliseconds: 350), () async {
      try {
        final page = await UzslApi.signs(query: q, limit: 30);
        if (!mounted || _searchController.text.trim().toLowerCase() != q) return;
        final local = results.map((w) => '${w['word']}'.toLowerCase()).toSet();
        setState(() => _serverResults = page.items.where((s) => !local.contains(s.word.toLowerCase())).toList());
      } catch (e) {
        debugPrint('Dictionary search on the server failed: $e');
      }
    });
  }
  void onDictionaryCardsTap(int index) {
    setState(() => selectedDictionaryCards = index);
    final cat = _pickedServerCategory;
    if (cat != null) _loadCategorySigns(cat.slug);
  }
  // category page (LastSeenStore "source") -> its word pages
  static const Map<String, Widget? Function(String id)> _wordPages = {
    'BirthOrderMultiples': BirthOrderMultiples.pageFor,
    'SomeCereals': SomeCereals.pageFor,
    'SomeDairy': SomeDairy.pageFor,
    'ExtendedFamily': ExtendedFamily.pageFor,
    'SomeFood': SomeFood.pageFor,
    'SomeFruits': SomeFruits.pageFor,
    'HouseholdLineageTerms': HouseholdLineageTerms.pageFor,
    'ImmediateFamily': ImmediateFamily.pageFor,
    'SomeNumbersFive': SomeNumbersFive.pageFor,
    'SomeNumbersFour': SomeNumbersFour.pageFor,
    'SomeNumbersOne': SomeNumbersOne.pageFor,
    'SomeNumbersThree': SomeNumbersThree.pageFor,
    'SomeNumbersTwo': SomeNumbersTwo.pageFor,
    'PartnersExes': PartnersExes.pageFor,
    'SomeVegetables': SomeVegetables.pageFor,
  };

  /// Opens a "Last seen" word's video page again; watching it moves it back to the front.
  Future<void> _playSign(Map<String, dynamic> item) async {
    if (item['source'] == 'api') {
      // a sign from the server dictionary
      final id = int.tryParse('${item['id']}');
      if (id == null) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ApiSignPage(signId: id)));
      _loadLastSeen();
      return;
    }
    final page = _wordPages[item['source']]?.call(item['id'] ?? '');
    if (page == null) return; // saved before words remembered their page
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await LastSeenStore.instance.add(item['word'], item['image'] ?? '', source: item['source'], id: item['id']);
    _loadLastSeen();
  }
  void _toggleSave(Map<String, dynamic> word) async { await SavedStore.instance.toggle(word); _loadSaved(); }

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
                    results.isEmpty && _serverResults.isEmpty
                      ? SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: Center(child: Text(AppLocalizations.of(context)!.translate('dict_no_results')))))
                      : SliverList(delegate: SliverChildBuilderDelegate(
                        (_, i) => i < results.length
                          ? _wordCard(results[i])
                          : Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: ApiSignTile(sign: _serverResults[i - results.length])),
                        childCount: results.length + _serverResults.length,
                      ))
                  else ...[ SliverToBoxAdapter(child: _cardsView()), SliverToBoxAdapter(child: _browseView()) ]
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
                      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const Saved())); _loadSaved(); },
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
              suffixIcon: GestureDetector(onTap: _handleVoiceSearch, child: Padding(padding: const EdgeInsets.all(12), child: Image.asset('web/icons/voice.png', width: 26, height: 26))),
              suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              filled: true, fillColor: c.isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEDF2F7), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)
            )
          )
        ]
      )
    );
  }

// =======================================================================
// Search
// =======================================================================
  Widget _wordCard(Map<String, dynamic> w) {
    final isSaved = _savedWordSet.contains(w['word']);
    final Color isColor = isSaved ? (c.isDark ? Colors.white24 : Colors.white) : c.chip;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.isDark ? c.card : Color(0xFFE3F2FD).withValues(alpha: 0.5), border: Border.all(color: c.cardBorder, width: 1),
          borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: c.isDark ? c.glow : Color(0xFF1E88E5).withValues(alpha: 0.9), blurRadius: 15)]
        ),
        child: Row(
          children: [
            Container(
              height: 64, width: 64, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Image.asset(w['image'], errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 35, color: Colors.blue)))
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w['word'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.text)),
                  Text(w['phonetic'] ?? '', style: TextStyle(fontSize: 17, color: c.isDark ? c.subText : Colors.grey[800]))
                ]
              )
            ),
            GestureDetector(
              onTap: () => _toggleSave(w),
              child: Container(
                padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isColor, border: Border.all(width: 1, color: c.cardBorder), borderRadius: BorderRadius.circular(14)),
                child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? const Color(0xFF4A7FD0) : Colors.blue)
              )
            )
          ]
        )
      )
    );
  }

// =======================================================================
// Cards View
// =======================================================================
  Widget _cardsView() {
    final lang = Localizations.localeOf(context).languageCode;
    final cats = _serverCategories;
    final List<Map<String, dynamic>> chips = cats == null
      ? dictionaryCardsItems
      : [
          {'icon': CategoryIcon.all, 'title': AppLocalizations.of(context)!.translate('all')},
          for (final cat in cats) {'icon': cat.icon ?? CategoryIcon.bySlug[cat.slug] ?? CategoryIcon.fallback, 'title': cat.nameFor(lang)},
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
                      item['icon'] != null
                          ? CategoryIcon(item['icon'], size: 20, color: isActive ? (c.isDark ? c.accent : Colors.blue[900]!) : c.text)
                          : Image.asset(item['image'], width: 20, height: 20, color: isActive ? (c.isDark ? c.accent : Colors.blue[900]) : c.text),
                      const SizedBox(width: 8),
                      Text(item['title'], style: TextStyle(color: isActive ? (c.isDark ? c.accent : Colors.blue[900]) : c.text, fontSize: 16, fontWeight: FontWeight.w600))
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
    final categoryId = selectedDictionaryCards >= 0 ? selectedDictionaryCards.toString() : '0';
    final isAll = categoryId == '0';
    final storesDic = storesDictionaryCardsData.storesDictionaryCardsByCategory[categoryId] ?? [];

    // category '0' → only 4 rows; others → all rows
    final stores = isAll ? storesDic.take(4).toList() : storesDic;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), decoration: BoxDecoration(color: c.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAll) ...[ _emergencyBanner(), const SizedBox(height: 18), _lastSeenSection(), const SizedBox(height: 18) ],
          // "All": the categories made in the dashboard (titles, counts and order from there);
          // offline, the app's own list as before
          if (isAll && _serverCategories != null)
            for (final cat in _serverCategories!) _serverCategoryRow(cat, categoryId)
          else
            ...List.generate(stores.length, (index) => _categoryRow(stores[index], categoryId)),
        ]
      )
    );
  }

// =======================================================================
// That isAll group
// =======================================================================
  Widget _emergencyBanner(){
    const String imageEmergency = 'web/icons/emergency.png';
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== 1) emergency =====
        GestureDetector(
          onTap: _handleEmergency,
          child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: Colors.red),
            boxShadow: [BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.9), blurRadius: 15)]
          ),
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
          : SizedBox(
            height: 150,
            child: ListView.builder(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: lastSeen.length, itemBuilder: (_, index) => _lastSeenCard(lastSeen[index]))
          ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.translate('celebrities'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: c.text)),
            GestureDetector(
              onTap: _handleAllPhrases,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                decoration: BoxDecoration(
                  color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: c.cardBorder),
                  boxShadow: [BoxShadow(color: c.glow, blurRadius: 15, offset: const Offset(0, 6))]
                ),
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
    final String image = item['image'] ?? '', label = item['word'] ?? '';
    return GestureDetector(
      onTap: () => _playSign(item),
      child: Container(
        width: 150, margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: c.chip, border: Border.all(width: 1, color: c.cardBorder), borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            // character image
            Positioned.fill(top: 15, child: ClipRRect(child: image.startsWith('http') ? Image.network(image, errorBuilder: (_, _, _) => const Icon(Icons.person, size: 60, color: Colors.blue)) : Image.asset(image, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: Colors.blue)))),
            // play button top-right
            Positioned(
              top: 10, right: 10,
              child: Container(
                height: 35, width: 35, decoration: BoxDecoration(color: const Color(0xFF4A7FD0).withValues(alpha: 0.3), shape: BoxShape.circle),
                child: Center(child: Container(height: 20, width: 20, decoration: const BoxDecoration(color: Color(0xFF4A7FD0), shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.white, size: 18)))
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
    final lang = Localizations.localeOf(context).languageCode;
    final signs = _categorySigns[cat.slug];
    List<ApiSign> ofKind(String kind) =>
        (signs ?? const <ApiSign>[]).where((s) => s.kind == kind).toList()..sort((a, b) => a.wordFor(lang).toLowerCase().compareTo(b.wordFor(lang).toLowerCase()));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20), decoration: BoxDecoration(color: c.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: signs == null
          ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          : signs.isEmpty
              ? Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(loc.translate('dict_no_results'), style: TextStyle(fontSize: 15, color: c.subText))))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // words first, then phrases (letters, numbers), each under its own heading
                  for (final kind in const ['word', 'phrase', 'letter', 'number'])
                    if (signs.any((s) => s.kind == kind)) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text('${loc.translate('dict_group_$kind')} · ${signs.where((s) => s.kind == kind).length}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text)),
                      ),
                      for (final sign in ofKind(kind)) ApiSignTile(sign: sign),
                    ],
                ]),
    );
  }

  /// A dashboard category as a row: its name in the app's language and how many signs it has.
  Widget _serverCategoryRow(ApiCategory cat, String categoryId) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final unit = lang == 'uz' && (cat.unitLabel?.isNotEmpty ?? false) ? cat.unitLabel! : loc.translate('dict_signs_count');
    return _categoryRow(
      {'icon': cat.icon ?? CategoryIcon.bySlug[cat.slug] ?? CategoryIcon.fallback, 'title': cat.nameFor(lang), 'title_sub': '${cat.signCount} $unit'},
      categoryId,
      onTap: () => onDictionaryCardsTap((_serverCategories?.indexOf(cat) ?? -1) + 1),
    );
  }

// =======================================================================
// that not isAll group if other cards all group subject
// =======================================================================
  Widget _categoryRow(Map<String, dynamic> item, String categoryId, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _openLessonsAll(categoryId, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: c.cardBorder),
          boxShadow: [BoxShadow(color: c.glow, blurRadius: 15)]
        ),
        child: Row(
          children: [
            Container(
              height: 56, width: 56, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Center(child: item['icon'] != null
                  ? CategoryIcon(item['icon'], size: 28, color: Colors.blue[700]!)
                  : Image.asset(item['image'], width: 28, height: 28, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 35, color: Colors.blue))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'], style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.text)),
                  Text(item['title_sub'] ?? '', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: c.isDark ? c.subText : Colors.grey[700])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: c.chip, border: Border.all(width: 1, color: c.cardBorder), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right)
            )
          ]
        )
      )
    );
  }

// =======================================================================
  Future<void> _openLessonsAll(String categoryId, Map<String, dynamic> item) async {
    final id = item['id'];
    Widget? page;

    if (categoryId == '0') {
      page = switch (id) {
        // '0' => const AlphabetResult(),
        // '1' => const FamilyResult(),
        // '2' => const AlphabetResult(),
        // '3' => const AlphabetResult(),
        _ => null,
      };
    } else if (categoryId == '1') {
      page = switch (id) { '0' => const ImmediateFamily(), '1' => const ExtendedFamily(), '2' => const PartnersExes(), '3' => const HouseholdLineageTerms(), '4' => const BirthOrderMultiples(), _ => null };
    } else if (categoryId == '2') {
      page = switch (id) { '0' => const SomeFood(), '1' => const SomeFruits(), '2' => const SomeVegetables(), '3' => const SomeCereals(), '4' => const SomeDairy(), _ => null };
    } else if (categoryId == '3') {
      page = switch (id) { '0' => const SomeNumbersOne(), '1' => const SomeNumbersTwo(), '2' => const SomeNumbersThree(), '3' => const SomeNumbersFour(), '4' => const SomeNumbersFive(), _ => null };
    }

    if (page == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    _loadLastSeen(); // words watched inside the category now show in "Last seen"
  }
}
