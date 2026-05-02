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

    final psikolojik = _map(katmanlar['psikolojik']);
    final yasamTarzi = _map(katmanlar['yasam_tarzi']);
    final fiziksel = _map(katmanlar['fiziksel_gelisim']);

    // Genel risk puanına katkılar (risk_engine.py:362-369 formülü)
    final psikolojikKatki = (
      _num(_map(psikolojik['anksiyete'])['ek_risk']) +
      _num(_map(psikolojik['depresyon'])['ek_risk']) +
      _num(_map(psikolojik['dehb'])['ek_risk']) +
      _num(_map(psikolojik['davranis'])['ek_risk'])
    ) / 4;
    final yasamTarziKatki = _num(yasamTarzi['risk_puani']);
    final fizikselKatki = _num(fiziksel['risk_puani']) * 0.6 +
        _num(_map(fiziksel['gelisim_gecikmesi'])['ek_risk']) * 0.4;

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
              if (dikkatAlanlari.isNotEmpty) ...[
                _AlertCard(items: dikkatAlanlari),
                SizedBox(height: r.scale(16)),
              ],
              _RingLayerCard(
                title: 'Duygusal ve Davranışsal Sağlık',
                subtitle: 'Yaşam alışkanlıklarının çocuğunuzun ruhsal durumundaki riski ne kadar artırdığını gösterir.',
                icon: Icons.psychology_alt_outlined,
                accent: AppTheme.secondaryBlue,
                contribution: psikolojikKatki,
                items: [
                  _buildEkRiskItem('Kaygı (Anksiyete)', _map(psikolojik['anksiyete'])),
                  _buildEkRiskItem('Depresyon', _map(psikolojik['depresyon'])),
                  _buildEkRiskItem('Dikkat eksikliği (DEHB)', _map(psikolojik['dehb'])),
                  _buildEkRiskItem('Davranış bozukluğu', _map(psikolojik['davranis'])),
                ],
              ),
              SizedBox(height: r.scale(12)),
              _RingLayerCard(
                title: 'Günlük Alışkanlıklar',
                subtitle: 'Ekran süresi, uyku düzeni ve fiziksel aktivitenin risk katkısı.',
                icon: Icons.favorite_outline,
                accent: AppTheme.accentPeach,
                contribution: yasamTarziKatki,
                items: [
                  _RingItem(
                    label: 'Toplam alışkanlık riski',
                    percent: _num(yasamTarzi['risk_puani']),
                    maxScale: 100,
                    description: _habitSummaryText(_num(yasamTarzi['risk_puani'])),
                    severity: _lifestyleSeverity(_num(yasamTarzi['risk_puani'])),
                  ),
                  _RingItem(
                    label: 'Ekran süresi',
                    percent: _num(yasamTarzi['ekran_risk']),
                    maxScale: 100,
                    description: _habitSummaryText(_num(yasamTarzi['ekran_risk'])),
                    severity: _lifestyleSeverity(_num(yasamTarzi['ekran_risk'])),
                  ),
                  _RingItem(
                    label: 'Uyku düzeni',
                    percent: _num(yasamTarzi['uyku_risk']),
                    maxScale: 100,
                    description: _habitSummaryText(_num(yasamTarzi['uyku_risk'])),
                    severity: _lifestyleSeverity(_num(yasamTarzi['uyku_risk'])),
                  ),
                  _RingItem(
                    label: 'Fiziksel aktivite',
                    percent: _num(yasamTarzi['aktivite_risk']),
                    maxScale: 100,
                    description: _habitSummaryText(_num(yasamTarzi['aktivite_risk'])),
                    severity: _lifestyleSeverity(_num(yasamTarzi['aktivite_risk'])),
                  ),
                ],
                footer: _splitDetails(_text(yasamTarzi['detaylar'])),
              ),
              SizedBox(height: r.scale(12)),
              _PhysicalLayerCard(fiziksel: fiziksel, contribution: fizikselKatki),
            ],
          ),
        ),
      ),
    );
  }

  _RingItem _buildEkRiskItem(String label, Map<String, dynamic> item) {
    final ek = _num(item['ek_risk']);
    return _RingItem(
      label: label,
      percent: ek,
      maxScale: 20,
      description: _ekRiskText(ek),
      severity: _ekRiskSeverity(ek),
    );
  }
}

// ── Hero Risk Card ──
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
                    risk.toStringAsFixed(0),
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
    // Eşikler NSCH 2023 popülasyon dağılımı ve k2q01 dış doğrulamayla kalibre.
    if (risk >= 80) return 'Çok Yüksek Risk';
    if (risk >= 65) return 'Yüksek Risk';
    if (risk >= 50) return 'Orta Risk';
    if (risk >= 35) return 'Düşük Risk';
    return 'Çok Düşük Risk';
  }
}

