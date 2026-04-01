import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../models/daily_log.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'daily_log_screen.dart'; // Eski analiz formunun yerini alacak
import 'result_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ChildProfile profile;
  
  const DashboardScreen({super.key, required this.profile});

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
    final logs = await StorageService.getDailyLogs();
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

    if (mounted) {
      setState(() {
        _riskResult = result;
        _isAnalyzing = false;
      });
    }
  }

  void _showUpdateDialog() {
    double tempBoy = _profile.heightCm;
    double tempKilo = _profile.weightKg;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Gelişim Güncelle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Boy (cm)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: tempBoy,
                    min: 100, max: 200,
                    activeColor: AppTheme.secondaryBlue,
                    onChanged: (val) => setStateDialog(() => tempBoy = val),
                  ),
                  Text('${tempBoy.toInt()} cm', style: const TextStyle(color: AppTheme.secondaryBlue)),
                  const SizedBox(height: 16),
                  
                  const Text('Kilo (kg)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: tempKilo,
                    min: 15, max: 120,
                    activeColor: AppTheme.secondaryBlue,
                    onChanged: (val) => setStateDialog(() => tempKilo = val),
                  ),
                  Text('${tempKilo.toInt()} kg', style: const TextStyle(color: AppTheme.secondaryBlue)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedProfile = ChildProfile(
                      name: _profile.name,
                      gender: _profile.gender,
                      age: _profile.age,
                      heightCm: tempBoy,
                      weightKg: tempKilo,
                    );
                    await StorageService.saveProfile(updatedProfile);
                    setState(() => _profile = updatedProfile);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      _loadData(); // Risk değişmiş olabilir
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    int loggedDays = _logs.length;
    double progress = (loggedDays / 7.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Kontrol Paneli'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
        centerTitle: true,
      ),
      body: _isLoadingLogs ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Üst Profil Kartı
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          _profile.initial,
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba,',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                            ),
                            Text(
                              _profile.name,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _showUpdateDialog,
                        tooltip: 'Boy/Kilo Güncelle',
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoStat('Yaş', '${_profile.age.toInt()}'),
                      _buildInfoStat('Boy', '${_profile.heightCm.toInt()} cm'),
                      _buildInfoStat('Kilo', '${_profile.weightKg.toInt()} kg'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Durum ve İlerleme veya Sonuç
            if (loggedDays < 7) ...[
              const Text('Haftalık Analiz Bekleniyor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.riskYellow),
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Text('$loggedDays/7 Gün Tamamlandı', style: const TextStyle(color: AppTheme.textGray)),
              const SizedBox(height: 16),
              const Text(
                'Yapay Zeka analizinin hesaplanabilmesi için 7 günlük uyku, ekran ve aktivite verisi girilmelidir. Eksik günleri + butonundan ekleyebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGray, fontSize: 13),
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
                Card(
                  elevation: 4,
                  shadowColor: AppTheme.primaryBlue.withOpacity(0.2),
                  color: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.psychology, size: 48, color: Colors.white),
                        const SizedBox(height: 16),
                        const Text('Haftalık Risk Durumu', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          '%${_riskResult!['genel_risk_puani']}',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          _riskResult!['analiz_sonucu'],
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultScreen(resultData: _riskResult!),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryBlue),
                          child: const Text('Detaylı Raporu Gör'),
                        )
                      ],
                    ),
                  ),
                )
              else 
                const Text('Sonuç alınamadı, API bağlantısını kontrol edin.', style: TextStyle(color: AppTheme.riskRed)),
            ],

            const SizedBox(height: 32),
            // Günlük Ekle Butonu
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyLogScreen()),
                  );
                  // Veri eklenince tekrar yükle
                  _loadData();
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Günlük İstatistik Gir (+)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.riskGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
      ],
    );
  }
}
