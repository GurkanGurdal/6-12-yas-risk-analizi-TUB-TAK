import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../models/daily_log.dart';
import '../services/storage_service.dart';

class DailyLogScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  final ChildProfile profile;

  const DailyLogScreen({super.key, required this.profile, this.onSaved});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  DateTime _selectedDate = DateTime.now();
  double _uykuSaati = 8;
  double _ekranSaati = 2;
  int _fizikselAktivite = 1;

  // Mevcut kayıt ve alan bazlı kayıt durumları
  DailyLog? _existingLog;
  bool _screenSaved = false;
  bool _sleepSaved = false;
  bool _activitySaved = false;

  /// Tüm kayıtlı günleri tutan harita (tarih string → DailyLog)
  Map<String, DailyLog> _loggedDates = {};

  /// Grafik periyodu: 0=Günlük, 1=Haftalık, 2=Aylık
  int _chartPeriod = 0;

  /// Grafikte hangi serilerin görüneceği
  bool _showScreen = true;
  bool _showSleep = true;
  bool _showActivity = true;

  @override
  void initState() {
    super.initState();
    _loadAllLogs();
  }

  String get _dateStr =>
      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

  Future<void> _loadAllLogs() async {
    final logs = await StorageService.getDailyLogsForProfile(widget.profile);
    if (!mounted) return;
    final map = <String, DailyLog>{};
    for (final l in logs) {
      map[l.date] = l;
    }
    setState(() => _loggedDates = map);
    _applyDateLog();
  }

  void _applyDateLog() {
    final log = _loggedDates[_dateStr];
    setState(() {
      _existingLog = log;
      if (log != null) {
        if (log.screenHours != null) _ekranSaati = log.screenHours!;
        if (log.sleepHours != null) _uykuSaati = log.sleepHours!;
        if (log.activityLevel != null) _fizikselAktivite = log.activityLevel!;
        _screenSaved = log.screenHours != null;
        _sleepSaved = log.sleepHours != null;
        _activitySaved = log.activityLevel != null;
      } else {
        _ekranSaati = 2;
        _uykuSaati = 8;
        _fizikselAktivite = 1;
        _screenSaved = false;
        _sleepSaved = false;
        _activitySaved = false;
      }
    });
  }

  void _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _CustomCalendarDialog(
        selectedDate: _selectedDate,
        loggedDates: _loggedDates,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _applyDateLog();
    }
  }

  /// Tek bir alanı kaydet (mevcut verilerle birleştir)
  Future<void> _saveField(String field) async {
    // Mevcut kayıttan diğer alanları al, yoksa varsayılanları kullan
    final existing = _existingLog;
    final log = DailyLog(
      date: _dateStr,
      sleepHours: field == 'sleep' ? _uykuSaati : existing?.sleepHours,
      screenHours: field == 'screen' ? _ekranSaati : existing?.screenHours,
      activityLevel: field == 'activity' ? _fizikselAktivite : existing?.activityLevel,
    );

    await StorageService.saveDailyLogForProfile(widget.profile, log);
    if (!mounted) return;

    setState(() {
      _existingLog = log;
      _loggedDates[_dateStr] = log;
      if (field == 'screen') _screenSaved = true;
      if (field == 'sleep') _sleepSaved = true;
      if (field == 'activity') _activitySaved = true;
    });

    final labels = {'screen': 'Ekran süresi', 'sleep': 'Uyku süresi', 'activity': 'Fiziksel aktivite'};
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${labels[field]} kaydedildi ✓'),
        backgroundColor: AppTheme.riskGreen,
        duration: const Duration(seconds: 1),
      ),
    );

    if (widget.onSaved != null) widget.onSaved!();
  }

  void _saveLog() async {
    final log = DailyLog(
      date: _dateStr,
      sleepHours: _uykuSaati,
      screenHours: _ekranSaati,
      activityLevel: _fizikselAktivite,
    );

    await StorageService.saveDailyLogForProfile(widget.profile, log);

    if (!mounted) return;
    setState(() {
      _existingLog = log;
      _loggedDates[_dateStr] = log;
      _screenSaved = true;
      _sleepSaved = true;
      _activitySaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_dateStr verisi başarıyla kaydedildi!'),
        backgroundColor: AppTheme.riskGreen,
      ),
    );
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: r.pagePadding(horizontal: 22, top: 10, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Neumorphic(
                style: AppTheme.nConvex(radius: r.scale(16)),
                padding: EdgeInsets.all(r.scale(16)),
                child: Row(
                  children: [
                    SizedBox(
                      width: r.scale(40),
                      height: r.scale(40),
                      child: Neumorphic(
                        style: AppTheme.nCircle(),
                        child: Center(
                          child: Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accentGold, size: r.scale(20)),
                        ),
                      ),
                    ),
                    SizedBox(width: r.scale(12)),
                    Expanded(
                      child: Text(
                        '7 günlük veri ile AI analizi daha doğru sonuç verir.',
                        style: TextStyle(color: AppTheme.textGray, height: 1.4, fontSize: r.scale(13)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: r.scale(20)),

              Neumorphic(
                style: AppTheme.nConvex(radius: r.scale(20)),
                padding: EdgeInsets.all(r.scale(18)),
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(r.scale(18)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: r.scale(48),
                        height: r.scale(48),
                        child: Neumorphic(
                          style: AppTheme.nCircle(),
                          child: Center(
                            child: Icon(Icons.calendar_month_rounded, color: AppTheme.primaryBlue, size: r.scale(22)),
                          ),
                        ),
                      ),
                      SizedBox(width: r.scale(14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tarih',
                              style: TextStyle(color: AppTheme.textGray, fontSize: r.scale(12), fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: r.scale(2)),
                            Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: r.scale(17),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: r.scale(36),
                        height: r.scale(36),
                        child: Neumorphic(
                          style: AppTheme.nConcave(radius: r.scale(10)),
                          child: Center(
                            child: Icon(Icons.edit_rounded, color: AppTheme.textGray, size: r.scale(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: r.scale(18)),

              _buildSliderCard(
                r,
                icon: Icons.phone_android_rounded,
                iconColor: AppTheme.riskRed,
                title: 'Ekran Süresi',
                value: _ekranSaati,
                valueLabel: '${_ekranSaati.toInt()} Saat',
                valueLabelColor: AppTheme.riskRed,
                min: 0,
                max: 14,
                divisions: 14,
                activeColor: AppTheme.riskRed,
                saved: _screenSaved,
                onChanged: (val) => setState(() {
                  _ekranSaati = val;
                  _screenSaved = false;
                }),
                onSave: () => _saveField('screen'),
              ),
              SizedBox(height: r.scale(14)),

              _buildSliderCard(
                r,
                icon: Icons.bedtime_rounded,
                iconColor: AppTheme.riskGreen,
                title: 'Uyku Süresi',
                value: _uykuSaati,
                valueLabel: '${_uykuSaati.toInt()} Saat',
                valueLabelColor: AppTheme.riskGreen,
                min: 0,
                max: 16,
                divisions: 16,
                activeColor: AppTheme.riskGreen,
                saved: _sleepSaved,
                onChanged: (val) => setState(() {
                  _uykuSaati = val;
                  _sleepSaved = false;
                }),
                onSave: () => _saveField('sleep'),
              ),
              SizedBox(height: r.scale(14)),

              Neumorphic(
                style: AppTheme.nConvex(radius: r.scale(20)),
                padding: EdgeInsets.all(r.scale(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: r.scale(40),
                          height: r.scale(40),
                          child: Neumorphic(
                            style: AppTheme.nCircle(),
                            child: Center(
                              child: Icon(Icons.directions_run_rounded, color: AppTheme.accentPeach, size: r.scale(20)),
                            ),
                          ),
                        ),
                        SizedBox(width: r.scale(12)),
                        Text(
                          'Fiziksel Aktivite',
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: r.scale(15),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (_activitySaved)
                          Icon(Icons.check_circle, color: AppTheme.riskGreen, size: r.scale(20))
                        else
                          GestureDetector(
                            onTap: () => _saveField('activity'),
                            child: Neumorphic(
                              style: AppTheme.nConvex(radius: r.scale(10), depth: 4),
                              padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: r.scale(6)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save_rounded, size: r.scale(14), color: AppTheme.accentPeach),
                                  SizedBox(width: r.scale(4)),
                                  Text('Kaydet', style: TextStyle(fontSize: r.scale(11), fontWeight: FontWeight.w600, color: AppTheme.accentPeach)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: r.scale(16)),
                    Row(
                      children: List.generate(3, (i) {
                        final labels = ['Düşük', 'Orta', 'Yüksek'];
                        final sublabels = ['0-20 dk/gün', '20-60 dk/gün', '60+ dk/gün'];
                        final icons = [Icons.self_improvement, Icons.directions_walk, Icons.directions_run];
                        final selected = _fizikselAktivite == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _fizikselAktivite = i;
                              _activitySaved = false;
                            }),
                            child: Neumorphic(
                              style: selected
                                  ? AppTheme.nConcave(radius: r.scale(14))
                                  : AppTheme.nConvex(radius: r.scale(14), depth: 4),
                              margin: EdgeInsets.symmetric(horizontal: r.scale(4)),
                              padding: EdgeInsets.symmetric(vertical: r.scale(10)),
                              child: Column(
                                children: [
                                  Icon(icons[i], color: selected ? AppTheme.primaryBlue : AppTheme.textGray, size: r.scale(22)),
                                  SizedBox(height: r.scale(4)),
                                  Text(
                                    labels[i],
                                    style: TextStyle(
                                      color: selected ? AppTheme.primaryBlue : AppTheme.textGray,
                                      fontSize: r.scale(12),
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: r.scale(2)),
                                  Text(
                                    sublabels[i],
                                    style: TextStyle(
                                      color: selected ? AppTheme.primaryBlue.withOpacity(0.6) : AppTheme.textGray.withOpacity(0.6),
                                      fontSize: r.scale(9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              SizedBox(height: r.scale(20)),

              // Mevcut veri göstergesi
              if (_existingLog != null)
                Padding(
                  padding: EdgeInsets.only(bottom: r.scale(14)),
                  child: Neumorphic(
                    style: AppTheme.nConcave(radius: r.scale(12)),
                    padding: EdgeInsets.symmetric(horizontal: r.scale(14), vertical: r.scale(10)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue, size: r.scale(16)),
                        SizedBox(width: r.scale(8)),
                        Expanded(
                          child: Text(
                            'Bu tarih için kayıtlı veri var. Değiştirip tekrar kaydedebilirsiniz.',
                            style: TextStyle(color: AppTheme.primaryBlue, fontSize: r.scale(12), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              NeumorphicButton(
                style: AppTheme.nConvex(radius: r.scale(16)),
                onPressed: _saveLog,
                padding: EdgeInsets.symmetric(vertical: r.scale(16)),
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: r.scale(20), color: AppTheme.primaryBlue),
                      SizedBox(width: r.scale(8)),
                      Text(
                        'Tümünü Kaydet',
                        style: TextStyle(
                          fontSize: r.scale(16),
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: r.scale(24)),

              // ── Grafik Bölümü ──
              if (_loggedDates.isNotEmpty) _buildChartSection(r),

              SizedBox(height: r.scale(24)),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  GRAFİK BÖLÜMLERİ
  // ════════════════════════════════════════════════════════════════

  Widget _buildChartSection(Responsive r) {
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(20)),
      padding: EdgeInsets.all(r.scale(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              SizedBox(
                width: r.scale(40),
                height: r.scale(40),
                child: Neumorphic(
                  style: AppTheme.nCircle(),
                  child: Center(
                    child: Icon(Icons.bar_chart_rounded, color: AppTheme.primaryBlue, size: r.scale(20)),
                  ),
                ),
              ),
              SizedBox(width: r.scale(12)),
              Text(
                'İstatistikler',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: r.scale(17),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: r.scale(16)),

          // Periyot seçici (48dp touch target)
          Row(
            children: List.generate(3, (i) {
              final labels = ['Günlük', 'Haftalık', 'Aylık'];
              final selected = _chartPeriod == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _chartPeriod = i),
                  child: Neumorphic(
                    style: selected
                        ? AppTheme.nConcave(radius: r.scale(12))
                        : AppTheme.nConvex(radius: r.scale(12), depth: 3),
                    margin: EdgeInsets.symmetric(horizontal: r.scale(4)),
                    padding: EdgeInsets.symmetric(vertical: r.scale(14)),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: selected ? AppTheme.primaryBlue : AppTheme.textGray,
                          fontSize: r.scale(12),
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: r.scale(14)),

          // Dönem etiketi
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.scale(4)),
            child: Row(
              children: [
                Icon(Icons.date_range_rounded, size: r.scale(14), color: AppTheme.textGray),
                SizedBox(width: r.scale(6)),
                Text(
                  _periodSubtitle,
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: r.scale(11),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: r.scale(10)),

          // Özet kartları (ortalamalar + trend)
          _buildSummaryRow(r),
          SizedBox(height: r.scale(16)),

          // Grafik (içe basılı neumorphic kutu + yumuşak geçiş)
          Neumorphic(
            style: AppTheme.nConcave(radius: r.scale(16)),
            padding: EdgeInsets.fromLTRB(
              r.scale(6),
              r.scale(14),
              r.scale(12),
              r.scale(8),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: SizedBox(
                key: ValueKey(_chartPeriod),
                height: r.scale(220),
                child: _buildLineChart(r),
              ),
            ),
          ),
          SizedBox(height: r.scale(14)),

          // Lejant
          _buildChartLegend(r),
        ],
      ),
    );
  }

  String get _periodSubtitle {
    switch (_chartPeriod) {
      case 0:
        return 'Son 7 gün';
      case 1:
        return 'Son 4 hafta';
      default:
        return 'Son 3 ay';
    }
  }

  /// Mevcut periyot verilerinden ortalama + trend hesaplar.
  /// improveDown=true → değer düştükçe iyidir (örn. ekran süresi).
  ({double avg, double trend, bool hasData}) _seriesSummary(List<FlSpot> spots) {
    final valid = spots.where((s) => !s.y.isNaN).map((s) => s.y).toList();
    if (valid.isEmpty) return (avg: 0, trend: 0, hasData: false);
    final avg = valid.reduce((a, b) => a + b) / valid.length;
    double trend = 0;
    if (valid.length >= 2) {
      final mid = valid.length ~/ 2;
      final first = valid.sublist(0, mid);
      final second = valid.sublist(mid);
      if (first.isNotEmpty && second.isNotEmpty) {
        final a = first.reduce((x, y) => x + y) / first.length;
        final b = second.reduce((x, y) => x + y) / second.length;
        trend = b - a;
      }
    }
    return (avg: avg, trend: trend, hasData: true);
  }

  Widget _buildSummaryRow(Responsive r) {
    final data = _chartPeriod == 0
        ? _buildDailyData()
        : _chartPeriod == 1
            ? _buildWeeklyData()
            : _buildMonthlyData();

    final screen = _seriesSummary(data['screen']!);
    final sleep = _seriesSummary(data['sleep']!);
    final act = _seriesSummary(data['activity']!);

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            r,
            icon: Icons.tv_rounded,
            color: AppTheme.riskRed,
            label: 'Ekran',
            summary: screen,
            unit: 'sa',
            improveDown: true,
          ),
        ),
        SizedBox(width: r.scale(8)),
        Expanded(
          child: _summaryCard(
            r,
            icon: Icons.nightlight_round,
            color: AppTheme.riskGreen,
            label: 'Uyku',
            summary: sleep,
            unit: 'sa',
            improveDown: false,
          ),
        ),
        SizedBox(width: r.scale(8)),
        Expanded(
          child: _summaryCard(
            r,
            icon: Icons.directions_run_rounded,
            color: AppTheme.accentPeach,
            label: 'Aktivite',
            summary: act,
            unit: '',
            improveDown: false,
            isActivity: true,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    Responsive r, {
    required IconData icon,
    required Color color,
    required String label,
    required ({double avg, double trend, bool hasData}) summary,
    required String unit,
    required bool improveDown,
    bool isActivity = false,
  }) {
    const actLevels = ['Düşük', 'Orta', 'Yüksek'];
    String valueText;
    if (!summary.hasData) {
      valueText = '—';
    } else if (isActivity) {
      valueText = actLevels[summary.avg.round().clamp(0, 2)];
    } else {
      valueText = summary.avg.toStringAsFixed(1);
    }

    return Neumorphic(
      style: AppTheme.nConcave(radius: r.scale(14)),
      padding: EdgeInsets.symmetric(
        horizontal: r.scale(10),
        vertical: r.scale(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: r.scale(14)),
              SizedBox(width: r.scale(5)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: r.scale(10),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: r.scale(8)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText,
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: r.scale(isActivity ? 13 : 17),
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                if (summary.hasData && !isActivity && unit.isNotEmpty) ...[
                  SizedBox(width: r.scale(2)),
                  Padding(
                    padding: EdgeInsets.only(bottom: r.scale(2)),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: r.scale(10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Periyoda göre verileri gruplayıp LineChart döndürür
  Widget _buildLineChart(Responsive r) {
    final data = _chartPeriod == 0
        ? _buildDailyData()
        : _chartPeriod == 1
            ? _buildWeeklyData()
            : _buildMonthlyData();

    final screenSpots = data['screen']!;
    final sleepSpots = data['sleep']!;
    final activitySpots = data['activity']!;

    final visibleSpots = <List<FlSpot>>[
      if (_showScreen) screenSpots,
      if (_showSleep) sleepSpots,
      if (_showActivity) activitySpots,
    ];

    final hasAny = visibleSpots.any((list) => list.any((s) => !s.y.isNaN));

    if (!hasAny) {
      final allHidden = !_showScreen && !_showSleep && !_showActivity;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allHidden ? Icons.visibility_off_outlined : Icons.show_chart_rounded,
              size: r.scale(36),
              color: AppTheme.textGray.withOpacity(0.4),
            ),
            SizedBox(height: r.scale(8)),
            Text(
              allHidden ? 'En az bir seri seçin' : 'Henüz yeterli veri yok',
              style: TextStyle(
                color: AppTheme.textGray,
                fontSize: r.scale(13),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!allHidden) ...[
              SizedBox(height: r.scale(4)),
              Text(
                'Günlük kayıt ekledikçe grafik oluşur',
                style: TextStyle(
                  color: AppTheme.textGray.withOpacity(0.7),
                  fontSize: r.scale(11),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final allY = visibleSpots
        .expand((list) => list)
        .where((s) => !s.y.isNaN)
        .map((s) => s.y);
    final rawMax = allY.fold<double>(0, (a, b) => math.max(a, b));

    // ~4 aralık verecek temiz bir adım seç
    double step;
    if (rawMax <= 4) {
      step = 1;
    } else if (rawMax <= 8) {
      step = 2;
    } else if (rawMax <= 12) {
      step = 3;
    } else if (rawMax <= 16) {
      step = 4;
    } else {
      step = 5;
    }
    final ceiledMax =
        math.max(step, ((rawMax / step).ceil() * step).toDouble());

    final bottomLabels = _chartPeriod == 0
        ? _dailyLabels()
        : _chartPeriod == 1
            ? _weeklyLabels()
            : _monthlyLabels();

    LineChartBarData makeLine(List<FlSpot> spots, Color color) {
      // Veri girilmemiş noktaları (null olan) filtrele — grafik atlamalı gitsin
      final filtered = spots.where((s) => !s.y.isNaN).toList();
      return LineChartBarData(
        spots: filtered,
        isCurved: false,
        color: color,
        barWidth: r.scale(2.5),
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: r.scale(3.5),
            color: Colors.white,
            strokeWidth: r.scale(2),
            strokeColor: color,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.08),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: ceiledMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: step,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.textGray.withOpacity(0.10),
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: r.scale(26),
              interval: step,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > ceiledMax + 0.01) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.only(right: r.scale(6)),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: r.scale(10),
                      color: AppTheme.textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: r.scale(24),
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= bottomLabels.length) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(top: r.scale(8)),
                  child: Text(
                    bottomLabels[idx],
                    style: TextStyle(
                      fontSize: r.scale(10),
                      color: AppTheme.textGray,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          if (_showScreen) makeLine(screenSpots, AppTheme.riskRed),
          if (_showSleep) makeLine(sleepSpots, AppTheme.riskGreen),
          if (_showActivity) makeLine(activitySpots, AppTheme.accentPeach),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.textDark.withOpacity(0.9),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipRoundedRadius: r.scale(8),
            tooltipPadding: EdgeInsets.symmetric(
              horizontal: r.scale(10),
              vertical: r.scale(6),
            ),
            tooltipMargin: r.scale(8),
            getTooltipItems: (touchedSpots) {
              final visibleLabels = <({String name, String unit, bool isActivity})>[
                if (_showScreen) (name: 'Ekran', unit: 'sa', isActivity: false),
                if (_showSleep) (name: 'Uyku', unit: 'sa', isActivity: false),
                if (_showActivity) (name: 'Aktivite', unit: '', isActivity: true),
              ];
              const actLevels = ['Düşük', 'Orta', 'Yüksek'];
              return touchedSpots.map((spot) {
                if (spot.barIndex >= visibleLabels.length) {
                  return null;
                }
                final label = visibleLabels[spot.barIndex];
                String val;
                if (label.isActivity) {
                  final level = spot.y.round().clamp(0, 2);
                  val = actLevels[level];
                } else {
                  val = '${spot.y.toStringAsFixed(1)} ${label.unit}';
                }
                return LineTooltipItem(
                  '${label.name}: $val',
                  TextStyle(
                    color: spot.bar.color ?? Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: r.scale(11),
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // ── Günlük: son 7 gün ──

  List<String> _dailyLabels() {
    const weekdays = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final labels = <String>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      labels.add(weekdays[d.weekday]);
    }
    return labels;
  }

  Map<String, List<FlSpot>> _buildDailyData() {
    final now = DateTime.now();
    final screen = <FlSpot>[];
    final sleep = <FlSpot>[];
    final activity = <FlSpot>[];

    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      final log = _loggedDates[key];
      final x = (6 - i).toDouble();
      screen.add(FlSpot(x, log?.screenHours ?? double.nan));
      sleep.add(FlSpot(x, log?.sleepHours ?? double.nan));
      activity.add(FlSpot(x, log?.activityLevel?.toDouble() ?? double.nan));
    }
    return {'screen': screen, 'sleep': sleep, 'activity': activity};
  }

  // ── Haftalık: son 4 hafta ortalamaları ──

  List<String> _weeklyLabels() {
    final labels = <String>[];
    final now = DateTime.now();
    for (int w = 3; w >= 0; w--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + w * 7));
      labels.add('${weekStart.day.toString().padLeft(2, '0')}/${weekStart.month.toString().padLeft(2, '0')}');
    }
    return labels;
  }

  Map<String, List<FlSpot>> _buildWeeklyData() {
    final now = DateTime.now();
    final screen = <FlSpot>[];
    final sleep = <FlSpot>[];
    final activity = <FlSpot>[];

    for (int w = 3; w >= 0; w--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + w * 7));
      double screenSum = 0, sleepSum = 0, actSum = 0;
      int screenCount = 0, sleepCount = 0, actCount = 0;

      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
        final log = _loggedDates[key];
        if (log == null) continue;
        if (log.screenHours != null) {
          screenSum += log.screenHours!;
          screenCount++;
        }
        if (log.sleepHours != null) {
          sleepSum += log.sleepHours!;
          sleepCount++;
        }
        if (log.activityLevel != null) {
          actSum += log.activityLevel!.toDouble();
          actCount++;
        }
      }

      final x = (3 - w).toDouble();
      screen.add(FlSpot(x, screenCount > 0 ? screenSum / screenCount : double.nan));
      sleep.add(FlSpot(x, sleepCount > 0 ? sleepSum / sleepCount : double.nan));
      activity.add(FlSpot(x, actCount > 0 ? actSum / actCount : double.nan));
    }
    return {'screen': screen, 'sleep': sleep, 'activity': activity};
  }

  // ── Aylık: son 3 ay ortalamaları ──

  List<String> _monthlyLabels() {
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    final now = DateTime.now();
    final labels = <String>[];
    for (int i = 2; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      labels.add(months[m.month]);
    }
    return labels;
  }

  Map<String, List<FlSpot>> _buildMonthlyData() {
    final now = DateTime.now();
    final screen = <FlSpot>[];
    final sleep = <FlSpot>[];
    final activity = <FlSpot>[];

    for (int i = 2; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final monthStr = "${m.year}-${m.month.toString().padLeft(2, '0')}";
      double screenSum = 0, sleepSum = 0, actSum = 0;
      int screenCount = 0, sleepCount = 0, actCount = 0;

      for (final entry in _loggedDates.entries) {
        if (!entry.key.startsWith(monthStr)) continue;
        final log = entry.value;
        if (log.screenHours != null) {
          screenSum += log.screenHours!;
          screenCount++;
        }
        if (log.sleepHours != null) {
          sleepSum += log.sleepHours!;
          sleepCount++;
        }
        if (log.activityLevel != null) {
          actSum += log.activityLevel!.toDouble();
          actCount++;
        }
      }

      final x = (2 - i).toDouble();
      screen.add(FlSpot(x, screenCount > 0 ? screenSum / screenCount : double.nan));
      sleep.add(FlSpot(x, sleepCount > 0 ? sleepSum / sleepCount : double.nan));
      activity.add(FlSpot(x, actCount > 0 ? actSum / actCount : double.nan));
    }
    return {'screen': screen, 'sleep': sleep, 'activity': activity};
  }

  Widget _buildChartLegend(Responsive r) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: r.scale(8),
      runSpacing: r.scale(8),
      children: [
        _chartLegendItem(
          r,
          AppTheme.riskRed,
          'Ekran (sa)',
          active: _showScreen,
          onTap: () => setState(() => _showScreen = !_showScreen),
        ),
        _chartLegendItem(
          r,
          AppTheme.riskGreen,
          'Uyku (sa)',
          active: _showSleep,
          onTap: () => setState(() => _showSleep = !_showSleep),
        ),
        _chartLegendItem(
          r,
          AppTheme.accentPeach,
          'Aktivite',
          active: _showActivity,
          onTap: () => setState(() => _showActivity = !_showActivity),
        ),
      ],
    );
  }

  Widget _chartLegendItem(
    Responsive r,
    Color color,
    String label, {
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.scale(8), vertical: r.scale(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: r.scale(17),
              color: color.withOpacity(active ? 1.0 : 0.35),
            ),
            SizedBox(width: r.scale(6)),
            Text(
              label,
              style: TextStyle(
                fontSize: r.scale(12),
                color: AppTheme.textDark.withOpacity(active ? 1.0 : 0.35),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════

  Widget _buildSliderCard(
    Responsive r, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required double value,
    required String valueLabel,
    required Color valueLabelColor,
    required double min,
    required double max,
    required int divisions,
    required Color activeColor,
    required ValueChanged<double> onChanged,
    required bool saved,
    required VoidCallback onSave,
  }) {
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(20)),
      padding: EdgeInsets.all(r.scale(18)),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: r.scale(40),
                height: r.scale(40),
                child: Neumorphic(
                  style: AppTheme.nCircle(),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: r.scale(20)),
                  ),
                ),
              ),
              SizedBox(width: r.scale(12)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: r.scale(15),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Neumorphic(
                style: AppTheme.nConcave(radius: r.scale(10)),
                padding: EdgeInsets.symmetric(horizontal: r.scale(12), vertical: r.scale(6)),
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    color: valueLabelColor,
                    fontSize: r.scale(14),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: r.scale(8)),
              if (saved)
                Icon(Icons.check_circle, color: AppTheme.riskGreen, size: r.scale(20))
              else
                GestureDetector(
                  onTap: onSave,
                  child: Neumorphic(
                    style: AppTheme.nConvex(radius: r.scale(10), depth: 4),
                    padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: r.scale(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_rounded, size: r.scale(14), color: iconColor),
                        SizedBox(width: r.scale(4)),
                        Text('Kaydet', style: TextStyle(fontSize: r.scale(11), fontWeight: FontWeight.w600, color: iconColor)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: r.scale(12)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: r.scale(6),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: r.scale(10)),
              overlayShape: RoundSliderOverlayShape(overlayRadius: r.scale(18)),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: activeColor,
              inactiveColor: activeColor.withOpacity(0.12),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Özel Takvim Diyaloğu ──

class _CustomCalendarDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, DailyLog> loggedDates;

  const _CustomCalendarDialog({
    required this.selectedDate,
    required this.loggedDates,
  });

  @override
  State<_CustomCalendarDialog> createState() => _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<_CustomCalendarDialog> {
  late DateTime _viewMonth;
  late DateTime _selected;
  final DateTime _today = DateTime.now();
  final DateTime _firstDate = DateTime.now().subtract(const Duration(days: 60));

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedDate;
    _viewMonth = DateTime(_selected.year, _selected.month);
  }

  void _prevMonth() {
    final prev = DateTime(_viewMonth.year, _viewMonth.month - 1);
    if (prev.isAfter(_firstDate.subtract(const Duration(days: 31)))) {
      setState(() => _viewMonth = prev);
    }
  }

  void _nextMonth() {
    final next = DateTime(_viewMonth.year, _viewMonth.month + 1);
    if (!next.isAfter(DateTime(_today.year, _today.month))) {
      setState(() => _viewMonth = next);
    }
  }

  String _monthName(int m) {
    const names = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return names[m];
  }

  String _dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final year = _viewMonth.year;
    final month = _viewMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon..7=Sun

    return Dialog(
      backgroundColor: AppTheme.nBase,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.scale(24))),
      child: Padding(
        padding: EdgeInsets.all(r.scale(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ay navigasyonu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: Icon(Icons.chevron_left_rounded, color: AppTheme.textDark, size: r.scale(24)),
                ),
                Text(
                  '${_monthName(month)} $year',
                  style: TextStyle(
                    fontSize: r.scale(17),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(Icons.chevron_right_rounded, color: AppTheme.textDark, size: r.scale(24)),
                ),
              ],
            ),
            SizedBox(height: r.scale(8)),

            // Gün başlıkları
            Row(
              children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'].map((d) {
                return Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: r.scale(11),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: r.scale(6)),

            // Gün hücreleri
            ..._buildWeeks(r, year, month, daysInMonth, firstWeekday),

            SizedBox(height: r.scale(12)),

            // Lejant
            _buildLegend(r),

            SizedBox(height: r.scale(12)),

            // Seç butonu
            NeumorphicButton(
              style: AppTheme.nConvex(radius: r.scale(12)),
              onPressed: () => Navigator.pop(context, _selected),
              padding: EdgeInsets.symmetric(vertical: r.scale(12), horizontal: r.scale(28)),
              child: Text(
                'Tarihi Seç',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: r.scale(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeeks(Responsive r, int year, int month, int daysInMonth, int firstWeekday) {
    final weeks = <Widget>[];
    // firstWeekday: 1=Mon, fill leading blanks
    final totalSlots = ((firstWeekday - 1) + daysInMonth);
    final rowCount = ((totalSlots) / 7).ceil();

    for (int week = 0; week < rowCount; week++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final slotIndex = week * 7 + col;
        final dayNum = slotIndex - (firstWeekday - 1) + 1;

        if (dayNum < 1 || dayNum > daysInMonth) {
          cells.add(const Expanded(child: SizedBox()));
          continue;
        }

        final date = DateTime(year, month, dayNum);
        final key = _dateKey(date);
        final log = widget.loggedDates[key];
        final isSelected = _isSameDay(date, _selected);
        final isToday = _isSameDay(date, _today);
        final isFuture = date.isAfter(_today);
        final isBefore = date.isBefore(_firstDate);
        final isDisabled = isFuture || isBefore;

        cells.add(Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isDisabled ? null : () => setState(() => _selected = date),
            child: _buildDayCell(r, dayNum, log, isSelected, isToday, isDisabled),
          ),
        ));
      }
      weeks.add(Padding(
        padding: EdgeInsets.symmetric(vertical: r.scale(2)),
        child: Row(children: cells),
      ));
    }
    return weeks;
  }

  Widget _buildDayCell(Responsive r, int day, DailyLog? log, bool isSelected, bool isToday, bool isDisabled) {
    final size = r.scale(44);
    final boxSize = size - r.scale(4);

    return SizedBox(
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gün numarası (arka planlı)
          Container(
            width: boxSize,
            height: boxSize - (log != null && !isDisabled && (log.screenHours != null || log.sleepHours != null || log.activityLevel != null) ? r.scale(8) : 0),
            decoration: isSelected
                ? BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(r.scale(10)),
                  )
                : isToday
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(r.scale(10)),
                        border: Border.all(color: AppTheme.primaryBlue, width: 1.5),
                      )
                    : null,
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: r.scale(13),
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                color: isDisabled
                    ? AppTheme.textGray.withOpacity(0.35)
                    : isSelected
                        ? Colors.white
                        : AppTheme.textDark,
              ),
            ),
          ),
          // Veri göstergesi noktaları
          if (log != null && !isDisabled && (log.screenHours != null || log.sleepHours != null || log.activityLevel != null))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (log.screenHours != null) _dot(r, AppTheme.riskRed, isSelected),
                if (log.screenHours != null && (log.sleepHours != null || log.activityLevel != null)) SizedBox(width: r.scale(2)),
                if (log.sleepHours != null) _dot(r, AppTheme.riskGreen, isSelected),
                if (log.sleepHours != null && log.activityLevel != null) SizedBox(width: r.scale(2)),
                if (log.activityLevel != null) _dot(r, AppTheme.accentPeach, isSelected),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dot(Responsive r, Color color, bool isSelected) {
    return Container(
      width: r.scale(4),
      height: r.scale(4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.85) : color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLegend(Responsive r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(r, AppTheme.riskRed, 'Ekran'),
        SizedBox(width: r.scale(14)),
        _legendItem(r, AppTheme.riskGreen, 'Uyku'),
        SizedBox(width: r.scale(14)),
        _legendItem(r, AppTheme.accentPeach, 'Aktivite'),
      ],
    );
  }

  Widget _legendItem(Responsive r, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: r.scale(6),
          height: r.scale(6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: r.scale(4)),
        Text(label, style: TextStyle(fontSize: r.scale(10), color: AppTheme.textGray, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
