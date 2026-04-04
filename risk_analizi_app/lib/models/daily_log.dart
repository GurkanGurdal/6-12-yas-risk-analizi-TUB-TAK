class DailyLog {
  final String date; // YYYY-MM-DD formatında, örn: "2024-04-01"
  final double? sleepHours;
  final double? screenHours;
  final int? activityLevel; // 0=Düşük, 1=Orta, 2=Yüksek

  DailyLog({
    required this.date,
    this.sleepHours,
    this.screenHours,
    this.activityLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      if (sleepHours != null) 'sleepHours': sleepHours,
      if (screenHours != null) 'screenHours': screenHours,
      if (activityLevel != null) 'activityLevel': activityLevel,
    };
  }

  factory DailyLog.fromJson(Map<String, dynamic> map) {
    return DailyLog(
      date: map['date'],
      sleepHours: (map['sleepHours'] as num?)?.toDouble(),
      screenHours: (map['screenHours'] as num?)?.toDouble(),
      activityLevel: map['activityLevel'] as int?,
    );
  }
}
