import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

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
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    if (_report == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(r.scale(24)),
            child: Neumorphic(
              style: AppTheme.nConvex(radius: r.scale(24)),
              padding: EdgeInsets.all(r.scale(28)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: r.scale(80),
                    height: r.scale(80),
                    child: Neumorphic(
                      style: AppTheme.nCircle(depth: 7),
                      child: Center(
                        child: Icon(Icons.analytics_outlined, size: r.scale(38), color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                  SizedBox(height: r.scale(20)),
                  Text(
                    'Hen\u00fcz detayl\u0131 rapor yok',
                    style: TextStyle(fontSize: r.scale(20), fontWeight: FontWeight.w700, color: AppTheme.textDark),
                  ),
                  SizedBox(height: r.scale(8)),
                  Text(
                    'Anasayfada 7 g\u00fcnl\u00fck veriyi tamamlay\u0131p analiz olu\u015fturduktan sonra rapor burada g\u00f6r\u00fcnecek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textGray, height: 1.5, fontSize: r.scale(14)),
                  ),
                  SizedBox(height: r.scale(24)),
                  NeumorphicButton(
                    style: AppTheme.nConvex(radius: r.scale(14), depth: 4),
                    onPressed: _loadReport,
                    padding: EdgeInsets.symmetric(horizontal: r.scale(24), vertical: r.scale(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue, size: r.scale(18)),
                        SizedBox(width: r.scale(8)),
                        Text(
                          'Yenile',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: r.scale(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ResultScreen(resultData: _report!);
  }
}
