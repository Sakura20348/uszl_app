class UserStatistics {
  final int completedLessons;
  final int lessonsIncrement;
  final double accuracy;
  final double accuracyIncrement;
  final int weeklyStreak;
  final int streakRecord;
  final int collectedPoints;
  final int pointsIncrement;
  final int dailyGoalMinutes;
  final int currentDailyMinutes;
  final List<bool> weeklyStudyStatus;
  final List<int> dailyMinutesHistory;
  final List<double> activityHeatmap;

  UserStatistics({
    required this.completedLessons,
    required this.lessonsIncrement,
    required this.accuracy,
    required this.accuracyIncrement,
    required this.weeklyStreak,
    required this.streakRecord,
    required this.collectedPoints,
    required this.pointsIncrement,
    required this.dailyGoalMinutes,
    required this.currentDailyMinutes,
    required this.weeklyStudyStatus,
    required this.dailyMinutesHistory,
    required this.activityHeatmap,
  });

  factory UserStatistics.empty() {
    return UserStatistics(
      completedLessons: 0,
      lessonsIncrement: 0,
      accuracy: 0.0,
      accuracyIncrement: 0.0,
      weeklyStreak: 0,
      streakRecord: 0,
      collectedPoints: 0,
      pointsIncrement: 0,
      dailyGoalMinutes: 10,
      currentDailyMinutes: 0,
      weeklyStudyStatus: List.filled(7, false),
      dailyMinutesHistory: List.filled(7, 0),
      activityHeatmap: List.filled(56, 0.0),
    );
  }

  /// The same numbers with another activity calendar (minutes per time slot and weekday)
  UserStatistics copyWith({List<double>? activityHeatmap}) => UserStatistics(
    completedLessons: completedLessons, lessonsIncrement: lessonsIncrement, accuracy: accuracy, accuracyIncrement: accuracyIncrement,
    weeklyStreak: weeklyStreak, streakRecord: streakRecord, collectedPoints: collectedPoints, pointsIncrement: pointsIncrement,
    dailyGoalMinutes: dailyGoalMinutes, currentDailyMinutes: currentDailyMinutes, weeklyStudyStatus: weeklyStudyStatus,
    dailyMinutesHistory: dailyMinutesHistory, activityHeatmap: activityHeatmap ?? this.activityHeatmap,
  );
}
