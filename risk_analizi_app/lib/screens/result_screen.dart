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
                title: 'Duygusal ve Davranışsal Sağlık',
                subtitle: 'Çocuğunuzun ruhsal durumunu gösteren değerlendirmedir. Yüksek puanlar profesyonel destek almanız gerektiğine işaret edebilir.',
                icon: Icons.psychology_alt_outlined,
                accent: AppTheme.secondaryBlue,
                lines: [
                  _akranKarsilastir(
                    'Kaygı (Anksiyete)',
                    _num(_map(_map(katmanlar['psikolojik'])['anksiyete'])['mutlak_risk']),
                    _num(_map(_map(katmanlar['psikolojik'])['anksiyete'])['temel_risk']),
                  ),
                  _akranKarsilastir(
                    'Depresyon',
                    _num(_map(_map(katmanlar['psikolojik'])['depresyon'])['mutlak_risk']),
                    _num(_map(_map(katmanlar['psikolojik'])['depresyon'])['temel_risk']),
                  ),
                  _akranKarsilastir(
                    'Dikkat eksikliği (DEHB)',
                    _num(_map(_map(katmanlar['psikolojik'])['dehb'])['mutlak_risk']),
                    _num(_map(_map(katmanlar['psikolojik'])['dehb'])['temel_risk']),
                  ),
                  _akranKarsilastir(
                    'Davranış bozukluğu',
                    _num(_map(_map(katmanlar['psikolojik'])['davranis'])['mutlak_risk']),
                    _num(_map(_map(katmanlar['psikolojik'])['davranis'])['temel_risk']),
                  ),
                ],
              ),
              SizedBox(height: r.scale(12)),
              _LayerCard(
                title: 'Günlük Alışkanlıklar',
                subtitle: 'Ekran süresi, uyku düzeni ve fiziksel aktivite gibi günlük yaşam alışkanlıklarının risk değerlendirmesidir.',
                icon: Icons.favorite_outline,
                accent: AppTheme.riskYellow,
                lines: [
                  _akranRiskOzet('Toplam alışkanlık', _num(_map(katmanlar['yasam_tarzi'])['risk_puani'])),
                  _akranRiskOzet('Ekran süresi', _num(_map(katmanlar['yasam_tarzi'])['ekran_risk'])),
                  _akranRiskOzet('Uyku düzeni', _num(_map(katmanlar['yasam_tarzi'])['uyku_risk'])),
                  _akranRiskOzet('Fiziksel aktivite', _num(_map(katmanlar['yasam_tarzi'])['aktivite_risk'])),
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
                  _akranRiskOzet('Fiziksel gelişim', _num(_map(katmanlar['fiziksel_gelisim'])['risk_puani'])),
                  _akranKarsilastir(
                    'Gelişim gecikmesi',
                    _num(_map(_map(katmanlar['fiziksel_gelisim'])['gelisim_gecikmesi'])['mutlak_risk']),
                    _num(_map(_map(katmanlar['fiziksel_gelisim'])['gelisim_gecikmesi'])['temel_risk']),
                  ),
                  'BMI: ${_num(_map(katmanlar['fiziksel_gelisim'])['hesaplanan_bmi']).toStringAsFixed(1)}  —  Vücut kitle indeksi',
                  _zSkorYorum('Boy', _num(_map(katmanlar['fiziksel_gelisim'])['boy_zscore'])),
                  _zSkorYorum('Kilo', _num(_map(katmanlar['fiziksel_gelisim'])['kilo_zscore'])),
                  _zSkorYorum('BMI', _num(_map(katmanlar['fiziksel_gelisim'])['bmi_zscore'])),
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
                  value: (risk / 300).clamp(0.0, 1.0),
                  strokeWidth: r.scale(8),
                  backgroundColor: AppTheme.nDark.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${risk.toStringAsFixed(0)}',
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
    if (risk >= 100) return 'Çok Yüksek Risk';
    if (risk >= 50) return 'Yüksek Risk';
    if (risk >= 25) return 'Orta Risk';
    if (risk >= 10) return 'Düşük Risk';
    return 'Çok Düşük Risk';
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

String _akranKarsilastir(String baslik, double mutlak, double temel) {
  final fark = mutlak - temel;
  if (fark.abs() < 1) {
    return '$baslik  —  Akranlarıyla benzer seviyede (%${mutlak.toStringAsFixed(1)}) ✓';
  } else if (fark > 0) {
    return '$baslik  —  Akranlarına göre %${fark.toStringAsFixed(1)} daha fazla risk (%${mutlak.toStringAsFixed(1)} vs %${temel.toStringAsFixed(1)})';
  } else {
    return '$baslik  —  Akranlarına göre %${fark.abs().toStringAsFixed(1)} daha az risk (%${mutlak.toStringAsFixed(1)} vs %${temel.toStringAsFixed(1)}) ✓';
  }
}

String _akranRiskOzet(String baslik, double risk) {
  if (risk <= 5) {
    return '$baslik  —  Akranlarına göre risk yok ✓';
  } else if (risk <= 25) {
    return '$baslik  —  Akranlarına göre %${risk.toStringAsFixed(0)} daha riskli (düşük)';
  } else if (risk <= 50) {
    return '$baslik  —  Akranlarına göre %${risk.toStringAsFixed(0)} daha riskli (orta)';
  } else {
    return '$baslik  —  Akranlarına göre %${risk.toStringAsFixed(0)} daha riskli (yüksek)';
  }
}

String _zSkorYorum(String baslik, double z) {
  final abs = z.abs();
  final yon = z >= 0 ? 'üstünde' : 'altında';
  if (abs < 0.5) {
    return '$baslik (${z.toStringAsFixed(2)})  —  Akranlarıyla uyumlu ✓';
  } else if (abs < 1.5) {
    return '$baslik (${z.toStringAsFixed(2)})  —  Akranlarının hafif $yon';
  } else if (abs < 2) {
    return '$baslik (${z.toStringAsFixed(2)})  —  Akranlarının belirgin $yon';
  } else {
    return '$baslik (${z.toStringAsFixed(2)})  —  Akranlarından çok $yon ⚠';
  }
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
  if (r.contains('cc0000') || r.contains('ff4444') || r.contains('kirmizi') || r.contains('kırmızı') || r.contains('red')) {
    return AppTheme.riskRed;
  }
  if (r.contains('ffaa') || r.contains('sari') || r.contains('sarı') || r.contains('yellow')) {
    return AppTheme.riskYellow;
  }
  if (r.contains('bb44') || r.contains('00cc00') || r.contains('yesil') || r.contains('yeşil') || r.contains('green')) {
    return AppTheme.riskGreen;
  }
  return AppTheme.primaryBlue;
}
