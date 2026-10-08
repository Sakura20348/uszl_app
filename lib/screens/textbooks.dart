import 'dart:io';
import 'package:signlang/services/notification_center.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_textbooks.dart';
import 'package:signlang/services/app_loading.dart';

import 'package:flutter/material.dart';
import 'package:signlang/api/api_errors.dart';
import 'package:signlang/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/profile/group/personal/personalInformation.dart';
import 'package:signlang/components/uiTextBooks/group/allLessons.dart';
import 'package:signlang/components/uiTextBooks/group/alphabetLessons/alphabetLessons.dart';
import 'package:signlang/components/uiTextBooks/group/familyLessons/familyLessons.dart';
import 'package:signlang/components/uiTextBooks/group/foodLessons/foodLessons.dart';
import 'package:signlang/components/uiTextBooks/group/numberLessons/numberLessons.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/buildLessonsTextbooks.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import 'package:signlang/components/web/notification/notification.dart';
import 'package:signlang/l10n/app_localizations.dart';

import '../components/profile/nameProfile/nameStore.dart';
import '../components/uiTextBooks/skeleton/skeleton.dart';
import '../components/web/notification/pulseDot.dart';

enum LessonStatus { passed, opened, locked }

class Textbooks extends StatefulWidget{
  final VoidCallback? onOpenDictionary;
  const Textbooks({super.key, this.onOpenDictionary});

  @override
  State<Textbooks> createState() => _TextbooksState();
}

class _TextbooksState extends State<Textbooks>{
  bool _isLoading = true;
  File? _profileImage;
  String _name = 'User';
  int tabIndex = 0;
  int numbers = 1;
  int _unreadCount = 0;

  final Map<String, int> _learnedOverrides = {};

  double get _overallProgress {
    final items = LessonsTextbooksData(context: context).lessonsTextbooksItems;
    int totalLearned = 0; int totalAll = 0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final id = item['id'];
      // int learned = _learnedOverrides[id] ?? int.tryParse('${item['learned']}') ?? 0;
      int learned = _learnedOverrides[id] ?? (LessonProgress.instance.learnedOf(id) > 0 ? LessonProgress.instance.learnedOf(id) : int.tryParse('${item['learned']}') ?? 0);
      int total = int.tryParse('${item['total']}') ?? 0;
      totalLearned += learned;
      totalAll += total;
    }
    return totalAll == 0 ? 0 : totalLearned / totalAll;
  }

  @override
  void initState(){
    super.initState(); _initData(); _initializeProfileData(); _loadProfileImage(); _loadUserName();
    _unreadCount = NotificationCenter.unread.value;
    NotificationCenter.unread.addListener(_onUnreadChanged);
    _loadUnread();
  }

// =======================================================================
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('first_name')?.trim() ?? '';
    if (mounted) setState(() => _name = name.isEmpty ? 'User' : name);
  }

  LessonStatus _statusFor(int i) {
    final items = LessonsTextbooksData(context: context).lessonsTextbooksItems;
    int totalOf(int k) => int.tryParse('${items[k]['total']}') ?? 0;

    int learnedOf(int k) {
      final id = items[k]['id'];
      if (_learnedOverrides.containsKey(id)) return _learnedOverrides[id]!;
      final saved = LessonProgress.instance.learnedOf(id);
      if (saved > 0) return saved;
      return int.tryParse('${items[k]['learned']}') ?? 0;
    }

    bool passed(int k) { final p = totalOf(k) > 0 && learnedOf(k) >= totalOf(k); return p; }

    if (passed(i)) return LessonStatus.passed;
    if (i == 0) return LessonStatus.opened;
    if (passed(i - 1)) return LessonStatus.opened; // prev passed -> unlock next
    return LessonStatus.locked;
  }

