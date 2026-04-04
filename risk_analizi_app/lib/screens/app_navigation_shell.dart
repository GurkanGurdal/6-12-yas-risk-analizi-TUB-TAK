import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import 'activities_screen.dart';
import 'analysis_report_screen.dart';
import 'dashboard_screen.dart';
import 'daily_log_screen.dart';
import 'growth_screen.dart';
import 'profiles_screen.dart';
import 'recommendations_screen.dart';
import 'settings_screen.dart';

class AppNavigationShell extends StatefulWidget {
  final ChildProfile profile;

  const AppNavigationShell({super.key, required this.profile});

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _currentIndex = 0;
  int _refreshKey = 0;
  int _previousIndex = 0;
  late ChildProfile _activeProfile;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _activeProfile = widget.profile;
  }

  List<Widget> _buildPages() {
    return [
      DashboardScreen(
        key: ValueKey('home_${_activeProfile.name}_${_activeProfile.age}_$_refreshKey'),
        profile: _activeProfile,
        onOpenAnalysisTab: () => setState(() => _currentIndex = 2),
      ),
      DailyLogScreen(
        key: ValueKey('log_${_activeProfile.name}_${_activeProfile.age}'),
        profile: _activeProfile,
        onSaved: () => setState(() {
          _refreshKey++;
          _currentIndex = 0;
        }),
      ),
      AnalysisReportScreen(
        key: ValueKey('analysis_${_activeProfile.name}_${_activeProfile.age}_$_refreshKey'),
        profile: _activeProfile,
      ),
      GrowthScreen(
        key: ValueKey('growth_${_activeProfile.name}_${_activeProfile.heightCm}_${_activeProfile.weightKg}'),
        profile: _activeProfile,
        onProfileUpdated: (updated) {
          setState(() {
            _activeProfile = updated;
            _refreshKey++;
          });
        },
      ),
      const RecommendationsScreen(),
      const ActivitiesScreen(),
      // Drawer pages (not in bottom bar)
      ProfilesScreen(
        initialProfile: _activeProfile,
        onActiveProfileChanged: (profile) {
          setState(() {
            _activeProfile = profile;
            _currentIndex = 0;
          });
        },
      ),
      const SettingsScreen(),
    ];
  }

  void _openDrawerPage(int pageIndex) {
    Navigator.pop(context); // drawer'ı kapat
    setState(() {
      if (_currentIndex < 6) _previousIndex = _currentIndex;
      _currentIndex = pageIndex;
    });
  }

  Widget _buildDrawerPageBar(Responsive r) {
    final title = _currentIndex == 6 ? 'Profiller' : 'Ayarlar';
    return Padding(
      padding: EdgeInsets.fromLTRB(r.scale(16), r.scale(8), r.scale(16), r.scale(4)),
      child: Row(
        children: [
          NeumorphicButton(
            style: AppTheme.nFlat(radius: r.scale(14)),
            padding: EdgeInsets.all(r.scale(10)),
            onPressed: () => setState(() => _currentIndex = _previousIndex),
            child: Icon(Icons.arrow_back_rounded, size: r.scale(20), color: AppTheme.textDark),
          ),
          SizedBox(width: r.scale(12)),
          Text(
            title,
            style: TextStyle(
              fontSize: r.scale(18),
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.nBase,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTheme.nBase,
        extendBody: true,
        drawer: _AppDrawer(
          activeProfile: _activeProfile,
          currentIndex: _currentIndex,
          onProfilesTap: () => _openDrawerPage(6),
          onSettingsTap: () => _openDrawerPage(7),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (_currentIndex >= 6)
                _buildDrawerPageBar(r),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _buildPages(),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(r.scale(16), 0, r.scale(16), MediaQuery.of(context).padding.bottom + r.scale(8)),
          child: _ModernBottomBar(
            currentIndex: _currentIndex < 6 ? _currentIndex : -1,
            onTap: (index) => setState(() => _currentIndex = index),
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
      ),
    );
  }
}

// ─── Drawer ───

class _AppDrawer extends StatelessWidget {
  final ChildProfile activeProfile;
  final int currentIndex;
  final VoidCallback onProfilesTap;
  final VoidCallback onSettingsTap;

  const _AppDrawer({
    required this.activeProfile,
    required this.currentIndex,
    required this.onProfilesTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Drawer(
      backgroundColor: AppTheme.nBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(r.scale(24)),
          bottomRight: Radius.circular(r.scale(24)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r.scale(16), vertical: r.scale(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil bilgisi
              Neumorphic(
                style: AppTheme.nConvex(radius: r.scale(18)),
                padding: EdgeInsets.all(r.scale(16)),
                child: Row(
                  children: [
                    SizedBox(
                      width: r.scale(48),
                      height: r.scale(48),
                      child: Neumorphic(
                        style: AppTheme.nCircle(),
                        child: Center(
                          child: Text(
                            activeProfile.initial,
                            style: TextStyle(
                              fontSize: r.scale(20),
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: r.scale(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeProfile.name,
                            style: TextStyle(
                              fontSize: r.scale(16),
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: r.scale(2)),
                          Text(
                            '${activeProfile.age.toInt()} ya\u015f \u2022 ${activeProfile.gender == 0 ? "Erkek" : "K\u0131z"}',
                            style: TextStyle(
                              fontSize: r.scale(12),
                              color: AppTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: r.scale(24)),

              // Menü öğeleri
              _DrawerItem(
                icon: Icons.groups_rounded,
                label: 'Profiller',
                color: AppTheme.primaryBlue,
                isActive: currentIndex == 6,
                onTap: onProfilesTap,
              ),
              SizedBox(height: r.scale(8)),
              _DrawerItem(
                icon: Icons.settings_rounded,
                label: 'Ayarlar',
                color: AppTheme.textGray,
                isActive: currentIndex == 7,
                onTap: onSettingsTap,
              ),

              const Spacer(),

              // Alt bilgi
              Center(
                child: Text(
                  'Risk Analizi v1.0',
                  style: TextStyle(
                    fontSize: r.scale(11),
                    color: AppTheme.textGray.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Neumorphic(
        style: isActive
            ? AppTheme.nConcave(radius: r.scale(14))
            : AppTheme.nFlat(radius: r.scale(14)),
        padding: EdgeInsets.symmetric(horizontal: r.scale(16), vertical: r.scale(14)),
        child: Row(
          children: [
            Icon(icon, color: isActive ? AppTheme.primaryBlue : color, size: r.scale(22)),
            SizedBox(width: r.scale(14)),
            Text(
              label,
              style: TextStyle(
                fontSize: r.scale(15),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textDark,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textGray.withOpacity(0.4),
              size: r.scale(20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Bar ───

class _ModernBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onMenuTap;

  const _ModernBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.onMenuTap,
  });

  static const _items = [
    (Icons.home_rounded, 'Anasayfa'),
    (Icons.edit_calendar_rounded, 'G\u00fcnl\u00fck'),
    (Icons.analytics_rounded, 'Analiz'),
    (Icons.straighten_rounded, 'Geli\u015fim'),
    (Icons.lightbulb_rounded, '\u00d6neriler'),
    (Icons.sports_esports_rounded, 'Aktivite'),
  ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Neumorphic(
      style: AppTheme.nConvex(radius: r.scale(24)),
      padding: EdgeInsets.all(r.scale(6)),
      child: Row(
        children: [
          // Hamburger menu button – standalone
          GestureDetector(
            onTap: onMenuTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: r.scale(6)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_rounded, size: r.scale(24), color: AppTheme.textGray),
                  SizedBox(height: r.scale(4)),
                  Text(
                    'Men\u00fc',
                    style: TextStyle(
                      fontSize: r.scale(10, minScale: 0.9, maxScale: 1.1),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: r.scale(4)),
          // Nav items inside concave neumorphic box
          Expanded(
            child: Neumorphic(
              style: AppTheme.nConcave(radius: r.scale(18)),
              padding: EdgeInsets.symmetric(horizontal: r.scale(4), vertical: r.scale(4)),
              child: Row(
                children: List.generate(_items.length, (index) {
                  final selected = index == currentIndex;
                  final (icon, label) = _items[index];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryBlue.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(r.scale(14)),
                        ),
                        padding: EdgeInsets.symmetric(vertical: r.scale(8)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: r.scale(20),
                              color: selected ? AppTheme.primaryBlue : AppTheme.textGray,
                            ),
                            SizedBox(height: r.scale(3)),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: r.scale(9, minScale: 0.9, maxScale: 1.1),
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected ? AppTheme.primaryBlue : AppTheme.textGray,
                              ),
                            ),
                            // Seçili göstergesi: küçük dot
                            SizedBox(height: r.scale(3)),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: selected ? r.scale(16) : 0,
                              height: r.scale(3),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.primaryBlue : Colors.transparent,
                                borderRadius: BorderRadius.circular(r.scale(2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
