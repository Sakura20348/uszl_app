import 'dart:io';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/services/app_loading.dart';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/profile/group/about/aboutSheet.dart';
import 'package:signlang/components/profile/group/allAchievements.dart';
import 'package:signlang/components/profile/group/personal/changePicture.dart';
import 'package:signlang/components/profile/group/personal/personalInformation.dart';
import 'package:signlang/components/profile/group/statistics/statisticsSceen.dart';
import 'package:signlang/components/profile/nameProfile/nameProfileSheet.dart';
import 'package:signlang/components/modeToggle.dart';
import 'package:signlang/components/profile/skeleton/skeleton.dart';
import 'package:signlang/components/web/day/today.dart';
import 'package:signlang/components/web/language/languageSheet.dart';
import 'package:signlang/components/web/notification/notificationProfile.dart';
import 'package:signlang/components/web/saved/saved.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/models/statistics.dart';
import 'package:signlang/services/statistics_service.dart';
import 'package:signlang/services/theme_service.dart';

import '../api/api_service.dart';
import '../components/profile/group/deleteProfile/logOutDelete.dart';
import '../components/profile/nameProfile/nameStore.dart';

class Profile extends StatefulWidget{
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  File? _profileImage;
  bool _isLoading = true;
  int tabIndex = 3; int selectedSetting = -1;
  String _appVersion = '';
  String _phoneNumber = '';

  late TextEditingController nameController;
  late TextEditingController lastNameController;

  late final achievementsData = AchievementsData(context: context);
  late final allSettingData = AllSettingsData(context: context);
  late final allSetting = allSettingData.storesByAllSettings['0'] ?? [];

  UserStatistics _stats = UserStatistics.empty();

// =======================================================================
  @override
  void initState(){ super.initState(); nameController = TextEditingController(); lastNameController = TextEditingController(); _initData(); _loadProfileImage(); _loadVersion(); _loadUserData(); }

  @override
  void dispose() { nameController.dispose(); lastNameController.dispose(); super.dispose(); }

// =======================================================================
  Future<void> _loadName() async { final savedName = await NameStorage.load(); if (savedName != null && mounted) {setState(() {nameController.text = savedName;});} }
  Future<void> _loadUserData() async {
    final savedName = await NameStorage.load();
    final savedLastName = await LastNameStorage.load();
    final savedPhone = await NumberStorage.load();

    if (!mounted) return;
    setState(() { if (savedName != null) {nameController.text = savedName;} if (savedLastName != null) {lastNameController.text = savedLastName;} _phoneNumber = savedPhone ?? ''; });
  }

  Future<void> _initializeData() async {
    await achievementsData.init();
    _stats = StatisticsService.instance.getStatistics();
    await Future.wait([ AppLoading.ready(), _loadServerStats() ]);
    if (!mounted) return;
    setState(() { _isLoading = false; });
  }

  // The server's numbers (same as Development details); this phone's own ones when offline or logged out
  Future<void> _loadServerStats() async {
    if (!await UzslApi.isLoggedIn()) return;
    try {
      final s = await UzslApi.stats();
      final local = _stats;
      _stats = UserStatistics(
        completedLessons: s.lessonsCompleted, lessonsIncrement: s.lessonsToday,
        accuracy: (s.accuracy ?? 0) / 100, accuracyIncrement: (s.accuracyToday ?? 0) / 100,
        weeklyStreak: s.currentStreak, streakRecord: s.longestStreak,
        collectedPoints: s.totalXp, pointsIncrement: s.xpToday,
        dailyGoalMinutes: s.dailyGoalMinutes, currentDailyMinutes: s.todayMinutes,
        weeklyStudyStatus: s.weekDays, dailyMinutesHistory: local.dailyMinutesHistory, activityHeatmap: local.activityHeatmap,
      );
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      debugPrint('Profile statistics from the server not loaded: $e');
    }
  }

