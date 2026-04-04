import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

import '../core/responsive.dart';
import '../core/theme.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final genelRisk = _num(resultData['genel_risk_puani']);
    final analizSonucu = _text(resultData['analiz_sonucu'], fallback: 'Sonuc hazir degil');
    final renk = _riskColor(_text(resultData['grafik_rengi']));
    final katmanlar = _map(resultData['katmanlar']);
    final dikkatAlanlari = _toStringList(resultData['dikkat_gerektiren_alanlar']);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: r.pagePadding(horizontal: 20, top: 8, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RiskHeroCard(
                risk: genelRisk,
                resultText: analizSonucu,
                riskColor: renk,
              ),
              SizedBox(height: r.scale(16)),
              if (dikkatAlanlari.isNotEmpty)
                _AlertCard(items: dikkatAlanlari),
              SizedBox(height: r.scale(16)),
              _LayerCard(
                title: 'Yapay Zeka Risk Analizi',
                subtitle: 'Makine öğrenmesi modelinin çocuğunuzun genel durumunu değerlendirmesidir. Yüksek değerler daha fazla dikkat gerektirir.',
                icon: Icons.analytics_outlined,
                accent: AppTheme.primaryBlue,
                lines: [
                  'Ek risk faktörü: %${_num(_map(katmanlar['genel_risk_ml'])['ek_risk']).toStringAsFixed(1)}  —  Yaşam koşullarından kaynaklanan ek risk',
                  'Toplam risk: %${_num(_map(katmanlar['genel_risk_ml'])['mutlak_risk']).toStringAsFixed(1)}  —  Tüm faktörler birlikte değerlendirildiğinde',
                  'Temel risk: %${_num(_map(katmanlar['genel_risk_ml'])['temel_risk']).toStringAsFixed(1)}  —  Yaş ve cinsiyete göre başlangıç riski',
                  'Model güveni: ${_text(_map(katmanlar['genel_risk_ml'])['agirlik'], fallback: '-')}',
                ],
              ),
              SizedBox(height: r.scale(12)),
              _LayerCard(
                title: 'Duygusal ve Davranışsal Sağlık',
                subtitle: 'Çocuğunuzun ruhsal durumunu gösteren değerlendirmedir. Yüksek puanlar profesyonel destek almanız gerektiğine işaret edebilir.',
                icon: Icons.psychology_alt_outlined,
                accent: AppTheme.secondaryBlue,
                lines: [
                  'Kaygı (Anksiyete): %${_num(_map(_map(katmanlar['psikolojik'])['anksiyete'])['ek_risk']).toStringAsFixed(1)}  —  Endişe ve korku belirtileri',
                  'Düşük ruh hali (Depresyon): %${_num(_map(_map(katmanlar['psikolojik'])['depresyon'])['ek_risk']).toStringAsFixed(1)}  —  Mutsuzluk ve ilgi kaybı belirtileri',
                  'Dikkat eksikliği (DEHB): %${_num(_map(_map(katmanlar['psikolojik'])['dehb'])['ek_risk']).toStringAsFixed(1)}  —  Odaklanma ve dürtü kontrolü',
                  'Genel psikolojik risk: %${_num(_map(katmanlar['psikolojik'])['ek_risk_ortalama']).toStringAsFixed(1)}  —  Üç alanın ortalaması',
                ],
              ),
              SizedBox(height: r.scale(12)),
              _LayerCard(
                title: 'Günlük Alışkanlıklar',
                subtitle: 'Ekran süresi, uyku düzeni ve fiziksel aktivite gibi günlük yaşam alışkanlıklarının risk değerlendirmesidir.',
                icon: Icons.favorite_outline,
                accent: AppTheme.riskYellow,
                lines: [
                  'Toplam alışkanlık riski: %${_num(_map(katmanlar['yasam_tarzi'])['risk_puani']).toStringAsFixed(1)}  —  Üç alanın birleşik değeri',
                  'Ekran süresi riski: %${_num(_map(katmanlar['yasam_tarzi'])['ekran_risk']).toStringAsFixed(1)}  —  Günlük ekran kullanım süresi',
                  'Uyku düzeni riski: %${_num(_map(katmanlar['yasam_tarzi'])['uyku_risk']).toStringAsFixed(1)}  —  Uyku süresi ve kalitesi',
                  'Fiziksel aktivite riski: %${_num(_map(katmanlar['yasam_tarzi'])['aktivite_risk']).toStringAsFixed(1)}  —  Hareket ve egzersiz düzeyi',
                  ..._splitDetails(_text(_map(katmanlar['yasam_tarzi'])['detaylar'])).map((d) => '• $d'),
                ],
              ),
              SizedBox(height: r.scale(12)),
              _LayerCard(
                title: 'Büyüme ve Fiziksel Gelişim',
                subtitle: 'Boy, kilo ve vücut kitle indeksinin yaşına göre karşılaştırmasıdır. Z-skoru 0\'a yakınsa çocuğunuz yaşıtlarıyla uyumludur.',
                icon: Icons.accessibility_new,
                accent: AppTheme.riskGreen,
                lines: [
                  'Fiziksel gelişim riski: %${_num(_map(katmanlar['fiziksel_gelisim'])['risk_puani']).toStringAsFixed(1)}  —  Genel büyüme uyumu',
                  'Vücut kitle indeksi: ${_num(_map(katmanlar['fiziksel_gelisim'])['hesaplanan_bmi']).toStringAsFixed(2)}  —  Boy–kilo oranı',
                  'Boy durumu (Z-skoru): ${_num(_map(katmanlar['fiziksel_gelisim'])['boy_zscore']).toStringAsFixed(2)}  —  Yaşıtlarıyla boy karşılaştırması',
                  'Kilo durumu (Z-skoru): ${_num(_map(katmanlar['fiziksel_gelisim'])['kilo_zscore']).toStringAsFixed(2)}  —  Yaşıtlarıyla kilo karşılaştırması',
                  'BMI durumu (Z-skoru): ${_num(_map(katmanlar['fiziksel_gelisim'])['bmi_zscore']).toStringAsFixed(2)}  —  Yaşıtlarıyla BMI karşılaştırması',
                  ..._splitDetails(_text(_map(katmanlar['fiziksel_gelisim'])['detaylar'])).map((d) => '• $d'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskHeroCard extends StatelessWidget {
  final double risk;
  final String resultText;
  final Color riskColor;

  const _RiskHeroCard({
    required this.risk,
    required this.resultText,
    required this.riskColor,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(24)),
      padding: EdgeInsets.all(r.scale(24)),
      child: Column(
        children: [
          Text(
            'Genel Risk Puani',
            style: TextStyle(color: AppTheme.textGray, fontSize: r.scale(15), fontWeight: FontWeight.w600),
          ),
          SizedBox(height: r.scale(14)),
          SizedBox(
            height: r.scale(100),
            width: r.scale(100),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: (risk / 100).clamp(0, 1),
                  strokeWidth: r.scale(8),
                  backgroundColor: AppTheme.nDark.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '%${risk.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: r.scale(28),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: r.scale(14)),
          Neumorphic(
            style: AppTheme.nConcave(radius: 999),
            padding: EdgeInsets.symmetric(horizontal: r.scale(14), vertical: r.scale(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: r.scale(8),
                  height: r.scale(8),
                  decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                ),
                SizedBox(width: r.scale(6)),
                Text(
                  _riskLevelText(risk),
                  style: TextStyle(color: riskColor, fontSize: r.scale(13), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(height: r.scale(14)),
          Text(
            resultText,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textDark, fontSize: r.scale(16), fontWeight: FontWeight.w600, height: 1.4),
          ),
        ],
      ),
    );
  }

  static String _riskLevelText(double risk) {
    if (risk > 60) return 'Yüksek Risk';
    if (risk > 30) return 'Orta Risk';
    return 'Düşük Risk';
  }
}

class _AlertCard extends StatelessWidget {
  final List<String> items;

  const _AlertCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(20)),
      padding: EdgeInsets.all(r.scale(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: r.scale(36),
                height: r.scale(36),
                child: Neumorphic(
                  style: AppTheme.nCircle(),
                  child: Center(
                    child: Icon(Icons.warning_amber_rounded, color: AppTheme.riskYellow, size: r.scale(18)),
                  ),
                ),
              ),
              SizedBox(width: r.scale(10)),
              Text(
                'Dikkat Gerektiren Alanlar',
                style: TextStyle(fontSize: r.scale(16), fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
            ],
          ),
          SizedBox(height: r.scale(12)),
          ...items.map(
            (e) => Padding(
              padding: EdgeInsets.only(bottom: r.scale(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: r.scale(6)),
                    child: Container(
                      width: r.scale(6),
                      height: r.scale(6),
                      decoration: BoxDecoration(
                        color: AppTheme.riskYellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: r.scale(10)),
                  Expanded(child: Text(e, style: TextStyle(color: AppTheme.textDark, fontSize: r.scale(14), height: 1.4))),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _LayerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<String> lines;

  const _LayerCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(20)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: r.scale(18), vertical: r.scale(4)),
          leading: SizedBox(
            width: r.scale(40),
            height: r.scale(40),
            child: Neumorphic(
              style: AppTheme.nCircle(),
              child: Center(
                child: Icon(icon, color: accent, size: r.scale(20)),
              ),
            ),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark, fontSize: r.scale(15))),
          subtitle: Padding(
            padding: EdgeInsets.only(top: r.scale(4)),
            child: Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textGray,
                fontSize: r.scale(12),
                height: 1.4,
              ),
            ),
          ),
          childrenPadding: EdgeInsets.fromLTRB(r.scale(18), 0, r.scale(18), r.scale(16)),
          children: [
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFE2E8F0),
              margin: EdgeInsets.only(bottom: r.scale(12)),
            ),
            ...lines.map(
              (line) => Padding(
                padding: EdgeInsets.only(bottom: r.scale(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: r.scale(6)),
                      child: Container(
                        width: r.scale(5),
                        height: r.scale(5),
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                    ),
                    SizedBox(width: r.scale(10)),
                    Expanded(child: Text(line, style: TextStyle(color: AppTheme.textDark, fontSize: r.scale(14), height: 1.4))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

String _text(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

Map<String, dynamic> _map(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), val));
  }
  return <String, dynamic>{};
}

List<String> _toStringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  }
  return const [];
}

List<String> _splitDetails(String raw) {
  if (raw.trim().isEmpty) return const [];
  return raw
      .split(';')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

Color _riskColor(String renk) {
  final r = renk.toLowerCase();
  if (r.contains('ff4444') || r.contains('kirmizi') || r.contains('kırmızı') || r.contains('red')) {
    return AppTheme.riskRed;
  }
  if (r.contains('ffaa') || r.contains('sari') || r.contains('sarı') || r.contains('yellow')) {
    return AppTheme.riskYellow;
  }
  if (r.contains('bb44') || r.contains('cc00') || r.contains('yesil') || r.contains('yeşil') || r.contains('green')) {
    return AppTheme.riskGreen;
  }
  return AppTheme.primaryBlue;
}
