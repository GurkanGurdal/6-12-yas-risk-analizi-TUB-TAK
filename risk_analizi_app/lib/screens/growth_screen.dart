import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../models/growth_record.dart';
import '../services/storage_service.dart';

class GrowthScreen extends StatefulWidget {
  final ChildProfile profile;
  final ValueChanged<ChildProfile>? onProfileUpdated;

  const GrowthScreen({
    super.key,
    required this.profile,
    this.onProfileUpdated,
  });

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  late ChildProfile _profile;
  List<GrowthRecord> _records = [];
  bool _isLoading = true;

  double _newHeight = 130;
  double _newWeight = 30;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _newHeight = _profile.heightCm;
    _newWeight = _profile.weightKg;
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await StorageService.getGrowthRecords(_profile);
    if (!mounted) return;
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  String get _todayStr {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _saveRecord() async {
    final record = GrowthRecord(
      date: _todayStr,
      heightCm: _newHeight,
      weightKg: _newWeight,
    );

    await StorageService.saveGrowthRecord(_profile, record);

    // Profil bilgisini de güncelle
    final profiles = await StorageService.getProfiles();
    final idx = profiles.indexWhere((p) =>
        p.name == _profile.name && p.gender == _profile.gender);
    if (idx >= 0) {
      final updated = ChildProfile(
        name: _profile.name,
        gender: _profile.gender,
        age: _profile.age,
        heightCm: _newHeight,
        weightKg: _newWeight,
      );
      await StorageService.updateProfileAt(idx, updated);
      await StorageService.setActiveProfile(updated);
      _profile = updated;
      widget.onProfileUpdated?.call(updated);
    }

    await _loadRecords();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ölçüm kaydedildi ✓'),
        backgroundColor: AppTheme.riskGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : ListView(
              padding: r.pagePadding(horizontal: 20, top: 8, bottom: 120),
              children: [
                // Başlık
                _buildHeader(r),
                SizedBox(height: r.scale(16)),

                // Mevcut değerler
                _buildCurrentValues(r),
                SizedBox(height: r.scale(16)),

                // Boy/Kilo güncelleme
                _buildUpdateCard(r),
                SizedBox(height: r.scale(16)),

                // Boy grafiği
                if (_records.length >= 2) ...[
                  _buildChartCard(r, 'Boy Değişimi (cm)', AppTheme.primaryBlue, true),
                  SizedBox(height: r.scale(14)),
                  _buildChartCard(r, 'Kilo Değişimi (kg)', AppTheme.accentPeach, false),
                ] else
                  _buildNoDataCard(r),
              ],
            ),
    );
  }

