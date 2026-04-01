import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile.dart';
import '../models/daily_log.dart';

class StorageService {
  static const String _profileKey = 'child_profile';
  static const String _profilesKey = 'child_profiles';
  static const String _settingsNotificationsKey = 'settings_notifications';
  static const String _settingsWeeklyReminderKey = 'settings_weekly_reminder';
  static const String _riskReportKey = 'risk_report';

  // Profili kaydet
  static Future<void> saveProfile(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(profile.toJson());
    await prefs.setString(_profileKey, jsonStr);

    // Aktif profil her kaydedildiğinde çoklu profil listesiyle de senkron kalır.
    final profiles = await getProfiles();
    final idx = profiles.indexWhere((p) => _isSameProfile(p, profile));
    if (idx >= 0) {
      profiles[idx] = profile;
    } else {
      profiles.add(profile);
    }
    await saveProfiles(profiles);
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

  // ==== MULTI PROFILE EKLENTISI ====

  static Future<List<ChildProfile>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_profilesKey);

    if (jsonStr == null || jsonStr.isEmpty) {
      // Geriye dönük uyumluluk: eski tek profil kaydını listeye yansıt.
      final single = await getProfile();
      return single == null ? [] : [single];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .whereType<Map>()
          .map((m) => ChildProfile.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveProfiles(List<ChildProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = profiles.map((p) => p.toJson()).toList();
    await prefs.setString(_profilesKey, jsonEncode(payload));
  }

  static Future<void> addProfile(ChildProfile profile) async {
    final profiles = await getProfiles();
    profiles.add(profile);
    await saveProfiles(profiles);
  }

  static Future<void> setActiveProfile(ChildProfile profile) async {
    await saveProfile(profile);
  }

  static Future<void> deleteProfileAt(int index) async {
    final profiles = await getProfiles();
    if (index < 0 || index >= profiles.length) return;

    final removed = profiles.removeAt(index);
    await saveProfiles(profiles);

    final active = await getProfile();
    if (active != null && _isSameProfile(active, removed)) {
      if (profiles.isNotEmpty) {
        await saveProfile(profiles.first);
      } else {
        await removeProfile();
      }
    }
  }

  static bool _isSameProfile(ChildProfile a, ChildProfile b) {
    return a.name == b.name &&
        a.gender == b.gender &&
        a.age == b.age &&
        a.heightCm == b.heightCm &&
        a.weightKg == b.weightKg;
  }

  // ==== SETTINGS EKLENTISI ====

  static Future<Map<String, bool>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getBool(_settingsNotificationsKey) ?? true;
    final weeklyReminder = prefs.getBool(_settingsWeeklyReminderKey) ?? true;

    return {
      'notifications': notifications,
      'weeklyReminder': weeklyReminder,
    };
  }

  static Future<void> saveSettings({
    required bool notifications,
    required bool weeklyReminder,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_settingsNotificationsKey, notifications);
    await prefs.setBool(_settingsWeeklyReminderKey, weeklyReminder);
  }

  // ==== DAILY LOGS EKLENTİSİ ====
  static const String _logsKey = 'daily_logs';

  static String _profileLogsKey(ChildProfile profile) {
    final raw = [
      profile.name.trim().toLowerCase(),
      profile.gender,
      profile.age.toStringAsFixed(2),
      profile.heightCm.toStringAsFixed(2),
      profile.weightKg.toStringAsFixed(2),
    ].join('|');
    final encoded = base64UrlEncode(utf8.encode(raw)).replaceAll('=', '');
    return '${_logsKey}_$encoded';
  }

  static String _profileRiskReportKey(ChildProfile profile) {
    final raw = [
      profile.name.trim().toLowerCase(),
      profile.gender,
      profile.age.toStringAsFixed(2),
      profile.heightCm.toStringAsFixed(2),
      profile.weightKg.toStringAsFixed(2),
    ].join('|');
    final encoded = base64UrlEncode(utf8.encode(raw)).replaceAll('=', '');
    return '${_riskReportKey}_$encoded';
  }

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

  static Future<List<DailyLog>> getDailyLogsForProfile(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _profileLogsKey(profile);
    final String? jsonStr = prefs.getString(key);
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

  static Future<void> saveDailyLogForProfile(ChildProfile profile, DailyLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _profileLogsKey(profile);
    List<DailyLog> logs = await getDailyLogsForProfile(profile);

    final existingIndex = logs.indexWhere((l) => l.date == log.date);
    if (existingIndex >= 0) {
      logs[existingIndex] = log;
    } else {
      logs.add(log);
    }

    logs.sort((a, b) => a.date.compareTo(b.date));
    final List<Map<String, dynamic>> listMap = logs.map((l) => l.toJson()).toList();
    await prefs.setString(key, jsonEncode(listMap));
  }

  // Son 7 gün kaydedildiyse hafızayı temizlemek isteyebiliriz (Tercihe bağlı)
  static Future<void> clearDailyLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logsKey);
  }

  static Future<void> clearDailyLogsForProfile(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileLogsKey(profile));
  }

  // ==== PROFILE BAZLI SON RISK RAPORU ====

  static Future<void> saveLatestRiskReportForProfile(
    ChildProfile profile,
    Map<String, dynamic> report,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileRiskReportKey(profile), jsonEncode(report));
  }

  static Future<Map<String, dynamic>?> getLatestRiskReportForProfile(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_profileRiskReportKey(profile));
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}

    return null;
  }
}