// =======================================================================
  Future<void> _initializeData() async {
    final results = await Future.wait([ ImageStorage.load(), AppLoading.ready() ]);
    if (!mounted) return;
    final String? path = results[0] as String?;
    setState(() { _profileImage = path != null ? File(path) : null; _isLoading = false; });
  }

  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _loadProfileImage() async { final path = await ImageStorage.load(); if (mounted) { setState(() => _profileImage = (path != null && path.isNotEmpty) ? File(path) : null); } }
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _initializeProfileData() async {
    final results = await Future.wait([ ImageStorage.load(), AppLoading.ready() ]);
    if (!mounted) return;
    final String? path = results[0] as String?;
    setState(() { if (path != null) { _profileImage = File(path); } else { _profileImage = null; } });
  }
  // Unread notifications on the server (NotificationCenter keeps them live: push, every 30 s, on resume)
  Future<void> _loadUnread() => NotificationCenter.refresh(alert: false);

  void _onUnreadChanged() { if (mounted) setState(() => _unreadCount = NotificationCenter.unread.value); }

  @override
  void dispose() { NotificationCenter.unread.removeListener(_onUnreadChanged); super.dispose(); }

// ================================ Button ==================================
// --- ACCOUNT ---
  void _handleProfile() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInformation())); _loadProfileImage(); _loadUserName(); }

// --- NOTIFICATION ---
  void _handleNotification() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())); _loadUnread(); }

// --- OPEN START LESSONS ---
  Future<void> _openLesson(int i) async {
    if (_statusFor(i) == LessonStatus.locked) return;
    final items = LessonsTextbooksData(context: context).lessonsTextbooksItems;
    final id = items[i]['id'];

    Widget? page;
    switch (id) {
      case '0': page = const AlphabetLessons(); break;
      case '1': page = const NumberLessons(); break;
      case '2': page = const FamilyLessons(); break;
      case '3': page = const FoodLessons(); break;
    }

    if (page == null) {
      // no screens in the app for this textbook: its lessons come from the dashboard
      final slug = builtInTextbookSlugs[id];
      if (slug != null && await openServerTextbook(context, slug)) { if (mounted) setState(() {}); return; }
      if (mounted) showRedSnackBar(context, AppLocalizations.of(context)!.translate('section_unavailable'));
      return;
    }
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    if (mounted) setState(() {});
    if (result is int && mounted) { setState(() { _learnedOverrides[id] = result; }); }
  }

