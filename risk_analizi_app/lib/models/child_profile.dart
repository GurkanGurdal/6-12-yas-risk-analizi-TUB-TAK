import 'dart:convert';

class ChildProfile {
  final String name;
  final int gender; // 0=Erkek, 1=Kız (API ile aynı)
  final double age;
  final double heightCm;
  final double weightKg;

  ChildProfile({
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
  });

  // Profilin ilk harfini avatar olarak göstermek için yardımcı fonksiyon
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  // JSON a çevirme (Hafızaya kaydetmek için)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
    };
  }

  // JSON dan okuma
  factory ChildProfile.fromJson(Map<String, dynamic> map) {
    return ChildProfile(
      name: map['name'],
      gender: map['gender'],
      age: map['age'],
      heightCm: map['heightCm'],
      weightKg: map['weightKg'],
    );
  }
}
