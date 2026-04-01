import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../models/daily_log.dart';
import '../services/storage_service.dart';

class DailyLogScreen extends StatefulWidget {
  final ChildProfile profile;

  const DailyLogScreen({super.key, required this.profile});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  DateTime _selectedDate = DateTime.now();
  double _uykuSaati = 8;
  double _ekranSaati = 2;
  int _fizikselAktivite = 1;

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveLog() async {
    // Tarihi YYYY-MM-DD olarak formatla
    final String dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    
    final log = DailyLog(
      date: dateStr,
      sleepHours: _uykuSaati,
      screenHours: _ekranSaati,
      activityLevel: _fizikselAktivite,
    );

    await StorageService.saveDailyLogForProfile(widget.profile, log);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$dateStr verisi başarıyla eklendi!'),
        backgroundColor: AppTheme.riskGreen,
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final r = Responsive(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.scale(16.0)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondaryBlue, size: r.scale(24)),
          SizedBox(width: r.scale(8)),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
        padding: r.pagePadding(horizontal: 24, top: 12, bottom: 28),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(r.scale(18)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(r.scale(20)),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timeline, color: AppTheme.primaryBlue, size: r.scale(28)),
                  SizedBox(width: r.scale(10)),
                  Expanded(
                    child: Text(
                      'Son 7 gün verisi analiz kalitesini artırır. Bugüne veya geçmiş güne veri girebilirsiniz.',
                      style: TextStyle(color: AppTheme.textGray, height: 1.35, fontSize: r.scale(14)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.scale(16)),
            // Takvim Seçici
            Card(
              child: ListTile(
                leading: Icon(Icons.calendar_month, color: AppTheme.primaryBlue, size: r.scale(32)),
                title: const Text('Tarih Seçin'),
                subtitle: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                trailing: const Icon(Icons.edit),
                onTap: _pickDate,
              ),
            ),
            SizedBox(height: r.scale(20)),
            
            _buildSectionTitle('Televizyon / Telefon', Icons.smartphone),
            Card(
              child: Padding(
                padding: EdgeInsets.all(r.scale(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ekran Süresi', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${_ekranSaati.toInt()} Saat', style: const TextStyle(color: AppTheme.riskRed)),
                      ],
                    ),
                    Slider(
                      value: _ekranSaati,
                      min: 0, max: 14, divisions: 14,
                      activeColor: AppTheme.riskRed,
                      onChanged: (val) => setState(() => _ekranSaati = val),
                    ),
                  ],
                ),
              ),
            ),
            
            _buildSectionTitle('Uyku Düzeni', Icons.bed_outlined),
            Card(
              child: Padding(
                padding: EdgeInsets.all(r.scale(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Uyku Süresi', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${_uykuSaati.toInt()} Saat', style: const TextStyle(color: AppTheme.riskGreen)),
                      ],
                    ),
                    Slider(
                      value: _uykuSaati,
                      min: 0, max: 16, divisions: 16,
                      activeColor: AppTheme.riskGreen,
                      onChanged: (val) => setState(() => _uykuSaati = val),
                    ),
                  ],
                ),
              ),
            ),

            _buildSectionTitle('Hareket', Icons.directions_run),
            Card(
              child: Padding(
                padding: EdgeInsets.all(r.scale(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aktivite Seviyesi', style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: r.scale(16)),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Düşük')),
                          ButtonSegment(value: 1, label: Text('Orta')),
                          ButtonSegment(value: 2, label: Text('Yüksek')),
                        ],
                        selected: {_fizikselAktivite},
                        onSelectionChanged: (set) {
                          setState(() => _fizikselAktivite = set.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: r.scale(48)),
            
            SizedBox(
              width: double.infinity,
              height: r.scale(60),
              child: ElevatedButton.icon(
                onPressed: _saveLog,
                icon: const Icon(Icons.save),
                label: const Text('Bu Günü Kaydet'),
              ),
            ),
            SizedBox(height: r.scale(32)),
          ],
        ),
      ),
      ),
    );
  }
}