// =======================================================================
  @override
  Widget build(BuildContext context){
    final lessonsTextbooksData = LessonsTextbooksData(context: context);
    final allItems = lessonsTextbooksData.storesByLessonsTextbooks['0'] ?? [];
    final lessonsTextbooksItems = allItems.take(4).toList();
    const String ImagePathNumber = 'web/icons/numbers.png'; const String ImagePathInfo = 'web/icons/info.png';
    final Color isColor = _unreadCount > 0 ? Colors.yellow.withValues(alpha: 0.7) : const Color(0xFF94A3B8);
    final Color isColors = _unreadCount > 0 ? const Color(0xFFE3F2FD).withValues(alpha:  Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.6) : AppColors.of(context).card;
    final Color isShadow = _unreadCount > 0 ? const Color(0xFF42A5F5).withValues(alpha: 0.9) : const Color(0xFFE3F2FD).withValues(alpha: 0.2);
    final IconData isIcon = _unreadCount > 0 ? Icons.notifications_active : Icons.notifications;
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.surface,
      body: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.bgGradient)),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  if (_isLoading)
                    // ======= 1 =======
                    SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: c.isDark ? Colors.white12 : Colors.grey[200]!, highlightColor: Color(0xFF42A5F5).withValues(alpha: 0.2), child: TextBooksSkeleton.buildSkeleton()))
                  else ... [
                    // ======= 2 =======
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== 1) account, search and notif =====
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // --- 1) account ---
                                GestureDetector(
                                  onTap: _handleProfile,
                                  child: Container(
                                    width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.2)),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: _profileImage != null && _profileImage!.path.isNotEmpty
                                        ? Image.file(_profileImage!, width: 46, height: 46, fit: BoxFit.cover) : const Center(child: Icon(Icons.person_outline, color: Colors.white, size: 24)
                                      ),
                                    ),
                                  ),
                                ),
                                // --- 2) search ---
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: GestureDetector(
                                      onTap: () => widget.onOpenDictionary?.call(),
                                      child: Container(
                                        height: 46, padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(color: c.isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(18), border: Border.all(color: c.cardBorder.withValues(alpha: 0.5), width: 1.5)),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.search, color: Color(0xFF94A3B8), size: 26), const SizedBox(width: 8),
                                            Text(AppLocalizations.of(context)!.translate('dictionary_search'), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // --- 3) notification bell action ---
                                Container(
                                  width: 46, height: 46,
                                  decoration: BoxDecoration(color: isColors, borderRadius: BorderRadius.circular(16), border: Border.all(width: 1, color: c.cardBorder), boxShadow: [BoxShadow(color: c.isDark ? Colors.transparent : isShadow, blurRadius: 15)]),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16), onTap: _handleNotification,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [Center(child: Icon(isIcon, color: isColor, size: 26)), if (_unreadCount > 0) Positioned(left: -6, bottom: -6, child: PulseDot(count: _unreadCount))],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ===== 2) text =====
                            Text('${AppLocalizations.of(context)!.translate('hello')} $_name!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: c.isDark ? c.subText : Colors.grey[700])),
                            Text(AppLocalizations.of(context)!.translate('learn_gestures'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30, color: c.text)),
                            const SizedBox(height: 16),
                            // ===== 3) how many line =====
                            Container(
                              width: double.infinity, padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: c.cardBorder), boxShadow: [BoxShadow(color: c.glow, blurRadius: 15)]),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.chip, border: Border.all(width: 1, color: c.cardBorder), borderRadius: BorderRadius.circular(14)),
                                        child: Center(child: Image.asset(ImagePathNumber, width: 20, height: 20, color: c.accent.withValues(alpha: 0.9))),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(AppLocalizations.of(context)!.translate('continue'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: c.subText)),
                                            Text('${AppLocalizations.of(context)!.translate('numbers_lesson')} $numbers', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.text))
                                          ],
                                        )
                                      ),
                                      GestureDetector(
                                        onTap: (){},
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(color: c.chip, border: Border.all(width: 1, color: c.cardBorder), borderRadius: BorderRadius.circular(18)),
                                          child: Center(child: Icon(Icons.keyboard_arrow_right_outlined, size: 24, color: c.accent.withValues(alpha: 0.9))),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 10,
                                          child: LinearProgressIndicator(
                                            value: _overallProgress, backgroundColor: c.isDark ? c.track : const Color(0xFFE0F7FA).withValues(alpha: 0.9),
                                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)), borderRadius: BorderRadius.circular(5)),
                                        )
                                      ),
                                      const SizedBox(width: 14),
                                      Text("${(_overallProgress * 100).ceil()}%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text.withValues(alpha: 0.6))),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Image.asset(ImagePathInfo, width: 16, height: 16), const SizedBox(width: 10),
                                      Text(AppLocalizations.of(context)!.translate('numbers_left'), style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: c.text))
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 12)
                          ],
                        ),
                      ),
                    ),
                    // ======= 3 =======
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                        child: Column(
                          children: [
                            // ===== 1) text and button ======
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppLocalizations.of(context)!.translate('textbooks'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: c.text)),
                                Container(
                                  padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                                  decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: c.cardBorder), boxShadow: [BoxShadow(color: c.glow, blurRadius: 15, offset: Offset(0, 6))]),
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllLessons())),
                                    child: Row(
                                      children: [
                                        Text(AppLocalizations.of(context)!.translate('all_lessons'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: c.text)),
                                        const SizedBox(width: 2), Icon(Icons.keyboard_arrow_right_outlined, size: 20, color: c.text)
                                      ]
                                    )
                                  )
                                )
                              ]
                            ),
                            const SizedBox(height: 16),
                            // ===== 2) lessons cards ======
                            Column(
                              children: List.generate(lessonsTextbooksItems.length, (i) {
                                final lesson = Map<String, dynamic>.from(lessonsTextbooksItems[i]);
                                final id = lesson['id'];
                                if (_learnedOverrides.containsKey(id)) { lesson['learned'] = _learnedOverrides[id]; }
                                lesson['status'] = _statusFor(i);

                                return GestureDetector(
                                  onTap: _statusFor(i) == LessonStatus.locked ? null : () => _openLesson(i),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: BuildLessonsTextbooks.buildLessonTextbooks(context, lesson),
                                  ),
                                );
                              }),
                            ),
                            // ===== 3) textbooks made in the dashboard ======
                            const ApiTextbookList(),
                          ],
                        ),
                      )
                    )
                  ]
                ],
              )
            )
          ),
        ),
      ),
    );
  }
}


