import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/models/statistics.dart';
import 'package:signlang/services/statistics_service.dart';
import 'package:signlang/components/profile/skeleton/skeleton.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/api/uzsl_api.dart';

import 'package:signlang/services/theme_service.dart';
class StatisticsSheen extends StatefulWidget{
  const StatisticsSheen({super.key});

  @override
  State<StatisticsSheen> createState() => _StatisticsSheenState();
}

class _StatisticsSheenState extends State<StatisticsSheen> {
  bool _isLoading = true;
  int _selectedTab = 0;
  late UserStatistics _stats;
  // From the server (null = offline or logged out: this phone's own numbers are shown)
  ApiStats? _server;
  int _weeks = 1;

  static const _periods = ['week', 'month', 'year'];

// =======================================================================
  @override
  void initState(){ super.initState(); _initializeData(); }

// =======================================================================
  Future<void> _initializeData() async {
    final local = StatisticsService.instance.getStatistics();
    var stats = local;
    if (await UzslApi.isLoggedIn()) {
      try {
        final results = await Future.wait([UzslApi.stats(), UzslApi.activity(_periods[_selectedTab])]);
        stats = _fromServer(results[0] as ApiStats, results[1] as ApiActivity);
      } on ApiException catch (e) {
        debugPrint('Statistics from the server not loaded: $e');
        _server = null;
      }
    }
    if (!mounted) return;
    setState(() { _stats = stats; _isLoading = false; });
  }

  // The server's numbers in the shape the cards and charts use
  UserStatistics _fromServer(ApiStats s, ApiActivity a) {
    _server = s;
    _weeks = a.weeks;
    return UserStatistics(
      completedLessons: s.lessonsCompleted,
      lessonsIncrement: s.lessonsToday,
      accuracy: (s.accuracy ?? 0) / 100,
      accuracyIncrement: (s.accuracyToday ?? 0) / 100,
      weeklyStreak: s.currentStreak,
      streakRecord: s.longestStreak,
      collectedPoints: s.totalXp,
      pointsIncrement: s.xpToday,
      dailyGoalMinutes: s.dailyGoalMinutes,
      currentDailyMinutes: s.todayMinutes,
      weeklyStudyStatus: s.weekDays,
      dailyMinutesHistory: a.bars,
      // Minutes per time slot and weekday, row by row (8 x 7)
      activityHeatmap: [for (final row in a.heatmap) for (final m in row) m.toDouble()],
    );
  }

  Future<void> _selectTab(int index) async {
    setState(() => _selectedTab = index);
    final server = _server;
    if (server == null) return;
    try {
      final activity = await UzslApi.activity(_periods[index]);
      if (mounted && _selectedTab == index) setState(() => _stats = _fromServer(server, activity));
    } on ApiException catch (e) {
      debugPrint('Activity not loaded: $e');
    }
  }

