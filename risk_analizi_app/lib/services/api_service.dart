import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:http/http.dart' as http;

class ApiService {
  // Canlı sunucu URL'si (Render)
  static const String _productionUrl = 'https://cocuk-gelisim-risk-api.onrender.com';
  // Lokal geliştirme URL'si
  static const String _localUrl = 'http://10.0.2.2:8000';

  static String get baseUrl {
    if (kDebugMode) {
      // Debug modda: Web ise localhost, Android emülatör ise 10.0.2.2
      if (kIsWeb) return 'http://localhost:8000';
      try {
        if (Platform.isAndroid) return 'http://10.0.2.2:8000';
        if (Platform.isIOS) return 'http://localhost:8000';
      } catch (_) {}
      return _localUrl;
    }
    return _productionUrl;
  }

  Future<Map<String, dynamic>?> analizYap({
    required double yas,
    required int cinsiyet,
    required double boyKm,
    required double kiloKg,
    required double uykuSaati,
    required double ekranSaati,
    required int fizikselAktivite,
  }) async {
    final url = Uri.parse('$baseUrl/tahmin');

    final payload = {
      "yas": yas,
      "cinsiyet": cinsiyet,
      "boy_cm": boyKm,
      "kilo_kg": kiloKg,
      "uyku_saati": uykuSaati,
      "ekran_saati": ekranSaati,
      "fiziksel_aktivite": fizikselAktivite
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // API UTF-8 olarak döndüğü için Türkçe karakter sorunu olmaması adına utf8 convert ekleyelim
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return decodedResponse;
      } else {
        print("Sunucu Hatası: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("İstek Başarısız: $e");
      return null;
    }
  }
}
