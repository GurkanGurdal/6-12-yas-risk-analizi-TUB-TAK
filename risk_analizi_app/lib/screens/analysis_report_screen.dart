import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../services/storage_service.dart';
import 'result_screen.dart';

class AnalysisReportScreen extends StatefulWidget {
  final ChildProfile profile;

  const AnalysisReportScreen({super.key, required this.profile});

  @override
  State<AnalysisReportScreen> createState() => _AnalysisReportScreenState();
}

class _AnalysisReportScreenState extends State<AnalysisReportScreen> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void didUpdateWidget(covariant AnalysisReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.name != widget.profile.name ||
        oldWidget.profile.gender != widget.profile.gender ||
        oldWidget.profile.age != widget.profile.age ||
        oldWidget.profile.heightCm != widget.profile.heightCm ||
        oldWidget.profile.weightKg != widget.profile.weightKg) {
      _loadReport();
    }
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final report = await StorageService.getLatestRiskReportForProfile(widget.profile);
    if (!mounted) return;

    setState(() {
      _report = report;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    if (_report == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(r.scale(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: r.scale(88),
                  height: r.scale(88),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold,
                    borderRadius: BorderRadius.circular(r.scale(24)),
                  ),
                  child: Icon(Icons.analytics_outlined, size: r.scale(42), color: AppTheme.primaryBlue),
                ),
                SizedBox(height: r.scale(16)),
                Text(
                  'Henüz detaylı rapor yok',
                  style: TextStyle(fontSize: r.scale(20), fontWeight: FontWeight.w700, color: AppTheme.textOnDark),
                ),
                SizedBox(height: r.scale(8)),
                Text(
                  'Anasayfada 7 günlük veriyi tamamlayıp analiz oluşturduktan sonra rapor burada görünecek.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.mutedOnDark, height: 1.35, fontSize: r.scale(14)),
                ),
                SizedBox(height: r.scale(16)),
                OutlinedButton.icon(
                  onPressed: _loadReport,
                  icon: const Icon(Icons.refresh, color: AppTheme.accentGold),
                  label: const Text('Yenile', style: TextStyle(color: AppTheme.accentGold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ResultScreen(resultData: _report!);
  }
}