  Widget _buildHeader(Responsive r) {
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(16)),
      padding: EdgeInsets.all(r.scale(18)),
      child: Row(
        children: [
          Neumorphic(
            style: AppTheme.nConcave(radius: r.scale(14)),
            padding: EdgeInsets.all(r.scale(10)),
            child: Icon(Icons.straighten_rounded, color: AppTheme.riskGreen, size: r.scale(26)),
          ),
          SizedBox(width: r.scale(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiziksel Gelişim',
                  style: TextStyle(
                    fontSize: r.scale(20),
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: r.scale(4)),
                Text(
                  '${_profile.name} — boy & kilo takibi',
                  style: TextStyle(fontSize: r.scale(12), color: AppTheme.textGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentValues(Responsive r) {
    return Row(
      children: [
        Expanded(
          child: Neumorphic(
            style: AppTheme.nFlat(radius: r.scale(16)),
            padding: EdgeInsets.all(r.scale(16)),
            child: Column(
              children: [
                Icon(Icons.height_rounded, color: AppTheme.primaryBlue, size: r.scale(28)),
                SizedBox(height: r.scale(8)),
                Text(
                  '${_profile.heightCm.toInt()} cm',
                  style: TextStyle(
                    fontSize: r.scale(22),
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: r.scale(4)),
                Text('Mevcut Boy', style: TextStyle(fontSize: r.scale(11), color: AppTheme.textGray)),
              ],
            ),
          ),
        ),
        SizedBox(width: r.scale(14)),
        Expanded(
          child: Neumorphic(
            style: AppTheme.nFlat(radius: r.scale(16)),
            padding: EdgeInsets.all(r.scale(16)),
            child: Column(
              children: [
                Icon(Icons.monitor_weight_rounded, color: AppTheme.accentPeach, size: r.scale(28)),
                SizedBox(height: r.scale(8)),
                Text(
                  '${_profile.weightKg.toInt()} kg',
                  style: TextStyle(
                    fontSize: r.scale(22),
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: r.scale(4)),
                Text('Mevcut Kilo', style: TextStyle(fontSize: r.scale(11), color: AppTheme.textGray)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateCard(Responsive r) {
    return Neumorphic(
      style: AppTheme.nFlat(radius: r.scale(16)),
      padding: EdgeInsets.all(r.scale(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ölçüm Güncelle',
            style: TextStyle(
              fontSize: r.scale(16),
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: r.scale(4)),
          Text(
            'Bugünkü ölçümleri girin',
            style: TextStyle(fontSize: r.scale(12), color: AppTheme.textGray),
          ),
          SizedBox(height: r.scale(16)),

          // Boy slider
          _buildSliderRow(
            r,
            icon: Icons.height_rounded,
            color: AppTheme.primaryBlue,
            label: 'Boy',
            value: _newHeight,
            suffix: ' cm',
            min: 60,
            max: 200,
            divisions: 140,
            onChanged: (v) => setState(() => _newHeight = v),
          ),
          SizedBox(height: r.scale(12)),

          // Kilo slider
          _buildSliderRow(
            r,
            icon: Icons.monitor_weight_rounded,
            color: AppTheme.accentPeach,
            label: 'Kilo',
            value: _newWeight,
            suffix: ' kg',
            min: 10,
            max: 150,
            divisions: 140,
            onChanged: (v) => setState(() => _newWeight = v),
          ),
          SizedBox(height: r.scale(18)),

          // Kaydet butonu
          Center(
            child: NeumorphicButton(
              style: AppTheme.nConvex(radius: r.scale(14)),
              onPressed: _saveRecord,
              padding: EdgeInsets.symmetric(horizontal: r.scale(28), vertical: r.scale(14)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save_rounded, color: AppTheme.riskGreen, size: r.scale(20)),
                  SizedBox(width: r.scale(8)),
                  Text(
                    'Ölçümü Kaydet',
                    style: TextStyle(
                      color: AppTheme.riskGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: r.scale(14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    Responsive r, {
    required IconData icon,
    required Color color,
    required String label,
    required double value,
    required String suffix,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: r.scale(20)),
            SizedBox(width: r.scale(8)),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: r.scale(14),
                color: AppTheme.textDark,
              ),
            ),
            const Spacer(),
            Neumorphic(
              style: AppTheme.nConcave(radius: r.scale(8)),
              padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: r.scale(4)),
              child: Text(
                '${value.toInt()}$suffix',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: r.scale(13),
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.15),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            trackHeight: r.scale(4),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: r.scale(8)),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(Responsive r, String title, Color color, bool isHeight) {
    final spots = <FlSpot>[];
    final labels = <int, String>{};

    for (int i = 0; i < _records.length; i++) {
      final rec = _records[i];
      final val = isHeight ? rec.heightCm : rec.weightKg;
      spots.add(FlSpot(i.toDouble(), val));

      // Tarih etiketi
      final parts = rec.date.split('-');
      if (parts.length == 3) {
        labels[i] = '${parts[2]}/${parts[1]}';
      }
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    final values = spots.map((s) => s.y);
    final minY = (values.reduce((a, b) => a < b ? a : b) - 5).floorToDouble();
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 5).ceilToDouble();

    return Neumorphic(
      style: AppTheme.nFlat(radius: r.scale(16)),
      padding: EdgeInsets.all(r.scale(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: r.scale(15),
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: r.scale(16)),
          SizedBox(
            height: r.scale(200),
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.nDark.withOpacity(0.25),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: r.scale(28),
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (!labels.containsKey(idx)) return const SizedBox.shrink();
                        // Show label at reasonable intervals
                        final maxLabels = 6;
                        final step = (spots.length / maxLabels).ceil().clamp(1, spots.length);
                        if (idx % step != 0 && idx != spots.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: r.scale(6)),
                          child: Text(
                            labels[idx]!,
                            style: TextStyle(
                              fontSize: r.scale(10),
                              color: AppTheme.textGray,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: r.scale(40),
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: r.scale(10),
                            color: AppTheme.textGray,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: color,
                    barWidth: r.scale(3),
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: r.scale(4),
                        color: Colors.white,
                        strokeWidth: r.scale(2.5),
                        strokeColor: color,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.textDark.withOpacity(0.85),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final dateLabel = labels[idx] ?? '';
                        final suffix = isHeight ? ' cm' : ' kg';
                        return LineTooltipItem(
                          '$dateLabel\n${spot.y.toInt()}$suffix',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: r.scale(12),
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_records.length >= 2) ...[
            SizedBox(height: r.scale(12)),
            _buildChangeSummary(r, isHeight, color),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeSummary(Responsive r, bool isHeight, Color color) {
    final first = _records.first;
    final last = _records.last;
    final firstVal = isHeight ? first.heightCm : first.weightKg;
    final lastVal = isHeight ? last.heightCm : last.weightKg;
    final diff = lastVal - firstVal;
    final suffix = isHeight ? 'cm' : 'kg';
    final sign = diff >= 0 ? '+' : '';
    final diffColor = diff >= 0 ? AppTheme.riskGreen : AppTheme.riskRed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'İlk ölçüm: ${firstVal.toInt()} $suffix',
          style: TextStyle(fontSize: r.scale(12), color: AppTheme.textGray),
        ),
        Neumorphic(
          style: AppTheme.nConcave(radius: r.scale(8)),
          padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: r.scale(4)),
          child: Text(
            '$sign${diff.toInt()} $suffix',
            style: TextStyle(
              fontSize: r.scale(12),
              fontWeight: FontWeight.w700,
              color: diffColor,
            ),
          ),
        ),
        Text(
          'Son ölçüm: ${lastVal.toInt()} $suffix',
          style: TextStyle(fontSize: r.scale(12), color: AppTheme.textGray),
        ),
      ],
    );
  }

  Widget _buildNoDataCard(Responsive r) {
    return Neumorphic(
      style: AppTheme.nFlat(radius: r.scale(16)),
      padding: EdgeInsets.all(r.scale(24)),
      child: Column(
        children: [
          Icon(Icons.show_chart_rounded, color: AppTheme.textGray.withOpacity(0.4), size: r.scale(48)),
          SizedBox(height: r.scale(12)),
          Text(
            'Grafik için en az 2 ölçüm gerekli',
            style: TextStyle(
              fontSize: r.scale(14),
              color: AppTheme.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: r.scale(6)),
          Text(
            'Yukarıdan ölçüm kaydederek boy ve kilo değişim grafiğini görüntüleyebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: r.scale(12), color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }
}
