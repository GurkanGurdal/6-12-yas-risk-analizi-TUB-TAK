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

          // Periyot seçici
          Row(
            children: List.generate(3, (i) {
              final labels = ['Günlük', 'Haftalık', 'Aylık'];
              final selected = _chartPeriod == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _chartPeriod = i),
                  child: Neumorphic(
                    style: selected
                        ? AppTheme.nConcave(radius: r.scale(12))
                        : AppTheme.nConvex(radius: r.scale(12), depth: 3),
                    margin: EdgeInsets.symmetric(horizontal: r.scale(4)),
                    padding: EdgeInsets.symmetric(vertical: r.scale(10)),
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
          SizedBox(height: r.scale(18)),

          // Grafik
          SizedBox(
            height: r.scale(220),
            child: _buildLineChart(r),
          ),
          SizedBox(height: r.scale(14)),

          // Lejant
          _buildChartLegend(r),
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

    final hasAny = screenSpots.any((s) => !s.y.isNaN) ||
        sleepSpots.any((s) => !s.y.isNaN) ||
        activitySpots.any((s) => !s.y.isNaN);

    if (!hasAny) {
      return Center(
        child: Text(
          'Henüz yeterli veri yok',
          style: TextStyle(color: AppTheme.textGray, fontSize: r.scale(13)),
        ),
      );
    }

    final allY = [...screenSpots, ...sleepSpots, ...activitySpots]
        .where((s) => !s.y.isNaN)
        .map((s) => s.y);
    final rawMax = allY.fold<double>(0, (a, b) => math.max(a, b));
    final ceiledMax = ((rawMax / 2).ceil() * 2).toDouble().clamp(2.0, 20.0);

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
          horizontalInterval: ceiledMax / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.textGray.withOpacity(0.12),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: r.scale(32),
              interval: ceiledMax / 4,
              getTitlesWidget: (value, meta) {
                if (value == ceiledMax) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: r.scale(10), color: AppTheme.textGray),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: r.scale(28),
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= bottomLabels.length) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(top: r.scale(6)),
                  child: Text(
                    bottomLabels[idx],
                    style: TextStyle(fontSize: r.scale(10), color: AppTheme.textGray),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          makeLine(screenSpots, AppTheme.riskRed),
          makeLine(sleepSpots, AppTheme.riskGreen),
          makeLine(activitySpots, AppTheme.accentPeach),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.textDark.withOpacity(0.85),
            getTooltipItems: (touchedSpots) {
              final labels = [
                ('Ekran', 'sa'),
                ('Uyku', 'sa'),
                ('Aktivite', ''),
              ];
              const actLevels = ['Düşük', 'Orta', 'Yüksek'];
              return touchedSpots.map((spot) {
                final i = spot.barIndex;
                final name = labels[i].$1;
                String val;
                if (i == 2) {
                  final level = spot.y.round().clamp(0, 2);
                  val = actLevels[level];
                } else {
                  val = '${spot.y.toStringAsFixed(1)} ${labels[i].$2}';
                }
                return LineTooltipItem(
                  '$name: $val',
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
    final labels = <String>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      labels.add('${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}');
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
      final hasData = log != null && (log.screenHours != null || log.sleepHours != null);
      screen.add(FlSpot(x, hasData ? (log.screenHours ?? 0) : double.nan));
      sleep.add(FlSpot(x, hasData ? (log.sleepHours ?? 0) : double.nan));
      activity.add(FlSpot(x, hasData ? (log.activityLevel?.toDouble() ?? 0) : double.nan));
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
      int count = 0;

      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
        final log = _loggedDates[key];
        if (log != null && (log.screenHours != null || log.sleepHours != null)) {
          screenSum += log.screenHours ?? 0;
          sleepSum += log.sleepHours ?? 0;
          actSum += log.activityLevel?.toDouble() ?? 0;
          count++;
        }
      }

      final x = (3 - w).toDouble();
      screen.add(FlSpot(x, count > 0 ? screenSum / count : double.nan));
      sleep.add(FlSpot(x, count > 0 ? sleepSum / count : double.nan));
      activity.add(FlSpot(x, count > 0 ? actSum / count : double.nan));
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
      int count = 0;

      for (final entry in _loggedDates.entries) {
        if (entry.key.startsWith(monthStr)) {
          final log = entry.value;
          screenSum += log.screenHours ?? 0;
          sleepSum += log.sleepHours ?? 0;
          actSum += log.activityLevel?.toDouble() ?? 0;
          count++;
        }
      }

      final x = (2 - i).toDouble();
      screen.add(FlSpot(x, count > 0 ? screenSum / count : double.nan));
      sleep.add(FlSpot(x, count > 0 ? sleepSum / count : double.nan));
      activity.add(FlSpot(x, count > 0 ? actSum / count : double.nan));
    }
    return {'screen': screen, 'sleep': sleep, 'activity': activity};
  }

  Widget _buildChartLegend(Responsive r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chartLegendItem(r, AppTheme.riskRed, 'Ekran (sa)'),
        SizedBox(width: r.scale(16)),
        _chartLegendItem(r, AppTheme.riskGreen, 'Uyku (sa)'),
        SizedBox(width: r.scale(16)),
        _chartLegendItem(r, AppTheme.accentPeach, 'Aktivite'),
      ],
    );
  }

  Widget _chartLegendItem(Responsive r, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: r.scale(10),
          height: r.scale(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(r.scale(3)),
          ),
        ),
        SizedBox(width: r.scale(5)),
        Text(
          label,
          style: TextStyle(fontSize: r.scale(11), color: AppTheme.textGray, fontWeight: FontWeight.w500),
        ),
      ],
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
