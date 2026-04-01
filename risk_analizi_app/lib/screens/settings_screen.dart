import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _bildirimler = true;
  bool _haftalikHatirlatma = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.getSettings();
    if (!mounted) return;
    setState(() {
      _bildirimler = settings['notifications'] ?? true;
      _haftalikHatirlatma = settings['weeklyReminder'] ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await StorageService.saveSettings(
      notifications: _bildirimler,
      weeklyReminder: _haftalikHatirlatma,
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
          Container(
            padding: EdgeInsets.all(r.scale(20)),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlue,
              borderRadius: BorderRadius.circular(r.scale(20)),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: AppTheme.accentGold, size: r.scale(24)),
                SizedBox(width: r.scale(10)),
                Expanded(
                  child: Text(
                    'Uygulama tercihlerinizi buradan yönetebilirsiniz.',
                    style: TextStyle(color: AppTheme.mutedOnDark, fontSize: r.scale(14)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: r.scale(14)),
          Card(
            color: AppTheme.secondaryBlue,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Bildirimler', style: TextStyle(color: AppTheme.textOnDark)),
                  subtitle: const Text('Genel bilgilendirme bildirimleri', style: TextStyle(color: AppTheme.mutedOnDark)),
                  value: _bildirimler,
                  onChanged: (v) {
                    setState(() => _bildirimler = v);
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  title: const Text('Haftalık analiz hatırlatması', style: TextStyle(color: AppTheme.textOnDark)),
                  subtitle: const Text('7 gün veri girişi için haftalık uyarı', style: TextStyle(color: AppTheme.mutedOnDark)),
                  value: _haftalikHatirlatma,
                  onChanged: (v) {
                    setState(() => _haftalikHatirlatma = v);
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: r.scale(12)),
          Card(
            color: AppTheme.secondaryBlue,
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.accentGold),
              title: const Text('Uygulama Sürümü', style: TextStyle(color: AppTheme.textOnDark)),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: r.scale(6)),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('v1.0.0', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryBlue, fontSize: r.scale(12))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
