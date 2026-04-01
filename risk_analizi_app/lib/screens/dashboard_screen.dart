import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../models/daily_log.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'daily_log_screen.dart'; // Eski analiz formunun yerini alacak
import 'analysis_report_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ChildProfile profile;
  final VoidCallback? onOpenAnalysisTab;
  
  const DashboardScreen({
    super.key,
    required this.profile,
    this.onOpenAnalysisTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ChildProfile _profile;
  List<DailyLog> _logs = [];
  bool _isLoadingLogs = true;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _riskResult;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingLogs = true);
    final logs = await StorageService.getDailyLogsForProfile(_profile);
    setState(() {
      _logs = logs;
      _isLoadingLogs = false;
    });

    if (_logs.length >= 7) {
      _runAutomaticAnalysis();
    }
  }

  Future<void> _runAutomaticAnalysis() async {
    setState(() => _isAnalyzing = true);
    
    // Son 7 günün ortalamasını al
    final last7 = _logs.reversed.take(7).toList();
    double sumSleep = 0, sumScreen = 0;
    int sumActivity = 0;
    
    for (var l in last7) {
      sumSleep += l.sleepHours;
      sumScreen += l.screenHours;
      sumActivity += l.activityLevel;
    }

    double avgSleep = sumSleep / 7;
    double avgScreen = sumScreen / 7;
    int avgActivity = (sumActivity / 7).round();

    final api = ApiService();
    final result = await api.analizYap(
      yas: _profile.age,
      cinsiyet: _profile.gender,
      boyKm: _profile.heightCm,
      kiloKg: _profile.weightKg,
      uykuSaati: avgSleep,
      ekranSaati: avgScreen,
      fizikselAktivite: avgActivity,
    );

    if (result != null) {
      await StorageService.saveLatestRiskReportForProfile(_profile, result);
    }

    if (mounted) {
      setState(() {
        _riskResult = result;
        _isAnalyzing = false;
      });
    }
  }

  double _riskPercentValue() {
    final raw = _riskResult?['genel_risk_puani'];
    if (raw is num) return raw.toDouble().clamp(0, 100).toDouble();
    if (raw is String) {
      final parsed = double.tryParse(raw.replaceAll(',', '.'));
      if (parsed != null) return parsed.clamp(0, 100).toDouble();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    int loggedDays = _logs.length;
    double progress = (loggedDays / 7.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoadingLogs ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: r.pagePadding(horizontal: 24, top: 12, bottom: 28),
        child: Column(
          children: [
            // Üst Profil Header (kartsiz)
            Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba,',
                              style: TextStyle(color: AppTheme.mutedOnDark, fontSize: r.scale(14)),
                            ),
                            Text(
                              _profile.name,
                              style: TextStyle(color: AppTheme.accentGold, fontSize: r.scale(24), fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: r.scale(12)),
                      CircleAvatar(
                        radius: r.scale(28),
                        backgroundColor: Colors.white.withOpacity(0.16),
                        child: Text(
                          _profile.initial,
                          style: TextStyle(fontSize: r.scale(24), color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.scale(10)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Yaş: ${_profile.age.toInt()}   •   Boy: ${_profile.heightCm.toInt()} cm   •   Kilo: ${_profile.weightKg.toInt()} kg',
                      style: TextStyle(
                        color: AppTheme.mutedOnDark,
                        fontSize: r.scale(14, minScale: 0.9, maxScale: 1.15),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            
            SizedBox(height: r.scale(32)),

            // Durum ve İlerleme veya Sonuç
            if (loggedDays < 7) ...[
              Text('Haftalık Analiz Bekleniyor', style: TextStyle(fontSize: r.scale(18), fontWeight: FontWeight.bold, color: AppTheme.textOnDark)),
              SizedBox(height: r.scale(16)),
              LinearProgressIndicator(
                value: progress,
                minHeight: r.scale(12),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                borderRadius: BorderRadius.circular(r.scale(10)),
              ),
              SizedBox(height: r.scale(8)),
              Text('$loggedDays/7 Gün Tamamlandı', style: TextStyle(color: AppTheme.mutedOnDark, fontSize: r.scale(14))),
              SizedBox(height: r.scale(16)),
              Text(
                'Yapay Zeka analizinin hesaplanabilmesi için 7 günlük uyku, ekran ve aktivite verisi girilmelidir. Eksik günleri + butonundan ekleyebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.mutedOnDark, fontSize: r.scale(13)),
              ),
            ] else ...[
              if (_isAnalyzing)
                const Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryBlue),
                    SizedBox(height: 16),
                    Text('Risk hesaplanıyor...', style: TextStyle(color: AppTheme.textGray)),
                  ],
                )
              else if (_riskResult != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(r.scale(24)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(r.scale(24)),
                        border: Border.all(color: Colors.white.withOpacity(0.30)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: r.scale(18),
                            offset: Offset(0, r.scale(8)),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(r.scale(16), r.scale(14), r.scale(16), r.scale(16)),
                        child: Column(
                          children: [
                            Icon(Icons.psychology, size: r.scale(30), color: Colors.white),
                            SizedBox(height: r.scale(6)),
                            Text('Haftalık Risk Durumu', style: TextStyle(color: Colors.white70, fontSize: r.scale(16))),
                            SizedBox(height: r.scale(6)),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final size = (constraints.maxWidth * 0.72).clamp(205.0, 235.0);
                                return SizedBox(
                                  height: r.scale(260),
                                  child: Center(
                                    child: SizedBox(
                                      width: size,
                                      height: size,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Positioned.fill(
                                            child: Transform.rotate(
                                              angle: math.pi,
                                              child: CircularProgressIndicator(
                                                value: _riskPercentValue() / 100,
                                                strokeWidth: r.scale(16, minScale: 0.9, maxScale: 1.2),
                                                backgroundColor: Colors.white24,
                                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                                              ),
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '%${_riskPercentValue().toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: (size * 0.18).clamp(r.scale(36), r.scale(52)),
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'Risk',
                                                style: TextStyle(color: Colors.white70, fontSize: r.scale(14)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: r.scale(8)),
                            Text(
                              _riskResult!['analiz_sonucu'],
                              style: TextStyle(color: Colors.white, fontSize: r.scale(18), fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: r.scale(16)),
                            ElevatedButton(
                              onPressed: () {
                                if (widget.onOpenAnalysisTab != null) {
                                  widget.onOpenAnalysisTab!();
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AnalysisReportScreen(profile: _profile),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryBlue),
                              child: const Text('Detaylı Raporu Gör'),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else 
                const Text('Sonuç alınamadı, API bağlantısını kontrol edin.', style: TextStyle(color: AppTheme.riskRed)),
            ],

            SizedBox(height: r.scale(32)),
            // Günlük Ekle Butonu
            SizedBox(
              width: double.infinity,
              height: r.scale(60),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DailyLogScreen(profile: _profile)),
                  );
                  // Veri eklenince tekrar yükle
                  _loadData();
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Günlük İstatistik Gir (+)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPeach,
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
