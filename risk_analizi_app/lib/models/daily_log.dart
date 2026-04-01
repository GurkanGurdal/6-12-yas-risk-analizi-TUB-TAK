class DailyLog {
  final String date; // YYYY-MM-DD formatında, örn: "2024-04-01"
  final double sleepHours;
  final double screenHours;
  final int activityLevel; // 0=Düşük, 1=Orta, 2=Yüksek

  DailyLog({
    required this.date,
    required this.sleepHours,
    required this.screenHours,
    required this.activityLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'sleepHours': sleepHours,
      'screenHours': screenHours,
      'activityLevel': activityLevel,
    };
  }

  factory DailyLog.fromJson(Map<String, dynamic> map) {
    return DailyLog(
      date: map['date'],
      sleepHours: map['sleepHours'],
      screenHours: map['screenHours'],
      activityLevel: map['activityLevel'] ?? 1,
    );
  }
}
