import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class AnalysisFormScreen extends StatefulWidget {
  final ChildProfile profile;
  const AnalysisFormScreen({super.key, required this.profile});

  @override
  State<AnalysisFormScreen> createState() => _AnalysisFormScreenState();
}

class _AnalysisFormScreenState extends State<AnalysisFormScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Yaşam Tarzı Değerleri
  double uykuSaati = 9;
  double ekranSaati = 2;
  int fizikselAktivite = 1; // 0=Düşük, 1=Orta, 2=Yüksek

  void _analizYap() async {
    setState(() => _isLoading = true);
    
    final sonuc = await _apiService.analizYap(
      yas: widget.profile.age,
      cinsiyet: widget.profile.gender,
      boyKm: widget.profile.heightCm,
      kiloKg: widget.profile.weightKg,
      uykuSaati: uykuSaati,
      ekranSaati: ekranSaati,
      fizikselAktivite: fizikselAktivite,
    );

    setState(() => _isLoading = false);

    if (sonuc != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(resultData: sonuc)),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Bağlantı Hatası! Python sunucusu açık mı?')),
      );
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondaryBlue, size: 24),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Yaşam Formu'),
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
      : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_graph, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bu form, bugün için hızlı risk tahmini üretir.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Çocuğunuzun son dönemdeki alışkanlıklarını seçiniz:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              
              _buildSectionTitle('Televizyon / Telefon', Icons.smartphone),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Günlük Ekran Süresi', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('${ekranSaati.toInt()} Saat', style: const TextStyle(color: AppTheme.riskRed)),
                        ],
                      ),
                      Slider(
                        value: ekranSaati,
                        min: 0, max: 14, divisions: 14,
                        activeColor: AppTheme.riskRed,
                        onChanged: (val) => setState(() => ekranSaati = val),
                      ),
                    ],
                  ),
                ),
              ),
              
              _buildSectionTitle('Uyku Düzeni', Icons.bed_outlined),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Günlük Uyku Süresi', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('${uykuSaati.toInt()} Saat', style: const TextStyle(color: AppTheme.riskGreen)),
                        ],
                      ),
                      Slider(
                        value: uykuSaati,
                        min: 0, max: 16, divisions: 16,
                        activeColor: AppTheme.riskGreen,
                        onChanged: (val) => setState(() => uykuSaati = val),
                      ),
                    ],
                  ),
                ),
              ),

              _buildSectionTitle('Hareket', Icons.directions_run),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fiziksel Aktivite Seviyesi', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 0, label: Text('Düşük')),
                            ButtonSegment(value: 1, label: Text('Orta')),
                            ButtonSegment(value: 2, label: Text('Yüksek')),
                          ],
                          selected: {fizikselAktivite},
                          onSelectionChanged: (set) {
                            setState(() => fizikselAktivite = set.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _analizYap,
                  icon: const Icon(Icons.psychology),
                  label: const Text('Yapay Zeka Analizini Başlat'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
      ),
    );
  }
}