  // Bar labels: weekdays, weeks of the month, or months, in the app language
  List<String> _barLabels(AppLocalizations loc, int count) {
    final lang = Localizations.localeOf(context).languageCode;
    const weekdays = {
      'uz': ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'],
      'ru': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
      'en': ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
    };
    const months = {
      'uz': ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn', 'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'],
      'ru': ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'],
      'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    };
    if (count == 12) return months[lang] ?? months['en']!;
    if (count == 4) return List.generate(4, (i) => '${i + 1}');
    return weekdays[lang] ?? weekdays['en']!;
  }

  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: CustomScrollView(
              slivers: [
                if (_isLoading)
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.2), child: StatisticsSheetSkeleton.buildSkeleton()))
                else
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.arrow_back_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.translate('development_details'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
                              Text(loc.translate('development_details_sub'), style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15, color: AppPalette.fg(Colors.grey[700]!)))
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _isTabs(loc),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _statGrid(loc),
                              const SizedBox(height: 16),
                              _dailyGoalCard(loc),
                              const SizedBox(height: 16),
                              _weeklyLearningCard(loc),
                              const SizedBox(height: 16),
                              _dailyMinutesChart(loc),
                              const SizedBox(height: 16),
                              _activityCalendar(loc),
                              const SizedBox(height: 30),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
              ],
            )
          )
        ),
      ),
    );
  }

  Widget _statGrid(AppLocalizations loc) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: loc.translate('completed_lessons'),
          value: '${_stats.completedLessons}',
          image: 'web/icons/book_open.png',
          progress: (_stats.completedLessons / 100).clamp(0.0, 1.0), // Assuming 100 is a milestone
          subValue: '+${_stats.lessonsIncrement}',
          subLabel: loc.translate('today_result'),
        ),
        _buildStatCard(
          title: loc.translate('accuracy'),
          value: '${(_stats.accuracy * 100).toInt()}%',
          image: 'web/icons/bullseye.png',
          progress: _stats.accuracy,
          subValue: '+${(_stats.accuracyIncrement * 100).toInt()}%',
          subLabel: loc.translate('today_result'),
        ),
        _buildStatCard(
          title: loc.translate('weekly_streak'),
          value: '${_stats.weeklyStreak} ${loc.translate('days').toLowerCase()}',
          image: 'web/icons/calendar_alt.png',
          progress: (_stats.weeklyStreak / 7).clamp(0.0, 1.0),
          subLabel: loc.translate('overall_result'),
          badge: _stats.weeklyStreak >= _stats.streakRecord && _stats.weeklyStreak > 0 ? loc.translate('record') : null,
        ),
        _buildStatCard(
          title: loc.translate('collected_points'),
          value: '${_stats.collectedPoints} xp',
          image: 'web/icons/bolt_alt.png',
          progress: (_stats.collectedPoints / 5000).clamp(0.0, 1.0), // Assuming 5000 is a milestone
          subValue: '+${_stats.pointsIncrement}',
          subLabel: loc.translate('today_result'),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String image,
    required double progress,
    String? subValue,
    required String subLabel,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.bg(Colors.white).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border(Colors.white), width: 1), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.blue).withOpacity(0.7), blurRadius: 10, offset: Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(title, style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.grey[800]!), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Image.asset(image, width: 20, height: 20, color: AppPalette.fg(Colors.blue[800]!))
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.blue[900]!))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, backgroundColor: AppPalette.bg(Colors.blue[50]!), valueColor: AlwaysStoppedAnimation<Color>(AppPalette.fg(Color(0xFF1A237E)).withOpacity(0.8)), minHeight: 6),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subLabel, style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.grey[900]!))),
              if (subValue != null)
                Text(subValue, style: TextStyle(fontSize: 12, color: AppPalette.fg(Colors.green[900]!), fontWeight: FontWeight.w600))
              else if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppPalette.bg(Colors.orange[100]!), borderRadius: BorderRadius.circular(8)),
                  child: Text(badge, style: TextStyle(fontSize: 9, color: AppPalette.fg(Colors.orange[900]!), fontWeight: FontWeight.w600)),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _dailyGoalCard(AppLocalizations loc) {
    int displayMinutes = _stats.currentDailyMinutes.clamp(0, _stats.dailyGoalMinutes);
    double goalProgress = (_stats.currentDailyMinutes / _stats.dailyGoalMinutes).clamp(0.0, 1.0);
    int percentage = (goalProgress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppPalette.border(Colors.white), width: 1),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.blue).withOpacity(0.9), blurRadius: 10, offset: Offset(0, 6))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.translate('daily_goal'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF1A237E)))),
              Container(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppPalette.fg(Colors.blue[700]!)),
                    const SizedBox(width: 4),
                    Text('${_stats.dailyGoalMinutes} ${loc.translate('minute')}', style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.blue[800]!), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goalProgress, backgroundColor: AppPalette.bg(Color(0xFFE3F2FD)), valueColor: AlwaysStoppedAnimation<Color>(AppPalette.fg(Color(0xFF1A237E)).withOpacity(0.8)), minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$displayMinutes/${_stats.dailyGoalMinutes} ${loc.translate('minute')}', style: TextStyle(fontSize: 15, color: AppPalette.fg(Colors.grey[800]!), fontWeight: FontWeight.w400)),
              Text('$percentage%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF1A237E)))),
            ],
          )
        ],
      ),
    );
  }

  Widget _weeklyLearningCard(AppLocalizations loc) {
    final days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    final completedDays = _stats.weeklyStudyStatus;
    final studyDaysCount = completedDays.where((day) => day).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppPalette.border(Colors.white), width: 1),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.blue).withOpacity(0.9), blurRadius: 10, offset: Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.translate('weekly_study'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 15, color: AppPalette.fg(Colors.blue[700]!)),
                    const SizedBox(width: 4),
                    Text('$studyDaysCount/7 ${loc.translate('days').toLowerCase()}', style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.blue[700]!), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppPalette.border(Colors.grey[700]!)),
          const SizedBox(height: 10),
          Text('$studyDaysCount ${loc.translate('days').toLowerCase()}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.blue[900]!))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (index) {
              final isCompleted = index < completedDays.length ? completedDays[index] : false;
              return Column(
                children: [
                  Text(days[index], style: TextStyle(fontSize: 15, color: AppPalette.fg(Colors.grey[900]!))),
                  const SizedBox(height: 8),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: AppPalette.bg(Colors.white), border: Border.all(color: isCompleted ? AppPalette.border(Color(0xFF1A237E)) : AppPalette.border(Colors.grey[500]!), width: 2),
                    ),
                    child: isCompleted ? Icon(Icons.check, color: AppPalette.fg(Color(0xFF0D47A1)), size: 20) : null,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppPalette.border(Colors.grey[700]!)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.history, size: 15, color: AppPalette.fg(Colors.grey[900]!)),
              const SizedBox(width: 4),
              Text('${_stats.weeklyStreak} ${loc.translate('day_goal').toLowerCase()} streak', style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.grey[800]!))),
              const Spacer(),
              Icon(Icons.trending_up, size: 15, color: AppPalette.fg(Colors.grey[900]!)),
              const SizedBox(width: 4),
              Text('${loc.translate('best_result')}: ${_stats.streakRecord} ${loc.translate('days').toLowerCase()}', style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.grey[800]!))),
            ],
          )
        ],
      ),
    );
  }

  Widget _dailyMinutesChart(AppLocalizations loc) {
    final data = _stats.dailyMinutesHistory;
    final days = _barLabels(loc, data.length);
    
    // Find max value for scaling
    int maxValue = data.reduce((a, b) => a > b ? a : b);
    if (maxValue < 60) maxValue = 60; // Minimum scale of 60 mins

    double averageMinutes = data.reduce((a, b) => a + b) / data.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppPalette.border(Colors.white), width: 1),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.blue).withOpacity(0.9), blurRadius: 10, offset: Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.translate('daily_minutes'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 15, color: AppPalette.fg(Colors.blue[700]!)),
                    const SizedBox(width: 4),
                    Text('${averageMinutes.toStringAsFixed(1)} ${loc.translate('minute')}/${loc.translate('days').toLowerCase()}', style: TextStyle(fontSize: 12, color: AppPalette.fg(Colors.blue[700]!), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (index) {
                double barHeight = (data[index] / maxValue) * 120;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30, height: barHeight > 0 ? barHeight : 4, // Show a tiny bar even if 0
                      decoration: BoxDecoration(color: AppPalette.bg(Colors.blue[900]!), borderRadius: BorderRadius.circular(8)),
                    ),
                    const SizedBox(height: 8),
                    Text(days[index], style: TextStyle(fontSize: 15, color: AppPalette.fg(Colors.grey[800]!))),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppPalette.border(Colors.grey[700]!)),
          const SizedBox(height: 8),
          Row( // need line vertical
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => Text('${((maxValue / 5) * (5 - index)).toInt()}', style: TextStyle(fontSize: 12, color: AppPalette.fg(Colors.grey[800]!)))),
          )
        ],
      ),
    );
  }

  Widget _activityCalendar(AppLocalizations loc) {
    final activityLevels = _stats.activityHeatmap;
    // At least 1, so an empty calendar (no learning yet) doesn't divide by zero
    final maxLevel = activityLevels.isEmpty ? 1.0 : activityLevels.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    // weekly average
    final fromServer = _server != null;
    double totalMinutes = fromServer
        ? activityLevels.fold(0.0, (sum, item) => sum + item)
        : activityLevels.fold(0.0, (sum, item) => sum + item) * _stats.dailyGoalMinutes;
    double weeklyAverage = totalMinutes / (fromServer ? _weeks : 8);

    final now = DateTime.now();
    int padCount = fromServer ? 0 : now.weekday % 7;
    List<double> paddedLevels = List.filled(padCount, -1.0) + activityLevels;

    const int totalCells = 56;
    if (paddedLevels.length > totalCells) { paddedLevels = paddedLevels.sublist(paddedLevels.length - totalCells); }
    // time labels down the left, one per grid row (8 rows)
    const timeLabels = ['22:00', '19:00', '16:00', '13:00', '10:00', '07:00', '04:00', '00:00'];

    const int columns = 7;
    final int rows = (paddedLevels.length / columns).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppPalette.border(Colors.white), width: 1),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.blue).withOpacity(0.9), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.translate('activity_calendar'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 15, color: AppPalette.fg(Colors.blue[700]!)),
                    const SizedBox(width: 4),
                    Text(
                      '${weeklyAverage.toInt()} ${loc.translate('minute')}/${loc.translate('week').toLowerCase()}',
                      style: TextStyle(fontSize: 12, color: AppPalette.fg(Colors.blue[700]!), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== time labels (left) + heatmap grid (right) =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  children: List.generate(rows, (r) {
                    return Container(
                      height: 30, margin: const EdgeInsets.only(bottom: 4), alignment: Alignment.centerRight,
                      child: Text(r < timeLabels.length ? timeLabels[r] : '', style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.grey[900]!))),
                    );
                  }),
                ),
              ),

              // the grid
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 4, mainAxisSpacing: 4, mainAxisExtent: 30),
                  itemCount: paddedLevels.length,
                  itemBuilder: (context, index) {
                    final level = paddedLevels[index];
                    if (level < 0) return const SizedBox();
                    final normalized = (level / maxLevel).clamp(0.0, 1.0);
                    return Container(decoration: BoxDecoration(color: AppPalette.bg(Colors.blue[900]!).withValues(alpha: 0.08 + normalized * 0.92), borderRadius: BorderRadius.circular(6)));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // weekday labels — indented to line up under the grid (past the time column)
          Padding(
            padding: const EdgeInsets.only(left: 41, right: 6), // ~ time-label column width
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _barLabels(loc, 7).map((d) => Text(d, style: TextStyle(fontSize: 14, color: AppPalette.fg(Colors.grey[800]!)))).toList(),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Text('0', style: TextStyle(fontSize: 12, color: AppPalette.fg(Colors.grey[800]!))),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), gradient: LinearGradient(colors: [AppPalette.bg(Colors.blue[50]!), AppPalette.bg(Colors.blue[900]!)])),
                ),
              ),
              const SizedBox(width: 10),
              Text(fromServer ? '${maxLevel.toInt()} ${loc.translate('minute')}' : '1000', style: TextStyle(fontSize: 12, color: AppPalette.fg(Colors.grey[800]!))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _isTabs(AppLocalizations loc) {
    final tabs = [
      { 'id': '0', 'titleKey': loc.translate('week')},
      { 'id': '1', 'titleKey': loc.translate('month') },
      { 'id': '2', 'titleKey': loc.translate('year') }
    ];
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
              onTap: () => _selectTab(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppPalette.bg(Color(0xFFE3F2FD)).withValues(alpha: 0.8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12), border: Border.all(width: isActive ? 1 : 0, color: isActive ? AppPalette.border(Colors.white) : Colors.transparent),
                ),
                child: Text(
                  tabs[index]['titleKey']!, textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? AppPalette.fg(Colors.black) : AppPalette.fg(Colors.grey[700]!)),
                ),
              ),
            )
          );
        })
      )
    );
  }
}