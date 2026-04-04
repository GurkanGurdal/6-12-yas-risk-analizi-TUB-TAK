import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../models/daily_log.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
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
  double _avgSleep = 0;
  double _avgScreen = 0;
  int _avgActivity = 0;

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

    // Compute averages from all available logs
    if (_logs.isNotEmpty) {
      double sumSleep = 0, sumScreen = 0;
      int sumActivity = 0;
      for (final l in _logs) {
        sumSleep += l.sleepHours ?? 0;
        sumScreen += l.screenHours ?? 0;
        sumActivity += l.activityLevel ?? 0;
      }
      setState(() {
        _avgSleep = sumSleep / _logs.length;
        _avgScreen = sumScreen / _logs.length;
        _avgActivity = (sumActivity / _logs.length).round();
      });
    }

    if (_logs.length >= 7) {
      _runAutomaticAnalysis();
    }
  }

  Future<void> _runAutomaticAnalysis() async {
    setState(() => _isAnalyzing = true);

    final last7 = _logs.reversed.take(7).toList();
    double sumSleep = 0;
    double sumScreen = 0;
    int sumActivity = 0;

    for (final l in last7) {
      sumSleep += l.sleepHours ?? 0;
      sumScreen += l.screenHours ?? 0;
      sumActivity += l.activityLevel ?? 0;
    }

    final avgSleep = sumSleep / 7;
    final avgScreen = sumScreen / 7;
    final avgActivity = (sumActivity / 7).round();

    setState(() {
      _avgSleep = avgSleep;
      _avgScreen = avgScreen;
      _avgActivity = avgActivity;
    });

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

    if (!mounted) return;
    setState(() {
      _riskResult = result;
      _isAnalyzing = false;
    });
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

  Color _riskColor() {
    final renk = _riskResult?['grafik_rengi'];
    if (renk is String) {
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
    }
    final v = _riskPercentValue();
    if (v > 60) return AppTheme.riskRed;
    if (v > 30) return AppTheme.riskYellow;
    return AppTheme.riskGreen;
  }

  String _riskLabel() {
    final sonuc = _riskResult?['analiz_sonucu'];
    if (sonuc is String && sonuc.isNotEmpty) {
      if (sonuc.contains('/')) return sonuc.split('/').first.trim();
      return sonuc;
    }
    final v = _riskPercentValue();
    if (v > 60) return 'Yüksek Risk';
    if (v > 30) return 'Orta Risk';
    return 'Düşük Risk';
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final loggedDays = _logs.length;
    final progress = (loggedDays / 7.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.nBase,
      body: _isLoadingLogs
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: r.pagePadding(horizontal: 22, top: 10, bottom: 120),
              child: Column(
                children: [
                  _buildHeader(r),
                  SizedBox(height: r.scale(24)),
                  if (loggedDays < 7)
                    _buildProgressCard(r, loggedDays, progress)
                  else ...[
                    if (_isAnalyzing)
                      _buildAnalyzingState(r)
                    else if (_riskResult != null)
                      _buildRiskResultSection(r)
                    else
                      _buildErrorState(r),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(Responsive r) {
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(20)),
      padding: EdgeInsets.symmetric(horizontal: r.scale(18), vertical: r.scale(14)),
      child: Row(
        children: [
          Neumorphic(
            style: AppTheme.nCircle(),
            padding: EdgeInsets.all(r.scale(3)),
            child: CircleAvatar(
              radius: r.scale(22),
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                _profile.initial,
                style: TextStyle(
                  fontSize: r.scale(18),
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: r.scale(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldin,',
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: r.scale(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: r.scale(2)),
                Text(
                  '${_profile.name}\'in Ebeveyni',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: r.scale(18),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.notifications_none_rounded,
            size: r.scale(24),
            color: AppTheme.textGray,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Responsive r) {
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(22)),
      padding: EdgeInsets.symmetric(
        horizontal: r.scale(20),
        vertical: r.scale(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat(r, 'Yaş', '${_profile.age.toInt()}', null, Icons.cake_outlined, AppTheme.accentPeach),
          _statDivider(r),
          _buildStat(r, 'Boy', '${_profile.heightCm.toInt()}', 'cm', Icons.straighten_outlined, AppTheme.accentGold),
          _statDivider(r),
          _buildStat(r, 'Kilo', '${_profile.weightKg.toInt()}', 'kg', Icons.monitor_weight_outlined, AppTheme.secondaryBlue),
        ],
      ),
    );
  }

  Widget _buildStat(Responsive r, String label, String value, String? unit, IconData icon, Color color) {
    return Column(
      children: [
        Neumorphic(
          style: AppTheme.nConcave(radius: r.scale(30)),
          padding: EdgeInsets.symmetric(horizontal: r.scale(16), vertical: r.scale(10)),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: r.scale(14),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(height: r.scale(10)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textGray,
                fontSize: r.scale(12),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (unit != null) ...[
              SizedBox(width: r.scale(3)),
              Text(
                '($unit)',
                style: TextStyle(
                  color: AppTheme.textGray.withOpacity(0.6),
                  fontSize: r.scale(10),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _statDivider(Responsive r) {
    return Container(
      width: r.scale(2),
      height: r.scale(44),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD8DDE6), Color(0xFFEDF1F9), Color(0xFFD8DDE6)],
        ),
      ),
    );
  }

  Widget _buildProgressCard(Responsive r, int loggedDays, double progress) {
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(24)),
      padding: EdgeInsets.all(r.scale(24)),
      child: Column(
        children: [
          Neumorphic(
            style: AppTheme.nConcave(radius: r.scale(60)),
            padding: EdgeInsets.all(r.scale(12)),
            child: SizedBox(
            height: r.scale(100),
            width: r.scale(100),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: r.scale(8),
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$loggedDays/7',
                        style: TextStyle(
                          fontSize: r.scale(22),
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      Text(
                        'gün',
                        style: TextStyle(
                          fontSize: r.scale(12),
                          color: AppTheme.textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
          SizedBox(height: r.scale(18)),
          Text(
            'Haftalık Analiz Bekleniyor',
            style: TextStyle(
              fontSize: r.scale(18),
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: r.scale(10)),
          Text(
            'AI analizinin oluşturulabilmesi için 7 günlük veri girilmelidir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: r.scale(13),
              height: 1.5,
            ),
          ),
          SizedBox(height: r.scale(18)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) {
              final filled = i < loggedDays;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: r.scale(32),
                height: r.scale(8),
                margin: EdgeInsets.symmetric(horizontal: r.scale(3)),
                decoration: filled
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(r.scale(4)),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      )
                    : BoxDecoration(
                        borderRadius: BorderRadius.circular(r.scale(4)),
                        color: AppTheme.nDark.withOpacity(0.18),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState(Responsive r) {
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(24)),
      padding: EdgeInsets.all(r.scale(32)),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryBlue),
          SizedBox(height: r.scale(16)),
          Text(
            'Risk hesaplanıyor...',
            style: TextStyle(color: AppTheme.textGray, fontSize: r.scale(14)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Responsive r) {
    return Neumorphic(
      style: AppTheme.nFlat(radius: r.scale(24)),
      padding: EdgeInsets.all(r.scale(24)),
      child: Row(
        children: [
          Neumorphic(
            style: AppTheme.nCircleConcave(),
            padding: EdgeInsets.all(r.scale(8)),
            child: Icon(Icons.error_outline_rounded, color: AppTheme.riskRed, size: r.scale(24)),
          ),
          SizedBox(width: r.scale(12)),
          Expanded(
            child: Text(
              'Sonuç alınamadı, API bağlantısını kontrol edin.',
              style: TextStyle(color: AppTheme.riskRed, fontSize: r.scale(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskResultSection(Responsive r) {
    return Column(
      children: [
        // Child PNG (right) + Info bar (left)
        SizedBox(
          height: (r.height * 0.42).clamp(r.scale(320), r.scale(420)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: vertical info bar
              Neumorphic(
                style: AppTheme.nConvex(radius: r.scale(20)),
                child: Container(
                  width: r.scale(130),
                  padding: EdgeInsets.symmetric(vertical: r.scale(14)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildVerticalInfoItem(r, '${_profile.age.toInt()}', 'Yaş', Icons.cake_outlined, AppTheme.accentPeach),
                      _buildVerticalInfoItem(r, '${_profile.heightCm.toInt()}', 'Boy (cm)', Icons.straighten_outlined, AppTheme.accentGold),
                      _buildVerticalInfoItem(r, '${_profile.weightKg.toInt()}', 'Kilo (kg)', Icons.monitor_weight_outlined, AppTheme.secondaryBlue),
                      Container(
                        width: r.scale(40),
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFD8DDE6), Color(0xFFEDF1F9), Color(0xFFD8DDE6)],
                          ),
                        ),
                      ),
                      _buildVerticalInfoItem(r, '${_avgSleep.toStringAsFixed(1)}', 'Uyku (sa)', Icons.bedtime_outlined, AppTheme.primaryBlue),
                      _buildVerticalInfoItem(r, '${_avgScreen.toStringAsFixed(1)}', 'Ekran (sa)', Icons.phone_android_outlined, AppTheme.riskYellow),
                      _buildVerticalInfoItem(r, const ['Düşük', 'Orta', 'Yüksek'][_avgActivity.clamp(0, 2)], 'Aktivite', Icons.directions_run_outlined, AppTheme.riskGreen),
                    ],
                  ),
                ),
              ),
              SizedBox(width: r.scale(8)),
              // Right: child PNG
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildChildSilhouette(r),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: r.scale(16)),
        _buildRiskCard(r),
      ],
    );
  }

  Widget _buildVerticalInfoItem(Responsive r, String value, String label, IconData icon, Color color) {
    return Neumorphic(
      style: AppTheme.nConcave(radius: r.scale(16)),
      child: Container(
        width: r.scale(112),
        padding: EdgeInsets.symmetric(horizontal: r.scale(8), vertical: r.scale(8)),
        child: Row(
          children: [
            Neumorphic(
              style: AppTheme.nCircle(depth: 4),
              padding: EdgeInsets.all(r.scale(7)),
              child: Icon(icon, size: r.scale(15), color: color),
            ),
            SizedBox(width: r.scale(7)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: r.scale(14),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textGray,
                      fontSize: r.scale(10),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard(Responsive r) {
    final riskVal = _riskPercentValue();
    final color = _riskColor();

    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(28)),
      child: Container(
        width: double.infinity,
        child: Padding(
        padding: EdgeInsets.fromLTRB(r.scale(22), r.scale(24), r.scale(22), r.scale(22)),
        child: Column(
          children: [
            Neumorphic(
              style: AppTheme.nCircle(depth: 8),
              padding: EdgeInsets.all(r.scale(14)),
              child: SizedBox(
                height: r.scale(88),
                width: r.scale(88),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: riskVal / 100,
                      strokeWidth: r.scale(8),
                      backgroundColor: color.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '%${riskVal.toInt()}',
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontSize: r.scale(22),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Risk',
                            style: TextStyle(
                              color: AppTheme.textGray,
                              fontSize: r.scale(11),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: r.scale(14)),
            Neumorphic(
              style: AppTheme.nConcave(radius: r.scale(999)),
              padding: EdgeInsets.symmetric(horizontal: r.scale(16), vertical: r.scale(7)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: r.scale(8),
                    height: r.scale(8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: r.scale(8)),
                  Text(
                    _riskLabel(),
                    style: TextStyle(
                      color: color,
                      fontSize: r.scale(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.scale(18)),
            NeumorphicButton(
                style: AppTheme.nConvex(radius: r.scale(14)),
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
                padding: EdgeInsets.symmetric(horizontal: r.scale(20), vertical: r.scale(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Detaylı Rapor',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: r.scale(13),
                      ),
                    ),
                    SizedBox(width: r.scale(6)),
                    Icon(Icons.arrow_forward_rounded, size: r.scale(16), color: AppTheme.primaryBlue),
                  ],
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildChildSilhouette(Responsive r) {
    final modelWidth = (r.width * 0.50).clamp(r.scale(190), r.scale(290)).toDouble();
    final modelHeight = (modelWidth * 1.45).clamp(r.scale(225), r.scale(340)).toDouble();

    return SizedBox(
      width: modelWidth,
      height: modelHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, -r.scale(12)),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: r.scale(8), sigmaY: r.scale(8)),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  AppTheme.primaryBlue.withOpacity(0.20),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'lib/assets/boy.png',
                  width: modelWidth,
                  height: modelHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -r.scale(12)),
            child: Image.asset(
              'lib/assets/boy.png',
              width: modelWidth,
              height: modelHeight,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
