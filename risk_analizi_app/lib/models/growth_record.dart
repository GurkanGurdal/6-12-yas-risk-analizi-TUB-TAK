class GrowthRecord {
  final String date; // YYYY-MM-DD
  final double heightCm;
  final double weightKg;

  GrowthRecord({
    required this.date,
    required this.heightCm,
    required this.weightKg,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'heightCm': heightCm,
    'weightKg': weightKg,
  };

  factory GrowthRecord.fromJson(Map<String, dynamic> map) => GrowthRecord(
    date: map['date'],
    heightCm: (map['heightCm'] as num).toDouble(),
    weightKg: (map['weightKg'] as num).toDouble(),
  );
}