  // Daily goal tile: pick 5, 10, 15 or 20 minutes; saved on this phone and on the server
  Future<void> _handleDailyGoal() async {
    final loc = AppLocalizations.of(context)!;
    final current = _stats.dailyGoalMinutes;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 60, height: 6, decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFF00B8D4)).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(5)))),
              const SizedBox(height: 18),
              Text(loc.translate('daily_goal'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              for (final minutes in const [5, 10, 15, 20])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.pop(context, minutes),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppPalette.bg(minutes == current ? const Color(0xFFE3F2FD) : Colors.white), borderRadius: BorderRadius.circular(18),
                        border: Border.all(width: 2, color: AppPalette.border(minutes == current ? const Color(0xFF4A7FD0) : const Color(0xFFE3F2FD))),
                      ),
                      child: Row(
                        children: [
                          Text('$minutes ${loc.translate('minute')}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          if (minutes == current) Icon(Icons.check_circle, color: AppPalette.fg(const Color(0xFF4A7FD0))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == current) return;
    await StatisticsService.instance.setDailyGoal(picked);
    _stats = StatisticsService.instance.getStatistics();
    if (mounted) setState(() {});
    await _loadServerStats();
  }

  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }

  Future<void> _initData() async {
    await achievementsData.init();
    _stats = StatisticsService.instance.getStatistics();
    await Future.wait([ AppLoading.ready(), _loadServerStats() ]);
    if (mounted) { setState(() { _isLoading = false; }); }
  }

  Future<void> _loadProfileImage() async { final path = await ImageStorage.load(); if (mounted) setState(() => _profileImage = (path != null && path.isNotEmpty) ? File(path) : null); }
  Future<void> _loadVersion() async { final info = await PackageInfo.fromPlatform(); if (mounted) { setState(() => _appVersion = info.version); } }

// ================================ Button ==================================
// --- ACCOUNT ---
  void _handleProfile() async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangePicture(currentImage: _profileImage),
    );

    if (result != null) {
      if (result == 'remove') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('profile_image_path');
        await ApiService.updateProfile(name: nameController.text, lastName: lastNameController.text, phone: _phoneNumber, image: '');
      } else if (result is File) {
        await ImageStorage.save(result.path);
        await ApiService.updateProfile(name: nameController.text, lastName: lastNameController.text, phone: _phoneNumber, image: result.path);
      }
      _loadProfileImage();
    }
  }

  void onDictionaryCardsTap(int index) { setState(() => selectedSetting = index); }

  void _showLanguagePicker() async {
    final picked = await showModalBottomSheet<int>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: LanguageSheet()),
    );
    if (picked != null && mounted) setState(() {});
  }

  void _showLogOutDelete() async {
    final delete = await showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(24)), child: LogOutDelete())
    );
    if (delete != null && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context){
    final c = AppColors.of(context);
    final String name = nameController.text; final String lastName = lastNameController.text;
    final int level = (_stats.completedLessons / 5).floor() + 1;
    final int goal = _stats.dailyGoalMinutes;
    final int sun = _stats.currentDailyMinutes.clamp(0, goal);
    final int weekDays = _stats.weeklyStudyStatus.where((e) => e).length;

    const String ImageInitial = 'web/icons/initial.png'; const String ImageCode = 'web/icons/code.png';
    late final categoryId = selectedSetting >= 0 ? selectedSetting.toString() : '0';
    late final settingItems = allSettingData.storesByAllSettings[categoryId] ?? [];

    BoxDecoration glass({double radius = 24, Offset offset = Offset.zero}) => BoxDecoration(
      color: c.card, border: Border.all(width: 1, color: c.cardBorder), borderRadius: BorderRadius.circular(radius),
      boxShadow: [BoxShadow(color: c.glow, blurRadius: 15, offset: offset)]
    );
    Widget arrow({double size = 20}) => Container(
      padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: c.chip, border: Border.all(width: 1, color: c.cardBorder), borderRadius: BorderRadius.circular(18)),
      child: Center(child: Icon(Icons.keyboard_arrow_right_outlined, size: size, color: c.accent.withOpacity(0.9))),
    );

    return Scaffold(
      backgroundColor: c.surface,
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.bgGradient)),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isTablet = constraints.maxWidth >= 600;
              final double contentWidth = constraints.maxWidth.clamp(0.0, isTablet ? 760.0 : double.infinity);
              final double hPad = isTablet ? 24 : 16;
              // With extendBody, padding.bottom already includes the bottom nav height.
              final double bottomPad = MediaQuery.of(context).padding.bottom + 12;

              Widget centered(Widget child) => Align(alignment: Alignment.topCenter, child: SizedBox(width: contentWidth, child: child));

              return RefreshIndicator(
                onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    if(_isLoading)
                      // ======= 1 =======
                      SliverToBoxAdapter(child: centered(Shimmer.fromColors(baseColor: c.isDark ? Colors.white12 : Colors.grey[200]!, highlightColor: const Color(0xFF42A5F5).withValues(alpha: 0.2), child: ProfileSkeleton.buildSkeleton())))
                    else ...[
                      // ======= 2 =======
                      SliverToBoxAdapter(
                        child: centered(Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: double.infinity, padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: glass(),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: _handleProfile,
                                          child: Container(
                                            width: isTablet ? 72 : 58, height: isTablet ? 72 : 58, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.3), border: Border.all(width: 1, color: c.cardBorder)),
                                            child: ClipOval(
                                              child: _profileImage != null && _profileImage!.path.isNotEmpty ? Image.file(_profileImage!, fit: BoxFit.cover) : const Center(child: Icon(Icons.person_outline, color: Colors.white, size: 24)),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0, right: 0,
                                          child: Container(
                                            width: 21, height: 21, padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                                            child: Image.asset('web/icons/edit.png'),
                                          )
                                        )
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('$name $lastName', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isTablet ? 22 : 20, fontWeight: FontWeight.w600, color: c.text)),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6, runSpacing: 6,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.fromLTRB(8, 2, 8, 2), decoration: BoxDecoration(color: Color(0xFFC5E1A5).withOpacity(c.isDark ? 0.2 : 0.5), borderRadius: BorderRadius.circular(12), border: Border.all(width: 1, color: c.isDark ? Colors.white12 : Color(0xFFF1F8E9))),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Image.asset(ImageInitial, width: 16, height: 16, color: c.isDark ? const Color(0xFFAED581) : Color(0xFF1B5E20).withOpacity(0.8)),
                                                    const SizedBox(width: 4),
                                                    Text(AppLocalizations.of(context)!.translate('initial'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: c.isDark ? const Color(0xFFAED581) : Color(0xFF1B5E20).withOpacity(0.8)))
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.fromLTRB(8, 2, 8, 2), decoration: BoxDecoration(color: Color(0xFFFFF59D).withOpacity(c.isDark ? 0.15 : 0.5), borderRadius: BorderRadius.circular(12), border: Border.all(width: 1, color: c.isDark ? Colors.white12 : Color(0xFFFFFDE7))),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Image.asset(ImageCode, width: 16, height: 16, color: c.isDark ? const Color(0xFFFFD54F) : Color(0xFFF57F17).withOpacity(0.9)),
                                                    const SizedBox(width: 4),
                                                    Text('$level ${AppLocalizations.of(context)!.translate('level')}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: c.isDark ? const Color(0xFFFFD54F) : Color(0xFFF57F17).withOpacity(0.9)))
                                                  ],
                                                ),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // dark and light
                                    const ModeToggle(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _handleDailyGoal,
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: glass(),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Flexible(child: Text(AppLocalizations.of(context)!.translate('daily_goal'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text))),
                                                  const SizedBox(width: 2),
                                                  arrow(),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        FittedBox(fit: BoxFit.scaleDown, child: Text('$sun/$goal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24, color: c.accent))),
                                                        Text(AppLocalizations.of(context)!.translate('minute'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: c.subText))
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 40, height: 40,
                                                    child: CircularProgressIndicator(value: goal > 0 ? (sun / goal).clamp(0.0, 1.0) : 0.0, strokeWidth: 7, backgroundColor: c.track, valueColor: AlwaysStoppedAnimation(c.accent), strokeCap: StrokeCap.round),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    ),
                                    SizedBox(width: isTablet ? 18 : 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap:  ()  =>
                                        {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => const Today(viewOnly: true)))
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: glass(),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Flexible(child: Text(AppLocalizations.of(context)!.translate('weekly_study'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text))),
                                                  const SizedBox(width: 2),
                                                  arrow(),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Flexible(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        FittedBox(fit: BoxFit.scaleDown, child: Text('$weekDays/7', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24, color: c.accent))),
                                                        Text(AppLocalizations.of(context)!.translate('days'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: c.subText))
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: List.generate(7, (i) {
                                                      final bool filled = _stats.weeklyStudyStatus[i];
                                                      return Container(
                                                        width: 6, height: 34, margin: const EdgeInsets.symmetric(horizontal: 1.5), decoration: BoxDecoration(color: filled ? c.accent : Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                                                      );
                                                    }),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        )),
                      ),
                      // ======= 3 =======
                      SliverToBoxAdapter(
                        child: Container(
                          padding: EdgeInsets.only(top: 20, bottom: bottomPad), decoration: BoxDecoration(color: c.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                          child: centered(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(child: Text(AppLocalizations.of(context)!.translate('your_achievements'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: c.text))),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllAchievements())),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                                        decoration: glass(offset: const Offset(0, 6)),
                                        child: Row(
                                          children: [
                                            Text(AppLocalizations.of(context)!.translate('all_achievements'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: c.text)),
                                            const SizedBox(width: 2),
                                            Icon(Icons.keyboard_arrow_right_outlined, size: 20, color: c.text)
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _allAchievements(c, isTablet, hPad),
                              const SizedBox(height: 18),
                              Padding(padding: EdgeInsets.symmetric(horizontal: hPad), child: Text(AppLocalizations.of(context)!.translate('general_settings'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: c.text))),
                              const SizedBox(height: 18),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                child: LayoutBuilder(
                                  builder: (context, box) {
                                    // Two columns of settings on tablets, one on phones.
                                    final int cols = isTablet ? 2 : 1;
                                    const double gap = 18;
                                    final double itemWidth = (box.maxWidth - gap * (cols - 1)) / cols;
                                    return Wrap(
                                      spacing: gap,
                                      children: List.generate(settingItems.length, (index) => SizedBox(width: itemWidth, child: _allSettings(settingItems[index], categoryId, c))),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                child: SizedBox(
                                  width: double.infinity, height: 56,
                                  child: ElevatedButton(
                                    onPressed: _showLogOutDelete,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFCDD2).withValues(alpha: 0.2), foregroundColor: c.isDark ? const Color(0xFFEF9A9A) : Colors.white, elevation: 6,
                                      shadowColor: const Color(0xFFB71C1C).withOpacity(c.isDark ? 0.4 : 0.9), side: BorderSide(width: 1, color: Color(0xFFB71C1C).withOpacity(0.2)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset('web/icons/door_open_alt.png', width: 24, height: 24,),
                                        const SizedBox(width: 4),
                                        Text(AppLocalizations.of(context)!.translate('log_out'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))
                                      ],
                                    )
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text('App version $_appVersion', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey)),
                                ),
                              )
                            ],
                          )),
                        ),
                      ),
                      // Fill any leftover height below the content with the surface color.
                      SliverFillRemaining(hasScrollBody: false, child: ColoredBox(color: c.surface)),
                    ]
                  ],
                )
              );
            }
          )
        ),
      ),
    );
  }

  Widget _allAchievements(AppColors c, bool isTablet, double hPad) {
    final achievementsItems = achievementsData.storesByAchievementsItems['0'] ?? [];
    final allItems = achievementsItems.take(4).toList();
    final double cardWidth = isTablet ? 170 : 140;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: isTablet ? 165 : 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, itemCount: allItems.length, padding: EdgeInsets.only(left: hPad, right: hPad - 12),
            itemBuilder: (_, index) {
              final item = allItems[index];
              final bool unlocked = item['unlocked'] ?? false;
              final List<double> matrix = [0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0,      0,      0,      0.6, 0,];

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllAchievements())),
                child: Container(
                  width: cardWidth, margin: const EdgeInsets.only(right: 12, bottom: 10), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: unlocked ? (c.isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.5)) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(24),
                    border: Border.all(width: 1, color: unlocked ? c.cardBorder : Colors.white.withOpacity(0.2)),
                    boxShadow: unlocked ? [BoxShadow(color: const Color(0xFF42A5F5).withOpacity(c.isDark ? 0.2 : 0.5), blurRadius: 10, offset: const Offset(0, 6))] : null
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ColorFiltered(
                        colorFilter: unlocked ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply) : ColorFilter.matrix(matrix),
                        child: Image.asset(item['image'] as String, height: 40, width: 40, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.stars, size: 40, color: Colors.grey)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['titleKey'] as String, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: unlocked ? c.text : Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['subKey'] as String, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: unlocked ? c.subText : Colors.grey.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
        )
      ],
    );
  }

  Widget _allSettings(Map<String, dynamic> item, String categoryId, AppColors c) {
    final Widget arrow = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: c.chip, border: Border.all(width: 1, color: c.cardBorder), borderRadius: BorderRadius.circular(18)),
      child: Center(child: Icon(Icons.keyboard_arrow_right_outlined, size: 24, color: c.accent.withOpacity(0.9))),
    );

    return GestureDetector(
      onTap: () => _openNextPage(item),
      child: Container(
        padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(color: c.card, border: Border.all(width: 1, color: c.cardBorder), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: c.isDark ? c.glow : const Color(0xFF29B6F6).withOpacity(0.9), blurRadius: 15)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.chip, border: Border.all(width: 1, color: c.cardBorder), borderRadius: BorderRadius.circular(18)),
                    child: Image.asset(item['image'], width: 22, height: 22, color: c.isDark ? const Color(0xFF64B5F6) : Colors.blue[600]),
                  ),
                  const SizedBox(width: 12),
                  Flexible(child: Text(item['titleKey'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: c.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (item['id'] == '2')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(item['lang'], width: 24),
                  const SizedBox(width: 8),
                  arrow,
                ],
              )
            else
              arrow,
          ],
        ),
      ),
    );
  }

  Future<void> _openNextPage(Map<String, dynamic> item,) async {
    // final id = item['id'];
    Widget? page;

    if (item['id'] == '2') {
      _showLanguagePicker();
    } else {
      page = switch (item['id']) {
        '0' => const PersonalInformation(),
        '1' => const StatisticsSheen(),
        '3' => const NotificationProfile(),
        '4' => const Saved(),
        '7' => const AboutSheet(),
        _ => null,
      };
    }
    if (page == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    if (mounted) { _loadProfileImage(); _loadUserData(); }
  }
}

// --------------------------------------------------------------------
