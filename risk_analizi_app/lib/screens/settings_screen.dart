import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

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
                // Header - neumorphic info card
                Neumorphic(
                  style: AppTheme.nConvex(radius: r.scale(16)),
                  padding: EdgeInsets.all(r.scale(18)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: r.scale(44),
                        height: r.scale(44),
                        child: Neumorphic(
                          style: AppTheme.nCircle(),
                          child: Center(
                            child: Icon(Icons.tune_rounded, color: AppTheme.accentGold, size: r.scale(22)),
                          ),
                        ),
                      ),
                      SizedBox(width: r.scale(12)),
                      Expanded(
                        child: Text(
                          'Uygulama tercihlerinizi buradan y\u00f6netebilirsiniz.',
                          style: TextStyle(color: AppTheme.textGray, fontSize: r.scale(14), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: r.scale(20)),

                // Notifications section
                _SectionLabel(r: r, text: 'B\u0130LD\u0130R\u0130MLER'),
                SizedBox(height: r.scale(10)),

                _buildSettingTile(
                  r,
                  icon: Icons.notifications_outlined,
                  iconColor: AppTheme.primaryBlue,
                  title: 'Bildirimler',
                  subtitle: 'Genel bilgilendirme bildirimleri',
                  value: _bildirimler,
                  onChanged: (v) {
                    setState(() => _bildirimler = v);
                    _saveSettings();
                  },
                ),
                SizedBox(height: r.scale(10)),

                _buildSettingTile(
                  r,
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppTheme.secondaryBlue,
                  title: 'Haftal\u0131k analiz hat\u0131rlatmas\u0131',
                  subtitle: '7 g\u00fcn veri giri\u015fi i\u00e7in haftal\u0131k uyar\u0131',
                  value: _haftalikHatirlatma,
                  onChanged: (v) {
                    setState(() => _haftalikHatirlatma = v);
                    _saveSettings();
                  },
                ),

                SizedBox(height: r.scale(28)),

                // About section
                _SectionLabel(r: r, text: 'HAKKINDA'),
                SizedBox(height: r.scale(10)),

                Neumorphic(
                  style: AppTheme.nConvex(radius: r.scale(18)),
                  padding: EdgeInsets.all(r.scale(18)),
                  child: Row(
                      children: [
                        SizedBox(
                          width: r.scale(48),
                          height: r.scale(48),
                          child: Neumorphic(
                            style: AppTheme.nCircle(),
                            child: Center(
                              child: Icon(Icons.health_and_safety_rounded, color: AppTheme.primaryBlue, size: r.scale(24)),
                            ),
                          ),
                        ),
                        SizedBox(width: r.scale(14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zeka Katmanlar\u0131',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: r.scale(16),
                                  color: AppTheme.textDark,
                                ),
                              ),
                              SizedBox(height: r.scale(2)),
                              Text(
                                '\u00c7ocuk Geli\u015fim Analizi',
                                style: TextStyle(
                                  color: AppTheme.textGray,
                                  fontSize: r.scale(13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Neumorphic(
                          style: AppTheme.nConcave(radius: 999),
                          padding: EdgeInsets.symmetric(horizontal: r.scale(12), vertical: r.scale(6)),
                          child: Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                              fontSize: r.scale(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingTile(
    Responsive r, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(18)),
      padding: EdgeInsets.symmetric(horizontal: r.scale(16), vertical: r.scale(14)),
      child: Row(
          children: [
            SizedBox(
              width: r.scale(44),
              height: r.scale(44),
              child: Neumorphic(
                style: AppTheme.nCircle(),
                child: Center(
                  child: Icon(icon, color: iconColor, size: r.scale(22)),
                ),
              ),
            ),
            SizedBox(width: r.scale(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: r.scale(15),
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: r.scale(2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textGray,
                      fontSize: r.scale(12),
                    ),
                  ),
                ],
              ),
            ),
            NeumorphicSwitch(
              value: value,
              onChanged: onChanged,
              style: NeumorphicSwitchStyle(
                activeTrackColor: AppTheme.primaryBlue,
                inactiveTrackColor: AppTheme.nDark.withOpacity(0.3),
                activeThumbColor: Colors.white,
                inactiveThumbColor: AppTheme.nBase,
              ),
            ),
          ],
        ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final Responsive r;
  final String text;

  const _SectionLabel({required this.r, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: r.scale(4)),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.textGray,
          fontSize: r.scale(12),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
