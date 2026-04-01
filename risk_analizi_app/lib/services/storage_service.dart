import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile.dart';
import '../models/daily_log.dart';

class StorageService {
  static const String _profileKey = 'child_profile';

  // Profili kaydet
  static Future<void> saveProfile(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(profile.toJson());
    await prefs.setString(_profileKey, jsonStr);
  }

  // Kayıtlı profili getir
  static Future<ChildProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_profileKey)) return null;
    
    final String? jsonStr = prefs.getString(_profileKey);
    if (jsonStr == null) return null;

    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return ChildProfile.fromJson(map);
    // ignore: empty_catches
    } catch (e) {}
    
    return null;
  }

  // Profili sil (Çıkış yapmak istenirse)
  static Future<void> removeProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }

  // ==== DAILY LOGS EKLENTİSİ ====
  static const String _logsKey = 'daily_logs';

  // Tüm günlük logları getir
  static Future<List<DailyLog>> getDailyLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_logsKey);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> listMap = jsonDecode(jsonStr);
      return listMap.map((m) => DailyLog.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  // Belirli bir günün verisini kaydet (Eğer o gün varsa üstüne yazar)
  static Future<void> saveDailyLog(DailyLog log) async {
    final prefs = await SharedPreferences.getInstance();
    List<DailyLog> logs = await getDailyLogs();

    // Aynı güne ait kayıt varsa bul ve sil/güncelle
    final existingIndex = logs.indexWhere((l) => l.date == log.date);
    if (existingIndex >= 0) {
      logs[existingIndex] = log;
    } else {
      logs.add(log);
    }
    
    // Tarihe göre sırala (en yeniden en eskiye veya tam tersi, burada oldest->newest yapalım)
    logs.sort((a, b) => a.date.compareTo(b.date));

    // Hafızaya yaz
    final List<Map<String, dynamic>> listMap = logs.map((l) => l.toJson()).toList();
    await prefs.setString(_logsKey, jsonEncode(listMap));
  }

  // Son 7 gün kaydedildiyse hafızayı temizlemek isteyebiliriz (Tercihe bağlı)
  static Future<void> clearDailyLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logsKey);
  }
}
