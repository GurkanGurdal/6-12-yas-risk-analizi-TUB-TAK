import 'package:flutter/material.dart';
import 'dart:ui';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import 'analysis_report_screen.dart';
import 'dashboard_screen.dart';
import 'profiles_screen.dart';
import 'settings_screen.dart';

class AppNavigationShell extends StatefulWidget {
  final ChildProfile profile;

  const AppNavigationShell({super.key, required this.profile});

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _currentIndex = 0;
  late ChildProfile _activeProfile;

  @override
  void initState() {
    super.initState();
    _activeProfile = widget.profile;
  }

  List<Widget> _buildPages() {
    return [
      DashboardScreen(
        key: ValueKey('home_${_activeProfile.name}_${_activeProfile.age}'),
        profile: _activeProfile,
        onOpenAnalysisTab: () => setState(() => _currentIndex = 1),
      ),
      AnalysisReportScreen(
        key: ValueKey('analysis_${_activeProfile.name}_${_activeProfile.age}'),
        profile: _activeProfile,
      ),
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

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _buildPages(),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(r.scale(16), 0, r.scale(16), r.scale(14)),
        child: SafeArea(
          top: false,
          child: _ModernBottomBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ),
      ),
    );
  }
}

class _ModernBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ModernBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_rounded, 'Anasayfa'),
    (Icons.analytics_rounded, 'Analiz'),
    (Icons.groups_rounded, 'Profiller'),
    (Icons.settings_rounded, 'Ayarlar'),
  ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(r.scale(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(r.scale(8)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(r.scale(22)),
            border: Border.all(color: Colors.white.withOpacity(0.30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: r.scale(20),
                offset: Offset(0, r.scale(8)),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
          final selected = index == currentIndex;
          final (icon, label) = _items[index];

          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(r.scale(16)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(vertical: r.scale(10)),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.accentGold.withOpacity(0.85) : Colors.transparent,
                  borderRadius: BorderRadius.circular(r.scale(16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: r.scale(22),
                      color: selected ? AppTheme.primaryBlue : Colors.white.withOpacity(0.82),
                    ),
                    SizedBox(height: r.scale(5)),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: r.scale(12, minScale: 0.9, maxScale: 1.2),
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppTheme.primaryBlue : Colors.white.withOpacity(0.82),
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
    );
  }
}