// ── Alert Card ──
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
                      decoration: BoxDecoration(color: AppTheme.riskYellow, shape: BoxShape.circle),
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

// ── Contribution Badge (başlığın yanında +X puan rozeti) ──
class _ContributionBadge extends StatelessWidget {
  final double value;
  final Color accent;
  const _ContributionBadge({required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final rounded = value < 10 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
    return Neumorphic(
      style: AppTheme.nConcave(radius: 999, depth: -2),
      padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: r.scale(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_circle_outline_rounded, color: accent, size: r.scale(13)),
          SizedBox(width: r.scale(4)),
          Text(
            '$rounded puan',
            style: TextStyle(
              color: accent,
              fontSize: r.scale(11.5),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ring Item Model ──
class _RingItem {
  final String label;
  final double percent;
  final double maxScale;
  final String description;
  final Color severity;

  const _RingItem({
    required this.label,
    required this.percent,
    required this.maxScale,
    required this.description,
    required this.severity,
  });
}

// ── Ring Layer Card (psychological + lifestyle) ──
class _RingLayerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<_RingItem> items;
  final List<String> footer;
  final double? contribution;

  const _RingLayerCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.items,
    this.footer = const [],
    this.contribution,
  });

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
                width: r.scale(42),
                height: r.scale(42),
                child: Neumorphic(
                  style: AppTheme.nCircle(),
                  child: Center(child: Icon(icon, color: accent, size: r.scale(20))),
                ),
              ),
              SizedBox(width: r.scale(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(title,
                              style: TextStyle(
                                  fontSize: r.scale(16),
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark)),
                        ),
                        if (contribution != null) ...[
                          SizedBox(width: r.scale(8)),
                          _ContributionBadge(value: contribution!, accent: accent),
                        ],
                      ],
                    ),
                    SizedBox(height: r.scale(2)),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppTheme.textGray, fontSize: r.scale(12), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.scale(14)),
          ...List.generate(items.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : r.scale(10)),
              child: _RingRow(item: items[i]),
            );
          }),
          if (footer.isNotEmpty) ...[
            SizedBox(height: r.scale(14)),
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            SizedBox(height: r.scale(10)),
            ...footer.map(
              (d) => Padding(
                padding: EdgeInsets.only(bottom: r.scale(6)),
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
                    Expanded(
                      child: Text(
                        d,
                        style: TextStyle(color: AppTheme.textGray, fontSize: r.scale(12.5), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Single Row with circular ring ──
class _RingRow extends StatelessWidget {
  final _RingItem item;
  const _RingRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final absP = item.percent.abs();
    final progress = (absP / item.maxScale).clamp(0.0, 1.0);
    final label = absP < 10
        ? '${item.percent.toStringAsFixed(1)}%'
        : '${item.percent.toStringAsFixed(0)}%';

    return Neumorphic(
      style: AppTheme.nConcave(radius: r.scale(14), depth: -3),
      padding: EdgeInsets.fromLTRB(r.scale(14), r.scale(12), r.scale(12), r.scale(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: r.scale(14),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: r.scale(4)),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: r.scale(12),
                    color: AppTheme.textGray,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: r.scale(12)),
          SizedBox(
            width: r.scale(56),
            height: r.scale(56),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: r.scale(5),
                  backgroundColor: AppTheme.nDark.withOpacity(0.22),
                  valueColor: AlwaysStoppedAnimation<Color>(item.severity),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: item.severity,
                      fontSize: r.scale(12),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Physical Layer Card ──
class _PhysicalLayerCard extends StatelessWidget {
  final Map<String, dynamic> fiziksel;
  final double? contribution;
  const _PhysicalLayerCard({required this.fiziksel, this.contribution});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final boyZ = _num(fiziksel['boy_zscore']);
    final kiloZ = _num(fiziksel['kilo_zscore']);
    final bmiZ = _num(fiziksel['bmi_zscore']);
    final bmi = _num(fiziksel['hesaplanan_bmi']);
    final gelisim = _map(fiziksel['gelisim_gecikmesi']);
    final gelisimEk = _num(gelisim['ek_risk']);
    final riskPuani = _num(fiziksel['risk_puani']);
    final detaylar = _splitDetails(_text(fiziksel['detaylar']));

    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(20)),
      padding: EdgeInsets.all(r.scale(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: r.scale(42),
                height: r.scale(42),
                child: Neumorphic(
                  style: AppTheme.nCircle(),
                  child: Center(child: Icon(Icons.accessibility_new, color: AppTheme.riskGreen, size: r.scale(20))),
                ),
              ),
              SizedBox(width: r.scale(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text('Büyüme ve Fiziksel Gelişim',
                              style: TextStyle(
                                  fontSize: r.scale(16),
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark)),
                        ),
                        if (contribution != null) ...[
                          SizedBox(width: r.scale(8)),
                          _ContributionBadge(value: contribution!, accent: AppTheme.riskGreen),
                        ],
                      ],
                    ),
                    SizedBox(height: r.scale(2)),
                    Text(
                      'Boy, kilo ve BMI\'nin yaşına göre karşılaştırması (Z-skoru 0\'a yakınsa yaşıtlarıyla uyumlu).',
                      style: TextStyle(color: AppTheme.textGray, fontSize: r.scale(12), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.scale(14)),
          _RingRow(
            item: _RingItem(
              label: 'Fiziksel gelişim riski',
              percent: riskPuani,
              maxScale: 100,
              description: _habitSummaryText(riskPuani),
              severity: _lifestyleSeverity(riskPuani),
            ),
          ),
          SizedBox(height: r.scale(10)),
          _RingRow(
            item: _RingItem(
              label: 'Gelişim gecikmesi katkısı',
              percent: gelisimEk,
              maxScale: 20,
              description: _ekRiskText(gelisimEk),
              severity: _ekRiskSeverity(gelisimEk),
            ),
          ),
          SizedBox(height: r.scale(14)),
          Container(height: 1, color: const Color(0xFFE2E8F0)),
          SizedBox(height: r.scale(12)),
          _ZScoreRow(label: 'BMI', value: bmi.toStringAsFixed(1), hint: 'Vücut kitle indeksi'),
          _ZScoreRow(label: 'Boy Z', value: boyZ.toStringAsFixed(2), hint: _zScoreHint(boyZ)),
          _ZScoreRow(label: 'Kilo Z', value: kiloZ.toStringAsFixed(2), hint: _zScoreHint(kiloZ)),
          _ZScoreRow(label: 'BMI Z', value: bmiZ.toStringAsFixed(2), hint: _zScoreHint(bmiZ)),
          if (detaylar.isNotEmpty) ...[
            SizedBox(height: r.scale(10)),
            ...detaylar.map(
              (d) => Padding(
                padding: EdgeInsets.only(bottom: r.scale(6)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: r.scale(6)),
                      child: Container(
                        width: r.scale(5),
                        height: r.scale(5),
                        decoration: const BoxDecoration(color: AppTheme.riskGreen, shape: BoxShape.circle),
                      ),
                    ),
                    SizedBox(width: r.scale(10)),
                    Expanded(
                      child: Text(d,
                          style: TextStyle(color: AppTheme.textGray, fontSize: r.scale(12.5), height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ZScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  const _ZScoreRow({required this.label, required this.value, required this.hint});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r.scale(6)),
      child: Row(
        children: [
          SizedBox(
            width: r.scale(60),
            child: Text(label, style: TextStyle(fontSize: r.scale(13), color: AppTheme.textGray, fontWeight: FontWeight.w600)),
          ),
          Text(value, style: TextStyle(fontSize: r.scale(14), color: AppTheme.textDark, fontWeight: FontWeight.w700)),
          SizedBox(width: r.scale(10)),
          Expanded(
            child: Text(hint, style: TextStyle(fontSize: r.scale(12), color: AppTheme.textGray, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──
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
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
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
  return raw.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

String _ekRiskText(double ek) {
  final abs = ek.abs();
  if (abs < 0.5) return 'Yaşam alışkanlıkları riski değiştirmiyor.';
  if (ek > 0) {
    return 'Yaşam alışkanlıkları riski %${abs.toStringAsFixed(abs < 10 ? 1 : 0)} artırıyor.';
  }
  return 'Yaşam alışkanlıkları riski %${abs.toStringAsFixed(abs < 10 ? 1 : 0)} azaltıyor.';
}

Color _ekRiskSeverity(double ek) {
  if (ek <= 0.5) return AppTheme.riskGreen;
  if (ek < 3) return AppTheme.primaryBlue;
  if (ek < 8) return AppTheme.riskYellow;
  return AppTheme.riskRed;
}

String _habitSummaryText(double risk) {
  if (risk <= 5) return 'Sağlıklı aralıkta, risk katkısı yok.';
  if (risk <= 25) return 'Düşük seviyede risk katkısı.';
  if (risk <= 50) return 'Orta seviyede risk katkısı.';
  return 'Yüksek seviyede risk katkısı.';
}

Color _lifestyleSeverity(double risk) {
  if (risk <= 5) return AppTheme.riskGreen;
  if (risk <= 25) return AppTheme.primaryBlue;
  if (risk <= 50) return AppTheme.riskYellow;
  return AppTheme.riskRed;
}

String _zScoreHint(double z) {
  final abs = z.abs();
  final yon = z >= 0 ? 'üstünde' : 'altında';
  if (abs < 0.5) return 'Yaşıtlarıyla uyumlu';
  if (abs < 1.5) return 'Yaşıtlarının hafif $yon';
  if (abs < 2) return 'Yaşıtlarının belirgin $yon';
  return 'Yaşıtlarından çok $yon';
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
